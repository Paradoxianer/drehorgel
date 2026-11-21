import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:just_audio/just_audio.dart';

import 'songs.dart';

/// Abstraktion für die Tonerzeugung. Die Kurbel liefert nur einen stufenlosen
/// Tempo-Faktor (1.0 = Originaltempo, 0 = Kurbel steht).
abstract class OrganPlayer {
  /// Android -> MIDI + SoundFont, sonst (Web/iOS) -> mp3.
  factory OrganPlayer.forPlatform() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return MidiOrganPlayer();
    }
    return AudioOrganPlayer();
  }

  Future<void> init(OrganRoll roll);

  Future<void> selectRoll(OrganRoll roll);

  /// [factor] 0 = anhalten (mit "Blasebalg leer"), sonst Tempo relativ zum
  /// Original.
  void setTempo(double factor);

  /// Welche Strophe gerade läuft (null, solange nichts geladen ist).
  Future<RollEntry?> currentEntry();

  /// Spult die Rolle an den Anfang von [entry] (spielt nur, wenn gekurbelt wird).
  Future<void> seekTo(RollEntry entry);

  Future<void> dispose();
}

/// Gemeinsame Logik: Plugin-Aufrufe serialisieren (immer nur der neueste
/// Tempo-Wert zählt) und das Wind-Modell des Blasebalgs.
abstract class _BellowsPlayer implements OrganPlayer {
  /// Unterhalb dieses Tempos reicht der Wind nicht mehr ganz: leiser und
  /// leicht zu tief.
  static const double fullWindTempo = 0.7;
  static const Duration deflateTime = Duration(milliseconds: 750);

  double? _pending;
  bool _busy = false;
  bool _playing = false;
  int _deflateGeneration = 0;
  RollIndex? _index;

  @override
  void setTempo(double factor) {
    _pending = factor;
    if (!_busy) _pump();
  }

  Future<void> _pump() async {
    _busy = true;
    try {
      while (_pending != null) {
        final f = _pending!;
        _pending = null;
        await _applyTempo(f);
      }
    } catch (e) {
      debugPrint('OrganPlayer: $e');
    } finally {
      _busy = false;
    }
  }

  Future<void> _applyTempo(double factor) async {
    if (factor > 0) {
      _deflateGeneration++; // laufendes "Ausatmen" abbrechen
      if (!_playing) {
        _playing = true;
        await startPlayback();
      }
      await setSpeed(factor);
      await setWind((factor / fullWindTempo).clamp(0.0, 1.0), 0);
    } else if (_playing) {
      _playing = false;
      unawaited(_deflate());
    }
  }

  /// Blasebalg leer: Druck fällt ab, die letzte Note sackt nach unten und
  /// verklingt, dann hält die Orgel an.
  Future<void> _deflate() async {
    final generation = ++_deflateGeneration;
    final sw = Stopwatch()..start();
    try {
      while (true) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        if (generation != _deflateGeneration) return; // wieder gekurbelt
        final t = min(1.0, sw.elapsedMilliseconds / deflateTime.inMilliseconds);
        final wind = 0.6 * pow(1 - t, 1.6).toDouble();
        await setWind(wind, 140 * pow(t, 1.4).toDouble());
        if (t >= 1) break;
      }
      if (generation != _deflateGeneration) return;
      await pausePlayback();
      await setWind(1, 0); // für den nächsten Start zurücksetzen
    } catch (e) {
      debugPrint('OrganPlayer deflate: $e');
    }
  }

  // --- plattformspezifisch ---
  Future<void> startPlayback();
  Future<void> pausePlayback();
  Future<void> setSpeed(double factor);

  /// [wind] 0..1 = Balgdruck (Lautstärke), [extraSagCents] zusätzliches
  /// Absinken der Tonhöhe.
  Future<void> setWind(double wind, double extraSagCents);
}

/// Android: Notenrolle als MIDI über FluidSynth mit der Drehorgel-SoundFont.
class MidiOrganPlayer extends _BellowsPlayer {
  final MidiPro _midi = MidiPro();
  int _sfId = 0;
  int _lastBend = -1;
  double _lastGain = -1;

  @override
  Future<void> init(OrganRoll roll) async {
    // Latenz ist egal (keine Live-Tasten), größerer Puffer = robuster.
    await _midi.init(sampleRate: 48000, bufferSize: 512);
    _sfId = await _midi.loadSoundfontAsset(assetPath: soundfontAsset);
    await _midi.setReverb(enabled: true, roomSize: 0.3, level: 0.4);
    await _load(roll);
  }

  Future<void> _load(OrganRoll roll) async {
    _index = await RollIndex.load(roll);
    await _midi.loadMidiAsset(assetPath: roll.midiAsset, sfId: _sfId);
    await _midi.setMidiLoop(-1);
    if (_playing) await _midi.playMidi();
  }

  @override
  Future<void> selectRoll(OrganRoll roll) async {
    await _midi.stopMidi();
    await _load(roll);
  }

  @override
  Future<void> startPlayback() => _midi.playMidi();

  @override
  Future<void> pausePlayback() => _midi.pauseMidi();

  @override
  Future<void> setSpeed(double factor) => _midi.setMidiTempo(factor.clamp(0.3, 2.5));

  @override
  Future<void> setWind(double wind, double extraSagCents) async {
    // Wenig Wind = Pfeifen klingen zu tief (bis -40 Cent) und leiser.
    final cents = -(1 - wind) * 40 - extraSagCents;
    final bend = (8192 + cents / 200 * 8192).round().clamp(0, 16383);
    if ((bend - _lastBend).abs() >= 16) {
      _lastBend = bend;
      for (var ch = 0; ch < 3; ch++) {
        await _midi.pitchBend(value: bend, channel: ch, sfId: _sfId);
      }
    }
    final gain = 0.85 * pow(wind, 0.8).toDouble();
    if ((gain - _lastGain).abs() > 0.01) {
      _lastGain = gain;
      await _midi.setMasterGain(gain);
    }
  }

  @override
  Future<void> seekTo(RollEntry entry) => _midi.seekMidi(entry.tick);

  @override
  Future<RollEntry?> currentEntry() async {
    final index = _index;
    if (index == null || !_midi.isInitialized) return null;
    final state = await _midi.getMidiPlayerState();
    if (state.status == null || index.totalTicks == 0) return null;
    return index.entryAtTick(state.currentTick % index.totalTicks);
  }

  @override
  Future<void> dispose() => _midi.dispose();
}

/// Web/iOS: vorgerenderte mp3 der Rolle, Tempo über die Wiedergabe-
/// geschwindigkeit (im Browser bleibt die Tonhöhe dabei gleich).
class AudioOrganPlayer extends _BellowsPlayer {
  final AudioPlayer _player = AudioPlayer();
  double _speed = 0;
  double _volume = -1;

  @override
  Future<void> init(OrganRoll roll) async {
    await _player.setLoopMode(LoopMode.one);
    await _load(roll);
  }

  Future<void> _load(OrganRoll roll) async {
    _index = await RollIndex.load(roll);
    await _player.setAsset(roll.mp3Asset);
    if (_playing) unawaited(_player.play());
  }

  @override
  Future<void> selectRoll(OrganRoll roll) => _load(roll);

  @override
  Future<void> startPlayback() async {
    unawaited(_player.play()); // play() endet erst beim Pausieren
  }

  @override
  Future<void> pausePlayback() => _player.pause();

  @override
  Future<void> setSpeed(double factor) async {
    // just_audio verträgt keine setSpeed-Aufrufe pro Frame -> 0.1er-Schritte.
    final speed = (factor.clamp(0.5, 2.0) * 10).roundToDouble() / 10;
    if (speed != _speed) {
      _speed = speed;
      await _player.setSpeed(speed);
    }
  }

  @override
  Future<void> setWind(double wind, double extraSagCents) async {
    final volume = (pow(wind, 0.8).toDouble() * 20).roundToDouble() / 20;
    if (volume != _volume) {
      _volume = volume;
      await _player.setVolume(volume);
    }
  }

  @override
  Future<void> seekTo(RollEntry entry) =>
      _player.seek(Duration(milliseconds: (entry.sec * 1000).round()));

  @override
  Future<RollEntry?> currentEntry() async {
    final index = _index;
    if (index == null) return null;
    return index.entryAtSec(_player.position.inMilliseconds / 1000.0);
  }

  @override
  Future<void> dispose() => _player.dispose();
}

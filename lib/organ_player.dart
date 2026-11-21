import 'package:just_audio/just_audio.dart';

/// Abstraktion für die Tonerzeugung. Die Kurbel liefert nur noch einen
/// stufenlosen Tempo-Faktor (1.0 = Originaltempo, 0 = steht).
///
/// Heute: [AudioOrganPlayer] (mp3 + Wiedergabegeschwindigkeit).
/// Später: ein MIDI-Player, der die Noten selbst taktet und das Tempo
/// stufenlos ohne Tonhöhenänderung übernimmt.
abstract class OrganPlayer {
  Future<void> init();

  /// [factor] 0 = anhalten, sonst Tempo relativ zum Original.
  void setTempo(double factor);

  Future<void> dispose();
}

class AudioOrganPlayer implements OrganPlayer {
  final String asset;
  final AudioPlayer _player = AudioPlayer();

  /// just_audio verträgt keine setSpeed-Aufrufe pro Frame – daher wird auf
  /// 0.1er-Schritte gerundet und nur bei Änderung gesetzt.
  double _currentSpeed = 0;

  AudioOrganPlayer(this.asset);

  @override
  Future<void> init() async {
    await _player.setAsset(asset);
    await _player.setLoopMode(LoopMode.one);
  }

  @override
  void setTempo(double factor) {
    if (factor <= 0) {
      if (_player.playing) _player.pause();
      _currentSpeed = 0;
      return;
    }
    final speed = (factor.clamp(0.5, 2.0) * 10).roundToDouble() / 10;
    if (speed != _currentSpeed) {
      _currentSpeed = speed;
      _player.setSpeed(speed);
    }
    if (!_player.playing) _player.play();
  }

  @override
  Future<void> dispose() => _player.dispose();
}

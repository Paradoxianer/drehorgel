import 'dart:convert';
import 'dart:io';

import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orgel/About.dart';
import 'package:orgel/donations.dart';
import 'package:orgel/globals.dart';
import 'package:orgel/songs.dart';

void main() {
  test('Kurbel-Drehachse liegt auf der Orgel', () {
    final pivot = organ.toStage(crankPivotInOrgan);
    expect(organ.rect.contains(pivot), isTrue);
  });

  test('Pro Umdrehung kommt im Schnitt nur wenig Geld zusammen', () {
    final d = Donations();
    for (var i = 0; i < 20000; i++) {
      d.newMoney();
    }
    final perRevolution = d.money / 20000;
    expect(perRevolution, inInclusiveRange(0.04, 0.15));
  });

  test('Spenden summieren sich', () {
    final d = Donations();
    for (var i = 0; i < 10; i++) {
      d.newMoney();
    }
    expect(d.money, greaterThan(0));
    expect(d.formatted, endsWith(' €'));
  });

  test('SoundFont enthält das Drehorgel-Preset', () {
    final bytes = File(soundfontAsset).readAsBytesSync();
    final presets = MidiPro.parseSoundfontPresets(bytes);
    expect(presets.map((p) => p.name), ['Drehorgel']);
    expect(presets.single.bank, 0);
    expect(presets.single.program, 0);
  });

  test('Jede Notenrolle hat MIDI, mp3 und einen passenden Index', () {
    for (final r in rolls) {
      expect(File(r.midiAsset).existsSync(), isTrue, reason: r.midiAsset);
      expect(File(r.mp3Asset).existsSync(), isTrue, reason: r.mp3Asset);
      final index = RollIndex.fromJson(
          jsonDecode(File(r.indexAsset).readAsStringSync()) as Map<String, dynamic>);
      expect(index.entries, isNotEmpty);
      expect(index.entryAtTick(0).verse, 1);
      // Strophen-Lookup: genau am Beginn jeder Strophe liefert der Index sie selbst.
      for (final e in index.entries) {
        expect(index.entryAtTick(e.tick), same(e));
        expect(index.entryAtSec(e.sec + 0.01), same(e));
      }
    }
  });

  test('Version im Info-Dialog passt zu pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version: ([0-9.]+)\+', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });
}

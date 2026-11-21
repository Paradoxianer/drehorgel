import 'dart:convert';

import 'package:flutter/services.dart';

/// Eine Notenrolle – wie das Lochband einer echten Drehorgel: mehrere Lieder
/// mit ihren Strophen laufen nacheinander durch und beginnen dann von vorn.
///
/// Alle Dateien erzeugt `tools/drehorgel_audio.py` (Rollen dort in ROLLS):
///  * `<id>.mid`  – Android (FluidSynth, Tempo stufenlos ohne Tonhöhenänderung)
///  * `<id>.mp3`  – Web/iOS (gleicher Klang, vorgerendert)
///  * `<id>.json` – Index: wo welches Lied/welche Strophe beginnt
class OrganRoll {
  final String id;
  final String title;

  const OrganRoll(this.id, this.title);

  String get midiAsset => 'assets/rolls/$id.mid';
  String get mp3Asset => 'assets/rolls/$id.mp3';
  String get indexAsset => 'assets/rolls/$id.json';
}

const List<OrganRoll> rolls = [
  OrganRoll('weihnachten', 'Weihnachtsrolle'),
  OrganRoll('standard', 'Standardrolle'),
];

const String soundfontAsset = 'assets/soundfonts/drehorgel.sf2';

/// Eine Strophe auf der Rolle.
class RollEntry {
  final String title;
  final int verse;
  final int verses;
  final int tick;
  final double sec;

  const RollEntry(this.title, this.verse, this.verses, this.tick, this.sec);

  factory RollEntry.fromJson(Map<String, dynamic> j) => RollEntry(
        j['title'] as String,
        j['verse'] as int,
        j['verses'] as int,
        j['tick'] as int,
        (j['sec'] as num).toDouble(),
      );
}

class RollIndex {
  final int totalTicks;
  final double durationSec;
  final List<RollEntry> entries;

  const RollIndex(this.totalTicks, this.durationSec, this.entries);

  factory RollIndex.fromJson(Map<String, dynamic> j) => RollIndex(
        j['totalTicks'] as int,
        (j['durationSec'] as num).toDouble(),
        [for (final e in j['entries'] as List) RollEntry.fromJson(e as Map<String, dynamic>)],
      );

  static Future<RollIndex> load(OrganRoll roll, [AssetBundle? bundle]) async {
    final text = await (bundle ?? rootBundle).loadString(roll.indexAsset);
    return RollIndex.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }

  /// Erste Strophe jedes Liedes, in Reihenfolge auf der Rolle.
  List<RollEntry> get songStarts => [
        for (final e in entries)
          if (e.verse == 1) e
      ];

  /// Liednamen in Reihenfolge (ohne Wiederholungen der Strophen).
  List<String> get titles => [for (final e in songStarts) e.title];

  RollEntry entryAtTick(int tick) => _last((e) => e.tick <= tick);

  RollEntry entryAtSec(double sec) => _last((e) => e.sec <= sec);

  RollEntry _last(bool Function(RollEntry) test) {
    var result = entries.first;
    for (final e in entries) {
      if (!test(e)) break;
      result = e;
    }
    return result;
  }
}

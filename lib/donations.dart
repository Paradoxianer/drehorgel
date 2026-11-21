import 'dart:math';

import 'package:flutter/foundation.dart';

/// Der erorgelte Betrag. Wird von der Kurbel befüllt (eine Umdrehung = eine
/// Spende) und von Spenden-Button, Tafel und fallendem Geld angezeigt.
class Donations extends ChangeNotifier {
  final Random _rng = Random();
  double money = 0.0;

  /// Betrag der letzten Spende (für das fallende Geld: Schein oder Münze).
  double lastAmount = 0.0;

  void newMoney() {
    // Wie am echten Stand: meist kleine Münzen, selten ein Euro, Scheine
    // fast nie. Im Schnitt ca. 8 Cent pro Kurbelumdrehung.
    double add = _pickCoin();
    lastAmount = add;
    money = ((money + add) * 100).roundToDouble() / 100;
    notifyListeners();
  }

  /// (Betrag, Gewicht) – Gewichte summieren sich zu 1000.
  static const List<(double, int)> _coins = [
    (0.01, 300), (0.02, 250), (0.05, 200), (0.10, 130),
    (0.20, 70), (0.50, 35), (1.00, 12), (2.00, 3),
  ];

  double _pickCoin() {
    // Ganz seltene Scheine
    final r = _rng.nextDouble();
    if (r < 1e-5) return 50;
    if (r < 1e-4) return 20;
    if (r < 5e-4) return 10;
    if (r < 1.5e-3) return 5;
    var roll = _rng.nextInt(1000);
    for (final (amount, weight) in _coins) {
      if (roll < weight) return amount;
      roll -= weight;
    }
    return 0.01;
  }

  String get formatted => '${money.toStringAsFixed(2).replaceAll('.', ',')} €';
}

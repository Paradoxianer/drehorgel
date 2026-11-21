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
    // Wahrscheinlichkeiten wie in der bisherigen Version.
    double add;
    if (_rng.nextDouble() < 1e-9) {
      add = 100;
    } else if (_rng.nextDouble() < 1e-8) {
      add = 50;
    } else if (_rng.nextDouble() < 2e-6) {
      add = 20;
    } else if (_rng.nextDouble() < 2e-5) {
      add = 10;
    } else if (_rng.nextDouble() < 1e-4) {
      add = 5;
    } else if (_rng.nextBool()) {
      add = 1;
    } else {
      add = _rng.nextInt(100) / 100.0;
    }
    lastAmount = add;
    money = ((money + add) * 100).roundToDouble() / 100;
    notifyListeners();
  }

  String get formatted => '${money.toStringAsFixed(2).replaceAll('.', ',')} €';
}

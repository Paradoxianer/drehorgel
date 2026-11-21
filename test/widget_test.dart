import 'package:flutter_test/flutter_test.dart';
import 'package:orgel/donations.dart';
import 'package:orgel/globals.dart';

void main() {
  test('Kurbel-Drehachse liegt auf der Orgel', () {
    final pivot = organ.toStage(crankPivotInOrgan);
    expect(organ.rect.contains(pivot), isTrue);
  });

  test('Spenden summieren sich', () {
    final d = Donations();
    for (var i = 0; i < 10; i++) {
      d.newMoney();
    }
    expect(d.money, greaterThan(0));
    expect(d.formatted, endsWith(' €'));
  });
}

import 'package:flutter/material.dart';

import 'donations.dart';
import 'flying_money.dart';
import 'globals.dart';
import 'the_crank.dart';

/// Ausschnitt im Hochformat: nur die Drehorgel samt Kurbel-Schwenkbereich.
const Rect organOnlyView = Rect.fromLTRB(40, 120, 740, 1080);

/// Die komplette Bühne in festen Koordinaten (1920x1080), am Stück skaliert.
/// Im Hochformat ([organOnly]) wird nur der Ausschnitt mit der Orgel gezeigt –
/// gleiche Koordinaten, nur ein anderer "Kamera"-Ausschnitt.
class Scene extends StatelessWidget {
  final Donations donations;
  final ValueChanged<double> onTempo;
  final bool organOnly;

  const Scene({super.key, required this.donations, required this.onTempo, this.organOnly = false});

  @override
  Widget build(BuildContext context) {
    final pivot = organ.toStage(crankPivotInOrgan);
    final crankSize = crankImageSize * organ.scale;
    final view = organOnly ? organOnlyView : Offset.zero & stageSize;

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      child: SizedBox.fromSize(
        size: view.size,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: -view.left,
            top: -view.top,
            width: stageSize.width,
            height: stageSize.height,
            child: _stage(pivot, crankSize),
          ),
        ]),
      ),
    );
  }

  Widget _stage(Offset pivot, double crankSize) {
    return Stack(
          clipBehavior: Clip.none,
          children: [
            if (!organOnly) ...[
              _sprite(maleSalutist),
              _sprite(femaleSalutist),
              _sprite(bucket),
              _BucketBoard(donations: donations),
            ],
            _sprite(organ),
            Positioned(
              key: const ValueKey('crank'), // Zustand beim Drehen des Geräts behalten
              left: pivot.dx - crankSize / 2,
              top: pivot.dy - crankSize / 2,
              width: crankSize,
              height: crankSize,
              child: TheCrank(
                size: crankSize,
                onTempo: onTempo,
                onRevolution: donations.newMoney,
              ),
            ),
            if (organOnly) _OrganMoneyPlate(donations: donations),
            Positioned.fill(
              key: ValueKey(organOnly), // Ziel ändert sich mit der Ausrichtung
              child: organOnly
                  // Hochformat: Münzen fallen in den Schlitz der Drehorgel
                  ? FallingMoney(
                      donations: donations,
                      target: organ.toStage(organSlotInOrgan),
                      startMinX: organOnlyView.left + 60,
                      startMaxX: organOnlyView.right - 60,
                      startY: organOnlyView.top - 60,
                    )
                  : FallingMoney(donations: donations),
            ),
          ],
    );
  }

  static Widget _sprite(StageSprite s) {
    final r = s.rect;
    return Positioned.fromRect(
      rect: r,
      child: Image.asset(s.asset, fit: BoxFit.fill),
    );
  }
}

/// Hochformat: Papierschild vorn an der Drehorgel mit dem erorgelten Betrag
/// (die Tafel am Spendentopf ist dort nicht zu sehen).
class _OrganMoneyPlate extends StatelessWidget {
  final Donations donations;
  const _OrganMoneyPlate({required this.donations});

  @override
  Widget build(BuildContext context) {
    final center = organ.toStage(organPlateCenterInOrgan);
    const w = 250.0, h = 112.0;
    return Positioned(
      left: center.dx - w / 2,
      top: center.dy - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: -0.03, // leicht schief angenagelt
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4E6C4),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF4A2E14), width: 3),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(2, 4))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListenableBuilder(
              listenable: donations,
              builder: (context, _) => FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Erorgelt',
                      style: TextStyle(fontSize: 26, color: Color(0xFF7A1A1A), fontFamily: 'serif')),
                  Text(donations.formatted,
                      style: const TextStyle(
                          fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFC0272D))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Zeigt den erorgelten Betrag auf der Tafel über dem Spendentopf.
class _BucketBoard extends StatelessWidget {
  final Donations donations;
  const _BucketBoard({required this.donations});

  @override
  Widget build(BuildContext context) {
    final topLeft = bucket.toStage(bucketBoardInImage.topLeft);
    final size = bucketBoardInImage.size * bucket.scale;
    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      width: size.width,
      height: size.height,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ListenableBuilder(
          listenable: donations,
          builder: (context, _) => FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Erorgelt',
                    style: TextStyle(fontSize: 34, color: Color(0xFF7A1A1A))),
                Text(
                  donations.formatted,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC0272D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

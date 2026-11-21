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
            if (!organOnly) Positioned.fill(child: FallingMoney(donations: donations)),
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

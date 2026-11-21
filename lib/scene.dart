import 'package:flutter/material.dart';

import 'donations.dart';
import 'flying_money.dart';
import 'globals.dart';
import 'the_crank.dart';

/// Die komplette Bühne in festen Koordinaten (1920x1080), am Stück skaliert.
class Scene extends StatelessWidget {
  final Donations donations;
  final ValueChanged<double> onTempo;

  const Scene({super.key, required this.donations, required this.onTempo});

  @override
  Widget build(BuildContext context) {
    final pivot = organ.toStage(crankPivotInOrgan);
    final crankSize = crankImageSize * organ.scale;

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      child: SizedBox.fromSize(
        size: stageSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _sprite(maleSalutist),
            _sprite(femaleSalutist),
            _sprite(bucket),
            _BucketBoard(donations: donations),
            _sprite(organ),
            Positioned(
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
            Positioned.fill(child: FallingMoney(donations: donations)),
          ],
        ),
      ),
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

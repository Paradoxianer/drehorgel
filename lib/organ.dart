import 'package:flutter/cupertino.dart';
import 'package:orgel/globals.dart';

class Organ extends StatelessWidget {
  double scale;

  Organ(this.scale);

  @override
  Widget build(BuildContext context) {
    //OrgelSizescaled
    Size orgelSizeScaled = orgelSize * scale;
    Offset orgelOffsetScaled = orgelOffset * scale;
    return Positioned(
        left: orgelOffsetScaled.dx,
        bottom: orgelOffsetScaled.dy,
        child: Image.asset(
          'assets/images/drehorgel.png',
          width: orgelSizeScaled.width,
          height: orgelSizeScaled.height,
        ))
    ;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:orgel/globals.dart';

class Organ extends StatelessWidget {

  Organ();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: FractionalOffset(0.0,1.0),
        child: FractionallySizedBox(
        widthFactor: 0.7,
        heightFactor: 0.7,
        child: Image.asset(
          'assets/images/drehorgel.png',
          alignment: FractionalOffset(0.0,1.0),
        )
    ));
  }
}

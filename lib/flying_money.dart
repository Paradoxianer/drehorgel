import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FlyingMoney extends StatefulWidget {
  @override
  State<FlyingMoney> createState() => FlyingMoneyState();
}

class FlyingMoneyState extends State<FlyingMoney> with SingleTickerProviderStateMixin {
  late AnimationController control;
  late Animation<double> rot;
  late Animation<double> trasl;
  
  @override
  void initState() {
    super.initState();

    control = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );

    rot = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(control);

    trasl = Tween<double>(
      begin: 0,
      end: 300,
    ).animate(control);

    control.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: control,
        builder: (_, child) => Stack(children: <Widget>[
              Positioned(
                top: trasl.value,
                left: 100,
                child: Transform(
                    transform: Matrix4.rotationZ(rot.value)..scale(0.1),
                    alignment: Alignment.center,
                    child: Image.asset('assets/images/Money.png')),
              ),
            ]
        )
    );
  }
}

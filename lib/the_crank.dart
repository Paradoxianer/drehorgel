import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:orgel/donation_button.dart';
import 'package:orgel/globals.dart';

class TheCrank extends StatefulWidget {
  final GlobalKey<DonationButtonState> donationButtonKey;
  TheCrank({Key? key,required this.donationButtonKey}) : super(key: key);
  @override
  _CrankState createState() => _CrankState();
}

class _CrankState extends State<TheCrank> {
  double fullAngle = 0.0;
  double oldAngle = 0.0;
  double angle = 0.0;
  int oldTime = 0;
  int time = 0;
  int nullCounter = 0;
  double speed = 1.0;
  double scale = 1.0;
  AudioPlayer player = AudioPlayer();

  Widget build(BuildContext context) {
    double scaleW = MediaQuery
        .of(context)
        .size
        .width / (orgelSize.width / 0.7);
    double scaleH = MediaQuery
        .of(context)
        .size
        .height / (orgelSize.height);
    if (scaleH > scaleW)
      scale = scaleW;
    else
      scale = scaleH;
    if (scale > 1)
      scale = 1.0;
    Offset sCP = crankOffset * scale;
    Size cS = crankSize * scale;
    Offset cSC = cS.center(Offset.zero);
    Offset moveTo = Offset(sCP.dx - cSC.dx, sCP.dy - cSC.dy);
    /*print("scale=$scale");
    print("ParentSize=${MediaQuery.of(context).size}");
    print("crankSize=$cS");
    print("moveTo=$moveTo");*/
    return Positioned(
        left: moveTo.dx,
        bottom: moveTo.dy,
        child: GestureDetector(
            onPanUpdate: _onPanUpdateHandler,
            onPanEnd: _onPanEndHandler,
            child: Transform(
                transform: new Matrix4.rotationZ(angle - pi / 2),
                alignment: FractionalOffset.center,
                child: Container(
                  /* decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                          )
                        ),*/
                    height: cS.height,
                    width: cS.width,
                    child: Image.asset(
                      'assets/images/kurbel_margin.png',
                      fit: BoxFit.fill,
                    )
                )
            )
        )
    );
  }

  double dp(double val, int places) {
    if (val == double.infinity)
        return double.infinity;
    else if (val == double.nan)
        return double.nan;
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  void initState() {
    super.initState();
    player.setAsset('assets/audios/We_wish_you.mp3',);
    player.setLoopMode(LoopMode.one);
  }

  _onPanEndHandler(DragEndDetails dragEndDetails) {
    player.stop();
  }

  void _onPanUpdateHandler(DragUpdateDetails details) {
    final touchPositionFromCenter =
        details.localPosition - (crankSize * scale).center(Offset.zero);
    double dSpeed = 0.0;
    double dAngle = 0.0;
    time = details.sourceTimeStamp!.inMilliseconds;
    //    The angle of this offset as radians clockwise from the positive x-axis, in the range -pi to pi, assuming positive values of the x-axis go to the right and positive values of the y-axis go down. [...]
    angle = pi + touchPositionFromCenter.direction;
    dAngle = (angle - oldAngle);
    if (dAngle > pi) {
      dAngle = (angle - 2 * pi) - oldAngle;
    }
    else if (dAngle < -pi) {
      dAngle = angle - (oldAngle - 2 * pi);
    }
    fullAngle += dAngle;
    dSpeed = dp(((angle - oldAngle) / (time - oldTime)) * 5, 3) - 0.02;
    if (dSpeed!=double.infinity &&  dSpeed!=double.nan) {
      speed = speed + dSpeed;
      //TODO: move player calls outside to enable await?
      if (!player.playing) {
        player.play();
        speed = 1.0;
        nullCounter = 0;
      } else {
        if (speed > 0.1) {
          nullCounter = 0;
          player.setSpeed(speed);
        }
        else {
          nullCounter++;
          if (nullCounter > 10) player.pause();
        }
      }
      /*  print ("=========");
        print("dAngle=$dAngle");
        print("dSpeed=$dSpeed");
        print("speed=$speed");
        print("fullAngle=$fullAngle");
        print("nullCounter=$nullCounter");*/
      if ((fullAngle > 2 * pi) || (fullAngle < (-2 * pi))) {
        fullAngle = 0;
        this.widget.donationButtonKey.currentState?.newMoney();
      }
    }
    oldAngle = angle;
    oldTime = time;
    angle -= pi;
    print("angle=$angle");
    setState(() {});
  }
}

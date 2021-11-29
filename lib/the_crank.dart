import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class TheCrank extends StatefulWidget {
  TheCrank({Key? key}) : super(key: key);

  @override
  _CrankState createState() => _CrankState();
}

class _CrankState extends State<TheCrank> {
  // TODO: add a random amout of money to your donation pot (maybe have a "all time collection" and a "now collection"
  double fullAngle = 0.0;
  int nullCounter = 0;
  double oldAngle = 0.0;
  double angle = 0.0;
  int oldTime = 0;
  int time = 0;
  double speed = 1.0;
  AudioPlayer player = AudioPlayer();

  void initState() {
    super.initState();
    player.setAsset('assets/audios/We_wish_you.mp3');
    player.setLoopMode(LoopMode.one);
  }

  double dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  void _onPanUpdateHandler(DragUpdateDetails details) {
    final touchPositionFromCenter = details.localPosition;
    setState(
      () {
        double dSpeed = 0.0;
        time = details.sourceTimeStamp!.inMilliseconds;
        angle = touchPositionFromCenter.direction;
        fullAngle += angle;
        dSpeed = dp(((oldAngle - angle) / (oldTime - time)) * 3, 3) - 0.02;
        print("deltaSpeed " + dSpeed.toString());
        speed = speed + dSpeed;
        print("resultingSpeed " + speed.toString());
        if (!player.playing) {
          player.play();
          speed = 1.0;
        } else {
          if (speed > 0) {
            nullCounter = 0;
            player.setSpeed(speed);
            oldAngle = angle;
            oldTime = time;
          } else {
            print("nullCounter=" + nullCounter.toString());
            nullCounter++;
            if (nullCounter > 10) player.pause();
            speed = 1.0;
          }
        }
      },
    );
  }

  _onPanEndHandler(DragEndDetails dragEndDetails) {
    player.stop();
  }

  Widget build(BuildContext context) {
    return GestureDetector(onPanUpdate: _onPanUpdateHandler, onPanEnd: _onPanEndHandler, child: Transform(transform: new Matrix4.rotationZ(angle)..scale(0.5), alignment: FractionalOffset(0.15, 0.5), child: Image.asset('assets/images/kurbel.png')));
  }
}

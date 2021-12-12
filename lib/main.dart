import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:orgel/About.dart';
import 'package:orgel/organ.dart';
import 'package:orgel/salutisten.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:orgel/the_crank.dart';
import 'package:orgel/donation_button.dart';

import 'donations.dart';
import 'globals.dart';

void main() {
  String? corps = Uri.base.queryParameters["custom1"]; //get the parameter for which Corps
  String? purpose = Uri.base.queryParameters["custom2"]; //get the second parameter to track the donations for this app
  // if no corps is specified then we use Chemnitz as default since we are the main developer
  if (corps == null)
    corps = "273";
  if (purpose == null)
    purpose = "Drehorgelspende";
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgeln für die Heilsarmee',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Orgeln für die Heilsarmee'),
    );
  }
}

class StatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const StatefulWrapper({required this.onInit, required this.child});
  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}
class _StatefulWrapperState extends State<StatefulWrapper> {
  @override
  void initState() {
    if(widget.onInit != null) {
      widget.onInit();
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  final ValueNotifier<double> _money = ValueNotifier<double>(0.0);
  final ValueNotifier<int> _rotation = ValueNotifier<int>(0);

  GlobalKey previewContainer = new GlobalKey();
  GlobalKey<DonationButtonState> dBKey  = new GlobalKey();
  MyHomePage({Key? key, required this.title}) : super(key: key);


  Future _init() async {
    _rotation.addListener(() {
      dBKey.currentState?.newMoney();
    });
  }
  @override
  Widget build(BuildContext context) {
    return StatefulWrapper(
        onInit: () {
        _init().then((value) {});
    },
    child: RepaintBoundary(
        key: previewContainer,
        child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget> [
                    Text(title),
                    IconButton(
                        onPressed: (){
                          About(context).show();
                        },
                        icon: Icon(Icons.three_p_outlined))
                  ]
              )
            ),
            body: Container(
                alignment: FractionalOffset(0.0,1.0),
                decoration: BoxDecoration(
                  image:  DecorationImage(
                    image: AssetImage("assets/images/background.jpg"),
                    fit: BoxFit.cover
                  )
                ),
                child:
                Stack(
                  fit: StackFit.expand,
                    clipBehavior: Clip.none,
                    alignment: FractionalOffset(0.0,1.0),
                    children: <Widget>[
                      Salutisten(),
                      FractionalTranslation(
                          translation: topfOffset,
                            child: Stack(
                              alignment: FractionalOffset(0,0),
                            children: <Widget>[
                              Image.asset('assets/images/bucket.png',alignment: Alignment.bottomCenter,),
                              Donations(money: _money,)
                            ]
                          )
                      ),

                      Organ(),
                      TheCrank(rotation: _rotation,),
                      Positioned.fill(
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              child: DonationButton(key:dBKey,money: _money)
                          )
                      ),
                      /*Positioned.fill(
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FloatingActionButton(
                                onPressed: () {
                                  shareScreenshot();
                                },
                                child: Icon(Icons.share)
                            )
                        )
                      )*/

                    ],
                  ),
                )
                )
            )
    );
  }

  takeScreenShot() async {
      }

  Future shareScreenshot() async {
    try {
      print("takingScreenshot");
      final directory = (await getApplicationDocumentsDirectory ()).path; //from path_provide package
      BuildContext? cC = previewContainer.currentContext;
      if (cC != null) {
        RenderRepaintBoundary boundary =
        cC.findRenderObject() as RenderRepaintBoundary;
        if (boundary.debugNeedsPaint) {
          print("Waiting for boundary to be painted.");
          await Future.delayed(const Duration(milliseconds: 20));
        }
        ui.Image image = await boundary.toImage();
        ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData!=null) {

          Uint8List pngBytes = byteData.buffer.asUint8List();
          File imgFile = new File('$directory/screenshot.png');
          imgFile.writeAsBytes(pngBytes);
        }
      }
      print("now we can share the screenshot");
      Share.shareFiles(['$directory/screenshot.png'], text: 'Ich hab für die Heilsarmee georgelt!\n - probiers auch mal! www.heilsarmee.de/files/orgel-app/index.html');
      //Share.share("Ich hab für die Heilsarmee georgelt");
    } catch (e) {
      print('error: $e');
    }
  }
}

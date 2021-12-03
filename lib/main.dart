import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:orgel/the_crank.dart';
import 'package:orgel/donation_button.dart';

void main() {
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

class MyHomePage extends StatelessWidget {
  final String title;
  GlobalKey previewContainer = new GlobalKey();
  GlobalKey dBKey  = new GlobalKey();
  //TODO: Add About Dialog
  /*include
  https://pixabay.com/vectors/arrow-rotate-ccw-left-turn-blue-293932/
  https://pixabay.com/illustrations/christmas-background-landscape-4701783/
  */
  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: previewContainer,
        child: Scaffold(
            appBar: AppBar(
              // TODO: add the Money Counter
              title: Text(title),
            ),
            body: Container(
                decoration: BoxDecoration(
                  image:  DecorationImage(
                    image: AssetImage("assets/images/background.png"),
                    fit: BoxFit.cover
                  )
                ),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/drehorgel.png'
                      ),
                      Positioned(top: -100, left: 300,
                          child: TheCrank(donationButtonKey: dBKey,),
                      )
                    ],
                  ),
                )
            ),
            bottomNavigationBar: BottomAppBar(
                    elevation: 0.0,
                    child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          /*FloatingActionButton(
                            onPressed: () {
                              shareScreenshot();
                            },
                            child: Icon(Icons.share)
                        ),*/
                          DonationButton(key: dBKey,)
                        ]
                    )
            )
        )
    );
  }

  takeScreenShot() async {
    BuildContext? cC = previewContainer.currentContext;
    if (cC != null) {
      RenderRepaintBoundary boundary =
          cC.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData;
    }
  }

  Future shareScreenshot() async {
    try {
      await takeScreenShot();
      debugPrint("now we can share the screenshot");
      /*await EsysFlutterShare.shareImage(
          'Game.png', bytes, 'Save The World');*/
    } catch (e) {
      print('error: $e');
    }
  }
}

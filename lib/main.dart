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

class MyHomePage extends StatelessWidget {
  final String title;

  GlobalKey previewContainer = new GlobalKey();
  GlobalKey<DonationButtonState> dButtonKey  = new GlobalKey();
  GlobalKey<DonationsState> donationsKey  = new GlobalKey();
  MyHomePage({Key? key, required this.title}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return  RepaintBoundary(
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
                      /*FractionalTranslation(
                          translation: topfOffset,
                            child: Stack(
                              alignment: FractionalOffset(0,0),
                            children: <Widget>[
                              Image.asset('assets/images/bucket.png',alignment: Alignment.bottomCenter,),
                              Donations(key: donationsKey,donationButtonKey: dButtonKey)
                            ]
                          )
                      ),*/

                      Organ(),
                      TheCrank(donationButtonKey: dButtonKey),
                      Positioned.fill(
                          child: Align(
                              alignment: Alignment.bottomCenter,
                              child: DonationButton(key:dButtonKey,donations: donationsKey)
                          )
                      ),
                      Positioned.fill(
                        child: Align(
                            alignment: Alignment.bottomLeft,
                            child: FloatingActionButton(
                                onPressed: () {
                                  shareScreenshot();
                                },
                                child: Icon(Icons.share)
                            )
                        )
                      )

                    ],
                  ),
                )
                )
            );
  }

  takeScreenShot() async {
      }

  Future shareScreenshot() async {
    try {
      print("takingScreenshot");
      final directory = (await getApplicationDocumentsDirectory()).path; //from path_provide package
      print('$directory');
      BuildContext? cC = previewContainer.currentContext;
      if (cC != null) {
        print('cc not null');
        RenderRepaintBoundary boundary =
        cC.findRenderObject() as RenderRepaintBoundary;
        print('$boundary');
        /*if (boundary.debugNeedsPaint) {
          print("Waiting for boundary to be painted.");
          await Future.delayed(const Duration(milliseconds: 25));
        }*/
        await Future.delayed(const Duration(milliseconds: 25));
        ui.Image image = await boundary.toImage();
        ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData!=null) {
          print("we have the data now we are sharing\n");
          Uint8List pngBytes = byteData.buffer.asUint8List();
          File imgFile = new File('$directory/screenshot.png');
          await imgFile.writeAsBytes(pngBytes);
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

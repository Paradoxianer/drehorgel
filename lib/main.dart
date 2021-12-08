import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: previewContainer,
        child: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget> [
                    Text(title),
                    IconButton(
                        onPressed: (){
                         showAboutDialog(
                           applicationName: "Orgeln",
                           context: context,
                            applicationVersion: '1.0.1',
                           applicationIcon: Icon(Icons.settings_applications),
                           children: <Widget>[
                         RichText(
                         text:
                              TextSpan(
                                text: 'Ein App mit der man Drehorgeln kann.\nSimuliert wird das weihnacthliche Spendensammeln der Heilsarmee.\nAm Ende hat der Nutzer die Möglichkeit den erorgelten Betrag zu spenden.\n\n',
                               // style: DefaultTextStyle.of(context).style,
                             children:  <TextSpan>[
                               TextSpan(text: "Idee und Umsetzung - Matthias Lindner\n\n"),
                               TextSpan(text: "Datenschutzerklärung - auf github.com\n",
                                 style: TextStyle(color: Colors.blue),
                                 recognizer: new TapGestureRecognizer()
                                   ..onTap = () { launch('https://raw.githubusercontent.com/Paradoxianer/drehorgel/main/Datenschutz');
                                   },
                               ),
                               TextSpan(text: "AGB  - auf github.com\n\n\n",
                                 style: TextStyle(color: Colors.blue),
                                 recognizer: new TapGestureRecognizer()
                                   ..onTap = () { launch('https://raw.githubusercontent.com/Paradoxianer/drehorgel/main/AGB');
                                   },
                               ),
                               TextSpan(text:"===== DANK geht an =====\n\n"),
                               TextSpan(text:"Hintergrund - "),
                               TextSpan(text:"Pixabay\n",
                                 style: TextStyle(color: Colors.blue),
                                 recognizer: new TapGestureRecognizer()
                                   ..onTap = () { launch('https://pixabay.com/illustrations/christmas-background-landscape-4701783');
                                   },),
                               TextSpan(text:"Musik - Daniel Matzeit - "),
                               TextSpan(text:"Website\n",
                                 style: TextStyle(color: Colors.blue),
                                 recognizer: new TapGestureRecognizer()
                                   ..onTap = () { launch('https://profis.check24.de/profil/tastenheld/aqgrra');
                                   },
                               ),
                               TextSpan(text:"Florian Walz - "),
                               TextSpan(text:"Website\n",
                                   style: TextStyle(color: Colors.blue),
                           recognizer: new TapGestureRecognizer()
                             ..onTap = () { launch('https://profis.check24.de/profil/tastenheld/aqgrra');
                             },
                               )
                              ]
                              )
                         )
                          ]
                         );
                        },
                        icon: Icon(Icons.three_p_outlined))
                  ]
              )
            ),
            body: Container(
                decoration: BoxDecoration(
                  image:  DecorationImage(
                    image: AssetImage("assets/images/background.jpg"),
                    fit: BoxFit.cover
                  )
                ),
                child: Center(
                  child:Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                  children:<Widget>[
                    Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomLeft,
                    children: <Widget>[
                      Image.asset(
                        'assets/images/drehorgel.png',
                      ),
                      TheCrank(donationButtonKey: dBKey),
                    ],
                  ),
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          /*FloatingActionButton(
                              onPressed: () {
                                shareScreenshot();
                              },
                              child: Icon(Icons.share)
                          ),*/
                          DonationButton(key: dBKey)
                        ]
                    )
                  ]
                )
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
      Share.shareFiles(['$directory/screenshot.png'], text: 'Ich hab für die Heilsarmee georgelt - probiers auch mal! www.projectconceptor.de/orgeln');
      //Share.share("Ich hab für die Heilsarmee georgelt");
    } catch (e) {
      print('error: $e');
    }
  }
}

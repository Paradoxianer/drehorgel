import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  //TODO: Add About Dialog
  /*include
  
  
  */
  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: previewContainer,
        child: Scaffold(
            appBar: AppBar(
              // TODO: add the Money Counter
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
                             Text("Programmiert von Matthias Lindner\n"),
                             Text("https://pixabay.com/vectors/arrow-rotate-ccw-left-turn-blue-293932"),
                             Text("https://pixabay.com/illustrations/christmas-background-landscape-4701783\n"),
                             Text("===== DANK ====="),
                             Text("Musik - Daniel Matzeit"),
                             Text("und Florian Walz... links kommen noch")
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
                        'assets/images/drehorgel.png'
                      ),
                      TheCrank(donationButtonKey: dBKey),
                    ],
                  ),
                    Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
        /*                  FloatingActionButton(
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
    BuildContext? cC = previewContainer.currentContext;
    if (cC != null) {
      RenderRepaintBoundary boundary =
          cC.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      //File imgFile =new File('$directory/screenshot.png');
      //imgFile.writeAsBytes(pngBytes);
    }
  }

  Future shareScreenshot() async {
    try {
      await takeScreenShot();
      //debugprint"now we can share the screenshot");
      //Share.shareFiles(['$directory/screenshot.png'], text: 'Ich hab für die Heilsarmee georgelt - probiers auch mal! www.projectconceptor.de/orgeln');
      //Share.share("Ich hab für die Heilsarmee georgelt");
    } catch (e) {
      //print'error: $e');
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import './the_crank.dart';
import './donation_button.dart';

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
  MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // TODO: add the Money Counter
          title: Text(title),
        ),
        body: Center(
          child: Stack(
            children: <Widget>[
              Image.asset('assets/images/drehorgel.png'),
              FractionalTranslation(
                  // TODO: Fix the position of the Crank according to the size of the Pipe Organ
                  translation: Offset(0.5, 0.0),
                  child: TheCrank())
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: shareScreenshot(),
                  icon: Icon(Icons.share)
                ),
                DonationButton()
              ]
          )
        )

        );
  }
  


   takeScreenShot() async{
    RenderRepaintBoundary boundary = previewContainer.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    final directory = (await getApplicationDocumentsDirectory()).path;
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);
    File imgFile =new File('$directory/screenshot.png');
        imgFile.writeAsBytes(pngBytes);
  }

  Future shareScreenshot() async {
    try {
      await takeScreenShot();
      debugPrint("now we can share the screenshot");
      /*await EsysFlutterShare.shareImage(
          'Game.png', bytes, 'Save The World');
    } catch (e) {
      print('error: $e');
    }*/
  }
}

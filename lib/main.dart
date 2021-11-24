import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';


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

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double angle = 0.0;
  AudioCache audioCache = AudioCache();

  void initState() {
    super.initState();
      audioCache.play('assets/audios/We_wish_you');
  }

  void _onPanUpdateHandler(DragUpdateDetails details) {
    final touchPositionFromCenter = details.localPosition;
    setState(
          () {
        angle = touchPositionFromCenter.direction;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          children: <Widget>[
            Image.asset('assets/images/drehorgel.png'),
            Transform.translate(
                offset: Offset(450,00),
            child: GestureDetector(
                onPanUpdate: _onPanUpdateHandler,
                child: Transform(
                  transform: new Matrix4.rotationZ(angle)..scale(0.5),
                      alignment: FractionalOffset(0.15,0.5),
                      child: Image.asset('assets/images/kurbel.png')
                    )
                  )
          )
          ],
        ),
      ),
    );
  }
}

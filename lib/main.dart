import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import './the_crank.dart';

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
  final String _url = 'https://www.heilsarmee.de/chemnitzkassberg/spenden-ssl.html?formular-korps-lokal/spende';
  MyHomePage({Key? key, required this.title}) : super(key: key);
  void _launchURL() async {
    if (!await launch(_url)) throw 'Could not launch $_url';
  }

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
        floatingActionButton: FloatingActionButton.extended(tooltip: 'Increment Counter', onPressed: _launchURL, icon: Icon(Icons.add_shopping_cart_rounded), label: Text("Spenden: " + 7.77.toString() + "€")));
  }
}

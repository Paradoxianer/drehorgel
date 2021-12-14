import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class About {
  BuildContext context;
  About(this.context);

  show(){
    showAboutDialog(
        applicationName: "Orgeln",
        context: context,
        applicationVersion: '1.0.1',
        applicationIcon: Image.asset('assets/images/ic_launcher.png'),
        children: <Widget>[
          RichText(
              text:
              TextSpan(
                  text: 'Ein App mit der man Drehorgeln kann.\nSimuliert wird das weihnacthliche Spendensammeln der Heilsarmee.\nAm Ende hat der Nutzer die Möglichkeit den erorgelten Betrag zu spenden.\n\n',
                  style: TextStyle(color: Colors.black),
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
                    TextSpan(text:"Musik - Daniel Matzeit - "),
                    TextSpan(text:"Website\n",
                      style: TextStyle(color: Colors.blue),
                      recognizer: new TapGestureRecognizer()
                        ..onTap = () { launch('https://profis.check24.de/profil/tastenheld/aqgrra');
                        },
                    ),
                    TextSpan(text:"Florian Walz - "),
                    TextSpan(text:"Website\n\n",
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
  }

}
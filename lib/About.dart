import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Muss zur Version in pubspec.yaml passen.
const String appVersion = '2.1.0';

/// Web-Version auf heilsarmee.de: Impressum und Datenschutzerklärung der
/// Heilsarmee in Deutschland (Verantwortliche Stelle für den Webserver).
const String webImpressumUrl = 'https://www.heilsarmee.de/impressum.html';
const String webDatenschutzUrl = 'https://www.heilsarmee.de/impressum.html#datenschutzhinweis';

class About {
  BuildContext context;
  About(this.context);

  show(){
    showAboutDialog(
        applicationName: "Orgeln",
        context: context,
        applicationVersion: appVersion,
        applicationIcon: Image.asset('assets/images/ic_launcher.png'),
        children: <Widget>[
          RichText(
              text:
              TextSpan(
                  text: 'Hier kann man Drehorgeln.\nSimuliert wird das weihnachtliche Spendensammeln der Heilsarmee.\nAm Ende hat der Nutzer die Möglichkeit den erorgelten Betrag zu spenden.\n\n',
                  style: TextStyle(color: Colors.black),
                  children:  <TextSpan>[
                    TextSpan(text: "Idee und Umsetzung - Matthias Lindner\n\n"),
                    if (kIsWeb) ...[
                      TextSpan(text: "Impressum\n",
                        style: TextStyle(color: Colors.blue),
                        recognizer: new TapGestureRecognizer()
                          ..onTap = () { launchUrl(Uri.parse(webImpressumUrl));
                          },
                      ),
                      TextSpan(text: "Datenschutzerklärung\n\n\n",
                        style: TextStyle(color: Colors.blue),
                        recognizer: new TapGestureRecognizer()
                          ..onTap = () { launchUrl(Uri.parse(webDatenschutzUrl));
                          },
                      ),
                    ] else ...[
                      TextSpan(text: "Datenschutzerklärung - auf github.com\n",
                        style: TextStyle(color: Colors.blue),
                        recognizer: new TapGestureRecognizer()
                          ..onTap = () { launchUrl(Uri.parse('https://raw.githubusercontent.com/Paradoxianer/drehorgel/main/Datenschutz'));
                          },
                      ),
                      TextSpan(text: "AGB  - auf github.com\n\n\n",
                        style: TextStyle(color: Colors.blue),
                        recognizer: new TapGestureRecognizer()
                          ..onTap = () { launchUrl(Uri.parse('https://raw.githubusercontent.com/Paradoxianer/drehorgel/main/AGB'));
                          },
                      ),
                    ],
                    TextSpan(text:"Drehorgelklang und Lied-Arrangements: eigene Synthese, gemeinfreie Melodien\n\n"),
                    TextSpan(text:"===== DANK geht an =====\n\n"),
                    TextSpan(text:"Design & Grafik - Florian Walz - "),
                    TextSpan(text:"mfw-design.com\n",
                      style: TextStyle(color: Colors.blue),
                      recognizer: new TapGestureRecognizer()
                        ..onTap = () { launchUrl(Uri.parse('https://www.mfw-design.com/'));
                        },
                    ),
                    TextSpan(text:"Musik der ersten Version - Daniel Matzeit\n\n"),
                  ]
              )
          )
        ]
    );
  }

}
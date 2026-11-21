import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'About.dart';
import 'donation_button.dart';
import 'donations.dart';
import 'organ_player.dart';
import 'scene.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Parameter der Web-Version: für welches Corps / welchen Zweck gesammelt wird.
  // Standard: Chemnitz, da wir die Hauptentwickler sind.
  final corps = Uri.base.queryParameters['custom1'] ?? '273';
  final purpose = Uri.base.queryParameters['custom2'] ?? 'Drehorgelspende';

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  runApp(MyApp(corps: corps, purpose: purpose));
}

class MyApp extends StatelessWidget {
  final String corps;
  final String purpose;
  const MyApp({super.key, this.corps = '273', this.purpose = 'Drehorgelspende'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orgeln für die Heilsarmee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: false),
      home: MyHomePage(corps: corps, purpose: purpose),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String corps;
  final String purpose;
  const MyHomePage({super.key, required this.corps, required this.purpose});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey _previewContainer = GlobalKey();
  final Donations _donations = Donations();
  final OrganPlayer _player = AudioOrganPlayer('assets/audios/We_wish_you.mp3');
  late final Future<void> _playerReady = _player.init();

  @override
  void dispose() {
    _player.dispose();
    _donations.dispose();
    super.dispose();
  }

  void _onTempo(double tempo) {
    _playerReady.then((_) => _player.setTempo(tempo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        key: _previewContainer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            Scene(donations: _donations, onTempo: _onTempo),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton.filled(
                        tooltip: 'Über diese App',
                        onPressed: () => About(context).show(),
                        icon: const Icon(Icons.info_outline),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: FloatingActionButton(
                        heroTag: 'share',
                        tooltip: 'Teilen',
                        onPressed: _shareScreenshot,
                        child: const Icon(Icons.share),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: DonationButton(
                        donations: _donations,
                        whichCorps: widget.corps,
                        whichPurpose: widget.purpose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const _RotateHint(),
          ],
        ),
      ),
    );
  }

  Future<void> _shareScreenshot() async {
    try {
      final boundary = _previewContainer.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      await Share.shareXFiles(
        [
          XFile.fromData(byteData.buffer.asUint8List(),
              name: 'drehorgel.png', mimeType: 'image/png')
        ],
        text: 'Ich habe für die Heilsarmee georgelt!\n'
            ' - probiers auch mal! https://www.heilsarmee.de/chemnitzkassberg/drehorgeln.html',
      );
    } catch (e) {
      debugPrint('error: $e');
    }
  }
}

/// Im Hochformat (z.B. Browser auf dem Handy) Hinweis zum Drehen anzeigen.
class _RotateHint extends StatelessWidget {
  const _RotateHint();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= size.height) return const SizedBox.shrink();
    return const Align(
      alignment: Alignment(0, -0.6),
      child: Card(
        color: Color(0xE6FFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.screen_rotation, size: 32),
            SizedBox(width: 12),
            Text('Bitte das Gerät quer halten', style: TextStyle(fontSize: 18)),
          ]),
        ),
      ),
    );
  }
}

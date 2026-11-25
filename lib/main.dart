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
import 'roll_ui.dart';
import 'songs.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Parameter der Web-Version: für welches Corps / welchen Zweck gesammelt wird.
  // Standard: Chemnitz, da wir die Hauptentwickler sind.
  final corps = Uri.base.queryParameters['custom1'] ?? '273';
  final purpose = Uri.base.queryParameters['custom2'] ?? 'Drehorgelspende';

  if (!kIsWeb) {
    // Querformat: ganze Szene, Hochformat: nur die Drehorgel.
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
  final OrganPlayer _player = OrganPlayer.forPlatform();
  OrganRoll _roll = rolls.first;
  /// Zuletzt im Menü gewählte Stelle -> sofortige Anzeige im Notenband.
  final ValueNotifier<RollEntry?> _jump = ValueNotifier(null);
  /// Was das Notenband gerade anzeigt.
  final ValueNotifier<RollEntry?> _shown = ValueNotifier(null);
  late Future<void> _playerReady = _player.init(_roll);

  @override
  void dispose() {
    _player.dispose();
    _donations.dispose();
    _jump.dispose();
    _shown.dispose();
    super.dispose();
  }

  void _onTempo(double tempo) {
    _playerReady.then((_) => _player.setTempo(tempo));
  }

  Future<void> _chooseRoll() async {
    final choice = await showRollChooser(context, _roll, _shown.value?.title);
    if (choice == null) return;
    final rollChanged = choice.roll.id != _roll.id;
    // Sofort zeigen, was gewählt wurde – nicht erst, wenn der Player nachzieht.
    _jump.value = choice.start ?? (await RollIndex.load(choice.roll)).entries.first;
    if (rollChanged) setState(() => _roll = choice.roll);
    _playerReady = _playerReady.then((_) async {
      if (rollChanged) await _player.selectRoll(choice.roll);
      final start = choice.start;
      if (start != null) await _player.seekTo(start);
    });
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
            Scene(
              donations: _donations,
              onTempo: _onTempo,
              organOnly: MediaQuery.orientationOf(context) == Orientation.portrait,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 56),
                        child: NoteBand(
                          key: ValueKey(_roll.id),
                          player: _player,
                          roll: _roll,
                          jump: _jump,
                          shown: _shown,
                          onTap: _chooseRoll,
                        ),
                      ),
                    ),
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
      await SharePlus.instance.share(ShareParams(
        files: [
          XFile.fromData(byteData.buffer.asUint8List(),
              name: 'drehorgel.png', mimeType: 'image/png')
        ],
        text: 'Ich habe für die Heilsarmee georgelt!\n'
            ' - probiers auch mal! ${kIsWeb ? 'https://www.heilsarmee.de/files/orgel-app/' : 'https://paradoxianer.github.io/drehorgel/'}',
      ));
    } catch (e) {
      debugPrint('error: $e');
    }
  }
}

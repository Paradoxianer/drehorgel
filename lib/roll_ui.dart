import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'organ_player.dart';
import 'songs.dart';

const _paper = Color(0xFFF4E6C4);
const _paperDark = Color(0xFFE2CC9A);
const _ink = Color(0xFF4A2E14);
const _wood = Color(0xFF6B4423);

/// Papierstreifen der Notenrolle: zeigt Lied und Strophe, die gerade laufen.
/// Ein Tipp darauf öffnet die Rollenauswahl.
///
/// [jump] meldet eine Auswahl aus dem Menü: Sie wird sofort angezeigt (mit
/// kurzem Aufleuchten) und so lange festgehalten, bis der Player dieselbe
/// Stelle meldet – ohne Kurbeln steht der Player ja noch an der alten Stelle.
class NoteBand extends StatefulWidget {
  final OrganPlayer player;
  final OrganRoll roll;
  final ValueListenable<RollEntry?> jump;

  /// Was das Band gerade anzeigt – die Rollenauswahl markiert dasselbe Lied.
  final ValueNotifier<RollEntry?> shown;
  final VoidCallback onTap;

  const NoteBand({
    super.key,
    required this.player,
    required this.roll,
    required this.jump,
    required this.shown,
    required this.onTap,
  });

  @override
  State<NoteBand> createState() => _NoteBandState();
}

class _NoteBandState extends State<NoteBand> with SingleTickerProviderStateMixin {
  RollEntry? _entry;
  RollEntry? _held; // gewählte, vom Player noch nicht bestätigte Stelle
  Timer? _timer;
  late final AnimationController _flash =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    widget.jump.addListener(_onJump);
    if (widget.jump.value != null) _onJump();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) => _poll());
  }

  @override
  void dispose() {
    widget.jump.removeListener(_onJump);
    _timer?.cancel();
    _flash.dispose();
    super.dispose();
  }

  void _onJump() {
    final e = widget.jump.value;
    if (e == null) return;
    setState(() => _entry = _held = e);
    widget.shown.value = e;
    _flash.forward(from: 0);
  }

  Future<void> _poll() async {
    try {
      final e = await widget.player.currentEntry();
      if (!mounted || e == null) return;
      final held = _held;
      if (held != null) {
        if (e.title != held.title) return; // Player hängt noch an der alten Stelle
        _held = null;
      }
      if (e.title != _entry?.title || e.verse != _entry?.verse) setState(() => _entry = e);
      widget.shown.value = e;
    } catch (_) {/* Player noch nicht bereit */}
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
    final line = e?.title ?? widget.roll.title;
    final verse = e != null && e.verses > 1 ? '${e.verse}/${e.verses}' : null;
    return Tooltip(
      message: 'Notenrolle wechseln',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _flash,
          builder: (context, child) {
            final t = _flash.isAnimating ? sin(pi * _flash.value) : 0.0;
            return Transform.scale(
              scale: 1 + 0.08 * t,
              child: DecoratedBox(
                decoration: BoxDecoration(boxShadow: [
                  if (t > 0)
                    BoxShadow(color: const Color(0xFFFFD54F).withValues(alpha: 0.9 * t), blurRadius: 24 * t, spreadRadius: 4 * t),
                ]),
                child: child,
              ),
            );
          },
          child: CustomPaint(
            painter: _PunchedPaperPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.music_note, color: _ink, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => SlideTransition(
                      // Text läuft wie das Band von rechts nach links durch
                      position: Tween(begin: const Offset(0.4, 0), end: Offset.zero).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      line,
                      key: ValueKey(line),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _ink, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'serif'),
                    ),
                  ),
                ),
                if (verse != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        border: Border.all(color: _wood), borderRadius: BorderRadius.circular(4)),
                    child: Text(verse,
                        semanticsLabel: '${e!.verse}. von ${e.verses} Strophen',
                        style: const TextStyle(color: _wood, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.swap_horiz, color: _wood, size: 20),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Papier mit Stanzlöchern oben und unten (wie ein Lochband).
class _PunchedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    canvas.drawShadow(Path()..addRRect(r), Colors.black, 4, false);
    canvas.drawRRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_paperDark, _paper, _paper, _paperDark],
            stops: [0, 0.2, 0.8, 1],
          ).createShader(Offset.zero & size));
    final hole = Paint()..color = _ink.withValues(alpha: 0.55);
    for (double x = 10; x < size.width - 6; x += 14) {
      canvas.drawCircle(Offset(x, 5), 2, hole);
      canvas.drawCircle(Offset(x, size.height - 5), 2, hole);
    }
    canvas.drawRRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..color = _wood.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ergebnis der Rollenauswahl: welche Rolle, und optional ab welchem Lied.
class RollSelection {
  final OrganRoll roll;
  final RollEntry? start; // null = Rolle von vorn
  const RollSelection(this.roll, [this.start]);
}

/// Auswahl der Notenrolle – als Holzkiste mit Papierrollen. Jedes Lied einer
/// Rolle ist antippbar: die Rolle wird dann bis zu diesem Lied vorgespult.
Future<RollSelection?> showRollChooser(
    BuildContext context, OrganRoll current, String? currentTitle) {
  return showDialog<RollSelection>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Container(
          decoration: BoxDecoration(
            color: _wood,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3E2712), width: 3),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16)],
          ),
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Notenrolle einlegen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _paper, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                ),
                // Quer nebeneinander, hoch untereinander.
                LayoutBuilder(
                  builder: (context, c) {
                    final cards = [
                      for (final r in rolls)
                        _RollCard(
                          roll: r,
                          selected: r.id == current.id,
                          currentTitle: r.id == current.id ? currentTitle : null,
                        ),
                    ];
                    if (c.maxWidth < 600) {
                      return Column(children: [
                        for (final card in cards)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: card),
                      ]);
                    }
                    return IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final card in cards)
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5), child: card)),
                      ]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RollCard extends StatelessWidget {
  final OrganRoll roll;
  final bool selected;
  final String? currentTitle;
  const _RollCard({required this.roll, required this.selected, this.currentTitle});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC0272D);
    return CustomPaint(
      painter: _PunchedPaperPainter(),
      child: Container(
        decoration: selected ? BoxDecoration(border: Border.all(color: red, width: 3)) : null,
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: FutureBuilder<RollIndex>(
          future: RollIndex.load(roll),
          builder: (context, snap) {
            final index = snap.data;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Kopf: ganze Rolle von vorn einlegen
              InkWell(
                onTap: () => Navigator.of(context).pop(RollSelection(roll)),
                child: Row(children: [
                  const SizedBox(width: 46, height: 46, child: CustomPaint(painter: _RollIconPainter())),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(roll.title,
                          style: const TextStyle(
                              color: _ink, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                      if (index != null)
                        Text(
                          '${index.entries.length} Strophen · ${(index.durationSec / 60).round()} Minuten',
                          style: TextStyle(color: _ink.withValues(alpha: 0.7), fontSize: 12),
                        ),
                    ]),
                  ),
                  if (selected) const Icon(Icons.check_circle, color: red),
                ]),
              ),
              if (index != null) ...[
                const Divider(color: _paperDark, height: 14, thickness: 1.5),
                for (final song in index.songStarts)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(RollSelection(roll, song)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                      child: Row(children: [
                        Icon(song.title == currentTitle ? Icons.volume_up : Icons.play_arrow,
                            size: 18, color: song.title == currentTitle ? red : _wood),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(song.title,
                              style: TextStyle(
                                  color: _ink,
                                  fontSize: 15,
                                  fontWeight:
                                      song.title == currentTitle ? FontWeight.bold : FontWeight.normal)),
                        ),
                        Text('×${song.verses}',
                            style: TextStyle(color: _ink.withValues(alpha: 0.6), fontSize: 13)),
                      ]),
                    ),
                  ),
              ],
            ]);
          },
        ),
      ),
    );
  }
}

/// Kleine aufgewickelte Papierrolle mit Lochmuster.
class _RollIconPainter extends CustomPainter {
  const _RollIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.62, h * 0.64);
    canvas.drawRect(body, Paint()..color = _paperDark);
    final rng = Random(3);
    final hole = Paint()..color = _ink.withValues(alpha: 0.6);
    for (var i = 0; i < 14; i++) {
      canvas.drawRect(
          Rect.fromLTWH(body.left + 4 + rng.nextDouble() * (body.width - 12),
              body.top + 4 + rng.nextDouble() * (body.height - 10), 5, 2.5),
          hole);
    }
    final end = Rect.fromCenter(center: Offset(body.right, h / 2), width: w * 0.3, height: h * 0.64);
    canvas.drawOval(end, Paint()..color = _paper);
    canvas.drawOval(end, Paint()
      ..style = PaintingStyle.stroke
      ..color = _wood
      ..strokeWidth = 1.5);
    canvas.drawOval(Rect.fromCenter(center: end.center, width: end.width * 0.35, height: end.height * 0.35),
        Paint()..color = _wood);
    // Papierzunge, die aus der Rolle hängt
    canvas.drawRect(Rect.fromLTWH(w * 0.02, h * 0.5, w * 0.12, h * 0.32), Paint()..color = _paperDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

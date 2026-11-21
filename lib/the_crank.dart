import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Die Kurbel. Wird als quadratisches Widget so platziert, dass die
/// Drehachse genau in seiner Mitte liegt (siehe Scene). Alle Koordinaten sind
/// Bühnenkoordinaten – die Skalierung erledigt die FittedBox der Szene, auch
/// für die Touch-Positionen.
///
/// Ausgabe:
///  * [onTempo]: stufenloser Tempo-Faktor (1.0 = [nominalRps] Umdrehungen/s,
///    0 = Kurbel steht)
///  * [onRevolution]: bei jeder vollen Umdrehung
class TheCrank extends StatefulWidget {
  final double size;
  final ValueChanged<double> onTempo;
  final VoidCallback onRevolution;

  /// Umdrehungen pro Sekunde, bei denen das Lied im Originaltempo läuft.
  final double nominalRps;

  const TheCrank({
    super.key,
    required this.size,
    required this.onTempo,
    required this.onRevolution,
    this.nominalRps = 1.0,
  });

  @override
  State<TheCrank> createState() => _CrankState();
}

class _CrankState extends State<TheCrank> with SingleTickerProviderStateMixin {
  /// Aktueller Winkel des Griffs (0 = nach rechts, im Uhrzeigersinn positiv,
  /// da die y-Achse nach unten zeigt).
  double _angle = 0.0;
  double _accumulated = 0.0; // für "volle Umdrehung"
  Duration? _lastEventTime;

  /// Geglättete Drehgeschwindigkeit in Umdrehungen/s.
  double _rps = 0.0;
  Duration _now = Duration.zero;
  final Stopwatch _clock = Stopwatch()..start();
  late final Ticker _ticker;
  double _lastReportedTempo = -1;

  static const double _stopRps = 0.15;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Läuft jeden Frame: lässt die Geschwindigkeit abklingen, wenn keine
  /// Bewegung mehr kommt (Finger steht still oder losgelassen) – die Orgel
  /// "leiert aus".
  void _onTick(Duration _) {
    final elapsed = _clock.elapsed;
    final dt = (elapsed - _now).inMicroseconds / 1e6;
    _now = elapsed;
    final last = _lastEventTime;
    final idle = last == null || (_now - last).inMilliseconds > 120;
    if (idle && _rps > 0) {
      _rps *= exp(-dt * 3.0); // Halbwertszeit ~0,23 s
      if (_rps < _stopRps) _rps = 0;
    }
    _report();
  }

  void _report() {
    final tempo = _rps < _stopRps ? 0.0 : _rps / widget.nominalRps;
    if ((tempo - _lastReportedTempo).abs() > 0.02 ||
        (tempo == 0) != (_lastReportedTempo == 0)) {
      _lastReportedTempo = tempo;
      widget.onTempo(tempo);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final v = d.localPosition - center;
    if (v.distance < widget.size * 0.05) return; // zu nah an der Achse
    final newAngle = v.direction; // atan2, -pi..pi

    var delta = newAngle - _angle;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    final t = _clock.elapsed;
    final last = _lastEventTime;
    if (last != null) {
      final dt = (t - last).inMicroseconds / 1e6;
      if (dt > 0 && dt < 0.5) {
        final inst = delta.abs() / (2 * pi) / dt;
        // Tiefpass, damit das Tempo nicht flattert.
        _rps = _rps + (inst - _rps) * min(1.0, dt * 8);
      }
    }
    _lastEventTime = t;

    _accumulated += delta;
    if (_accumulated.abs() >= 2 * pi) {
      _accumulated -= _accumulated.sign * 2 * pi;
      widget.onRevolution();
    }
    setState(() => _angle = newAngle);
    _report();
  }

  /// Beim Anfassen springt der Griff unter den Finger, ohne dass das als
  /// Drehung zählt.
  void _onPanStart(DragStartDetails d) {
    _lastEventTime = null;
    final v = d.localPosition - Offset(widget.size / 2, widget.size / 2);
    if (v.distance >= widget.size * 0.05) {
      setState(() => _angle = v.direction);
    }
  }

  void _onPanEnd(DragEndDetails d) {
    _lastEventTime = null; // ab jetzt klingt das Tempo im Ticker ab
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.rotate(
        // Im Bild zeigt der Griff nach unten (= +pi/2).
        angle: _angle - pi / 2,
        child: Image.asset(
          'assets/images/kurbel_margin.png',
          width: widget.size,
          height: widget.size,
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

import 'donations.dart';
import 'globals.dart';

/// Lässt bei jeder neuen Spende Geld von oben in den Spendentopf fallen.
/// Liegt als Ebene über der Bühne und arbeitet in Bühnenkoordinaten.
class FallingMoney extends StatefulWidget {
  final Donations donations;

  const FallingMoney({super.key, required this.donations});

  @override
  State<FallingMoney> createState() => _FallingMoneyState();
}

/// Öffnung des Topfes im Bucket-Bild (Bildpixel).
const Offset _bucketSlotInImage = Offset(268, 462);

class _Drop {
  final AnimationController controller;
  final Offset start;
  final double spin;
  final double amount;
  _Drop(this.controller, this.start, this.spin, this.amount);
}

class _FallingMoneyState extends State<FallingMoney>
    with TickerProviderStateMixin {
  final List<_Drop> _drops = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    widget.donations.addListener(_onDonation);
  }

  @override
  void dispose() {
    widget.donations.removeListener(_onDonation);
    for (final d in _drops) {
      d.controller.dispose();
    }
    super.dispose();
  }

  void _onDonation() {
    final c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1100 + _rng.nextInt(400)),
    );
    final drop = _Drop(
      c,
      Offset(1250 + _rng.nextDouble() * 600, -120),
      (_rng.nextDouble() * 2 - 1) * 4 * pi,
      widget.donations.lastAmount,
    );
    c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _drops.remove(drop));
        c.dispose();
      }
    });
    setState(() => _drops.add(drop));
    c.forward();
  }

  @override
  Widget build(BuildContext context) {
    final target = bucket.toStage(_bucketSlotInImage);
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final d in _drops)
            AnimatedBuilder(
              animation: d.controller,
              builder: (context, child) {
                final t = d.controller.value;
                // Waagerecht gleichmäßig, senkrecht beschleunigt (Schwerkraft).
                final x = d.start.dx + (target.dx - d.start.dx) * t;
                final y = d.start.dy + (target.dy - d.start.dy) * t * t;
                // Kurz vor dem Topf kleiner werden = "fällt hinein".
                final scale = t < 0.85 ? 1.0 : 1.0 - (t - 0.85) / 0.15 * 0.7;
                return Positioned(
                  left: x - 60,
                  top: y - 60,
                  width: 120,
                  height: 120,
                  child: Transform.rotate(
                    angle: d.spin * t,
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: _MoneyPiece(amount: d.amount),
            ),
        ],
      ),
    );
  }
}

/// Schein ab 5 €, goldene Münze für 1–2 €, Kupfermünze für Cent-Beträge.
class _MoneyPiece extends StatelessWidget {
  final double amount;
  const _MoneyPiece({required this.amount});

  @override
  Widget build(BuildContext context) {
    if (amount >= 5) {
      return Image.asset('assets/images/Money.png', fit: BoxFit.contain);
    }
    final gold = amount >= 1;
    final label = gold ? '${amount.toInt()}€' : '${(amount * 100).round()}';
    final size = gold ? 70.0 : 54.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: gold
                ? const [Color(0xFFFFF1A8), Color(0xFFE0B23A), Color(0xFF9C7418)]
                : const [Color(0xFFF6C7A0), Color(0xFFC06E3A), Color(0xFF7A3E1C)],
          ),
          border: Border.all(
              color: gold ? const Color(0xFF8A6512) : const Color(0xFF6A3418),
              width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(2, 3))
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.32,
            fontWeight: FontWeight.bold,
            color: gold ? const Color(0xFF6B4A08) : const Color(0xFF4A2410),
          ),
        ),
      ),
    );
  }
}

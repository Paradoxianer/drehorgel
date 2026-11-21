import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'donations.dart';

class DonationButton extends StatelessWidget {
  final Donations donations;
  final String whichCorps;
  final String whichPurpose;

  /// Spendenseite des Korps Chemnitz-Kaßberg mit eingebettetem
  /// Twingle-Formular. Twingle übernimmt Query-Parameter mit Präfix `tw_`:
  ///  * `tw_amount`        – Betrag in Euro mit Dezimalpunkt; wird nur
  ///    übernommen, wenn er im Formular-Bereich liegt (aktuell 5–10000 €)
  ///  * `tw_target_id_fix` – Spendenzweck über die `internal_id` (= Korps-
  ///    Nummer, Chemnitz-Kaßberg = 273) und nur diesen zur Auswahl anbieten.
  ///    Ohne den Parameter steht der Zweck auf "Berlin-Prenzlauer Berg"!
  ///  * `tw_cid`           – Kampagnen-Kennung (unsichtbar, zur Auswertung)
  /// (Früher Altruja mit `#custom1=…&custom2=…&betrag=…` – funktioniert nicht
  /// mehr.)
  static const String _url =
      'https://www.heilsarmee.de/chemnitzkassberg/spenden-ssl.html';

  /// Mindestbetrag des Twingle-Formulars; kleinere Beträge würden ignoriert.
  static const double _minAmount = 5.0;

  const DonationButton({
    super.key,
    required this.donations,
    this.whichCorps = '273',
    this.whichPurpose = 'Drehorgelspende',
  });

  /// Vorgeschlagener Betrag für die echte Spende (mindestens [_minAmount]).
  double get _suggestedAmount => donations.money < _minAmount ? _minAmount : donations.money;

  Uri get _donateUrl => Uri.parse(_url).replace(queryParameters: {
        'tw_amount': _suggestedAmount.toStringAsFixed(2),
        'tw_target_id_fix': whichCorps,
        'tw_cid': whichPurpose,
      });

  static String _euro(double v) => '${v.toStringAsFixed(2).replaceAll('.', ',')} €';

  /// Erst erklären, dann (freiwillig) zur externen Spendenseite – die App
  /// selbst wickelt keine Zahlung ab, und eine Spende schaltet nichts frei.
  Future<void> _confirmAndOpen(BuildContext context) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF4E6C4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF6B4423), width: 3),
        ),
        icon: const Icon(Icons.volunteer_activism, color: Color(0xFFC0272D), size: 36),
        title: const Text('Jetzt wirklich spenden?',
            style: TextStyle(color: Color(0xFF4A2E14), fontFamily: 'serif', fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            'Du hast ${_euro(donations.money)} erorgelt – dieses Geld ist nur gespielt.\n\n'
            'Wenn du möchtest, kannst du jetzt echt an die Heilsarmee spenden. '
            'Die Spende geht direkt an das Korps Chemnitz-Kaßberg '
            '(Die Heilsarmee in Deutschland, KdöR), wird über deren Webseite '
            'abgewickelt und ist steuerlich absetzbar.\n\n'
            'Vorgeschlagen sind ${_euro(_suggestedAmount)} – den Betrag kannst du '
            'auf der Spendenseite frei ändern.',
            style: const TextStyle(color: Color(0xFF4A2E14), fontSize: 15),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF6B4423))),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC0272D)),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Zur Spendenseite'),
          ),
        ],
      ),
    );
    if (go != true) return;
    if (!await launchUrl(_donateUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_donateUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'donate',
      tooltip: 'Echt an die Heilsarmee spenden (öffnet deren Webseite)',
      onPressed: () => _confirmAndOpen(context),
      icon: const Icon(Icons.favorite),
      label: const Text('Echt spenden'),
    );
  }
}

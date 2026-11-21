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

  Future<void> _launchURL(BuildContext context) async {
    final money = donations.money;
    if (money > 200) await _showMyDialog(context);
    final amount = money < _minAmount ? _minAmount : money;
    final donateUrl = Uri.parse(_url).replace(queryParameters: {
      'tw_amount': amount.toStringAsFixed(2),
      'tw_target_id_fix': whichCorps,
      'tw_cid': whichPurpose,
    });
    if (!await launchUrl(donateUrl)) {
      throw 'Could not launch $donateUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: donations,
      builder: (context, _) => FloatingActionButton.extended(
        heroTag: 'donate',
        tooltip: 'Erorgelten Betrag spenden',
        onPressed: () => _launchURL(context),
        icon: const Icon(Icons.volunteer_activism),
        label: Text('Spenden: ${donations.formatted}'),
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.red,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(32.0))),
        title: const Text('Große Spende'),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Danke dass du spenden möchtest'),
              Text(
                  'Bitte beachte, der erorgelte Betrag wird automatisch in das Spendenformular übernommen.'),
              Text('Du kannst den Betrag auf unserer Website noch ändern.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'donations.dart';

class DonationButton extends StatelessWidget {
  final Donations donations;
  final String whichCorps;
  final String whichPurpose;

  static const String _url =
      'https://www.heilsarmee.de/chemnitzkassberg/spenden-ssl.html#';

  const DonationButton({
    super.key,
    required this.donations,
    this.whichCorps = '273',
    this.whichPurpose = 'Drehorgelspende',
  });

  Future<void> _launchURL(BuildContext context) async {
    final money = donations.money;
    var donateUrl = '${_url}custom1=$whichCorps&custom2=$whichPurpose&betrag=';
    if (money > 0.25) {
      if (money > 200) await _showMyDialog(context);
      donateUrl += money.toStringAsFixed(2).replaceAll('.', ',');
    } else {
      donateUrl += '5,00';
    }
    if (!await launchUrl(Uri.parse(donateUrl))) {
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

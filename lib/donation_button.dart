import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationButton extends StatefulWidget {
  DonationButton({Key? key}) : super(key: key);
  @override
  DonationButtonState createState() => DonationButtonState();
}

class DonationButtonState extends State<DonationButton>
    with SingleTickerProviderStateMixin {
  double money = 0.0;
  int oldRot = 0;
  final String _url =
      'https://www.heilsarmee.de/chemnitzkassberg/spenden-ssl.html#custom1=273&betrag=';

  @override
  void initState() {
    super.initState();
  }

  _launchURL() async {
    String donateUrl = "";
    if (money > 0.25) {
      if (money > 200 )
          await _showMyDialog();
        //TODO: Add a alert  Dialog to make shure that people know that they will donat this amount of money
      donateUrl = _url + money.toStringAsFixed(2).replaceAll(".", ",");
    } else {
      donateUrl = _url + 5.00.toString();
    }
    if (!await launch(donateUrl)) throw 'Could not launch $_url';
  }

  @override
  Widget build(BuildContext context) {
    newMoney();
    return FloatingActionButton.extended(
        tooltip: 'Money collected',
        onPressed: _launchURL,
        icon: Icon(Icons.add_shopping_cart_rounded),
        label: Text("Spenden: " + money.toString() + "€"));
  }

  double dp(double val, int places) {
    num mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  newMoney() {
    var rng = new Random();
    setState(() {
      if (rng.nextInt(1000000001) / 1000000000 == 1)
        money += 100;
      else if (rng.nextInt(100000001) / 100000000 == 1)
        money += 50;
      else if (rng.nextInt(500001) / 500000 == 1)
        money += 20;
      else if (rng.nextInt(50001) / 50000 == 1)
        money += 10;
      else if (rng.nextInt(10001) / 10000 == 1)
        money += 5;
      else {
        int euros = (rng.nextInt(20001) / 10000).toInt();
        if (euros > 0)
          money += euros;
        else
          money += dp(rng.nextInt(10000) / 1000, 2);
      }
      money = dp(money, 2);
    });
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32.0))),
          title: const Text('Große Spende'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Danke dass du spenden möchtest'),
                Text('Bitte beachte, der erorgelte Betrag wird automatisch in das Spendenformular übernommen.'),
                Text('Du kannst den Betrag auf unserer Website noch ändern.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK',style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
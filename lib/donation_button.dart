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
      if (money > 100 )
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
      else if (rng.nextInt(5001) / 5000 == 1)
        money += 10;
      else if (rng.nextInt(1001) / 1000 == 1)
        money += 5;
      else {
        int euros = (rng.nextInt(1001) / 1000).toInt();
        if (euros > 0)
          money += euros;
        else
          money += dp(rng.nextInt(1000) / 100, 2);
      }
      money = dp(money, 2);
    });
  }
}
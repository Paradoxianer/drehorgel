import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationButton extends StatefulWidget {
  @override
  State<DonationButton> createState() => DonationButtonState();
}

class DonationButtonState extends State<DonationButton> with SingleTickerProviderStateMixin {
  double money = 0.0;
  final String _url = 'https://www.heilsarmee.de/chemnitzkassberg/spenden-ssl.html#custom1=273&betrag=';

  @override
  void initState() {
    super.initState();
  }

  _launchURL() async {
    String donateUrl = "";
    if (money >0.25){
      donateUrl = _url + money.toStringAsFixed(2).replaceAll(".", ",");
    }
    else
    {
      donateUrl = _url + 5.00.toString();
    }
    if (!await launch(donateUrl)) throw 'Could not launch $_url';
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
        tooltip: 'Money collected',
        onPressed: _launchURL,
        icon: Icon(Icons.add_shopping_cart_rounded),
        label: Text("Spenden: " + money.toString() + "€"));
  }

  newMoney() {
    var rng = new Random();
    setState(() {
      int hunderter = rng.nextInt(100000);
      int fuenfziger = rng.nextInt(500);
      int zwanziger = rng.nextInt(100);
      int zehner = rng.nextInt(100);
      int fuenfer = rng.nextInt(1);
      int euros = rng.nextInt(5);
      int cents = rng.nextInt(100);
      money = money + euros + cents / 100;
    });
  }
}

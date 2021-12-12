import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'donations.dart';

class DonationButton extends StatefulWidget {
  GlobalKey<DonationsState> donations;
  String wichCorps;
  String wichPurpose;
  
  DonationButton({Key? key,required this.donations,this.wichCorps="273",this.wichPurpose="Drehorgelspende"}) : super(key: key);
  @override
  State<DonationButton> createState() => new DonationButtonState();
  
}

class DonationButtonState extends State<DonationButton>
    with SingleTickerProviderStateMixin {
  double money = 0.0;
  int oldRot = 0;
  final String _url =
      'https://www.heilsarmee.de/chemnitzkassberg/spenden-ssl.html#';

  @override
  void initState() {
    super.initState();
    money = 0.0;
  }

  _launchURL() async {
    String donateUrl = "";
    donateUrl=_url+"custom1="+this.widget.wichCorps+"&custom2="+this.widget.wichPurpose+"&betrag=";
    if (money > 0.25) {
      if (money > 200) await _showMyDialog();
      donateUrl = donateUrl + money.toStringAsFixed(2).replaceAll(".", ",");
    } else {
      donateUrl = donateUrl + 5.00.toString();
    }
    if (!await launch(donateUrl)) throw 'Could not launch $_url';
  }

  @override
  Widget build(BuildContext context) {
    return
      FloatingActionButton.extended(
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
    double addMoney = 0.0;
    var rng = new Random();
    setState(() {
      if (rng.nextInt(1000000001) / 1000000000 == 1)
        addMoney += 100;
      else if (rng.nextInt(100000001) / 100000000 == 1)
        addMoney += 50;
      else if (rng.nextInt(500001) / 500000 == 1)
        addMoney += 20;
      else if (rng.nextInt(50001) / 50000 == 1)
        addMoney += 10;
      else if (rng.nextInt(10001) / 10000 == 1)
        addMoney += 5;
      else {
        int euros = (rng.nextInt(20001) / 10000).toInt();
        if (euros > 0)
          addMoney += euros;
        else
          addMoney += dp(rng.nextInt(10000) / 10000, 2);
      }
      money = dp(money+addMoney, 2);
    });
    this.widget.donations.currentState?.setState(() {});
    setState(() { });
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
                Text(
                    'Bitte beachte, der erorgelte Betrag wird automatisch in das Spendenformular übernommen.'),
                Text('Du kannst den Betrag auf unserer Website noch ändern.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
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

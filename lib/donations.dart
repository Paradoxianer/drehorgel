import 'package:flutter/cupertino.dart';
import 'package:orgel/donation_button.dart';
import 'package:orgel/globals.dart';

class Donations extends StatefulWidget {
  final GlobalKey<DonationButtonState> donationButtonKey;
  const Donations({ Key? key,required this.donationButtonKey}) : super(key: key);

  @override
  State<Donations> createState() => DonationsState();
}

class DonationsState extends State<Donations> {

  @override
  Widget build(BuildContext context) {
    double? money = this.widget.donationButtonKey.currentState?.money;
    if (money == null)
      money=0.0;
    return
      FractionalTranslation(
                translation: Offset(1.5, 0.75),
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                        "$money €",
                        style: TextStyle(fontSize: 100)
                    )
                )
            );

  }
}
import 'package:flutter/cupertino.dart';
import 'package:orgel/donation_button.dart';
import 'package:orgel/globals.dart';

class Donations extends StatefulWidget {
  final ValueNotifier<double> money;

  const Donations({ Key? key,required this.money}) : super(key: key);

  @override
  State<Donations> createState() => _DonationsState();
}

class _DonationsState extends State<Donations> {

  @override
  Widget build(BuildContext context) {
    //money = this.widget.donationButtonKey?.currentState?.money;
    return
      ValueListenableBuilder<double>(
          builder: (BuildContext context, double value, Widget? child) {
            // This builder will only get called when the _counter
            // is updated.
            return FractionalTranslation(
                translation: Offset(1.5, 0.75),
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                        "$value €",
                        style: TextStyle(fontSize: 100)
                    )
                )
            );
          },
          valueListenable: this.widget.money
      );
  }
}
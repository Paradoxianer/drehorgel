import 'package:url_launcher/url_launcher.dart';

class DonationButton extends StatefulWidget {
  @override
  State<DonationButton> createState() => DonationButtonState();
}

class DonationButtonState extends State<DonationButton> with SingleTickerProviderStateMixin {
 double money = 0.0;
 @override
  void initState() {
    super.initState();
  }
  _launchURL() async {
    if (!await launch(_url)) throw 'Could not launch $_url';
  }

  FloatingActionButton.extended(tooltip: 'Increment Counter', onPressed: _launchURL, icon: Icon(Icons.add_shopping_cart_rounded), label: Text("Spenden: " + 7.77.toString() + "€")));
}
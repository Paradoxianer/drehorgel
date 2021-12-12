
import 'package:flutter/cupertino.dart';
import 'package:orgel/globals.dart';

class Salutisten extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder:
    (BuildContext context, BoxConstraints constraints){
      if (constraints.maxWidth>constraints.maxHeight) {
        return Row(
            children: <Widget>[
              Image.asset(
                'assets/images/male.png',
              ),
              Image.asset(
                'assets/images/female.png',
              ),
            ],
          );
      }
      else{
        return Container();
      }

    }
    );
  }
}



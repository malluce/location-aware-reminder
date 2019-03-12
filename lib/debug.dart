import 'package:flutter/material.dart';
import 'package:moc_app/main.dart';
import 'wearable.dart';


class Debug extends StatefulWidget {
  LAReState state;

  Debug({this.state});

  @override
  State<StatefulWidget> createState() {
    return _DebugState(state:  state);
  }
}

class _DebugState extends State<Debug> {
  LAReState state;

  _DebugState({this.state});

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
        FlatButton(onPressed: state.startVibrate, child: Text("Good vibrations")),
        FlatButton(onPressed: state.stopVibrate, child: Text("Stawp it")),
    ],);
  }
}

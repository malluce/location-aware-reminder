import 'package:flutter/material.dart';
import 'package:moc_app/main.dart';

class Debug extends StatefulWidget {
  final LAReState state;

  Debug({this.state});

  @override
  State<StatefulWidget> createState() {
    return _DebugState(state: state);
  }
}

class _DebugState extends State<Debug> {
  LAReState state;

  _DebugState({this.state});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Row(
        children: [
          Center(
            child: Text("Wearable Connection Status: \n" +
                state.connector.currentDeviceState.toString()),
          )
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FlatButton(
            onPressed: () {
              state.startVibrate();
              setState(() {});
            },
            child: Text("Good vibrations"),
            color: Colors.blue,
          ),
          FlatButton(
            onPressed: () {
              state.stopVibrate();
              setState(() {});
            },
            child: Text("Stawp it"),
            color: Colors.blue,
          ),
          FlatButton(
            onPressed: () {
              setState(() {});
            },
            child: Text("Refresh State"),
            color: Colors.blue,
          ),
        ],
      ),
    ]);
  }
}

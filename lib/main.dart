import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:moc_app/example.dart';
import 'package:moc_app/wearable.dart';
import 'dart:async';

import 'reminder.dart';
import 'debug.dart';
import 'map.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:system_setting/system_setting.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Location-Aware Reminder",
      home: Container(child: LARe()),
    );
  }
}

class LARe extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return LAReState();
  }
}

/// Used for disk storage of reminder list. Allows persistance between app uses.
class ReminderStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/reminders.json');
  }

  /// writes the reminder list to disk
  Future<File> writeReminders(List<Reminder> reminders) async {
    final file = await _localFile;

    debugPrint("writing json: " + remindersToJson(reminders));

    return file.writeAsString(remindersToJson(reminders));
  }

  /// converts the reminder list to JSON String.
  String remindersToJson(List<Reminder> reminders) {
    return jsonEncode(reminders);
  }

  /// reads the reminders from disk
  Future<List<Reminder>> readReminders() async {
    final file = await _localFile;
    debugPrint(file.path);

    // Read the file
    String contents = await file.readAsString();

    debugPrint("read json: " + contents);

    // JSON is a list of reminders, read this into List
    List<dynamic> reminderJsonList = jsonDecode(contents);

    // create reminder list
    List<Reminder> reminders = [];
    // for every reminder in the list, create the Reminder from json and add it to the reminder list
    for (var x in reminderJsonList) {
      debugPrint(x.toString());
      reminders.add(Reminder.fromJson(x));
    }

    return reminders;
  }
}

class LAReState extends State<LARe>{
  // the reminder list
  List<Reminder> _reminders = [];

  ReminderStorage storage = ReminderStorage();

  bool bluetoothAlertOpen = false;

  WearableConnector connector = WearableConnector();

  // keeps track of the subscription of updateLocation to the location stream
  StreamSubscription<Map<String, double>> _subscription;

  // the current location
  Location _location;

  double _latitude = 0;
  double _longitude = 0;

  // the reminders which the user is in radius
  List<Reminder> _reminderInRadius = [];

  // whether or not the alert which states that the user is in a reminder radius is currently visible or not
  bool alertIsVisible = false;



  // delete reminder from state and writes it to disk
  void deleteReminder(Reminder reminder) {
    setState(() {
      _reminders.remove(reminder);
    });
    writeRemindersToDisk();
  }

  // adds a reminder to the state and writes it to disk
  void addReminder(Reminder reminder) {
    setState(() {
      _reminders.add(reminder);
    });
    writeRemindersToDisk();
  }

  List<Reminder> get reminders => _reminders;

  double get longitude => _longitude;
  double get latitude => _latitude;

  ///
  /// Updates the location based on the current key-value-pairs output by Location class.
  ///
  void updateLocation(Map<String, double> currentLocation) {
    if (!this.mounted) {
      return;
    }
    // update variables
    setState(() {
      _longitude = currentLocation['longitude'];
      _latitude = currentLocation['latitude'];
      _reminderInRadius = [];
    });

    // check if user is in radius of any reminder, add all near reminders to _reminderInRadius
    for (Reminder reminder in reminders) {
      double distance = computeDistanceBetween(
          reminder.toLatLng(), new LatLng(_latitude, _longitude));
      if (distance < reminder.radius) {
        _reminderInRadius.add(reminder);
        debugPrint("in radius of " + reminder.toString());
      }
    }

    // show dialog (only once, even if more than one reminders are near)
    if (_reminderInRadius.isNotEmpty && !alertIsVisible) {
      alertIsVisible = true;
      startVibrate();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("You are near"),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    "Got it, delete these reminders!",
                    style: TextStyle(fontSize: 15.0),
                  ),
                  onPressed: () {
                    // delete reminders
                    for (Reminder reminder in _reminderInRadius) {
                      deleteReminder(reminder);
                    }
                    alertIsVisible = false;
                    stopVibrate();
                    Navigator.pop(context);
                  }),
            ],
            content: SingleChildScrollView(
                child: Column(
                  children: _reminderInRadius.map((Reminder r) {
                    return Text(r.title);
                  }).toList(),
                )),
          ));
    }
    print("lon: " + _longitude.toString());
    print("lat: " + _latitude.toString());
  }

  @override
  void initState() {
    super.initState();
    // first, load reminders from disk
    loadRemindersFromDisk().then((List<Reminder> r) {
      setState(() {
        _reminders = r;
      });
    });

    _location = Location();

    // get first location immediatly, not just after change
    _location.getLocation().then(updateLocation, onError: (e) {
      debugPrint("error");
    });

    debugPrint("after get location");

    // location stream changes trigger updateLocation
    _subscription = _location.onLocationChanged().listen(
      updateLocation,
      onError: (e) {
        debugPrint("erro stream");
      },
      onDone: () {
        debugPrint("done");
      },
    );

    debugPrint("after on loc changed");

  }

  void startVibrate() {
    connector.vibrate();
  }

  void stopVibrate() {
    connector.stopVibrate();
  }

  /// Loads the reminder from the disk.
  Future<List<Reminder>> loadRemindersFromDisk() async {
    debugPrint("loading from disk");
    return storage.readReminders();
  }

  /// Writes the current reminders to disk.
  Future<void> writeRemindersToDisk() async {
    debugPrint("writing reminders to disk");
    await storage.writeReminders(reminders);
  }

  @override
  void dispose() {
    super.dispose();
    connector.cancelConnection();
    _subscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(_reminders.toString());
    Future.delayed(Duration.zero, () {
      debugPrint("getting called");
      FlutterBlue.instance.isOn.then((on) {
        if (!on && !bluetoothAlertOpen) {
          bluetoothAlertOpen = true;
          debugPrint("is set open");
          showDialog(
              context: context,
              builder: (context) {
                return SimpleDialog(
                    title:
                        Text("Active Bluetooth for LARe to function properly."),
                    children: <Widget>[
                      Row(
                        children: [
                          FlatButton(
                            onPressed: () {
                              SystemSetting.goto(SettingTarget.BLUETOOTH);
                            },
                            child: Text(
                              "goto settings",
                              style: TextStyle(color: Colors.white),
                            ),
                            color: Colors.blue,
                          ),
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                                bluetoothAlertOpen = false;
                              },
                              child: Text("done",
                                  style: TextStyle(color: Colors.white)), color: Colors.blue,)
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      )
                    ]);
              });
        }
      });
    });
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        floatingActionButton: Container(
            child: AddReminderButton(
          state: this,
        )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          title: Text("Location-Aware Reminder (LARe)"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.access_alarm)),
              Tab(icon: Icon(Icons.map)),
              Tab(text: "debug"),
            ],
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            ReminderList(
              state: this,
            ),
            ReminderMap(state: this),
            Debug(state: this),
          ],
        ),
      ),
    );
  }
}

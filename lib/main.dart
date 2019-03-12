import 'package:flutter/material.dart';
import 'package:moc_app/example.dart';
import 'package:moc_app/wearable.dart';

import 'reminder.dart';
import 'debug.dart';
import 'map.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

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

class LAReState extends State<LARe> {
  // the reminder list
  List<Reminder> _reminders = [
    new Reminder(
      title: "Eier einkaufen",
      lon: 8.385233,
      lat: 48.993533,
      radius: 2000.0,
      icon: Icon(Icons.shopping_cart),
    ),
    new Reminder(
      title: "Skript abholen",
      lon: 8.408001,
      lat: 49.012510,
      radius: 150.0,
      icon: Icon(Icons.library_books),
    ),
  ];

  ReminderStorage storage = ReminderStorage();

  WearableConnector connector = WearableConnector();

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

  @override
  void initState() {
    super.initState();

    // first, load reminders from disk
    loadRemindersFromDisk().then((List<Reminder> r) {
      setState(() {
        _reminders = r;
      });
    });
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
  void deactivate() {
    super.deactivate();
    connector.cancelConnection();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(_reminders.toString());
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        floatingActionButton: AddReminderButton(
          state: this,
        ),
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

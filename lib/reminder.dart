import 'package:flutter/material.dart';
import 'main.dart';
import 'package:latlong/latlong.dart';

// for map displaying
import 'package:flutter_map/flutter_map.dart';

///
/// Representation of the reminders.
///
class Reminder {
  Reminder(
      {@required this.title,
      @required this.lat,
      @required this.lon,
      @required this.radius,
      @required this.icon});

  String title; // name of the reminder
  // GPS coordinates
  double lat;
  double lon;
  double
      radius; // the radius in which the user should be reminded of this reminder
  Icon icon; // the icon of this reminder

  /// convenience method to convert this reminder to LatLng.
  LatLng toLatLng() {
    return LatLng(lat, lon);
  }

  @override
  String toString() {
    return title +
        ",(" +
        lat.toString() +
        "," +
        lon.toString() +
        "),r=" +
        radius.toString();
  }

  /// creates a reminder from its JSON representation.
  Reminder.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    lat = json['lat'];
    lon = json['lon'];
    radius = json['radius'];
    icon = Icon(IconData(
      json['icon'],
      fontFamily: 'MaterialIcons',
    ));
  }

  /// converts this reminder to json
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'lat': lat,
      'lon': lon,
      'radius': radius,
      'icon': icon.icon.codePoint
    };
  }

  /// shows a summary of this reminder (an AlertDialog which shows all attributes)
  void showSummary(BuildContext context) {
    LatLng latLng = this.toLatLng();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 30.0),
              ),
            ),
            content: FlutterMap(
              options: MapOptions(
                center: latLng,
                zoom: 13.0,
              ),
              layers: [
                TileLayerOptions(
                  urlTemplate: "https://api.tiles.mapbox.com/v4/"
                      "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                  additionalOptions: {
                    'accessToken':
                        'pk.eyJ1IjoibWFsbHVjZSIsImEiOiJjanF6MmNqeTIwNmppNDJwbHprOGhuaXo1In0.K_3lEcDSPALLWJPO-on54g',
                    'id': 'mapbox.streets',
                  },
                ),
                MarkerLayerOptions(
                  markers: [
                    Marker(
                      point: latLng,
                      width: 80.0,
                      height: 80.0,
                      builder: (ctx) => Container(
                            child: IconButton(
                              iconSize: 40.0,
                              icon: icon,
                              onPressed: () => debugPrint("pressed!"),
                            ),
                          ),
                    ),
                  ],
                ),
                CircleLayerOptions(circles: [
                  CircleMarker(
                      point: latLng,
                      radius: radius,
                      color: Colors.blue.withOpacity(0.7),
                      useRadiusInMeter: true)
                ])
              ],
            ),
            actions: <Widget>[
              FlatButton(
                  child: Text(
                    "Got it!",
                    style: TextStyle(fontSize: 20.0),
                  ),
                  onPressed: () => Navigator.pop(context)),
            ]);
      },
    );
  }
}

/// Reminder list for displaying all reminders.
class ReminderList extends StatelessWidget {
  final LAReState state;

  ReminderList({this.state});

  final _listItemStyle = const TextStyle(fontSize: 20.0);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (BuildContext context, int index) {
        Reminder reminder = state.reminders[index];
        return ListTile(
          title: Row(
            children: [
              reminder.icon,
              Center(
                child: Text(
                  reminder.title,
                  style: _listItemStyle,
                ),
              ),
              //Container(
              //  width: 32.0,
              //  height: 0.0,
              //)
            ],
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          ),
          onTap: () => reminder.showSummary(context),
          onLongPress: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                      title: Text("Delete \"" + reminder.title + "\"?"),
                      children: [
                        Row(
                          children: <Widget>[
                            SimpleDialogOption(
                              child: FlatButton(
                                onPressed: () {
                                  state.deleteReminder(reminder);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Yes",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            SimpleDialogOption(
                              child: FlatButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "No",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        )
                      ]);
                },
              ),
        );
      },
      padding: EdgeInsets.all(16.0),
      itemCount: state.reminders.length,
      separatorBuilder: (BuildContext context, int index) {
        return Divider(color: Colors.black);
      },
    );
  }
}

/// Button to add a new reminder.
class AddReminderButton extends StatelessWidget {
  final LAReState state;

  AddReminderButton({this.state});

  @override
  Widget build(BuildContext context) {
    debugPrint("addReminderButton: " + state.reminders.toString());
    return FloatingActionButton(
        onPressed: () => openAddReminderRoute(context, state),
        child: Icon(Icons.alarm_add));
  }
}

/// Opens a new Route to add a reminder.
void openAddReminderRoute(BuildContext context, LAReState state) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddReminderRoute(
                state: state,
              )));
}

typedef LatLngToVoidCallback = void Function(LatLng);

class LonLatMapChooser extends StatefulWidget {
  final LAReState state;
  final LatLngToVoidCallback callback;
  final DoubleWrapper radius;

  LonLatMapChooser({this.state, this.callback, this.radius});

  @override
  State<StatefulWidget> createState() {
    debugPrint("creating LonLatMapChooserState with radius of " +
        radius.value.toString());
    return LonLatMapChooserState(
        state: state, callback: callback, radius: radius);
  }
}

class LonLatMapChooserState extends State<LonLatMapChooser> {
  LAReState state;
  LatLngToVoidCallback callback;
  DoubleWrapper radius;

  LonLatMapChooserState({this.state, this.callback, this.radius});

  double _currentLat;
  double _currentLon;

  bool first = true;

  @override
  void initState() {
    super.initState();
    _currentLon = state.longitude;
    _currentLat = state.latitude;
  }

  void _updateChosenLocation(LatLng newLatLng) {
    setState(() {
      _currentLat = newLatLng.latitude;
      _currentLon = newLatLng.longitude;
      callback(LatLng(_currentLat, _currentLon));
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "chooser map is rebuilding now, radius" + radius.value.toString());

    LatLng currentLatLng = new LatLng(_currentLat, _currentLon);

    return FlutterMap(
      options: MapOptions(
          center: currentLatLng,
          zoom: 13.0,
          onPositionChanged: (pos, b) {
            debugPrint("new position: " + pos.center.toString());
            if (!first) {
              _updateChosenLocation(pos.center);
            }
            first = false;
          }),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://api.tiles.mapbox.com/v4/"
              "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
          additionalOptions: {
            'accessToken':
                'pk.eyJ1IjoibWFsbHVjZSIsImEiOiJjanF6MmNqeTIwNmppNDJwbHprOGhuaXo1In0.K_3lEcDSPALLWJPO-on54g',
            'id': 'mapbox.streets',
          },
        ),
        MarkerLayerOptions(
          markers: [
            Marker(
              point: currentLatLng,
              width: 80.0,
              height: 80.0,
              builder: (ctx) => Container(
                    child: IconButton(
                      iconSize: 40.0,
                      icon: Icon(Icons.add_location),
                      onPressed: () => debugPrint("pressed!"),
                    ),
                  ),
            ),
          ],
        ),
        CircleLayerOptions(circles: [
          CircleMarker(
              point: currentLatLng,
              radius: radius.value,
              color: Colors.blue.withOpacity(0.5),
              useRadiusInMeter: true)
        ])
      ],
    );
  }
}

/// Route which displays the AddReminderForm to add reminders.
class AddReminderRoute extends StatelessWidget {
  final LAReState state;

  AddReminderRoute({this.state});

  @override
  Widget build(BuildContext context) {
    return AddReminderForm(
      state: state,
    );
  }
}

/// Form used to add a new reminder.
class AddReminderForm extends StatefulWidget {
  final LAReState state;

  AddReminderForm({this.state});

  @override
  State<StatefulWidget> createState() {
    return _AddReminderFormState(state: state);
  }
}

class DoubleWrapper {
  double value;

  DoubleWrapper(this.value);
}

/// the actual form
class _AddReminderFormState extends State<AddReminderForm> {
  _AddReminderFormState({this.state});

  final LAReState state;
  final _formKey = GlobalKey<FormState>();

  LonLatMapChooser lonLat;

  // current values of the form
  String _name = "";
  double _lat;
  double _lon;
  DoubleWrapper _radius;
  Icon _icon;

  // list of icons which can be used for reminders
  List<Icon> _icons = [
    Icons.access_alarm,
    Icons.shopping_cart,
    Icons.library_books,
    Icons.call,
    Icons.wc,
    Icons.school
  ].map((f) => Icon(f)).toList();

  @override
  void initState() {
    super.initState();
    debugPrint("initing add reminder form state");
    _radius = DoubleWrapper(300);
    _icon = _icons[0]; // default icon = alarm clock
  }

  /// Checks if the String is a valid name.
  String _validateName(String value) {
    if (value.isEmpty) {
      return "The name must not be empty.";
    } else {
      return null;
    }
  }

  void setLatLng(LatLng toSet) {
    debugPrint("setting lat lon:" + toSet.toString());
    setState(() {
      _lat = toSet.latitude;
      _lon = toSet.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "rebuilding add reminder form, radius:" + _radius.value.toString());
    TextFormField name = TextFormField(
      decoration: InputDecoration(labelText: "Name"),
      validator: _validateName,
      onSaved: (String value) {
        setState(() {
          _name = value;
        });
      },
    );
    debugPrint(
        "creating MapChooser with radius of " + _radius.value.toString());
    lonLat = LonLatMapChooser(
      state: state,
      callback: setLatLng,
      radius: _radius,
    );
    var radius = Slider(
        label: "Radius (in m)",
        value: _radius.value,
        min: 15,
        max: 5000,
        onChanged: (double val) {
          setState(() {
            _radius.value = val;
          });
        });

    var icon = DropdownButtonHideUnderline(
        child: DropdownButton(
      disabledHint: Text("Icon"),
      hint: Text("hint"),
      value: _icon,
      items: _icons.map((Icon icon) {
        return new DropdownMenuItem(child: icon, value: icon);
      }).toList(),
      onChanged: (Icon icon) {
        setState(() {
          debugPrint(
              "setting icon, codepoint:" + icon.icon.codePoint.toString());
          _icon = icon;
        });
      },
    ));

    return Scaffold(
      appBar: AppBar(
        title: Text("Create a new reminder."),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            child: Form(
              key: _formKey,
              autovalidate: true,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Column(
                    children: <Widget>[
                      Row(
                        children: [
                          Flexible(
                              child: Container(
                            width: 10000.0,
                            child: name,
                          )),
                          Flexible(child: icon),
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                      ),
                      Row(
                        children: <Widget>[
                          Container(
                            height: 15.0,
                          )
                        ],
                      ),
                      Row(children: [
                        Text("Radius:"),
                        Flexible(
                          child: radius,
                          fit: FlexFit.tight,
                        )
                      ]),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  )
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          ),
          Flexible(
            child: lonLat,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          if (_formKey.currentState.validate()) {
            _formKey.currentState.save(); // save state, fills in the variables
            Reminder reminderToAdd = Reminder(
                title: _name,
                lat: _lat,
                lon: _lon,
                radius: _radius.value,
                icon: _icon);
            debugPrint("adding " + reminderToAdd.toString());
            state.addReminder(reminderToAdd);
            Navigator.pop(context); // go back
          }
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

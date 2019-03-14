import 'package:flutter/material.dart';
import 'main.dart';
import 'package:latlong/latlong.dart';

// for map displaying
import 'package:flutter_map/flutter_map.dart';

// for GPS info
import 'package:location/location.dart';

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
    debugPrint(icon.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: Row(
              children: <Widget>[
                Text(title),
                icon,
              ],
              mainAxisAlignment: MainAxisAlignment.spaceAround,
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Center(
                    child: Text("(lon,lat)=(" +
                        lon.toString() +
                        "," +
                        lat.toString() +
                        ")"),
                  ),
                  Center(
                    child: Text("radius=" + radius.toString() + "m"),
                  ),
                ],
              ),
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

class LonLatMapChooserRoute extends StatelessWidget {
  final LAReState state;
  final LatLngToVoidCallback callback;

  LonLatMapChooserRoute({this.state, this.callback});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Choose the reminder location.")),
      body: Container(
        child: LonLatMapChooser(
          state: state,
          callback: callback,
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: null),
    );
  }
}

typedef LatLngToVoidCallback = void Function(LatLng);

class LonLatMapChooser extends StatefulWidget {
  final LAReState state;
  final LatLngToVoidCallback callback;

  LonLatMapChooser({this.state, this.callback});

  @override
  State<StatefulWidget> createState() {
    return LonLatMapChooserState(state: state, callback: callback);
  }
}

class LonLatMapChooserState extends State<LonLatMapChooser> {
  LAReState state;
  LatLngToVoidCallback callback;

  LonLatMapChooserState({this.state, this.callback});

  double _currentLat;
  double _currentLon;

  bool first = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _currentLon = state.longitude;
    _currentLat = state.latitude;
  }

  void _updateChosenLocation(LatLng newLatLng) {
    setState(() {
      _currentLat = newLatLng.latitude;
      _currentLon = newLatLng.longitude;
    });
  }

  @override
  void deactivate() {
    // TODO: implement deactivate
    debugPrint("deactivating");
    super.deactivate();
    callback(LatLng(_currentLat, _currentLon));
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
          center: LatLng(_currentLat, _currentLon),
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
              point: LatLng(_currentLat, _currentLon),
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
        )
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
    return Scaffold(
      appBar: AppBar(title: Text("Create a new reminder.")),
      body: Container(
        child: AddReminderForm(
          state: state,
        ),
        padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      ),
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

/// the actual form
class _AddReminderFormState extends State<AddReminderForm> {
  _AddReminderFormState({this.state});

  final LAReState state;
  final _formKey = GlobalKey<FormState>();

  FormField _lonLat;
  TextEditingController _lonController = TextEditingController(text: "");
  TextEditingController _latController = TextEditingController(text: "");

  // current values of the form
  String _name = "";
  double _lat;
  double _lon;
  double _radius = 0;
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
    _icon = _icons[0]; // default icon = alarm clock
  }

  /// Checks if a String is a valid valid number (i.e. double).
  bool _validNumber(String value) {
    if (value == null) {
      return false;
    }
    double number = double.tryParse(value);
    if (number == null) {
      return false;
    }
    return true;
  }

  ///
  /// Checks whether or not a supplied string value is a valid number within the specified bounds.
  /// Returns null if valid. Else returns error message.
  String _validateWithinBounds(
      String value, double lb, double ub, String name) {
    if (_validNumber(value)) {
      double lon = double.parse(value);
      if (lon >= lb && lon <= ub) {
        return null;
      } else {
        return "The number you entered is not a valid " + name + " .";
      }
    } else {
      return "This is not a valid number.";
    }
  }

  void _openMapRoute() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LonLatMapChooserRoute(
                  state: state,
                  callback: setLatLng,
                )));
  }

  /// Checks if the String is a valid longitude.
  String _validateLongitude(String value) {
    return _validateWithinBounds(value, -180, 180, "longitude");
  }

  /// Checks if the String is a valid latitude.
  String _validateLatitude(String value) {
    return _validateWithinBounds(value, -90, 90, "latitude");
  }

  /// Checks if the String is a valid radius.
  String _validateRadius(String value) {
    return _validateWithinBounds(value, 1.0, double.maxFinite, "radius");
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
      _latController.text = toSet.latitude.toString();
      _lonController.text = toSet.longitude.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    TextFormField name = TextFormField(
      decoration: InputDecoration(labelText: "Name"),
      validator: _validateName,
      onSaved: (String value) {
        setState(() {
          _name = value;
        });
      },
    );
    _lonLat = FormField(
      key: GlobalKey(),
      builder: (FormFieldState state) {
        return FlatButton(
          child: Text("choose on map"),
          onPressed: () => _openMapRoute(),
        );
      },
    );
    var _latField = TextFormField(
      controller: _latController,
      decoration: InputDecoration(labelText: "Latitude"),
      validator: _validateLatitude,
      onSaved: (String value) {
        setState(() {
          _lat = double.parse(value);
        });
      },
    );
    var _lonField = TextFormField(
      controller: _lonController,
      decoration: InputDecoration(labelText: "Longitude"),
      validator: _validateLongitude,
      onSaved: (String value) {
        setState(() {
          _lon = double.parse(value);
        });
      },
    );
    TextFormField radius = TextFormField(
      decoration: InputDecoration(labelText: "Radius (in m)"),
      validator: _validateRadius,
      onSaved: (String value) {
        setState(() {
          _radius = double.parse(value);
        });
      },
    );
    FormField icon = FormField(
      key: GlobalKey(),
      builder: (FormFieldState state) {
        return InputDecorator(
          decoration: InputDecoration(labelText: "Icon"),
          child: DropdownButton(
            value: _icon,
            items: _icons.map((Icon icon) {
              return new DropdownMenuItem(child: icon, value: icon);
            }).toList(),
            onChanged: (Icon icon) {
              setState(() {
                debugPrint("setting icon, codepoint:" +
                    icon.icon.codePoint.toString());
                _icon = icon;
              });
            },
          ),
        );
      },
    );

    return Form(
      key: _formKey,
      autovalidate: true,
      child: ListView(
        children: [
          name,
          _lonLat,
          _latField,
          _lonField,
          radius,
          icon,
          Padding(
            padding: EdgeInsets.all(1),
            child: RaisedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState
                      .save(); // save state, fills in the variables
                  Reminder reminderToAdd = new Reminder(
                      title: _name,
                      lat: _lat,
                      lon: _lon,
                      radius: _radius,
                      icon: _icon);
                  debugPrint("adding " + reminderToAdd.toString());
                  state.addReminder(reminderToAdd);
                  Navigator.pop(context); // go back
                }
              },
              child: Text("Create"),
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

// for map displaying
import 'package:flutter_map/flutter_map.dart';

// for PI, sin etc. (distance function)
import 'dart:math';

// for circles on map
import 'package:flutter_map/plugin_api.dart';

import 'package:latlong/latlong.dart';

// for GPS info
import 'package:location/location.dart';

// for await, futures etc.
import 'dart:async';

import 'main.dart';
import 'reminder.dart';

///
/// The reminder map.
///
class ReminderMap extends StatefulWidget {
  final LAReState state;

  ReminderMap({this.state});

  @override
  State<StatefulWidget> createState() {
    return _ReminderMapState(state: state);
  }
}

///
/// The reminder map state which constantly polls GPS and checks if user is in radius of any reminder.
///
class _ReminderMapState extends State<ReminderMap> {
  final LAReState state;

  _ReminderMapState({this.state});

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

  @override
  void initState() {
    print("initing map state");
    super.initState();

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

  @override
  void deactivate() {
    super.deactivate();
    print("deactivating map state");
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
  }

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
    for (Reminder reminder in state.reminders) {
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
      state.startVibrate();
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
                          state.deleteReminder(reminder);
                        }
                        alertIsVisible = false;
                        state.stopVibrate();
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
  Widget build(BuildContext context) {
    print("rebuilding map state, lat=" +
        _latitude.toString() +
        ",lon=" +
        _longitude.toString());

    List<Marker> markers = [];
    List<CircleMarker> circles = [];
    // reminder markers
    for (Reminder reminder in state.reminders) {
      circles.add(buildCircleMarker(reminder.toLatLng(), reminder.radius));
      markers.add(buildMarker(reminder.toLatLng(), reminder.icon));
    }
    // current location marker
    markers.add(buildMarker(
        new LatLng(_latitude, _longitude), Icon(Icons.location_on)));

    if (_latitude == 0 && _longitude == 0) {
      return Text("waiting for valid value");
    }

    return FlutterMap(
      options: MapOptions(
        center: LatLng(_latitude, _longitude),
        zoom: 13.0,
        onPositionChanged: (pos, b) => debugPrint("new position: " + pos.toString())
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
          markers: markers,
        ),
        CircleLayerOptions(
          circles: circles,
        )
      ],
    );
  }
}

///
/// Builds a marker at a LatLng with a specified icon.
///
Marker buildMarker(LatLng latLon, Icon icon) {
  return Marker(
    point: latLon,
    width: 80.0,
    height: 80.0,
    builder: (ctx) => Container(
          child: IconButton(
            icon: icon,
            onPressed: () => debugPrint("pressed!"),
          ),
        ),
  );
}

///
/// Builds a circle marker at a LatLng with a specified radius in meter.
///
CircleMarker buildCircleMarker(LatLng center, double radius) {
  return CircleMarker(
    point: center,
    radius: radius,
    useRadiusInMeter: true,
    color: Colors.blue.withOpacity(0.7),
  );
}

///
/// Computes the distance between two LatLng points in meter.
///
double computeDistanceBetween(LatLng l1, LatLng l2) {
  double earthRadiusInM = 6371e3;
  double dLat = l2.latitudeInRad - l1.latitudeInRad;
  double dLon = l2.longitudeInRad - l1.longitudeInRad;

  double a = sin(dLat / 2) * sin(dLat / 2) +
      sin(dLon / 2) *
          sin(dLon / 2) *
          cos(l1.latitudeInRad) *
          cos(l2.latitudeInRad);

  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  debugPrint("distance: " + (earthRadiusInM * c).toString());

  return earthRadiusInM * c;
}

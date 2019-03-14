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

  @override
  Widget build(BuildContext context) {
    print("rebuilding map state, lat=" +
        state.latitude.toString() +
        ",lon=" +
        state.longitude.toString());

    List<Marker> markers = [];
    List<CircleMarker> circles = [];
    // reminder markers
    for (Reminder reminder in state.reminders) {
      circles.add(buildCircleMarker(reminder.toLatLng(), reminder.radius));
      markers.add(buildMarker(reminder.toLatLng(), reminder.icon));
    }
    // current location marker
    markers.add(buildMarker(
        new LatLng(state.latitude, state.longitude), Icon(Icons.location_on)));

    if (state.latitude == 0 && state.longitude == 0) {
      return Text("waiting for valid value");
    }

    return FlutterMap(
      options: MapOptions(
        center: LatLng(state.latitude, state.longitude),
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

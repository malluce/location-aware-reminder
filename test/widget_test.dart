// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moc_app/main.dart';
import 'package:moc_app/map.dart';
import 'package:latlong/latlong.dart';

void main() {
  print(computeDistanceBetween(new LatLng(51.5,0), new LatLng(38.8, -77.1)));
}

import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class WearableConnector {
  static const String WEARABLE_ID = "EF:EA:F0:C2:F5:5E";
  static const String SERVICE_UUID = "713d0000-503e-4c75-ba94-3148f18d941e";
  static const String VIBRATION_CHARACTERISTIC_UUID =
      "713d0003-503e-4c75-ba94-3148f18d941e";
  static const int AMOUNT_OF_VIBRATION_MOTORS = 4;
  BluetoothDevice _device = BluetoothDevice(id: DeviceIdentifier(WEARABLE_ID));
  StreamSubscription<BluetoothDeviceState> _deviceConnection;
  BluetoothDeviceState _currentDeviceState;
  FlutterBlue _flutterBlue = FlutterBlue.instance;

  void cancelConnection() {
    debugPrint("DISCONNECTING");
    _deviceConnection?.cancel();
  }

  void vibrate() {

    _flutterBlue.isOn.then((on) {
      debugPrint("is on: " + on.toString());
    });
    debugPrint("in vibrate");
    connectWriteAndBail([0xFF,0xFF,0xFF,0xFF]);
  }

  void stopVibrate() {
    debugPrint("in stop vibrate");
    connectWriteAndBail([0x00,0x00,0x00,0x00]);
  }

  void connectWriteAndBail(List<int> values) async{
    if(_currentDeviceState==BluetoothDeviceState.connected)  {
      debugPrint("was connected, setting vibr char to " + values.toString() + "and disconnecting");
      writeVibrationCharacteristic(values);
      return;
    }

    debugPrint("was not connected, trying to connect");
    _deviceConnection = _flutterBlue.connect(_device, autoConnect: false).listen((s)async {
      _currentDeviceState = s;
      _device.onStateChanged().listen((x) {
        _currentDeviceState = x;
      });
      debugPrint("new connection status: "+ s.toString());
      if(s == BluetoothDeviceState.connected) {
         writeVibrationCharacteristic(values);
      }
    });
  }

  Future<Null> writeVibrationCharacteristic(List<int> values) {
    if (values.length != AMOUNT_OF_VIBRATION_MOTORS) {
      throw Exception("This wearable has" +
          AMOUNT_OF_VIBRATION_MOTORS.toString() +
          "motors. Please supply this amount of bytes.");
    }

    _device.discoverServices().then((services) {
      services.forEach((service)  {
        if (service.uuid == Guid(SERVICE_UUID)) {
          var characteristics = service.characteristics;
          for (BluetoothCharacteristic c in characteristics) {
            if (c.uuid == Guid(VIBRATION_CHARACTERISTIC_UUID)) {
               _device.writeCharacteristic(c, values);
            }
          }
        }
      });
    });
  }
}

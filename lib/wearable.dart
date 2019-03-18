import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:collection/collection.dart';

class WearableConnector {
  static const String WEARABLE_ID = "EF:EA:F0:C2:F5:5E";
  static const String SERVICE_UUID = "713d0000-503e-4c75-ba94-3148f18d941e";
  static const String VIBRATION_CHARACTERISTIC_UUID =
      "713d0003-503e-4c75-ba94-3148f18d941e";
  static const int AMOUNT_OF_VIBRATION_MOTORS = 4;
  BluetoothDevice _device = BluetoothDevice(id: DeviceIdentifier(WEARABLE_ID));
  StreamSubscription<BluetoothDeviceState> _deviceConnection;
  BluetoothDeviceState currentDeviceState;
  FlutterBlue _flutterBlue = FlutterBlue.instance;
  static const List<int> VIBRATE_ON_VALUES = [0xFF, 0xFF, 0xFF, 0xFF];
  static const List<int> VIBRATE_OFF_VALUES = [0x00, 0x00, 0x00, 0x00];

  void cancelConnection() {
    debugPrint("DISCONNECTING");
    _deviceConnection?.cancel();
  }

  void vibrate() {
    _flutterBlue.isOn.then((on) {
      debugPrint("is on: " + on.toString());
    });
    debugPrint("in vibrate");
    connectWriteAndBail(VIBRATE_ON_VALUES);
  }

  void stopVibrate() {
    debugPrint("in stop vibrate");
    connectWriteAndBail(VIBRATE_OFF_VALUES);
  }

  void connectWriteAndBail(List<int> values) {
    if (currentDeviceState == BluetoothDeviceState.connected) {
      debugPrint("was connected, setting vibr char to " + values.toString());
      writeVibrationCharacteristic(values);
      return;
    }

    debugPrint("was not connected, trying to connect");
    _deviceConnection =
        _flutterBlue.connect(_device, autoConnect: false).listen((s) async {
      currentDeviceState = s;
      _device.onStateChanged().listen((x) {
        debugPrint("new connection status: " + s.toString());
        currentDeviceState = x;
      });
      debugPrint("new connection status: " + s.toString());
      if (s == BluetoothDeviceState.connected) {
        writeVibrationCharacteristic(values);
      }
    });
  }

  Future<Null> writeVibrationCharacteristic(List<int> values) async {
    if (values.length != AMOUNT_OF_VIBRATION_MOTORS) {
      throw Exception("This wearable has" +
          AMOUNT_OF_VIBRATION_MOTORS.toString() +
          "motors. Please supply this amount of bytes.");
    }

    List<BluetoothService> services = await _device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid == Guid(SERVICE_UUID)) {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          if (c.uuid == Guid(VIBRATION_CHARACTERISTIC_UUID)) {
            await _device.writeCharacteristic(c, values);
            if (ListEquality().equals(values, VIBRATE_OFF_VALUES)) {
              // cancel device connection on motor off
              debugPrint("cancelling device connection");
              await _deviceConnection.cancel();
              currentDeviceState = BluetoothDeviceState.disconnected;
            }
          }
        }
      }
    }
  }
}

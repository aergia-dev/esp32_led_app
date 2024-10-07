import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'protocol.dart';

class Ble {
  static Ble _instance = new Ble();

  static Ble get instance => _instance;

  // int current_color;
  // Color currentColor;

  StreamController currentColorController = StreamController<Color>();
  StreamController stateController = StreamController<BluetoothDeviceState>();

  StreamController lightOnOffController = StreamController<bool>();
  bool lightState = false;

  StreamController ready = StreamController<bool>();
  final String devName = "SleepLight";
  BluetoothDevice device;
  BluetoothCharacteristic characteristic;

  final String serviceUUID = "000000ff-0000-1000-8000-00805f9b34fb";
  final String characteristicUUID = "0000ff01-0000-1000-8000-00805f9b34fb";

  void connect() {
    print("connect");
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 4));
  }

  void init() async {
    print("init");
    FlutterBlue.instance.scanResults.listen((results) async {
      print("results: $results");
      for (var result in results) {
        if (result.device.name == devName) {
          FlutterBlue.instance.stopScan();
          device = result.device;
          await device.connect();

          device.state.listen((state) {
            print("device state $state");
            if (state == BluetoothDeviceState.connected) {
              stateController.add(BluetoothDeviceState.connected);
            }
          });

          device.services.listen((services) async {
            print("services  $services");

            services.forEach((s) async {
              // print('service: $s');
              if (s.uuid.toString() == serviceUUID) {
                s.characteristics.forEach((c) {
                  // print('ch: $c');
                  if (c.uuid.toString() == characteristicUUID) {
                    characteristic = c;
                    ready.add(true);
                    // readLightOnOff();
                    // readLedColor();
                  }
                });
              }
            });
          });
          device.discoverServices();
          print("device $device");
          print('connected ${FlutterBlue.instance.connectedDevices}');
        }
      }
    });
  }

  void disconnect() {
    print("disconnect");
    device.disconnect();
    stateController.add(BluetoothDeviceState.disconnected);
    device = null;
    ready.add(false);
  }


  void toggleLed(bool onOff) async {
    // device
    print(onOff);
    if (device != null) {
      if (!onOff) {
        await characteristic.write(Protocol.map['LED_OFF']);
      } else
        await characteristic.write(Protocol.map['LED_ON']);
    }

    await readLightOnOff();
  }

  Future<void> changeLedColor(Color c) async {
  //  print("change color: $r, $g, $b");
    await characteristic.write([...Protocol.map['CHANGE_COLOR'], ...[c.red, c.green, c.blue]]);
  }

  Future<void> readLedColor() async {
    await characteristic.write(Protocol.map['READ_CURRENT_COLOR']);

    List<int> read = await characteristic.read();
    // currentColor = Color.fromARGB(0xff, read[1], read[2], read[3]);
    currentColorController.add(Color.fromARGB(0xff, read[1], read[2], read[3]));
    print("read color: ${Color.fromARGB(read[0], read[1], read[2], read[3])}");
    //await characteristic.write([0x01, 0x04, 0x03, r, g, b]);

    return;
  }

  Future<void> readLightOnOff() async {
    bool lightState;
    await characteristic.write(Protocol.map['READ_LIGHTONOFF']);
    List<int> read = await characteristic.read();
    print("light onoff ${read[0]}");
    if (read[0] == 0) {
      lightOnOffController.add(false);
      lightState = false;
    } else {
      lightOnOffController.add(true);
      lightState = true;
    }
  }

  //save current color into flash.
  Future<void> applyColor(Color c) async {
    await characteristic.write([...Protocol.map['SAVE_COLOR_FLASH'],...[c.red, c.green, c.blue]]);
  }

  Future<void> controllBrightness(int val) async {
      await characteristic.write([...Protocol.map['BRIGHTNESS'], val]);
  }
}

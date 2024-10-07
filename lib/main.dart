// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'widgets.dart';
import 'package:flutter_switch/flutter_switch.dart';
import "ble.dart";
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return MainPage();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainScreen createState() => _MainScreen();
}

class _MainScreen extends State<MainPage> {
  bool lightConnected = false;
  bool lightOnOff = false;
  Color currentColor = Colors.white;
  Color backupColor;
  double _sliderVal = 50;

   @override
  void initState() {
    Ble.instance.init();
    super.initState();

    //after read current color of lamp.
    Ble.instance.currentColorController.stream.listen((color) async {
      await changeColor(color);
      backupColor = color;
    });

    FlutterBlue.instance.state.listen((event) {
      print("flutter blue state : $event");
    });

    Ble.instance.stateController.stream.listen((event) {
        if (event == BluetoothDeviceState.connected)
          setState(() => lightConnected = true);
        else
          setState(() => lightConnected = false);
      });

    Ble.instance.lightOnOffController.stream.listen((event) {
        setState(() => lightOnOff = event);
    });

    Ble.instance.ready.stream.listen((event) async {
      if(event == true){
        await Ble.instance.readLedColor();
        await Ble.instance.readLightOnOff();
      }
    });
  }


  void changeColor(Color color) {
    setState(() => currentColor = color);
    // print("current color: $color");
    // colorController.add(color);
    Ble.instance.changeLedColor(color);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sleep Light"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("connect light",
                      textAlign: TextAlign.center, textScaleFactor: 1.0),
                  SizedBox(height: 10.0),
                  FlutterSwitch(
                    value: lightConnected,
                    width: 50.0,
                    height: 30.0,
                    toggleSize: 20,
                    borderRadius: 30.0,
                    padding: 2.0,
                    onToggle: (val) {

                        // setState(() {
                        //   status1 = val;
                        // });

                        if (val) {
                          Ble.instance.connect();
                        } else {
                          Ble.instance.disconnect();
                        }
                      // }
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("Toggle Light",
                      textAlign: TextAlign.center, textScaleFactor: 1.0),
                  SizedBox(height: 10.0),
                  FlutterSwitch(
                    value: lightOnOff,
                    width: 50.0,
                    height: 30.0,
                    toggleSize: 20,
                    borderRadius: 30.0,
                    padding: 2.0,
                    onToggle: (val) {
                      lightOnOff = val;
                      print(val);
                      Ble.instance.toggleLed(val);
                    },
                  ),
                ],
              ),
              // StreamBuilder<Color>(
              //   stream: colorController.stream,
              //   initialData: Colors.white,
              //   builder: (c, snapshot) =>
                    Row(
                  children: <Widget>[
                    Text("Change Color",
                        textAlign: TextAlign.center, textScaleFactor: 1.0),
                    SizedBox(width: 30.0),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              titlePadding: const EdgeInsets.all(0.0),
                              contentPadding: const EdgeInsets.all(0.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              content: SingleChildScrollView(
                                child: SlidePicker(
                                  pickerColor: currentColor,
                                  onColorChanged: changeColor,
                                  paletteType: PaletteType.rgb,
                                  enableAlpha: false,
                                  displayThumbColor: true,
                                  showLabel: false,
                                  showIndicator: true,
                                  indicatorBorderRadius:
                                      const BorderRadius.vertical(
                                    top: const Radius.circular(25.0),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: const Text('Choose'),
                      style: ElevatedButton.styleFrom(
                        primary: currentColor,
                        onPrimary: Colors.white,
                      ),
                      // textColor: useWhiteForeground(currentColor)
                      //     ? const Color(0xffffffff)
                      //     : const Color(0xff000000),
                    ),
                    SizedBox(width: 5.0),
                    ElevatedButton(
                      onPressed: () {
                        Ble.instance.applyColor(currentColor);
                        backupColor = currentColor;
                      },
                      child: Text("apply"),
                    ),
                    SizedBox(width: 5.0),
                    ElevatedButton(
                      onPressed: () {
                        if(backupColor == null)
                          backupColor = Colors.white;
                        currentColor = backupColor;
                        changeColor(currentColor);
                      },
                      child: Text("revert"),
                    )
                  ],
                ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: <Widget>[
              //     Text("Control Brightness",
              //         textAlign: TextAlign.center, textScaleFactor: 1.0),
              //     SizedBox(height: 10.0),
              //     Slider(
              //         value:_sliderVal,
              //         min: 0,
              //         max:100,
              //         divisions: 100,
              //         label: _sliderVal.round().toString(),
              //         onChanged: (double val) {
              //           setState(() {
              //             _sliderVal = val;
              //           });
              //           Ble.instance.controllBrightness(val.toInt());
              //         })
              //   ],
              // ),

              // )
            ],
          ),
        ),
      ),
    );
  }
}

class __MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sleep Light'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                  child: FlutterSwitch(
                width: 120,
                height: 55,
                valueFontSize: 20,
                toggleSize: 40,
                padding: 10,
                showOnOff: true,
                //onToggle: (val) {
                //print(val);
                //},
              ))
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}
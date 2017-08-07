/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import 'src/ui/route/add_server.dart';
import 'src/ui/route/home.dart';
import 'src/db/dbmanager.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _SubmarineState createState() => new _SubmarineState();
}

class _SubmarineState extends State<MyApp> {
  Widget _home;

  _SubmarineState() {
    _checkIfServerAvailable();
  }

  _checkIfServerAvailable() async {
    await DBManager.prepare();
    var hasServer = await DBManager.getInstance().hasServer();
    setState(() {
      _home = hasServer ? new Home() : new AddServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_home == null) {
      return new Container();
    }

    return new MaterialApp(
      title: 'Submarine',
      theme: new ThemeData(
          brightness: Brightness.dark, accentColor: Colors.lightBlueAccent
          //primaryColor: new Color(0xFF4A148C),
          ),
      home: _home,
    );
  }
}

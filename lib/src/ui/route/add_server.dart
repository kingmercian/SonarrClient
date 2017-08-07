/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../network/network.dart';
import '../../model/model.dart';
import 'list_shows.dart';
import '../../db/dbmanager.dart';
import 'home.dart';

class AddServer extends StatefulWidget {
  @override
  _AddServerState createState() => new _AddServerState();
}

class _AddServerState extends State<AddServer> {
  final TextEditingController _serverController = new TextEditingController();
  final TextEditingController _portController = new TextEditingController();
  final TextEditingController _pathController = new TextEditingController();
  final TextEditingController _keyController = new TextEditingController();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  bool _https = false;
  bool _loading = false;
  var _server;
  bool _hasServer = false;

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  @override
  initState() async {
    super.initState();
    await _loadInfo();
  }

  _loadInfo() async {
    if (await DBManager.getInstance().hasServer()) {
      var server = await DBManager.getInstance().getServer();
      _hasServer = true;
      _serverController.text = server.hostname;
      _portController.text = "${server.port}";
      _pathController.text = server.path;
      _keyController.text = server.apiKey;

      setState(() => _https = server.https);
    }
  }

  _validateAndAdd() {
    final FormState form = _formKey.currentState;

    if (form.validate()) {
      _addServer();
    }
  }

  _addServer() async {
    _server = new Server()
      ..https = _https
      ..hostname = _serverController.text
      ..path = _pathController.text
      ..port = int.parse(_portController.text)
      ..apiKey = _keyController.text;

    setState(() {
      _loading = true;
    });

    try {
      Status status =
          await Client.getTemporaryInstance(server: _server).getStatus();

      _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content:
              new Text("Connecter to server, version: ${status.version}")));

      DBManager.getInstance().addServer(_server);

      if (_hasServer) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
            context,
            new MaterialPageRoute<ListShows>(
                builder: (BuildContext context) => new Home()));
      }
    } on InvalidApiKeyException catch (_) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: new Text("Invalid API Key."),
          backgroundColor: Colors.redAccent));
    } on CantConnectException catch (_) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(
          content: new Text(
              "Can't connect to the server, please check the configuration and try again."),
          backgroundColor: Colors.redAccent));
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  String _validatePort(String value) {
    if (value.isEmpty) return null;
    // TODO: Update regex to reject 0
    final RegExp portExp = new RegExp(
        r'^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$');

    if (!portExp.hasMatch(value)) return "Not a valid port number";

    return null;
  }

  String _validateServer(String value) {
    if (value.isEmpty) return "You must enter an IP address or hostname";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    var loader = (_loading)
        ? new Container(
            height: 110.0,
            child: new Center(child: new CircularProgressIndicator()))
        : new Container();

    RaisedButton action = _hasServer
        ? new RaisedButton(
            onPressed: _validateAndAdd,
            child: const Text("Update"),
          )
        : new RaisedButton(
            onPressed: _validateAndAdd,
            child: const Text("Add"),
          );

    Text title =
        _hasServer ? const Text("Edit Connection") : const Text("Add Server");

    var form = new Container(
      margin: const EdgeInsets.all(24.0),
      child: new Form(
          key: _formKey,
          child: new Column(
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  new Text("Use https"),
                  new Align(
                    alignment: FractionalOffset.centerRight,
                    child: new Switch(
                        value: _https,
                        onChanged: (bool https) => setState(() {
                              _https = https;
                            })),
                  ),
                ],
              ),
              new TextFormField(
                controller: _serverController,
                autofocus: true,
                decoration: new InputDecoration(
                  hintText: "IP or hostname of the server",
                  labelText: "Server",
                ),
                validator: _validateServer,
              ),
              new TextFormField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                  hintText: "Port to be used",
                  labelText: "Port",
                ),
                validator: _validatePort,
              ),
              new TextFormField(
                controller: _pathController,
                decoration: new InputDecoration(
                  hintText: "Path",
                  labelText: "Path",
                ),
              ),
              new TextFormField(
                controller: _keyController,
                decoration: new InputDecoration(
                  hintText: "API Key to connect",
                  labelText: "Key",
                ),
              ),
              action,
            ],
          )),
    );

    var body = new CustomScrollView(
      slivers: <Widget>[
        new SliverToBoxAdapter(child: form),
        new SliverToBoxAdapter(
          child: loader,
        )
      ],
    );

    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: title,
        ),
        body: body);
  }
}

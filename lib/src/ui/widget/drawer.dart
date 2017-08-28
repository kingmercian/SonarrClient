/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../network/network.dart';
import '../../model/model.dart';
import '../../utils/utils.dart';
import '../route/add_server.dart';
import '../route/update_sonarr.dart';

class SubmarineDrawer extends StatefulWidget {
  @override
  _SubmarineDrawerState createState() => new _SubmarineDrawerState();
}

class _SubmarineDrawerState extends State<SubmarineDrawer> {
  bool _isLoading = true;
  Status _status;
  List<HealthMessage> _health;
  List<Drive> _drives;

  _goToSettings() {
    Navigator.push(
        context,
        new MaterialPageRoute<AddServer>(
            builder: (BuildContext context) => new AddServer()));
  }

  _goToUpdate() {
    Navigator.push(
        context,
        new MaterialPageRoute<UpdateSonarr>(
            builder: (BuildContext context) => new UpdateSonarr()));
  }

  @override
  initState() {
    super.initState();
    _loadInfo();
  }

  _loadInfo() async {
    setState(() => _isLoading = true);

    await Client.prepare();
    _status = await Client.getInstance().getStatus();
    _health = await Client.getInstance().getHealth();
    _drives = await Client.getInstance().getDrives();

    setState(() => _isLoading = false);
  }

  Widget _element(String label) {
    return new Container(
      margin: const EdgeInsets.only(left: 22.0, top: 8.0),
      child: new Text(label),
    );
  }

  Widget _subElement(String label) {
    return new Container(
      margin: const EdgeInsets.only(left: 28.0, top: 4.0),
      child: new Text(
        label,
        style: new TextStyle(fontSize: 12.0, color: Colors.grey),
      ),
    );
  }

  Widget _header(String label) {
    return new Container(
      margin: const EdgeInsets.only(left: 12.0, top: 8.0),
      child: new Text(
        label,
        style: new TextStyle(fontSize: 20.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ListTile editConnection = new ListTile(
      leading: const Icon(Icons.settings),
      title: const Text('Connection Settings'),
      onTap: () => _goToSettings(),
    );


    ListTile updateSonarr = new ListTile(
      leading: const Icon(Icons.update),
      title: const Text('Update Sonarr'),
      onTap: () => _goToUpdate(),
    );

    if (_isLoading)
      return new ListView(
        children: <Widget>[
          new Container(
              height: 110.0,
              child: new Center(child: new CircularProgressIndicator())),
          editConnection
        ],
      );

    List<Widget> content = [
      new Divider(),
      _header('System Info'),
      _element('Sonarr ${_status.version}'),
      _element('Mono Version ${_status.runtimeVersion}'),
      _element('${_status.operativeSystem.getLabel()} - '
          '${capitalize(_status.osName)} ${_status.osVersion}'),
      _element('Branch ${_status.branch}'),
    ];

    if (_health.isNotEmpty) {
      content.add(new Divider());
      content.add(_header("Health Info"));
      content.addAll(_health.map((HealthMessage message) {
        return _element(message.message);
      }).toList());
    }

    if (_drives.isNotEmpty) {
      content.add(new Divider());
      content.add(_header("Disk Info"));
      content.addAll(_drives.map((Drive drive) {
        return new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _element(drive.path),
            _subElement(drive.label),
            _subElement(
                "${drive.freeSpace} available (${drive.totalSpace} total)"),
          ],
        );
      }).toList());
    }

    content.add(new Divider());
    content.add(editConnection);
    content.add(updateSonarr);

    return new RefreshIndicator(
        onRefresh: _loadInfo,
        child: new Container(
          margin: const EdgeInsets.only(top: 22.0),
          child: new ListView(
            children: content,
          ),
        ));
  }
}

/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/client.dart';

class AddEditShow extends StatefulWidget {
  Show _show;
  List<Profile> _profiles = [];
  List<RootFolder> _rootFolders = [];

  AddEditShow(this._show, this._profiles, this._rootFolders);

  @override
  _AddEditShowState createState() =>
      new _AddEditShowState(_show, _profiles, _rootFolders);
}

class _AddEditShowState extends State<AddEditShow> {
  Show _show;
  Profile _selectedProfile;
  RootFolder _selectedRootFolder;
  MonitorSeasons _selectedMonitoredSeasons;
  ShowType _selectedShowType;
  bool _loading = false;
  bool _addingShow = true;
  bool _monitorShow = false;
  bool _seasonFolder = false;
  List<Profile> _profiles = [];
  List<RootFolder> _rootFolders = [];

  _AddEditShowState(this._show, this._profiles, this._rootFolders) {
    // Preload the info for Edit
    if (_show.id != null) {
      _addingShow = false;
      for (Profile profile in _profiles) {
        if (profile.id == _show.profileId) _selectedProfile = profile;
      }

      String currentType = _show.raw["seriesType"];

      for (ShowType type in ShowType.values) {
        if (type.getValue() == currentType) {
          _selectedShowType = type;
        }
      }

      _monitorShow = _show.monitored;
      _seasonFolder = _show.seasonFolder;
    } else {
      _selectedShowType = ShowType.STANDARD;
      _selectedMonitoredSeasons = MonitorSeasons.values[0];
      _selectedRootFolder = _rootFolders[0];
      _selectedProfile = _profiles[0];
    }
  }

  _addShow() async {
    setState(() => _loading = true);
    await Client.getInstance().addShow(
        _show,
        _selectedProfile,
        _selectedRootFolder,
        _selectedShowType,
        _selectedMonitoredSeasons,
        _seasonFolder);

    Navigator.pop(context, true);
  }

  _editShow() async {
    setState(() => _loading = true);
    await Client.getInstance().updateShow(_show, _selectedProfile,
        _selectedShowType, _monitorShow, _seasonFolder);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    Widget profileRow = new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        new Text("Profile:"),
        new DropdownButton<Profile>(
            value: _selectedProfile,
            items: _profiles.map((Profile profile) {
              return new DropdownMenuItem<Profile>(
                  value: profile,
                  child: new Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: new Text(profile.name),
                  ));
            }).toList(),
            onChanged: (Profile profile) => _selectedProfile = profile)
      ],
    );

    Widget typeRow = new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        new Text("Type:"),
        new DropdownButton<ShowType>(
            value: _selectedShowType,
            items: ShowType.values.map((ShowType showType) {
              return new DropdownMenuItem<ShowType>(
                  value: showType,
                  child: new Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: new Text(showType.getLabel()),
                  ));
            }).toList(),
            onChanged: (ShowType showType) => _selectedShowType = showType)
      ],
    );

    Row pathRow = new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        new Text("Path:"),
        new DropdownButton<RootFolder>(
            value: _selectedRootFolder,
            items: _rootFolders.map((RootFolder rootFolder) {
              return new DropdownMenuItem<RootFolder>(
                  value: rootFolder,
                  child: new Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: new Text(rootFolder.path),
                  ));
            }).toList(),
            onChanged: (RootFolder rootFolder) =>
                _selectedRootFolder = rootFolder)
      ],
    );

    Widget monitorRow = _addingShow
        ? new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text("Monitor:"),
              new DropdownButton<MonitorSeasons>(
                  value: _selectedMonitoredSeasons,
                  items: MonitorSeasons.values.map((MonitorSeasons monitor) {
                    return new DropdownMenuItem<MonitorSeasons>(
                        value: monitor,
                        child: new Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: new Text(monitor.getLabel()),
                        ));
                  }).toList(),
                  onChanged: (MonitorSeasons monitor) =>
                      _selectedMonitoredSeasons = monitor)
            ],
          )
        : new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text("Monitor:"),
              new Checkbox(
                  value: _monitorShow,
                  onChanged: (monitor) => setState(() {
                        _monitorShow = monitor;
                      }))
            ],
          );

    Widget seasonFolder = new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        new Text("Season Folder:"),
        new Checkbox(
            value: _seasonFolder,
            onChanged: (seasonFolder) => setState(() {
                  _seasonFolder = seasonFolder;
                }))
      ],
    );

    Widget loadingOrAction;

    if (_loading) {
      loadingOrAction = new Container(
          height: 50.0,
          width: 50.0,
          child: new Center(child: new CircularProgressIndicator()));
    } else {
      loadingOrAction = _addingShow
          ? new RaisedButton(
              onPressed: () => _addShow(),
              child: new Text("ADD"),
            )
          : new RaisedButton(
              onPressed: () => _editShow(),
              child: new Text("UPDATE"),
            );
    }

    List<Widget> content = [profileRow, typeRow, monitorRow, seasonFolder];
    if (_addingShow) content.add(pathRow);
    content.add(loadingOrAction);

    Column body = new Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: content,
    );

    var scroll = new CustomScrollView(slivers: [
      new SliverToBoxAdapter(
          child: new Container(
              margin: const EdgeInsets.fromLTRB(30.0, 8.0, 16.0, 8.0),
              child: new DropdownButtonHideUnderline(child: body)))
    ]);

    return new Scaffold(body: scroll);
  }
}

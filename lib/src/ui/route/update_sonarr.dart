/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/network.dart';
import '../../utils/utils.dart';
import '../widget/submarine_message.dart';
import '../widget/changelog.dart';

class UpdateSonarr extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _UpdateSonarrState();
}

class _UpdateSonarrState extends State<UpdateSonarr> {
  bool _loading = true;
  List<SonarrRelease> _releases = [];
  bool _installing = false;

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  _UpdateSonarrState() {
    _getReleases();
  }

  _getReleases({bool displayLoader: true}) async {
    if (displayLoader) setState(() => _loading = true);

    await Client.prepare();

    _releases = await Client.getInstance().getReleases();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  _changeLog(SonarrRelease release) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new Changelog(
              release.features, release.fixes, release.version);
        });
  }

  _update() async {
    if (mounted) {
      setState(() => _installing = true);
    }

    await Client.getInstance().updateSonarr();

    if (mounted) {
      setState(() => _installing = false);
      _showSnackBar("Update request sent succesfully. It may take some minutes");
    }
  }

  _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
        duration: new Duration(seconds: 3),
        backgroundColor: Colors.blue,
        content: new Text(message)));
  }

  Widget _getReleaseContent(SonarrRelease release) {
    Color bgColor =
        (_releases.indexOf(release) % 2 == 0) ? Colors.black54 : Colors.black12;

    DateTime date = release.releaseDate;

    Text dateLabel = new Text(
      "${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}",
      style: new TextStyle(fontSize: 12.0, color: Colors.grey),
    );

    Text version = new Text(
      release.version,
      style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );

    List<Widget> body = [dateLabel, version];

    List<Widget> actions = [
      new IconButton(
        icon: const Icon(Icons.assignment, color: Colors.white),
        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
        tooltip: "See changelog",
        onPressed: () => _changeLog(release),
      )
    ];

    if (release.installed) {
      actions.add(new Chip(
        label: new Text("Installed"),
        backgroundColor: Colors.lightBlue,
      ));
    } else if (release.installable) {
      if (!_installing) {
        actions.add(new IconButton(
          icon: const Icon(Icons.update, color: Colors.lightBlue),
          padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
          tooltip: "Install update",
          onPressed: () => _update(),
        ));
      } else {
        actions.add(new Container(
            height: 24.0,
            width: 24.0,
            margin: const EdgeInsets.only(top: 13.0, bottom: 13.0, right: 14.0),
            child: new Center(child: new CircularProgressIndicator())));
      }
    }

    Row actionsRow = new Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions,
    );

    body.add(actionsRow);

    return new Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(28.0, 12.0, 28.0, 2.0),
        alignment: FractionalOffset.centerLeft,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> body = [];

    if (!_loading && _releases.isNotEmpty) {
      body.addAll(_releases.map((SonarrRelease release) {
        return _getReleaseContent(release);
      }).toList());
    }

    if (!_loading && _releases.isEmpty) {
      body.add(new SubmarineMessage("No updates info available", Icons.warning,
          margin: const EdgeInsets.only(top: 80.0)));
    }

    var loadingOrBody = (_loading)
        ? new Container(
            height: 110.0,
            child: new Center(child: new CircularProgressIndicator()))
        : new Container(
            margin: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 8.0),
            child: new Column(
              children: body,
            ));

    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text("Sonarr Updates"),
        ),
        body: new RefreshIndicator(
            onRefresh: () async {
              _getReleases();
            },
            child: new CustomScrollView(slivers: <Widget>[
              new SliverToBoxAdapter(child: loadingOrBody)
            ])));
  }
}

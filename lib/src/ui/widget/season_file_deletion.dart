/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';

import '../../model/model.dart';
import '../../network/network.dart';
import '../../utils/utils.dart';
import 'submarine_message.dart';

class SeasonFileDeletion extends StatefulWidget {
  final Season _season;

  SeasonFileDeletion(this._season);

  @override
  _SeasonFileDeletionState createState() => new _SeasonFileDeletionState();
}

class _SeasonFileDeletionState extends State<SeasonFileDeletion> {
  List<int> _epsToDelete = [];
  int _currentEp = 0;

  @override
  initState() {
    super.initState();

    for (Episode ep in widget._season.episodes) {
      if (ep.hasFile) {
        _epsToDelete.add(ep.episodeFileId);
      }
    }

    _deleteEpisodes();
  }

  _deleteEpisodes() async {
    for (int fileId in _epsToDelete) {
      await Client.getInstance().deleteDownloadedEpisode(fileId);
      setState(() => _currentEp++);
    }
  }

  @override
  Widget build(BuildContext context) {
    var progress = _currentEp / _epsToDelete.length;

    Widget body;

    if (_currentEp < _epsToDelete.length) {
      Episode ep = widget._season.episodes[_currentEp];

      String message =
          "Deleting ${sxxepxx(widget._season.number, ep.episodeNumber)} - ${ep.title}";

      body = new Container(
        margin: const EdgeInsets.only(top: 30.0),
        child: new Text(
          message,
          textAlign: TextAlign.center,
          style: new TextStyle(fontSize: 16.0),
        ),
      );
    } else {
      body = new SubmarineMessage(
        "File deletion completed",
        Icons.done,
        margin: const EdgeInsets.only(top: 30.0),
      );
    }

    return new Column(
      children: <Widget>[new LinearProgressIndicator(value: progress), body],
    );
  }
}

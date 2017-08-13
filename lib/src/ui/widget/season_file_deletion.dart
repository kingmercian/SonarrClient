import 'package:flutter/material.dart';

import '../../model/model.dart';

class SeasonFileDeletion extends StatefulWidget {

  Season _season;

  SeasonFileDeletion(this._season);

  @override
  _SeasonFileDeletionState createState() => new _SeasonFileDeletionState();
}

class _SeasonFileDeletionState extends State<SeasonFileDeletion> {

  List<int> _episodesToDelete = [];
  int _deleted = 0;

  @override
  initState() {
    super.initState();

    for (Episode ep in widget._season.episodes) {
      if (ep.hasFile) {
        _episodesToDelete.add(ep.episodeFileId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new LinearProgressIndicator(value: _episodesToDelete.length / _deleted);
  }
}
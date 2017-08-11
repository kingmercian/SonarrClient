import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/network.dart';
import 'submarine_message.dart';
import 'text_diff.dart';

class RenameFiles extends StatefulWidget {
  int _showId;
  int _seasonNumber;

  RenameFiles(this._showId, {int seasonNumber}) {
    _seasonNumber = (seasonNumber != null) ? seasonNumber : null;
  }

  @override
  _RenameFilesState createState() => new _RenameFilesState();
}

class _RenameFilesState extends State<RenameFiles> {
  bool _loading = true;
  List<Rename> _renamePreview = [];
  Set<int> _filesToRename = new Set();
  bool _diff = true;

  @override
  initState() {
    super.initState();
    _loadRenamingPreview();
  }

  _loadRenamingPreview() async {
    setState(() => _loading = true);

    _renamePreview = await Client
        .getInstance()
        .previewRename(widget._showId, seasonNumber: widget._seasonNumber);

    _addAll();

    setState(() => _loading = false);
  }

  _addAll() {
    for (Rename rename in _renamePreview) {
      _filesToRename.add(rename.fileId);
    }
  }

  _renameFiles() async {
    Client
        .getInstance()
        .rename(_filesToRename.toList(growable: false), widget._showId);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    double textWidth = screenSize.width - 65.0;
    List<Widget> body = [];

    if (_loading) {
      Widget loader = new SliverToBoxAdapter(
          child: new Container(
              height: 110.0,
              width: 110.0,
              child: new Center(child: new CircularProgressIndicator())));

      body.add(loader);
    } else {
      if (_renamePreview.isEmpty) {
        body.add(new SliverToBoxAdapter(
            child: new SubmarineMessage("Nothing to rename", Icons.done,
                margin: const EdgeInsets.only(top: 40.0))));
      } else {
        var onRename = (_filesToRename.isEmpty) ? null : () => _renameFiles();

        Row actions = new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Row(
              children: <Widget>[
                new Switch(
                    value: _diff,
                    onChanged: (selected) {
                      setState(() => _diff = selected);
                    }),
                new Text("Diff"),
              ],
            ),
            new RaisedButton(onPressed: onRename, child: new Text("Rename")),
          ],
        );

        Widget header = new SliverToBoxAdapter(
            child: new Container(
          alignment: FractionalOffset.center,
          margin: const EdgeInsets.all(12.0),
          child: actions,
        ));

        body.add(header);

        body.addAll(_renamePreview.map((Rename rename) {
          Color bgColor = (_renamePreview.indexOf(rename) % 2 == 0)
              ? Colors.black54
              : Colors.black12;

          Container renaming;

          renaming = (_diff)
              ? new Container(
                  width: textWidth,
                  child: new TextDiff(rename.currentPath, rename.newPath))
              : new Container(
                  width: textWidth,
                  child: new Column(
                    children: <Widget>[
                      new Text(
                        rename.currentPath,
                        style: new TextStyle(color: Colors.redAccent),
                      ),
                      new Text(rename.newPath),
                    ],
                  ),
                );

          Row body = new Row(
            children: <Widget>[
              new Checkbox(
                  value: _filesToRename.contains(rename.fileId),
                  onChanged: (selected) {
                    if (selected) {
                      _filesToRename.add(rename.fileId);
                    } else {
                      _filesToRename.remove(rename.fileId);
                    }
                    setState(() {});
                  }),
              renaming,
            ],
          );

          return new SliverToBoxAdapter(
              child: new Container(
                  color: bgColor,
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 12.0, 6.0),
                  child: body));
        }).toList());
      }
    }

    return new Scaffold(
      body: new CustomScrollView(
        slivers: body,
      ),
    );
  }
}

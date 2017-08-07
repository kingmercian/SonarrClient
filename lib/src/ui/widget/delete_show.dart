/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';

class DeleteShowResult {
  bool delete = false;
  bool deleteFiles = false;
}

class DeleteShow extends StatefulWidget {
  Show _show;

  DeleteShow(this._show);

  @override
  State<StatefulWidget> createState() => new _DeleteShowState(_show);
}

class _DeleteShowState extends State<DeleteShow> {
  Show _show;
  bool _deleteFiles = false;

  _DeleteShowState(this._show);

  @override
  Widget build(BuildContext context) {
    Text title = new Text("Deleting '${_show.title}'");

    Row content = new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Text("Delete all files"),
          new Checkbox(
              value: _deleteFiles,
              onChanged: (selected) {
                this.setState(() {
                  _deleteFiles = selected;
                });
              })
        ]);

    DeleteShowResult result = new DeleteShowResult();

    AlertDialog alert =
        new AlertDialog(title: title, content: content, actions: <Widget>[
      new SimpleDialogOption(
        child: new Text("CANCEL"),
        onPressed: () {
          result.delete = false;
          Navigator.pop(context, result);
        },
      ),
      new SimpleDialogOption(
        child: new Text("DELETE"),
        onPressed: () {
          result.delete = true;
          result.deleteFiles = _deleteFiles;
          Navigator.pop(context, result);
        },
      ),
    ]);

    return alert;
  }
}

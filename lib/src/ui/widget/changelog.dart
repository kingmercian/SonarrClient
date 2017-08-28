/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';

class Changelog extends StatelessWidget {
  List<String> _features;
  List<String> _fixes;
  String _version;

  Changelog(this._features, this._fixes, this._version, {Key key})
      : super(key: key);

  Widget _getHeader(String header, Color color) {
    return new SliverToBoxAdapter(
        child: new Container(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 8.0),
            child: new Text(
              header,
              style: new TextStyle(fontSize: 18.0, color: color),
            )));
  }

  List<Widget> _getWidgets(List<String> items) {
    return items.map((String feature) {
      Color bgColor =
          (items.indexOf(feature) % 2 == 0) ? Colors.black54 : Colors.black12;

      return new SliverToBoxAdapter(
          child: new Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(32.0, 12.0, 32.0, 12.0),
              child: new Text(feature)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Widget title = new SliverToBoxAdapter(
        child: new Container(
      alignment: FractionalOffset.center,
      margin: const EdgeInsets.all(12.0),
      child: new Text(
        "Version $_version",
        overflow: TextOverflow.clip,
        softWrap: true,
        style: new TextStyle(fontSize: 18.0),
        textAlign: TextAlign.center,
      ),
    ));

    List<Widget> body = [title];

    if (_features.isNotEmpty) {
      body.add(_getHeader("New", Colors.lightGreen));
      List<Widget> features = _getWidgets(_features);
      body.addAll(features);
    }

    if (_fixes.isNotEmpty) {
      body.add(_getHeader("Fixes", Colors.lightBlue));
      List<Widget> fixes = _getWidgets(_fixes);
      body.addAll(fixes);
    }

    return new Scaffold(
      body: new CustomScrollView(
        slivers: body,
      ),
    );
  }
}

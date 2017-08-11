/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';

class SubmarineMessage extends StatelessWidget {
  final EdgeInsets margin;
  final IconData _iconData;
  final String _message;

  SubmarineMessage(this._message, this._iconData, {Key key, this.margin})
      : assert(margin == null || margin.isNonNegative),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
        margin: margin,
        alignment: FractionalOffset.center,
        child: new Column(
          children: <Widget>[
            new Icon(
              _iconData,
              size: 40.0,
            ),
            new Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: new Text(
                _message,
                textAlign: TextAlign.center,
                style: new TextStyle(fontSize: 16.0),
              ),
            )
          ],
        ));
  }
}

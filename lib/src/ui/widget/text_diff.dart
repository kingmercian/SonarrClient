/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../utils/diff/diff.dart';

class TextDiff extends StatelessWidget {
  String _before;
  String _after;

  TextDiff(this._before, this._after);

  @override
  Widget build(BuildContext context) {
    List<Diff> diffs = DiffUtil.diff(_before, _after);
    TextStyle removed = new TextStyle(color: Colors.redAccent);
    TextStyle added = new TextStyle(color: Colors.greenAccent);

    List<TextSpan> spans = diffs.map((diff) {
      TextStyle style = diff.operation == DiffOperation.EQUAL
          ? null
          : diff.operation == DiffOperation.INSERT ? added : removed;
      return new TextSpan(style: style, text: diff.text);
    }).toList();

    TextSpan span = new TextSpan(children: spans);

    return new RichText(text: span);
  }
}

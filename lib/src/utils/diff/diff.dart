/* Copyright (c) 2017 Miguel Castiblanco */
library Diff;

import 'dart:math';

part 'diff_util.dart';

enum DiffOperation {
  DELETE,
  INSERT,
  EQUAL
}

class Diff {

  DiffOperation operation;
  String text;

  Diff(this.operation, this.text);

  String toString() {
    String prettyText = this.text.replaceAll('\n', '\u00b6');
    return 'Diff(${this.operation},"$prettyText")';
  }
}
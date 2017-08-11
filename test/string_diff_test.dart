/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:test/test.dart';
import 'package:Submarine/src/utils/diff/diff.dart';

void main() {
  test('diff equal strings', () {

    List<Diff> diffs = DiffUtil.diff("hello", "hello");
    expect(diffs.length, 1);

    Diff diff = diffs[0];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "hello");
  });

  test('diff different strings - addition', () {

    List<Diff> diffs = DiffUtil.diff("I need car", "I need an awesome car");
    expect(diffs.length, 3);

    Diff diff = diffs[0];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "I need ");

    diff = diffs[1];
    expect(diff.operation, DiffOperation.INSERT);
    expect(diff.text, "an awesome ");

    diff = diffs[2];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "car");
  });

  test('diff different strings - deletion', () {

    List<Diff> diffs = DiffUtil.diff("I needa a car", "I need a car");
    expect(diffs.length, 3);

    Diff diff = diffs[0];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "I need");

    diff = diffs[1];
    expect(diff.operation, DiffOperation.DELETE);
    expect(diff.text, "a");

    diff = diffs[2];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, " a car");
  });

  test('diff different strings - mixed', () {

    List<Diff> diffs = DiffUtil.diff("mo", "so");
    expect(diffs.length, 3);

    Diff diff = diffs[0];
    expect(diff.operation, DiffOperation.DELETE);
    expect(diff.text, "m");

    diff = diffs[1];
    expect(diff.operation, DiffOperation.INSERT);
    expect(diff.text, "s");

    diff = diffs[2];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "o");
  });

  test('diff different strings - deletion', () {

    List<Diff> diffs = DiffUtil.diff("I need a whole new car soon", "I need a car");
    expect(diffs.length, 4);

    Diff diff = diffs[0];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "I need a ");

    diff = diffs[1];
    expect(diff.operation, DiffOperation.DELETE);
    expect(diff.text, "whole new ");

    diff = diffs[2];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "car");

    diff = diffs[3];
    expect(diff.operation, DiffOperation.DELETE);
    expect(diff.text, " soon");
  });

  test('real case test', () {
    List<Diff> diffs = DiffUtil.diff('Season 19/S19E21 - 1 and 2 – Assemble! The Vinsmoke Family HDTV-720p.mkv',
        'Season 19/S19E21 - The First and the Second Join! The Vinsmoke Family HDTV-720p.mkv');

    expect(diffs.length, 4);

    Diff diff = diffs[0];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "Season 19/S19E21 - ");

    diff = diffs[1];
    expect(diff.operation, DiffOperation.DELETE);
    expect(diff.text, "1 and 2 – Assemble");

    diff = diffs[2];
    expect(diff.operation, DiffOperation.INSERT);
    expect(diff.text, "The First and the Second Join");

    diff = diffs[3];
    expect(diff.operation, DiffOperation.EQUAL);
    expect(diff.text, "! The Vinsmoke Family HDTV-720p.mkv");

  });



}
/* Copyright (c) 2017 Miguel Castiblanco */
part of Diff;

// String diff util. It's a shortened version of
// https://code.google.com/archive/p/google-diff-match-patch/
class DiffUtil {

  // Calculate the diff between two strings, and return the list of Diffs
  static List<Diff> diff(String origin, String destination) {
    // Check for null inputs.
    if (origin == null || destination == null) {
      throw new ArgumentError('Null inputs. (diff_main)');
    }

    // Check for equality (speedup).
    List<Diff> diffs;
    if (origin == destination) {
      diffs = [];
      if (origin.isNotEmpty) {
        diffs.add(new Diff(DiffOperation.EQUAL, origin));
      }
      return diffs;
    }

    // Trim off common prefix (speedup).
    int commonLength = _commonPrefix(origin, destination);
    String commonPrefix = origin.substring(0, commonLength);
    origin = origin.substring(commonLength);
    destination = destination.substring(commonLength);

    // Trim off common suffix (speedup).
    commonLength = _commonSuffix(origin, destination);
    String commonSuffix = origin.substring(origin.length - commonLength);
    origin = origin.substring(0, origin.length - commonLength);
    destination = destination.substring(0, destination.length - commonLength);

    // Compute the diff on the middle block.
    diffs = _computeDiff(origin, destination);
    // Restore the prefix and suffix.
    if (commonPrefix.isNotEmpty) {
      diffs.insert(0, new Diff(DiffOperation.EQUAL, commonPrefix));
    }
    if (commonSuffix.isNotEmpty) {
      diffs.add(new Diff(DiffOperation.EQUAL, commonSuffix));
    }

    return diffs;
  }

  // pretty basic computation of the difference between two strings
  static List<Diff> _computeDiff(String origin, String destination) {
    List<Diff> diffs = <Diff>[];

    if (origin.length == 0) {
      // Just add some text (speedup).
      diffs.add(new Diff(DiffOperation.INSERT, destination));
      return diffs;
    }

    if (destination.length == 0) {
      // Just delete some text (speedup).
      diffs.add(new Diff(DiffOperation.DELETE, origin));
      return diffs;
    }

    String longText = origin.length > destination.length ? origin : destination;
    String shortText =
        origin.length > destination.length ? destination : origin;
    int i = longText.indexOf(shortText);
    if (i != -1) {
      // Shorter text is inside the longer text (speedup).
      DiffOperation op = (origin.length > destination.length)
          ? DiffOperation.DELETE
          : DiffOperation.INSERT;
      diffs.add(new Diff(op, longText.substring(0, i)));
      diffs.add(new Diff(DiffOperation.EQUAL, shortText));
      diffs.add(new Diff(op, longText.substring(i + shortText.length)));
      return diffs;
    }

    if (shortText.length == 1) {
      // Single character string.
      // After the previous speedup, the character can't be an equality.
      diffs.add(new Diff(DiffOperation.DELETE, origin));
      diffs.add(new Diff(DiffOperation.INSERT, destination));
      return diffs;
    }

    return [
      new Diff(DiffOperation.DELETE, origin),
      new Diff(DiffOperation.INSERT, destination)
    ];
  }

  // Calculate the common prefix of two strings
  static int _commonPrefix(String origin, String destination) {
    final n = min(origin.length, destination.length);
    for (int i = 0; i < n; i++) {
      if (origin[i] != destination[i]) {
        return i;
      }
    }
    return n;
  }

  // Calculate the common suffix of two strings
  static int _commonSuffix(String origin, String destination) {
    final originLength = origin.length;
    final destinationLength = destination.length;
    final n = min(originLength, destinationLength);
    for (int i = 1; i <= n; i++) {
      if (origin[originLength - i] != destination[destinationLength - i]) {
        return i - 1;
      }
    }
    return n;
  }
}

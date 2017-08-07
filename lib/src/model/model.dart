/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';

class Show {
  int id;
  String title;
  String sortTitle;
  String network;
  int runtime;
  bool monitored;
  bool seasonFolder;
  String status;
  int seasonCount;
  int year;
  int tvdbId;
  String titleSlug;
  int profileId;
  int qualityProfileId;
  String path;
  List<Season> seasons;
  DateTime previousAiring;
  DateTime nextAiring;
  String overview;
  String sizeOnDisk;
  int requestedEpisodes;
  int downloadedEpisodes;
  int totalEpisodes;
  String posterUrl;
  String bannerUrl;
  String fanartUrl;
  Map raw;
}

class Season {
  int number;
  bool monitored;
  int requestedEpisodes;
  int downloadedEpisodes;
  int totalEpisodes;
  List<Episode> episodes = new List<Episode>();
}

class Episode {
  int id;
  int episodeNumber;
  String overview;
  DateTime airDate;
  bool hasFile;
  bool monitored;
  String title;
  int seasonNumber;
  String downloadedQuality;
  int episodeFileId;
  String showTitle;
}

class EpisodeFile {
  int id;
  String path;
  bool qualityCutoffNotMet;
  int seasonNumber;
  int seriesId;
  int size;
}

class Profile {
  int id;
  String language;
  String name;
}

class RootFolder {
  int id;
  String path;
  String freeSpace;
}

class Status {
  String version;
  OS operativeSystem;
  String osName;
  String osVersion;
  String branch;
  DateTime buildTime;
  String runtimeVersion;
}

class HealthMessage {
  String type;
  String message;
}

class Drive {
  String path;
  String label;
  String freeSpace;
  String totalSpace;
}

class ServerModel {
  bool https;
  String hostname;
  String path = "";
  int port;
  String apiKey;

  ServerModel();

  Map<String, dynamic> toMap() {
    return {
      'https': https,
      'hostname': hostname,
      'path': path,
      'port': port,
      'apiKey': apiKey
    };
  }

  ServerModel.fromMap(Map<String, dynamic> map)
      : https = map["https"],
        hostname = map["hostname"],
        path = map["path"],
        port = map["port"],
        apiKey = map["apiKey"];
}

class Release {
  String guid;
  String quality;
  int ageDays;
  double ageHours;
  double ageMinutes;
  String size;
  String indexer;
  String title;
  bool rejected;
  String rejectionMessage;
  Map raw;
  bool downloadAllowed;
}

class MissingRecord {
  int episodeId;
  String showTitle;
  String episodeTitle;
  int episodeNumber;
  int seasonNumber;
  DateTime airDate;
}

class Page<T> {
  int page;
  int pageSize;
  int totalRecords;
  List<T> records = new List<T>();
}

class HistoryRecord {
  String showTitle;
  String episodeTitle;
  int episodeNumber;
  int seasonNumber;
  DateTime date;
  EventType type;
}

class QueueItem {
  String showTitle;
  String episodeTitle;
  int episodeNumber;
  int seasonNumber;
  String quality;
  String timeLeft;
  String status;
}

class EventType {
  static final values = <EventType>[GRABBED, IMPORTED, FAILED, DELETED];
  static final GRABBED =
      new EventType._("grabbed", "Grabbed", Icons.cloud_download);
  static final IMPORTED = new EventType._(
      "downloadFolderImported", "File Imported", Icons.vertical_align_bottom);
  static final FAILED =
      new EventType._("downloadFailed", "Download Failed", Icons.cloud_off);
  static final DELETED =
      new EventType._("episodeFileDeleted", "File Deleted", Icons.delete);

  final String _type;
  final String _label;
  final IconData _icon;

  EventType._(this._type, this._label, this._icon);

  static EventType getByType(String type) {
    for (EventType eventType in values) {
      if (eventType._type == type) return eventType;
    }

    return null;
  }

  IconData getIcon() => _icon;
  String getLabel() => _label;
}

class ShowType {
  static final values = <ShowType>[STANDARD, ANIME, DAILY];
  static final STANDARD = new ShowType._("Standard", "standard");
  static final ANIME = new ShowType._("Anime", "anime");
  static final DAILY = new ShowType._("Daily", "daily");

  String _label;
  String _value;

  ShowType._(this._label, this._value);

  String getLabel() {
    return _label;
  }

  String getValue() {
    return _value;
  }
}

class MonitorSeasons {
  static final values = <MonitorSeasons>[NONE, ALL, FIRST, LAST];
  static final NONE = new MonitorSeasons._("None");
  static final ALL = new MonitorSeasons._("All");
  static final FIRST = new MonitorSeasons._("First");
  static final LAST = new MonitorSeasons._("Last");

  String _label;

  MonitorSeasons._(this._label);

  getLabel() {
    return _label;
  }
}

class OS {
  static final values = <OS>[LINUX, OSX, WINDOWS];
  static final LINUX = new OS._("Linux");
  static final OSX = new OS._("MacOS");
  static final WINDOWS = new OS._("Windows");

  String _label;

  OS._(this._label);

  getLabel() {
    return _label;
  }
}
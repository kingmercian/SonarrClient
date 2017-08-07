/* Copyright (c) 2017 Miguel Castiblanco */
import '../model/model.dart';
import 'dart:convert';

List<Show> parseShows(String json, {bool searchResult = false}) {
  List<Show> shows = new List();
  JSON.decode(json).forEach((it) => shows.add(parseShowMap(it, searchResult)));
  return shows;
}

Show parseShow(String json) {
  return parseShowMap(JSON.decode(json), false);
}

Show parseShowMap(Map json, bool searchResult) {
  List images = json["images"];

  return new Show()
    ..id = json["id"]
    ..title = json["title"]
    ..monitored = json["monitored"]
    ..sortTitle = json["sortTitle"]
    ..overview = json.containsKey("overview") ? json["overview"] : ""
    ..network = json["network"]
    ..runtime = json["runtime"]
    ..status = json["status"]
    ..seasonCount = json["seasonCount"]
    ..year = json["year"]
    ..tvdbId = json["tvdbId"]
    ..titleSlug = json["titleSlug"]
    ..profileId = json["profileId"]
    ..qualityProfileId = json["qualityProfileId"]
    ..path = json["path"]
    ..seasonFolder =
        json.containsKey("seasonFolder") ? json["seasonFolder"] : false
    ..sizeOnDisk =
        json.containsKey("sizeOnDisk") ? _getSize(json["sizeOnDisk"]) : "0 MB"
    ..previousAiring = _getDate(json["previousAiring"])
    ..nextAiring = _getDate(json["nextAiring"])
    ..seasons = parseSeasons(json["seasons"], searchResult)
    ..bannerUrl = _getImage(images, "banner")
    ..posterUrl = _getImage(images, "poster")
    ..fanartUrl = _getImage(images, "fanart")
    ..raw = json;
}

String _getImage(List images, String type) {
  for (Map image in images) {
    if (image["coverType"] == type) {
      return image["url"];
    }
  }
  return "";
}

DateTime _getDate(String date) {
  if (date != null && date.isNotEmpty) {
    return DateTime.parse(date);
  }
  return null;
}

List<Profile> parseProfiles(String json) {
  List<Profile> profiles = new List();
  JSON.decode(json).forEach((it) => profiles.add(parseProfile(it)));
  return profiles;
}

Profile parseProfile(Map json) {
  return new Profile()
    ..id = json["id"]
    ..language = json["language"]
    ..name = json["name"];
}

List<Episode> parseEpisodes(String json) {
  List<Episode> result = new List();
  JSON.decode(json).forEach((it) => result.add(parseEpisodeMap(it)));
  return result;
}

Episode parseEpisode(String json) {
  return parseEpisodeMap(JSON.decode(json));
}

Episode parseEpisodeMap(Map json) {
  Episode ep = new Episode()
    ..id = json["id"]
    ..episodeNumber = json["episodeNumber"]
    ..overview = json["overview"]
    ..hasFile = json["hasFile"]
    ..monitored = json["monitored"]
    ..title = json["title"]
    ..seasonNumber = json["seasonNumber"]
    ..airDate = json.containsKey("airDateUtc")
        ? DateTime.parse(json["airDateUtc"])
        : null
    ..showTitle = json.containsKey("series") ? json["series"]["title"] : "";

  if (ep.hasFile) {
    ep.downloadedQuality = json["episodeFile"]["quality"]["quality"]["name"];
    ep.episodeFileId = json["episodeFileId"];
  }

  return ep;
}

List<Season> parseSeasons(List seasons, bool searchResult) {
  List<Season> result = new List();

  for (Map season in seasons) {
    result.add(parseSeason(season, searchResult));
  }

  return result;
}

Season parseSeason(Map json, bool searchResult) {
  int requestedEpisodes = (searchResult)
      ? json["episodeCount"]
      : json.containsKey("statistics") ? json["statistics"]["episodeCount"] : 0;
  int downloadedEpisodes = (searchResult)
      ? json["episodeFileCount"]
      : json.containsKey("statistics")
          ? json["statistics"]["episodeFileCount"]
          : 0;
  int totalEpisodes = (searchResult)
      ? json["totalEpisodeCount"]
      : json.containsKey("statistics")
          ? json["statistics"]["totalEpisodeCount"]
          : 0;

  return new Season()
    ..number = json["seasonNumber"]
    ..monitored = json["monitored"]
    ..requestedEpisodes = requestedEpisodes
    ..downloadedEpisodes = downloadedEpisodes
    ..totalEpisodes = totalEpisodes;
}

List<RootFolder> parseRootFolders(String json) {
  List<RootFolder> result = new List();
  JSON.decode(json).forEach((it) => result.add(parseRootFolder(it)));
  return result;
}

RootFolder parseRootFolder(Map map) {
  return new RootFolder()
    ..id = map["id"]
    ..path = map["path"]
    ..freeSpace = _getSize(map["freeSpace"]);
}

Status parseStatus(String json) {
  var map = JSON.decode(json);

  OS os = map["isLinux"] ? OS.LINUX : map["isOsx"] ? OS.OSX : OS.WINDOWS;

  return new Status()
    ..version = map["version"]
    ..operativeSystem = os
    ..osName = map["osName"]
    ..osVersion = map["osVersion"]
    ..branch = map["branch"]
    ..buildTime = DateTime.parse(map["buildTime"])
    ..runtimeVersion = map["runtimeVersion"];
}

List<HealthMessage> parseHealthMessages(String json) {
  List<HealthMessage> result = [];
  JSON.decode(json).forEach((it) => result.add(parseHealthMessage(it)));

  return result;
}

List<Drive> parseDrives(String json) {
  List<Drive> result = [];
  JSON.decode(json).forEach((it) => result.add(parseDrive(it)));

  return result;
}

Drive parseDrive(Map map) {
  return new Drive()
      ..path = map["path"]
      ..label = map["label"]
      ..freeSpace = _getSize(map["freeSpace"])
      ..totalSpace = _getSize(map["totalSpace"]);
}

HealthMessage parseHealthMessage(Map map) {
  return new HealthMessage()
      ..type = map["type"]
      ..message = map["message"];
}

List<Release> parseReleases(String json) {
  List<Release> result = new List();
  JSON.decode(json).forEach((it) => result.add(parseRelease(it)));
  return result;
}

Release parseRelease(Map map) {
  var rejectionMessage =
      (map["rejections"] as List).length > 0 ? map["rejections"][0] : "";

  return new Release()
    ..guid = map["guid"]
    ..quality = map["quality"]["quality"]["name"]
    ..title = map["title"]
    ..ageDays = map["age"]
    ..ageHours = map["ageHours"]
    ..ageMinutes = map["ageMinutes"]
    ..indexer = map["indexer"]
    ..rejected = map["rejected"]
    ..size = _getSize(map["size"])
    ..downloadAllowed = map["downloadAllowed"]
    ..rejectionMessage = rejectionMessage
    ..raw = map;
}

String _getSize(num size) {
  num inGB = size / 1073741824;

  if (inGB >= 1000) {
    num inTB = inGB / 1000;
    return "${inTB.round()} TB";
  }

  if (inGB > 1) {
    return "${inGB.round()} GB";
  }

  num inMB = size / 1048567;

  return "${inMB.round()} MB";
}

Page<MissingRecord> parseMissingPage(String json) {
  Map map = JSON.decode(json);
  Page<MissingRecord> result = new Page()
    ..page = map["page"]
    ..pageSize = map["pageSize"]
    ..totalRecords = map["totalRecords"];

  map["records"].forEach((it) => result.records.add(parseMissingRecord(it)));
  return result;
}

MissingRecord parseMissingRecord(Map map) {
  return new MissingRecord()
    ..episodeId = map["id"]
    ..episodeTitle = map["title"]
    ..showTitle = map["series"]["title"]
    ..seasonNumber = map["seasonNumber"]
    ..episodeNumber = map["episodeNumber"]
    ..airDate = map.containsKey("airDateUtc")
        ? DateTime.parse(map["airDateUtc"])
        : null;
}

Page<HistoryRecord> parseHistoryPage(String json) {
  Map map = JSON.decode(json);
  Page<HistoryRecord> result = new Page()
    ..page = map["page"]
    ..pageSize = map["pageSize"]
    ..totalRecords = map["totalRecords"];

  map["records"].forEach((it) => result.records.add(parseHistoryRecord(it)));
  return result;
}

HistoryRecord parseHistoryRecord(Map map) {
  return new HistoryRecord()
    ..episodeTitle = map["episode"]["title"]
    ..showTitle = map["series"]["title"]
    ..seasonNumber = map["episode"]["seasonNumber"]
    ..episodeNumber = map["episode"]["episodeNumber"]
    ..type = EventType.getByType(map["eventType"])
    ..date = DateTime.parse(map["date"]);
}

List<QueueItem> parseQueueItems(String json) {
  List<QueueItem> result = new List();
  JSON.decode(json).forEach((it) => result.add(parseQueueItem(it)));
  return result;
}

QueueItem parseQueueItem(Map map) {
  return new QueueItem()
    ..episodeTitle = map["episode"]["title"]
    ..showTitle = map["series"]["title"]
    ..seasonNumber = map["episode"]["seasonNumber"]
    ..episodeNumber = map["episode"]["episodeNumber"]
    ..status = map["status"]
    ..quality = map["quality"]["quality"]["name"]
    ..timeLeft = map["timeleft"];
}

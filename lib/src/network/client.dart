/* Copyright (c) 2017 Miguel Castiblanco */
import 'http.dart';
import 'network.dart';
import 'dart:convert';
import '../model/model.dart';
import '../db/dbmanager.dart';

import 'dart:async';

class Client {
  static Client _INSTANCE;
  Map<int, Show> _showsCache = new Map();

  Server _server;
  Sonarr _sonarr;

  Client._(this._server) {
    _sonarr = new Sonarr(_server);
  }

  static Client getInstance() {
    return _INSTANCE;
  }

  static Future prepare() async {
    if (_INSTANCE != null) return _INSTANCE;

    var server = await DBManager.getInstance().getServer();
    _INSTANCE = new Client._(server);
  }

  static Client getTemporaryInstance({Server server}) {
    return new Client._(server);
  }

  Server getServer() {
    return _server;
  }

  // Shows

  Future<List<Show>> getShows() async {
    List<Show> result = await _sonarr.get("series", parseShows);
    result.sort((a, b) {
      return a.sortTitle.compareTo(b.sortTitle);
    });

    _showsCache.clear();

    for (Show show in result) {
      _showsCache[show.id] = show;
    }

    return result;
  }

  Future<Show> getShow(int showId) async {
    return await _sonarr.get("series/$showId", parseShow);
  }

  Future<Null> deleteShow(int showId, bool deleteFiles) async {
    return await _sonarr.delete("series/$showId?deleteFiles=$deleteFiles");
  }

  Future<Null> updateShow(Show show, Profile profile, ShowType type,
      bool monitor, bool seasonFolder) async {
    Map body = show.raw;
    body["profileId"] = profile.id.toString();
    body["qualityProfileId"] = profile.id;
    body["seriesType"] = type.getValue();
    body["monitored"] = monitor;
    body["seasonFolder"] = seasonFolder;

    await _sonarr.put("series/${show.id}", JSON.encode(body));
  }

  Future<Null> addShow(Show show, Profile profile, RootFolder path,
      ShowType type, MonitorSeasons monitor, bool seasonFolder) async {
    Map body = show.raw;
    body["profileId"] = profile.id.toString();
    body["qualityProfileId"] = profile.id;
    body["rootFolderPath"] = path.path;
    body["seriesType"] = type.getValue();
    body["seasonFolder"] = seasonFolder;

    // Monitoring config
    if (MonitorSeasons.FIRST == monitor) {
      for (Map season in body["seasons"]) {
        season["monitored"] = season["seasonNumber"] == 1;
      }
    } else if (MonitorSeasons.NONE == monitor) {
      for (Map season in body["seasons"]) {
        season["monitored"] = false;
      }
    } else if (MonitorSeasons.ALL == monitor) {
      for (Map season in body["seasons"]) {
        season["monitored"] = true;
      }
    } else if (MonitorSeasons.LAST == monitor) {
      int lastSeason = -1;

      for (Map season in body["seasons"]) {
        int seasonNumber = season["seasonNumber"];
        if (seasonNumber > lastSeason) lastSeason = seasonNumber;
      }

      for (Map season in body["seasons"]) {
        season["monitored"] = season["seasonNumber"] == lastSeason;
      }
    }

    await _sonarr.post("series", JSON.encode(body));
  }

  Future<List<Show>> lookup(String term) async {
    return await _sonarr.get("series/lookup?term=$term",
        (String body) => parseShows(body, searchResult: true));
  }

  // Episodes

  Future<List<Episode>> getEpisodes(int showId) async {
    return await _sonarr.get("episode?seriesId=$showId", parseEpisodes);
  }

  Future<Episode> getEpisode(int id) async {
    return await _sonarr.get("episode/$id", parseEpisode);
  }

  Future autoEpisodeSearch(int episodeId) async {
    Map<String, dynamic> bodyMap = new Map();
    bodyMap["name"] = "EpisodeSearch";
    bodyMap["episodeIds"] = <int>[episodeId];

    await _executeCommand(JSON.encode(bodyMap));
  }

  Future<List<Release>> episodeSearch(int episodeId) async {
    return await _sonarr.get(
        "release?episodeId=$episodeId&sort_by=releaseWeight&order=asc",
        parseReleases);
  }

  Future searchAllMonitored(int showId) async {
    Map<String, dynamic> bodyMap = new Map();
    bodyMap["name"] = "seriesSearch";
    bodyMap["seriesId"] = showId;

    await _executeCommand(JSON.encode(bodyMap));
  }

  Future downloadEpisode(Release release) async {
    return await _sonarr.post("release", JSON.encode(release.raw));
  }

  Future monitorEpisode(int id, bool monitor) async {
    Completer<Map<String, dynamic>> completer = new Completer();

    await _sonarr.get("episode/$id", (json) {
      completer.complete(JSON.decode(json));
    });

    var episode = await completer.future;
    episode["monitored"] = monitor;

    return await _sonarr.put("episode/$id", JSON.encode(episode));
  }

  Future<Null> deleteDownloadedEpisode(int episodeFileId) async {
    await _sonarr.delete("episodeFile/$episodeFileId");
  }

  Future<List<Episode>> getCalendar(
      DateTime start, DateTime end, bool unmonitored) async {
    return await _sonarr.get(
        "calendar?start=$start&end=$end&unmonitored=$unmonitored",
        parseEpisodes);
  }

  Future<List<Episode>> getTodayCalendar(bool unmonitored) async {
    return await _sonarr.get(
        "calendar?unmonitored=$unmonitored", parseEpisodes);
  }

  // Others

  Future<List<QueueItem>> getQueue() async {
    return await _sonarr.get(
        "queue?sort_by=timeleft&order=asc", parseQueueItems);
  }

  Future<List<Profile>> getProfiles() async {
    return await _sonarr.get("profile", parseProfiles);
  }

  Future<List<RootFolder>> getRootFolders() async {
    return await _sonarr.get("rootfolder", parseRootFolders);
  }

  Future<Status> getStatus() async {
    return await _sonarr.get("system/status", parseStatus);
  }

  Future<List<Drive>> getDrives() async {
    return await _sonarr.get("diskspace", parseDrives);
  }

  Future<List<HealthMessage>> getHealth() async {
    return await _sonarr.get("health", parseHealthMessages);
  }

  Future<List<Rename>> previewRename(int showId, {int seasonNumber}) async {
    String path = "rename?seriesId=$showId";

    path = seasonNumber != null ? "$path&seasonNumber=$seasonNumber" : path;

    return await _sonarr.get(path, parseRenamingPreviews);
  }

  Future rename(List<int> files, int showId) async {
    Map<String, dynamic> bodyMap = new Map();
    bodyMap["name"] = "renameFiles";
    bodyMap["seriesId"] = showId;
    bodyMap["seasonNumber"] = -1;
    bodyMap["files"] = files;

    _executeCommand(JSON.encode(bodyMap));
  }

  Future<Page<MissingRecord>> getMissing(int page, int pageSize) async {
    return await _sonarr.get(
        "wanted/missing?page=$page&pageSize=$pageSize"
        "&sortKey=airDateUtc&sortDir=desc&filterKey=monitored"
        "&filterValue=true",
        parseMissingPage);
  }

  Future<Page<HistoryRecord>> getHistory(int page, int pageSize) async {
    return await _sonarr.get(
        "history?page=$page&pageSize=$pageSize"
        "&sortKey=date&sortDir=desc",
        parseHistoryPage);
  }

  Future<Page<BlacklistedRelease>> getBlacklist(int page, int pageSize) async {
    if (_showsCache.isEmpty) {
      await getShows();
    }

    String blacklist =
        await _sonarr.getBody("blacklist?page=$page&pageSize=$pageSize"
            "&sortKey=date&sortDir=desc");

    return parseBlacklistPage(blacklist, _showsCache);
  }

  Future monitorSeason(int showId, int seasonNumber, bool monitor) async {
    Completer<Map<String, dynamic>> completer = new Completer();

    await _sonarr.get("series/$showId", (json) {
      completer.complete(JSON.decode(json));
    });

    var show = await completer.future;
    s:
    for (Map season in show["seasons"]) {
      if (season["seasonNumber"] == seasonNumber) {
        season["monitored"] = monitor;
        break s;
      }
    }

    return await _sonarr.put("series/$showId", JSON.encode(show));
  }

  // Internal

  Future _executeCommand(String body) async {
    return await _sonarr.post("/command", body);
  }
}

class InvalidApiKeyException implements Exception {
  String toString() {
    return "Invalid API Key";
  }
}

class CantConnectException implements Exception {
  String toString() {
    return "Can't connect to the server";
  }
}

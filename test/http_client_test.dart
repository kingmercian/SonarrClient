/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:test/test.dart';
import 'package:Submarine/src/network/network.dart';
import 'package:Submarine/src/db/dbmanager.dart';
import 'package:Submarine/src/model/model.dart';
import 'package:mockito/mockito.dart';
import 'package:mock_web_server/mock_web_server.dart';
import 'dart:io';

class MockDBManager extends Mock implements DBManager {}

enum ServerType { NON_EXISTING, MOCK }

var dbManager = new MockDBManager();

MockWebServer _server;

main() async {

  setUp(() async {
    _server = new MockWebServer();
    await _server.start();
    await _setServer(ServerType.MOCK);
  });

  tearDown(() {
    _server.shutdown();
  });

  test("Test - Can't connect to the server", () async {
    await _setServer(ServerType.NON_EXISTING);
    expect(Client.getInstance().getStatus(),
        throwsA(new isInstanceOf<CantConnectException>()));
  });

  test("Test - Invalid API", () async {
    _server.enqueue(httpCode: 401);
    expect(Client.getInstance().getStatus(),
        throwsA(new isInstanceOf<InvalidApiKeyException>()));
  });

  test("Test - get Status", () async {
    _server.enqueue(body: _readFile("responses/get_status.json"));
    var status = await Client.getInstance().getStatus();
    // Validate Response
    expect(status.version, "2.0.0.4928");
    expect(status.operativeSystem, OS.LINUX);

    // Validate Request
    var request = _server.takeRequest();
    expect(request.headers.value("X-Api-Key"), "mockedApiKey");
    expect(request.uri.path, "/api/system/status");
    expect(request.method, "GET");
  });

  test('Test - get Shows', () async {
    _server.enqueue(body: _readFile("responses/get_shows.json"));
    List<Show> shows = await Client.getInstance().getShows();
    expect(shows.length, 47);

    // Check that the shows are ordered
    expect(shows[0].id, 134);
    expect(shows[0].title, "Adventure Time");
    expect(shows[46].id, 66);
    expect(shows[46].title, "The X-Files");

    var request = _server.takeRequest();
    expect(request.uri.path, "/api/series");
    expect(request.method, "GET");
  });

  test('Test - get Single Show', () async {
    _server.enqueue(body: _readFile("responses/get_show.json"));
    var show = await Client.getInstance().getShow(134);

    // Validate Response
    expect(show.id, 134);
    expect(show.sizeOnDisk, "993 MB");
    expect(show.seasonCount, 9);
    expect(show.seasons.length, 10);
    expect(show.status, "continuing");
    expect(show.monitored, true);

    expect(_server.requestCount, 1);
  });

  test('Test - get Episodes', () async {
    _server.enqueue(body: _readFile("responses/get_episodes.json"));
    var episodes = await Client.getInstance().getEpisodes(134);

    // Validate Response
    expect(episodes.length, 280);

    var episode = episodes.firstWhere((ep) {
      return ep.id == 15289;
    });

    expect(episode, isNotNull);
    expect(episode.hasFile, false);
    expect(episode.monitored, false);
    expect(episode.title, "All's Well That Rats Swell");
    expect(episode.episodeNumber, 4);
    expect(episode.seasonNumber, 0);

    // Validate Request
    var request = _server.takeRequest();

    expect(request.uri.queryParameters.length, 1);
    expect(request.uri.queryParameters["seriesId"], "134");

  });

  test('Test - get Profiles', () async {
    _server.enqueue(body: _readFile("responses/get_profiles.json"));
    var profiles = await Client.getInstance().getProfiles();

    // Validate Response
    expect(profiles.length, 8);

    for (Profile profile in profiles) {
      expect(profile.id, greaterThan(0));
      expect(profile.language, isNotEmpty);
      expect(profile.name, isNotEmpty);
    }

  });

  test('Test - get Rootfolders', () async {
    _server.enqueue(body: _readFile("responses/get_rootfolder.json"));
    var rootFolders = await Client.getInstance().getRootFolders();

    // Validate Response
    expect(rootFolders.length, 1);

    expect(rootFolders[0].id, 1);
    expect(rootFolders[0].freeSpace, "281 GB");
    expect(rootFolders[0].path, "/media/USBHDD1/Shows/");
  });

  test('Test - get Health', () async {
    _server.enqueue(body: _readFile("responses/get_health.json"));
    var health = await Client.getInstance().getHealth();

    // Validate Response
    expect(health.length, 1);

    expect(health[0].type, "warning");
    expect(health[0].message, "Indexers unavailable due to failures: 6box, NZBCat");
  });

  test('Test - get Disk Space', () async {
    _server.enqueue(body: _readFile("responses/get_diskspace.json"));
    var drives = await Client.getInstance().getDrives();

    // Validate Response
    expect(drives.length, 3);

    var drive = drives.firstWhere((drive) {
      return drive.path == "/media/USBHDD1";
    });

    expect(drive, isNotNull);
    expect(drive.freeSpace, "281 GB");
    expect(drive.totalSpace, "2 TB");
    expect(drive.label, "UUID=c137fb3d-dc88-4482-9156-9fc6c017b029");

  });
}

_setServer(ServerType type) async {
  Server server;
  switch (type) {
    case ServerType.NON_EXISTING:
      server = new Server()
        ..https = false
        ..hostname = "test.starcarr.co"
        ..port = 8989
        ..apiKey = "demo";
      break;
    case ServerType.MOCK:
      server = new Server()
        ..https = false
        ..hostname = _server.host
        ..port = _server.port
        ..apiKey = "mockedApiKey";
      break;
  }

  when(dbManager.getServer()).thenReturn(server);
  await Client.prepare(dbManager: dbManager, forceReload: true);
}

String _readFile(String fileName) {
  String baseDir = Directory.current.path.endsWith('/test')
      ? Directory.current.path + '/'
      : Directory.current.path + '/test/';

  File script = new File(baseDir + fileName);
  return script.readAsStringSync();
}

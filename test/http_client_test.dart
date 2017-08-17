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
    expect(shows.length, greaterThan(0));

    var request = _server.takeRequest();
    expect(request.uri.path, "/api/series");
    expect(request.method, "GET");
  });

  test('Test - get Episodes', () {});

  test('Test - get Profiles', () {});

  test('Test - get Health', () {});

  test('Test - ', () {});
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

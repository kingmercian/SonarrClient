/* Copyright (c) 2017 Miguel Castiblanco */
import "package:path/path.dart";
import 'dart:io';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import '../network/server.dart';
import '../model/model.dart';

class DBManager {
  static final DBManager _INSTANCE = new DBManager._private();
  static Database _db;
  static Store _serverStore;

  static final _DB_NAME = "submarine.db";
  static final _SERVER_STORE = "server";

  DBManager._private() {}

  static DBManager getInstance() {
    return _INSTANCE;
  }

  static Future<bool> prepare() async {
    if (_db != null) return true;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    print("dbdir $documentsDirectory");

    String path = join(documentsDirectory.path, _DB_NAME);
    DatabaseFactory dbFactory = ioDatabaseFactory;
    _db = await dbFactory.openDatabase(path);
    _serverStore = _db.getStore(_SERVER_STORE);
    return true;
  }

  addServer(Server server) async {
    var modelServer = new ServerModel()
      ..https = server.https
      ..hostname = server.hostname
      ..port = server.port
      ..path = server.path
      ..apiKey = server.apiKey;

    Record record = new Record(
        _serverStore, {"hasServer": true, "server": modelServer.toMap()});
    await _db.putRecord(record);
  }

  Future<Server> getServer() async {
    var jsonServer = (await _db.findStoreRecords(_serverStore, new Finder()))
        .first["server"];

    var serverModel = new ServerModel.fromMap(jsonServer);

    return new Server()
      ..https = serverModel.https
      ..hostname = serverModel.hostname
      ..port = serverModel.port
      ..path = serverModel.path
      ..apiKey = serverModel.apiKey;
  }

  Future<bool> hasServer() async {
    var records = await _db.findStoreRecords(_serverStore, new Finder());

    if (records.isEmpty) return false;
    var hasServer = records.first;
    return hasServer != null &&
        hasServer["hasServer"] != null &&
        hasServer["hasServer"];
  }
}

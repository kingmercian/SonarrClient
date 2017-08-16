/* Copyright (c) 2017 Miguel Castiblanco */
import 'longpoll.dart';
import 'network.dart';
import 'dart:async';
import '../db/dbmanager.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';

abstract class SonarrNotificationListener {
  void onMessage(String action, Map<String, dynamic> message);
}

class MessageType {
  static final values = <MessageType>[
    SERIES,
    EPISODE,
    EPISODE_FILE,
    COMMAND,
    SYSTEM,
    QUEUE,
    CALENDAR,
    WANTED_CUTOFF,
    WANTED_MISSING,
    HEALTH];

  static final SERIES = new MessageType._("series");
  static final EPISODE = new MessageType._("episode");
  static final EPISODE_FILE = new MessageType._("episodefile");
  static final COMMAND = new MessageType._("command");
  static final SYSTEM = new MessageType._("system/task");
  static final QUEUE = new MessageType._("queue");
  static final CALENDAR = new MessageType._("calendar");
  static final WANTED_CUTOFF = new MessageType._("wanted/cutoff");
  static final WANTED_MISSING = new MessageType._("wanted/missing");
  static final HEALTH = new MessageType._("health");

  String _name;

  MessageType._(this._name);

  String getName() {
    return _name;
  }
}

class Notifications extends WidgetsBindingObserver{

  static final String UPDATED = "updated";
  static final String DELETED = "deleted";

  static Notifications _INSTANCE;

  Server _server;
  Longpoll _longpoll;
  int _listenersCount = 0;

  Map<String, List<SonarrNotificationListener>> _listeners = {
    MessageType.SERIES.getName(): [],
    MessageType.EPISODE.getName(): [],
    MessageType.EPISODE_FILE.getName(): [],
    MessageType.COMMAND.getName(): [],
    MessageType.SYSTEM.getName(): [],
    MessageType.QUEUE.getName(): [],
    MessageType.CALENDAR.getName(): [],
    MessageType.WANTED_CUTOFF.getName(): [],
    MessageType.WANTED_MISSING.getName(): [],
    MessageType.HEALTH.getName(): []
  };

  Notifications._(this._server) {
    _longpoll = new Longpoll(_server);
    WidgetsBinding.instance.addObserver(this);
  }

  static Future prepare({forceReload: false}) async {
    if (_INSTANCE != null && !forceReload) return _INSTANCE;

    var server = await DBManager.getInstance().getServer();
    _INSTANCE = new Notifications._(server);
  }

  static Notifications getInstance() {
    return _INSTANCE;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (AppLifecycleState.paused == state) {
      _stopLongpoll(force: true);
    } else if (AppLifecycleState.resumed == state) {
      _startLongpoll();
    }
  }

  void onMessage(String body) {
    if (body.isNotEmpty) {
      try {
        List<Map<String, dynamic>> messages = JSON.decode(body)["M"];

        for (Map<String, dynamic> message in messages) {
          String type = message["name"];
          String action = message["body"]["action"];
          print("informing $type of $action");
          for(SonarrNotificationListener listener in _listeners[type]) {
            listener.onMessage(action, message);
          }
        }
      } catch (ex, stack){
        print("Error when processing the longpoll $ex $stack");
      }
    }

  }

  void addListener(MessageType messageType, SonarrNotificationListener listener) {
    _listeners[messageType.getName()].add(listener);
    _listenersCount++;
    _startLongpoll();
  }

  void removeListener(MessageType messageType, SonarrNotificationListener listener) {
    _listeners[messageType.getName()].remove(listener);
    _listenersCount--;
    _stopLongpoll();
  }

  void _startLongpoll() {
    if (_listenersCount > 0 && !_longpoll.isPolling()) {
      _longpoll.longpoll((message) => onMessage(message));
    }
  }

  void _stopLongpoll({bool force: false}) {
    if ((force || _listenersCount == 0) && _longpoll.isPolling()) {
      _longpoll.stop();
    }
  }
}

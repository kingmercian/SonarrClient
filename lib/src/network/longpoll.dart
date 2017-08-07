/* Copyright (c) 2017 Miguel Castiblanco */
import 'dart:async';
import 'network.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'response.dart';

typedef void OnResponse(String body);

class Longpoll {
  Server _server;
  HttpClient _httpClient = new HttpClient();
  bool _longpoll = false;
  int _id = 0;

  Longpoll(this._server) {
    _httpClient.badCertificateCallback = (_, __, ___) => true;
  }

  Future<SubmarineResponse> _get(String path) async {
    StringBuffer body = new StringBuffer();
    String url = "${_server.getUrl()}/$path";
    HttpClientRequest request = await _httpClient.getUrl(Uri.parse(url));
    request.headers.add("X-Api-Key", _server.apiKey);

    HttpClientResponse response = await request.close();
    print("LONGPOLL GET ${response.statusCode}");
    Completer<String> completer = new Completer();

    response.transform(UTF8.decoder).listen((data) {
      body.write(data);
    }, onDone: () {
      completer.complete(body.toString());
    });

    return new SubmarineResponse()
      ..statusCode = response.statusCode
      ..body = await completer.future;
  }

  Future<Null> longpoll(OnResponse handler) async {
    _longpoll = true;
    _id = new Random().nextInt(9999999);

    SubmarineResponse response =
        await _get("signalr/negotiate?_=$_id&apiKey=${_server.apiKey}");
    String token =
        _percentEncode(JSON.decode((response.body))["ConnectionToken"]);
    while (_longpoll) {
      int id = new Random().nextInt(9);
      SubmarineResponse response =
          await _get("signalr/connect?transport=longPolling"
              "&connectionToken=$token&tid=$id&_=$_id&apiKey=${_server.apiKey}");

      handler(response.body);
    }
  }

  String _percentEncode(String input) {
    // Do initial percentage encoding of using Uri.encodeComponent()
    input = Uri.encodeComponent(input);

    // Percentage encode characters ignored by Uri.encodeComponent()
    input = input.replaceAll('-', '%2D');
    input = input.replaceAll('_', '%5F');
    input = input.replaceAll('.', '%2E');
    input = input.replaceAll('!', '%21');
    input = input.replaceAll('~', '%7E');
    input = input.replaceAll('*', '%2A');
    input = input.replaceAll('\'', '%5C');
    input = input.replaceAll('(', '%28');
    input = input.replaceAll(')', '%29');

    return input;
  }

  void stop() => _longpoll = false;

  bool isPolling() => _longpoll;
}

/* Copyright (c) 2017 Miguel Castiblanco */
import 'dart:async';

import 'dart:io';
import 'network.dart';
import 'response.dart';
import 'dart:convert';

class Sonarr {
  Server _server;
  HttpClient _httpClient = new HttpClient();

  Sonarr(this._server) {
    _httpClient.badCertificateCallback = (_, __, ___) => true;
  }

  _addHeader(HttpClientRequest request) {
    request.headers.add("X-Api-Key", _server.apiKey);
  }

  _addContentType(HttpClientRequest request) {
    request.headers.contentType =
    new ContentType("application", "json", charset: "utf-8");
  }

  // Internal

  Future<SubmarineResponse> _get(String path) async {
    String url = _server.getApiUrl(path);
    HttpClientRequest request = await _httpClient.getUrl(Uri.parse(url));
    _addHeader(request);

    return _read(await request.close());
  }

  Future<SubmarineResponse> _post(String path, String body) async {
    HttpClientRequest request =
        await _httpClient.postUrl(Uri.parse(_server.getApiUrl(path)));
    _addHeader(request);
    _addContentType(request);
    request.write(body);

    return _read(await request.close());
  }

  Future<SubmarineResponse> _put(String path, String body) async {
    HttpClientRequest request =
        await _httpClient.putUrl(Uri.parse(_server.getApiUrl(path)));
    _addHeader(request);
    _addContentType(request);
    request.write(body);

    return _read(await request.close());
  }

  Future<SubmarineResponse> _delete(String path) async {
    HttpClientRequest request =
        await _httpClient.deleteUrl(Uri.parse(_server.getApiUrl(path)));
    _addHeader(request);

    return _read(await request.close());
  }

  Future<SubmarineResponse> _read(HttpClientResponse response) async {
    StringBuffer body = new StringBuffer();
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

  // Public

  Future post(String path, String body, {parse(String json)}) async {
    var response = await _post(path, body);
    print("POST $path [${response.statusCode}]");

    if (response.statusCode == 401) {
      throw new InvalidApiKeyException();
    }

    if (parse != null) return parse(response.body);

    return null;
  }

  Future put(String path, String body) async {
    var response = await _put(path, body);
    print("PUT $path [${response.statusCode}]");

    if (response.statusCode == 401) {
      throw new InvalidApiKeyException();
    }
  }

  Future get(String path, parse(String json)) async {
    try {
      var response = await _get(path);
      print("GET $path [${response.statusCode}]");

      if (response.statusCode == 401) {
        throw new InvalidApiKeyException();
      }

      return parse(response.body);
    } on SocketException catch (_) {
      throw new CantConnectException();
    }
  }

  Future delete(String path) async {
    try {
      var response = await _delete(path);
      print("DELETE $path");

      if (response.statusCode == 401) {
        throw new InvalidApiKeyException();
      }

      return;
    } on SocketException catch (_) {
      throw new CantConnectException();
    }
  }
}

/* Copyright (c) 2017 Miguel Castiblanco */
class Server {
  bool https;
  bool selfSignedCerts;
  String hostname;
  String path = "";
  int port;
  String apiKey;

  String getUrl() {
    String protocol = https ? "https://" : "http://";
    String _path = path.isEmpty ? "" : "/${path}";
    return "$protocol${hostname}:${port}$_path";
  }

  String getApiQueryParam() {
    return "&apikey=$apiKey";
  }

  String getApiUrl(String endpoint) {
    return "${getUrl()}/api/$endpoint";
  }
}

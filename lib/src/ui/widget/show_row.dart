/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';

import '../../model/model.dart';
import '../../network/network.dart';

typedef void OnShowSelected(BuildContext context, Show show);

class ShowRow extends StatelessWidget {
  bool _isLocal;
  Show _show;
  OnShowSelected _listener;

  ShowRow(this._show, this._listener, {bool isLocal = true}) {
    _isLocal = isLocal;
  }

  @override
  Widget build(BuildContext context) {
    return new InkWell(
        onTap: () => this._listener(context, _show),
        child: new Card(
            child: new Container(
                child: new Column(children: <Widget>[
          new Image.network(_getImageUrl(_show), fit: BoxFit.cover),
          new Container(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: new Text(_show.title,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.title,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis))
        ]))));
  }

  String _getImageUrl(Show show) {
    if (!_isLocal) {
      return show.bannerUrl;
    }
    Server server = Client.getInstance().getServer();
    return "${server.getApiUrl("")}${_show.bannerUrl}${server.getApiQueryParam()}";
  }
}

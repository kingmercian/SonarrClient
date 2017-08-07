/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/client.dart';

class SearchEpisodeResponse {
  bool downloadRequested;
  int episodeId;
}

class SearchEpisode extends StatefulWidget {
  String _episodeTitle;
  int _episodeId;

  SearchEpisode(this._episodeId, this._episodeTitle, {Key key})
      : super(key: key);

  @override
  _SearchEpisodeState createState() =>
      new _SearchEpisodeState(_episodeId, _episodeTitle);
}

class _SearchEpisodeState extends State<SearchEpisode> {
  bool _loading = true;
  String _episodeTitle;
  int _episodeId;
  List<Release> _releases;
  List<String> _releasesBeingDownloaded = [];

  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  _SearchEpisodeState(this._episodeId, this._episodeTitle) {
    _search();
  }

  _search() async {
    _releases = await Client.getInstance().episodeSearch(_episodeId);

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  _download(Release release) async {
    setState(() => _releasesBeingDownloaded.add(release.guid));

    await Client.getInstance().downloadEpisode(release);

    if (mounted) {
      setState(() => _releasesBeingDownloaded.remove(release.guid));
    }

    Navigator.pop(
        context,
        new SearchEpisodeResponse()
          ..episodeId = _episodeId
          ..downloadRequested = true);
  }

  @override
  Widget build(BuildContext context) {
    Widget title = new SliverToBoxAdapter(
        child: new Container(
      alignment: FractionalOffset.center,
      margin: const EdgeInsets.all(12.0),
      child: new Text(
        "Searching '${_episodeTitle}'",
        overflow: TextOverflow.clip,
        softWrap: true,
        style: new TextStyle(fontSize: 18.0),
        textAlign: TextAlign.center,
      ),
    ));

    List<Widget> body = [title];

    if (_loading) {
      Widget loader = new SliverToBoxAdapter(
          child: new Container(
              height: 110.0,
              width: 110.0,
              child: new Center(child: new CircularProgressIndicator())));

      body.add(loader);
    } else {
      List<Widget> releases = _releases.map((Release release) {
        Color bgColor = (_releases.indexOf(release) % 2 == 0)
            ? Colors.black54
            : Colors.black12;

        String age = "${release.ageDays} days";

        if (release.ageDays == 0) {
          age = (release.ageMinutes < 60.0)
              ? "${release.ageMinutes.floor()} minutes"
              : "${release.ageHours.floor()} hours";
        }

        Text relInfo = new Text(
          "$age - ${release.indexer}",
          overflow: TextOverflow.clip,
          softWrap: true,
          style: new TextStyle(fontSize: 12.0, color: Colors.grey),
        );

        Text title = new Text(
          "${release.title}",
          overflow: TextOverflow.clip,
          softWrap: true,
          style: new TextStyle(fontSize: 14.0),
        );

        Chip quality = new Chip(
            label: new Text(
          release.quality,
          style: new TextStyle(fontSize: 11.0),
        ));

        Chip size = new Chip(
            label: new Text(
          release.size,
          style: new TextStyle(fontSize: 11.0),
        ));

        Widget downloadOrLoading;

        if (_releasesBeingDownloaded.contains(release.guid)) {
          downloadOrLoading = new Container(
              height: 24.0,
              width: 24.0,
              margin:
                  const EdgeInsets.only(top: 13.0, bottom: 13.0, right: 14.0),
              child: new Center(child: new CircularProgressIndicator()));
        } else {
          var action =
              release.downloadAllowed ? () => _download(release) : null;

          downloadOrLoading = new IconButton(
              icon: new Icon(Icons.get_app),
              tooltip: "Download this release",
              onPressed: action);
        }

        Widget rejectionMessage = release.rejected
            ? new Text(
                release.rejectionMessage,
                style: new TextStyle(fontSize: 11.0, color: Colors.redAccent),
              )
            : new Container();

        Row downloadRow = new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[quality, size, downloadOrLoading],
        );

        Column body = new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[relInfo, title, rejectionMessage, downloadRow],
        );

        return new SliverToBoxAdapter(
            child: new Container(
                color: bgColor,
                padding: const EdgeInsets.fromLTRB(28.0, 12.0, 28.0, 6.0),
                child: body));
      }).toList();

      body.addAll(releases);
    }

    return new Scaffold(
      key: _scaffoldKey,
      body: new CustomScrollView(
        slivers: body,
      ),
    );
  }
}

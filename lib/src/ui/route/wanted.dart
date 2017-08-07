/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../utils/utils.dart';
import '../../network/network.dart';
import '../widget/episode_search.dart';

class Wanted extends StatefulWidget {
  @override
  _WantedState createState() => new _WantedState();
}

class _WantedState extends State<Wanted> {
  static final GlobalKey<ScaffoldState> _globalKey =
      new GlobalKey<ScaffoldState>();

  bool _loading = true;
  List<MissingRecord> _missingRecords = new List<MissingRecord>();

  DateTime _tomorrow;
  DateTime _today;
  bool _requesting = false;
  int _currentPage;
  int _totalRecords;

  _WantedState() {
    _today = getTodayLocal();
    _tomorrow = getTomorrowLocal();

    Client.prepare().then((_) => _getWanted());
  }

  _getWanted({int pageNumber: 1}) async {
    if (pageNumber == 1) {
      setState(() {
        _loading = true;
        _missingRecords.clear();
      });
    }

    if (_totalRecords == null || _totalRecords > _missingRecords.length) {
      await _getSynced(pageNumber);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  _getSynced(int pageNumber) async {
    if (!_requesting) {
      _requesting = true;
      var missingPage = await Client.getInstance().getMissing(pageNumber, 15);
      _missingRecords.addAll(missingPage.records);
      _totalRecords = missingPage.totalRecords;
      _requesting = false;
      _currentPage = pageNumber;
    }
  }

  _autoSearch(int id) async {
    await Client.getInstance().autoEpisodeSearch(id);

    _showSnackBar("Download request sent");
  }

  _manualSearch(int id, String title) async {
    var response = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new SearchEpisode(id, title);
        });

    if (response != null && response is SearchEpisodeResponse) {
      _showSnackBar("Download request sent");
    }
  }

  _showSnackBar(String message) {
    _globalKey.currentState.showSnackBar(new SnackBar(
        duration: new Duration(seconds: 3),
        backgroundColor: Colors.blue,
        content: new Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    SliverAppBar appBar = new SliverAppBar(
      title: new Text("Missing"),
    );

    List<Widget> slivers = [appBar];

    if (_loading) {
      slivers.add(new SliverToBoxAdapter(
          child: new Container(
        height: 110.0,
        child: new Center(child: new CircularProgressIndicator()),
      )));
    } else {
      slivers.add(new SliverList(
          delegate: new SliverChildBuilderDelegate((context, index) {
        if (index == _missingRecords.length) return null;
        if (index == _missingRecords.length - 5)
          _getWanted(pageNumber: _currentPage + 1);

        if (index == _missingRecords.length) {
          return new Container(
            height: 50.0,
            width: 50.0,
            child: new Center(child: new CircularProgressIndicator()),
          );
        }

        Color bgColor = (index % 2 == 0) ? Colors.black54 : Colors.black12;

        MissingRecord record = _missingRecords[index];

        Text airDateText;
        bool hasAirDate = record.airDate != null;

        if (hasAirDate) {
          String airDateLabel = "";
          DateTime airDate = record.airDate.toLocal();

          if (isSameDay(airDate, _today)) {
            airDateLabel = "Today ${airDate.hour}:${twoDigits(airDate.minute)}";
          } else if (isSameDay(airDate, _tomorrow)) {
            airDateLabel =
                "Tomorrow ${airDate.hour}:${twoDigits(airDate.minute)}";
          } else {
            airDateLabel =
                airDate.toString().substring(0, airDate.toString().length - 7);
          }

          airDateText = new Text(
            airDateLabel,
            style: new TextStyle(fontSize: 12.0, color: Colors.grey),
          );
        }

        Text show = new Text(
          record.showTitle,
          style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        );

        Text title =
            new Text("${sxxepxx(record.seasonNumber, record.episodeNumber)} "
                "- ${record.episodeTitle}");

        List<Widget> actionButtons = [];

        actionButtons.add(new IconButton(
            icon: const Icon(
              Icons.get_app,
              color: Colors.white,
            ),
            padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
            tooltip: "Automatic search",
            onPressed: () => _autoSearch(record.episodeId)));
        actionButtons.add(new IconButton(
          icon: const Icon(Icons.face, color: Colors.white),
          padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
          tooltip: "Manual search",
          onPressed: () => _manualSearch(record.episodeId, record.episodeTitle),
        ));

        Widget actions = new Row(
            mainAxisAlignment: MainAxisAlignment.end, children: actionButtons);

        List<Widget> body = [];

        if (hasAirDate) {
          body.add(airDateText);
        }

        body.addAll([show, title, actions]);

        double marginTop = index == 0 ? 12.0 : 0.0;

        return new Container(
            color: bgColor,
            margin: new EdgeInsets.fromLTRB(16.0, marginTop, 12.0, 0.0),
            padding: const EdgeInsets.fromLTRB(28.0, 12.0, 28.0, 2.0),
            alignment: FractionalOffset.centerLeft,
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: body,
            ));
      })));
    }

    return new RefreshIndicator(
        key: _globalKey,
        onRefresh: () async {
          await _getWanted();
        },
        child: new CustomScrollView(slivers: slivers));
  }
}

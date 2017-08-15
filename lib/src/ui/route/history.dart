/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../utils/utils.dart';
import '../../network/network.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => new _HistoryState();
}

class _HistoryState extends State<History> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  bool _loading = true;
  List<HistoryRecord> _historyRecords = new List<HistoryRecord>();

  DateTime _tomorrow;
  DateTime _today;
  bool _requesting = false;
  int _currentPage;
  int _totalRecords;

  _HistoryState() {
    _today = getTodayLocal();
    _tomorrow = getTomorrowLocal();

    Client.prepare().then((_) => _getWanted());
  }

  _getWanted({int pageNumber: 1}) async {
    if (pageNumber == 1) {
      setState(() {
        _loading = true;
        _historyRecords.clear();
      });
    }

    if (_totalRecords == null || _totalRecords > _historyRecords.length) {
      await _getSynced(pageNumber);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  _getSynced(int pageNumber) async {
    if (!_requesting) {
      _requesting = true;
      var historyPage = await Client.getInstance().getHistory(pageNumber, 15);
      _historyRecords.addAll(historyPage.records);
      _totalRecords = historyPage.totalRecords;
      _requesting = false;
      _currentPage = pageNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    double textWidth = screenSize.width - 140.0;

    List<Widget> slivers = [];

    if (_loading) {
      slivers.add(new SliverToBoxAdapter(
          child: new Container(
        height: 110.0,
        child: new Center(child: new CircularProgressIndicator()),
      )));
    } else {
      slivers.add(new SliverList(
          delegate: new SliverChildBuilderDelegate((context, index) {
        if (index > _historyRecords.length) return null;
        if (index == _historyRecords.length - 5)
          _getWanted(pageNumber: _currentPage + 1);

        if (index == _historyRecords.length) {
          if (_historyRecords.length == _totalRecords) return null;

          return new Container(
            height: 50.0,
            width: 50.0,
            child: new Center(child: new CircularProgressIndicator()),
          );
        }

        Color bgColor = (index % 2 == 0) ? Colors.black54 : Colors.black12;

        HistoryRecord record = _historyRecords[index];

        Text airDateText;
        bool hasAirDate = record.date != null;

        if (hasAirDate) {
          String airDateLabel = "";
          DateTime airDate = record.date.toLocal();

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

        List<Widget> body = [];

        if (hasAirDate) {
          body.add(airDateText);
        }

        Text typeText = new Text(
          record.type.getLabel(),
          style: new TextStyle(fontSize: 12.0, color: Colors.grey),
        );

        body.addAll([show, title, typeText]);

        double marginTop = index == 0 ? 12.0 : 0.0;

        Widget text = new Container(
          width: textWidth,
          margin: const EdgeInsets.only(left: 12.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: body,
          ),
        );

        Icon icon = new Icon(
          record.type.getIcon(),
          color: Colors.white,
          size: 35.0,
        );

        Container iconContainer = new Container(
          margin: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: icon,
        );

        Row row = new Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[iconContainer, text],
        );

        return new Container(
            color: bgColor,
            margin: new EdgeInsets.fromLTRB(16.0, marginTop, 12.0, 0.0),
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 28.0, 12.0),
            alignment: FractionalOffset.centerLeft,
            child: row);
      })));
    }

    return new Scaffold(
        key: _scaffoldKey,
        body: new RefreshIndicator(
            onRefresh: () async {
              await _getWanted();
            },
            child: new CustomScrollView(slivers: slivers)));
  }
}

/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../utils/utils.dart';
import '../../network/network.dart';

class Blacklist extends StatefulWidget {
  @override
  _BlacklistState createState() => new _BlacklistState();
}

class _BlacklistState extends State<Blacklist> {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  bool _loading = true;
  List<BlacklistedRelease> _blReleases = new List<BlacklistedRelease>();

  DateTime _tomorrow;
  DateTime _today;
  bool _requesting = false;
  int _currentPage;
  int _totalRecords;

  _BlacklistState() {
    _today = getTodayLocal();
    _tomorrow = getTomorrowLocal();

    Client.prepare().then((_) => _getBlacklist());
  }

  _getBlacklist({int pageNumber: 1}) async {
    if (mounted) {
      if (pageNumber == 1) {
        setState(() {
          _loading = true;
          _blReleases.clear();
        });
      }
    }

    if (_totalRecords == null || _totalRecords > _blReleases.length) {
      print("totalRecords [$_totalRecords], have [${_blReleases.length}], getting page [$pageNumber]");
      await _getSynced(pageNumber);
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  _getSynced(int pageNumber) async {
    if (!_requesting) {
      _requesting = true;
      var blPage = await Client.getInstance().getBlacklist(pageNumber, 15);
      _blReleases.addAll(blPage.records);
      _totalRecords = blPage.totalRecords;
      _requesting = false;
      _currentPage = pageNumber;
    }
  }

  @override
  Widget build(BuildContext context) {

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
        if (index > _blReleases.length) return null;
        if (index == _blReleases.length - 5) {
          _getBlacklist(pageNumber: _currentPage + 1);
        }

        if (index == _blReleases.length) {
          if (_blReleases.length == _totalRecords) return null;


          return new Container(
            height: 50.0,
            width: 50.0,
            child: new Center(child: new CircularProgressIndicator()),
          );
        }

        Color bgColor = (index % 2 == 0) ? Colors.black54 : Colors.black12;

        BlacklistedRelease record = _blReleases[index];

        Text airDateText;
        bool date = record.date != null;

        if (date) {
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

        Text title = new Text(record.releaseTitle);

        List<Widget> body = [];

        if (date) {
          body.add(airDateText);
        }

        Text quality = new Text(
          record.quality,
          style: new TextStyle(fontSize: 12.0, color: Colors.grey),
        );

        body.addAll([show, title, quality]);

        double marginTop = index == 0 ? 12.0 : 0.0;

        Widget text = new Container(
          margin: const EdgeInsets.only(left: 12.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: body,
          ),
        );

        return new Container(
            color: bgColor,
            margin: new EdgeInsets.fromLTRB(16.0, marginTop, 12.0, 0.0),
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 28.0, 12.0),
            alignment: FractionalOffset.centerLeft,
            child: text);
      })));
    }

    return new Scaffold(
        key: _scaffoldKey,
        body: new RefreshIndicator(
            onRefresh: () async {
              await _getBlacklist();
            },
            child: new CustomScrollView(slivers: slivers)));
  }
}

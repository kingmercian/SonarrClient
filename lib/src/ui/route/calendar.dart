/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/network.dart';
import '../../utils/utils.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => new _CalendarState();
}

class _CalendarState extends State<Calendar> {
  List<Episode> _todayEpisodes = [];
  List<Episode> _thisWeekEpisodes = [];
  bool _loading = true;
  bool _unmonitored = false;
  DateTime _tomorrow;
  DateTime _oneWeekFromToday;
  DateTime _today;

  _CalendarState() {
    _getAllCalendars();
    _today = getTodayLocal();
    _tomorrow = getTomorrowLocal();
    _oneWeekFromToday = _tomorrow.add(new Duration(days: 6));
  }

  _getAllCalendars() async {
    setState(() => _loading = true);
    await Client.prepare();
    _todayEpisodes = await Client.getInstance().getTodayCalendar(_unmonitored);
    _thisWeekEpisodes = await Client.getInstance().getCalendar(
        _tomorrow.add(new Duration(days: 1)), _oneWeekFromToday, _unmonitored);

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  _updateUnmonitored(bool selected) {
    setState(() => _unmonitored = selected);
    _getAllCalendars();
  }

  Widget _getEpisodeContent(Episode ep, bool upcoming) {
    Color bgColor;

    if (upcoming) {
      bgColor = (_todayEpisodes.indexOf(ep) % 2 == 0)
          ? Colors.black54
          : Colors.black12;
    } else {
      bgColor = (_thisWeekEpisodes.indexOf(ep) % 2 == 0)
          ? Colors.black54
          : Colors.black12;
    }

    bool hasAirDate = ep.airDate != null;
    Text airDateText;

    if (hasAirDate) {
      String airDateLabel = "";
      DateTime airDate = ep.airDate.toLocal();

      if (upcoming && isSameDay(airDate, _today)) {
        airDateLabel = "Today ${airDate.hour}:${twoDigits(airDate.minute)}";
      } else if (upcoming && isSameDay(airDate, _tomorrow)) {
        airDateLabel = "Tomorrow ${airDate.hour}:${twoDigits(airDate.minute)}";
      } else {
        airDateLabel =
            "${airDate.toString().substring(0, airDate.toString().length - 7)} "
            "(${dayOfWeek(airDate.weekday)})";
      }

      airDateText = new Text(
        airDateLabel,
        style: new TextStyle(fontSize: 12.0, color: Colors.grey),
      );
    }

    Text show = new Text(
      ep.showTitle,
      style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );

    Text title =
        new Text("${sxxepxx(ep.seasonNumber, ep.episodeNumber)} - ${ep.title}");

    List<Widget> body = [];

    if (hasAirDate) {
      body.add(airDateText);
    }

    body.addAll([show, title]);

    if (!ep.monitored) {
      body.add(new Text(
        "unmonitored",
        style: new TextStyle(color: Colors.grey, fontSize: 12.0),
      ));
    }

    return new Container(
        color: bgColor,
        padding: const EdgeInsets.fromLTRB(28.0, 12.0, 28.0, 12.0),
        alignment: FractionalOffset.centerLeft,
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ));
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> body = [];

    SliverAppBar appBar = new SliverAppBar(
      title: new Text("Calendar"),
      actions: <Widget>[
        new PopupMenuButton(
          onSelected: (selected) => _updateUnmonitored(selected),
          itemBuilder: (BuildContext context) => <PopupMenuItem>[
                new PopupMenuItem(
                    value: !_unmonitored,
                    child: const Text('Toggle unmonitored')),
              ],
        ),
      ],
    );

    if (!_loading && _todayEpisodes.isNotEmpty) {
      body.add(new Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: new Text(
          "Upcoming",
          style: new TextStyle(fontSize: 18.0),
        ),
      ));

      body.addAll(_todayEpisodes.map((Episode ep) {
        return _getEpisodeContent(ep, true);
      }).toList());
    }

    if (!_loading && _thisWeekEpisodes.isNotEmpty) {
      if (_todayEpisodes.isNotEmpty) {
        body.add(new Container(
          margin: const EdgeInsets.only(bottom: 12.0, top: 12.0),
          child: new Text(
            "Rest of the Week",
            style: new TextStyle(fontSize: 18.0),
          ),
        ));
      }

      body.addAll(_thisWeekEpisodes.map((Episode ep) {
        return _getEpisodeContent(ep, false);
      }).toList());
    }

    if (!_loading && _todayEpisodes.isEmpty && _thisWeekEpisodes.isEmpty) {
      body.add(
        new Container(
            margin: const EdgeInsets.only(top: 80.0),
            alignment: FractionalOffset.center,
            child: new Column(
              children: <Widget>[
                new Icon(
                  Icons.warning,
                  size: 40.0,
                ),
                new Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: new Text(
                    "No upcoming episodes today or\n the rest of this week",
                    textAlign: TextAlign.center,
                    style: new TextStyle(fontSize: 16.0),
                  ),
                )
              ],
            )),
      );
    }

    var loadingOrBody = (_loading)
        ? new Container(
            height: 110.0,
            child: new Center(child: new CircularProgressIndicator()))
        : new Container(
            margin: const EdgeInsets.fromLTRB(16.0, 12.0, 12.0, 8.0),
            child: new Column(
              children: body,
            ));

    return new RefreshIndicator(
        onRefresh: _getAllCalendars,
        child: new CustomScrollView(slivers: [
          appBar,
          new SliverToBoxAdapter(
            child: loadingOrBody,
          )
        ]));
  }
}

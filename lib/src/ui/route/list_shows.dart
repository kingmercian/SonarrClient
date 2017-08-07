/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../network/network.dart';
import '../../model/model.dart';
import '../widget/show_row.dart';
import 'detail_show.dart';

class ListShows extends StatefulWidget {
  ListShows({Key key}) : super(key: key);

  @override
  _ListShowsState createState() => new _ListShowsState();
}

class _ListShowsState extends State<ListShows>
    implements SonarrNotificationListener {
  static Client _client;
  List<Show> _shows = new List();
  bool _loading = true;

  _ListShowsState() {
    Client.prepare().then((_) {
      setState(() => _client = Client.getInstance());
      _getShows();
    });

    Notifications.prepare().then((_) {
      Notifications.getInstance().addListener(MessageType.SERIES, this);
    });
  }

  _getShows() async {
    setState(() {
      _loading = true;
    });

    _shows = await _client.getShows();

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  _onShowSelected(BuildContext context, Show show) async {
    await Navigator.push(
        context,
        new MaterialPageRoute<ShowDetail>(
            builder: (BuildContext context) =>
                new ShowDetail(show, _client.getServer())));
  }

  @override
  void onMessage(String action, Map<String, dynamic> message) {
    print("listShows received [$action]");

    if (mounted) {
      if (Notifications.DELETED == action || Notifications.UPDATED == action) {
        _getShows();
      }
    }
  }

  @override
  void dispose() {
    Notifications.getInstance().removeListener(MessageType.SERIES, this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SliverAppBar appBar = new SliverAppBar(
      title: new Text("Submarine"),
    );

    List<Widget> content = [appBar];

    if (_loading) {
      content.add(new SliverToBoxAdapter(
        child: new Container(
            height: 110.0,
            child: new Center(child: new CircularProgressIndicator())),
      ));
    } else {
      content.addAll(_shows.map((Show show) {
        return new SliverToBoxAdapter(
            child: new ShowRow(show, _onShowSelected));
      }));
    }

    return new RefreshIndicator(
        onRefresh: _getShows, child: new CustomScrollView(slivers: content));
  }
}

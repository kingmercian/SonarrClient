/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/network.dart';
import '../../utils/utils.dart';
import '../widget/submarine_message.dart';

class Queue extends StatefulWidget {
  @override
  _QueueState createState() => new _QueueState();
}

class _QueueState extends State<Queue> implements SonarrNotificationListener {
  bool _loading = true;
  List<QueueItem> _items = [];

  _QueueState() {
    _getQueue();

    Notifications.prepare().then((_) {
      Notifications.getInstance().addListener(MessageType.QUEUE, this);
    });
  }

  _getQueue({bool displayLoader: true}) async {
    if (displayLoader) setState(() => _loading = true);

    await Client.prepare();

    _items = await Client.getInstance().getQueue();

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void onMessage(String action, Map<String, dynamic> message) {
    print("Queue received [$action]");

    if (mounted) {
      //if (Notifications.DELETED == action || Notifications.UPDATED == action) {
      _getQueue(displayLoader: false);
      //}
    }
  }

  @override
  void dispose() {
    Notifications.getInstance().removeListener(MessageType.QUEUE, this);
    super.dispose();
  }

  Widget _getEpisodeContent(QueueItem item) {
    Color bgColor =
        (_items.indexOf(item) % 2 == 0) ? Colors.black54 : Colors.black12;

    Text epInfo = new Text(
      "${sxxepxx(item.seasonNumber, item.episodeNumber)} - "
          "${item.quality}",
      style: new TextStyle(fontSize: 12.0, color: Colors.grey),
    );

    Text show = new Text(
      item.showTitle,
      style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
    );

    Text title = new Text(item.episodeTitle);

    Text timeLeft = new Text(
      item.timeLeft,
      style: new TextStyle(color: Colors.grey, fontSize: 12.0),
    );

    List<Widget> body = [epInfo, show, title, timeLeft];

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

    if (!_loading && _items.isNotEmpty) {
      body.addAll(_items.map((QueueItem item) {
        return _getEpisodeContent(item);
      }).toList());
    }

    if (!_loading && _items.isEmpty) {
      body.add(new SubmarineMessage("No items in queue", Icons.warning,
          margin: const EdgeInsets.only(top: 80.0)));
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
        onRefresh: () async {
          _getQueue();
        },
        child: new CustomScrollView(slivers: [
          new SliverToBoxAdapter(
            child: loadingOrBody,
          )
        ]));
  }
}

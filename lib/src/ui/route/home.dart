/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import 'list_shows.dart';
import 'calendar.dart';
import 'wanted.dart';
import 'add_show.dart';
import 'queue.dart';
import 'history.dart';
import '../widget/drawer.dart';

class Home extends StatefulWidget {
  @override
  HomeState createState() => new HomeState();
}

class HomeState extends State<Home> {
  int _currentIndex = 0;

  ListShows _shows = new ListShows();
  Calendar _calendar = new Calendar();
  TabBarView _activity;
  Wanted _wanted = new Wanted();

  List<StatefulWidget> _content;
  List<BottomNavigationBarItem> _navigationItems;

  final List<Tab> _activityTabs = [
    new Tab(text: 'Queue'),
    new Tab(text: 'History')
  ];
  final _queue = new Queue();
  final _history = new History();

  @override
  void initState() {
    super.initState();
    _activity = new TabBarView(children: [_queue, _history]);

    _content = [_shows, _calendar, _activity, _wanted];

    _navigationItems = [
      new BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard), title: new Text("Series")),
      new BottomNavigationBarItem(
          icon: const Icon(Icons.date_range), title: new Text("Calendar")),
      new BottomNavigationBarItem(
          icon: const Icon(Icons.schedule), title: new Text("Activity")),
      new BottomNavigationBarItem(
          icon: const Icon(Icons.favorite_border), title: new Text("Wanted"))
    ];
  }

  _addShow() {
    Navigator.push(
        context,
        new MaterialPageRoute<AddShow>(
            builder: (BuildContext context) => new AddShow()));
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _content[_currentIndex];

    final BottomNavigationBar botNavBar = new BottomNavigationBar(
      items: _navigationItems,
      currentIndex: _currentIndex,
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );

    var actionButton = body is ListShows
        ? new FloatingActionButton(
            onPressed: () => _addShow(),
            tooltip: 'Add Series',
            child: new Icon(Icons.add, size: 24.0),
          )
        : null;

    Drawer drawer = new Drawer(
      child: new SubmarineDrawer(),
    );

    if (body is TabBarView) {
      return new DefaultTabController(
        length: 2,
        initialIndex: 0,
        child: new Scaffold(
          appBar: new AppBar(
            title: new Text("Activity"),
            bottom: new TabBar(tabs: _activityTabs),
          ),
          drawer: drawer,
          bottomNavigationBar: botNavBar,
          body: new TabBarView(children: [_queue, _history]),
        ),
      );
    }

    return new Scaffold(
      drawer: drawer,
      body: new Center(child: body),
      bottomNavigationBar: botNavBar,
      floatingActionButton: actionButton,
    );
  }
}

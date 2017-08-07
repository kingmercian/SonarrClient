/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';

import '../../network/network.dart';
import '../../model/model.dart';
import '../../ui/widget/add_edit_show.dart' as AddEditShow;

class AddShow extends StatefulWidget {
  @override
  _AddShowState createState() => new _AddShowState();
}

class _AddShowState extends State<AddShow> {
  static final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final TextEditingController _queryController = new TextEditingController();
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  List<Show> _shows = new List();
  bool _loading = false;
  List<Profile> _profiles = [];
  List<RootFolder> _rootFolders = [];

  _AddShowState() {
    _loadConfigurations();
  }

  _loadConfigurations() async {
    _profiles = await Client.getInstance().getProfiles();
    _rootFolders = await Client.getInstance().getRootFolders();
  }

  _lookup() async {
    _formKey.currentState.save();

    setState(() {
      _loading = true;
      _shows = new List();
    });

    _shows = await Client.getInstance().lookup(_queryController.text);

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  _onShowSelected(Show show) async {
    var response = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new AddEditShow.AddEditShow(show, _profiles, _rootFolders);
        });

    if (response != null && response is bool && response) {
      _scaffoldKey.currentState.showSnackBar(new SnackBar(
          backgroundColor: Colors.blue,
          content: new Text("Added '${show.title}' to your library")));
    }
  }

  @override
  Widget build(BuildContext context) {
    var loader = (_loading)
        ? new Container(
            height: 110.0,
            child: new Center(child: new CircularProgressIndicator()))
        : new Container();

    var form = new Container(
        margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: new Form(
            key: _formKey,
            child: new Column(children: <Widget>[
              new TextFormField(
                controller: _queryController,
                decoration: new InputDecoration(
                  hintText: "use 'tvdb:' to look up by tvdb",
                  labelText: "Name",
                ),
              ),
              new RaisedButton(
                  onPressed: () => _lookup(), child: new Text("Search"))
            ])));

    var body = new CustomScrollView(slivers: <Widget>[
      new SliverToBoxAdapter(child: form),
      new SliverToBoxAdapter(child: loader),
      new SliverToBoxAdapter(
          child: new Column(
              children: _shows.map((Show show) {
        List<Widget> card = [];

        String overview = (show.overview.isNotEmpty)
            ? show.overview
            : "No overview available";

        if (show.bannerUrl.isNotEmpty) {
          card.add(new Image.network(show.bannerUrl, fit: BoxFit.fill));
        }

        Widget add = new Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            new FlatButton(
                child: new Text("ADD"), onPressed: () => _onShowSelected(show))
          ],
        );

        card.add(new Container(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
            child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  new Text(show.title.trim(),
                      style: Theme.of(context).textTheme.title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                  new Container(
                      margin: new EdgeInsets.only(top: 12.0),
                      child: new Text(overview,
                          style: Theme.of(context).textTheme.body1,
                          textAlign: TextAlign.left)),
                  add
                ])));

        return new InkWell(
            //onTap: () => _onShowSelected(context, show),
            child: new Card(
                child: new Container(child: new Column(children: card))));
      }).toList())),
    ]);

    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text("Add Series"),
        ),
        body: body);
  }
}

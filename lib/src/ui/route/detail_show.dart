/* Copyright (c) 2017 Miguel Castiblanco */
import 'package:flutter/material.dart';
import '../../model/model.dart';
import '../../network/network.dart';
import '../widget/episode_search.dart';
import '../widget/delete_show.dart';
import '../widget/rename_files.dart';
import '../widget/season_file_deletion.dart';
import '../widget/add_edit_show.dart' as AddEditShow;
import '../../utils/utils.dart';

class ShowDetail extends StatefulWidget {
  Show _show;
  Server _server;

  ShowDetail(this._show, this._server, {Key key}) : super(key: key);

  @override
  _ShowDetailState createState() => new _ShowDetailState(_show, _server);
}

enum Action { EDIT, DELETE, RENAME_EPISODES, SEARCH_MONITORED }
enum SeasonAction { DELETE_EPISODES, RENAME_EPISODES }

class _ShowDetailState extends State<ShowDetail> {
  Show _show;
  int _showId;
  Server _server;
  Map<int, Season> _seasons = new Map();
  bool _loadingAllEpisodes = false;
  List<int> _episodesBeingDeleted = [];
  List<int> _episodesChangingMonitorStatus = [];
  List<int> _seasonsChangingMonitorStatus = [];
  List<Profile> _profiles = [];
  List<RootFolder> _rootFolders = [];
  String _profile = "";
  bool _loadingShow = true;

  final double _appBarHeight = 256.0;
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>();

  _ShowDetailState(this._show, this._server) {
    _showId = _show.id;
    _refreshShow();
    _loadConfigurations();
  }

  _loadConfigurations() async {
    _profiles = await Client.getInstance().getProfiles();
    _rootFolders = await Client.getInstance().getRootFolders();

    _refreshQuality();
  }

  _refreshQuality() {
    prof:
    for (Profile profile in _profiles) {
      if (profile.id == _show.profileId) {
        setState(() => this._profile = profile.name);
        break prof;
      }
    }
  }

  _getEpisodes() async {
    setState(() => _loadingAllEpisodes = true);

    List<Episode> episodes = await Client.getInstance().getEpisodes(_show.id);

    // Make sure to clean the list before adding the eps
    for (Season season in _seasons.values) {
      season.episodes.clear();
    }

    episodes.forEach((Episode ep) {
      _seasons[ep.seasonNumber].episodes.add(ep);
    });

    if (mounted) {
      setState(() => _loadingAllEpisodes = false);
    }
  }

  _monitorEpisode(Episode ep) {
    if (_show.monitored) {
      setState(() => _episodesChangingMonitorStatus.add(ep.id));

      Client.getInstance().monitorEpisode(ep.id, !ep.monitored).then((_) {
        _episodesChangingMonitorStatus.remove(ep.id);
        _reloadEpisode(ep);
      });
    } else {
      _showUnmonitoredError();
    }
  }

  _monitorSeason(Season season) async {
    if (_show.monitored) {
      setState(() {
        _seasonsChangingMonitorStatus.add(season.number);
        _loadingAllEpisodes = true;
      });

      await Client
          .getInstance()
          .monitorSeason(_show.id, season.number, !season.monitored);

      await _refreshShow(withLoader: false);
      if (mounted) {
        setState(() => _seasonsChangingMonitorStatus.remove(season.number));
      }
    } else {
      _showUnmonitoredError();
    }
  }

  _showUnmonitoredError() {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
        duration: new Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
        content: new Text(
            "You need to monitor the series in order to monitor seasons or episodes")));
  }

  _refreshShow({bool withLoader: true}) async {
    if (withLoader) {
      setState(() => _loadingShow = true);
    }
    var show = await Client.getInstance().getShow(_showId);

    if (mounted) {
      setState(() {
        _show = show;
        _loadingShow = false;
      });

      _refreshQuality();
      _reloadSeasons();
    }
  }

  _reloadSeasons() {
    for (Season season in _show.seasons) {
      _seasons[season.number] = season;
    }

    _getEpisodes();
  }

  _executeAction(Action action) {
    switch (action) {
      case Action.EDIT:
        _editShow();
        break;
      case Action.RENAME_EPISODES:
        _previewRenaming();
        break;
      case Action.SEARCH_MONITORED:
        _searchAllMonitored();
        break;
      case Action.DELETE:
        _showDeleteShowDialog();
        break;
    }
  }

  _executeSeasonAction(SeasonAction action, Season season) {
    switch (action) {
      case SeasonAction.RENAME_EPISODES:
        print("Renaming eps for the season ${season.number}");
        _previewRenaming(seasonNumber: season.number);
        break;
      case SeasonAction.DELETE_EPISODES:
        print("Deleting eps for the season ${season.number}}");
        _deleteSeasonFiles(season);
        break;
    }
  }

  _searchAllMonitored() async {
    await Client.getInstance().searchAllMonitored(_show.id);

    _showSnackBar("Download request sent");
  }

  _showDeleteShowDialog() async {
    var result =
        await showDialog(context: context, child: new DeleteShow(_show));

    if (result != null && result is DeleteShowResult && result.delete) {
      _deleteShow(result.deleteFiles);
    }
  }

  _deleteShow(bool deleteFiles) async {
    await Client.getInstance().deleteShow(_show.id, deleteFiles);
    Navigator.pop(context);
  }

  _editShow() async {
    var response = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new AddEditShow.AddEditShow(_show, _profiles, _rootFolders);
        });

    if (response != null && response is bool && response) {
      _refreshShow();
      _showSnackBar("Updated sucessfully");
    }
  }

  _previewRenaming({int seasonNumber}) async {
    var response = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new RenameFiles(_showId, seasonNumber: seasonNumber);
        });

    if (response != null && response is bool && response) {
      _reloadSeasons();
      _showSnackBar("Request for renaming sent succesfully");
    }
  }

  _deleteSeasonFiles(Season season) async {
    var alert = new AlertDialog(
        title: new Text("Deleting files of ${getSeasonLabel(season.number)}"),
        content: new Text(
            "Are you sure you want to delete all the files for the season?"),
        actions: <Widget>[
          new SimpleDialogOption(
            child: new Text("CANCEL"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          new SimpleDialogOption(
            child: new Text("DELETE"),
            onPressed: () async {
              //setState(() => _episodesBeingDeleted.add(ep.id));

              Navigator.pop(context);

              await showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return new SeasonFileDeletion(season);
                  });

              _reloadSeasons();
            },
          ),
        ]);

    showDialog(context: context, child: alert);
  }

  _deleteEpisodeFile(Episode ep) {
    var alert = new AlertDialog(
        title: new Text("Deleting episode"),
        content: new Text("Are you sure you want to delete episode ${ep
            .episodeNumber} from ${getSeasonLabel(ep.seasonNumber)}"),
        actions: <Widget>[
          new SimpleDialogOption(
            child: new Text("CANCEL"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          new SimpleDialogOption(
            child: new Text("DELETE"),
            onPressed: () async {
              setState(() => _episodesBeingDeleted.add(ep.id));

              Navigator.pop(context);
              await Client
                  .getInstance()
                  .deleteDownloadedEpisode(ep.episodeFileId);
              _episodesBeingDeleted.remove(ep.id);
              _reloadEpisode(ep);
            },
          ),
        ]);

    showDialog(context: context, child: alert);
  }

  _autoSearch(Episode ep) async {
    await Client.getInstance().autoEpisodeSearch(ep.id);

    _showSnackBar("Download request sent");
  }

  _showSnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
        duration: new Duration(seconds: 3),
        backgroundColor: Colors.blue,
        content: new Text(message)));
  }

  _manualSearch(Episode ep) async {
    var response = await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return new SearchEpisode(ep.id, ep.title);
        });

    if (response != null && response is SearchEpisodeResponse) {
      _showSnackBar("Download request sent");
    }
  }

  _reloadEpisode(Episode ep) async {
    var newEp = await Client.getInstance().getEpisode(ep.id);

    if (mounted) {
      setState(() {
        int index = _seasons[ep.seasonNumber].episodes.indexOf(ep);
        _seasons[ep.seasonNumber].episodes[index] = newEp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    StringBuffer summary = new StringBuffer();
    String status = capitalize(_show.status);
    summary.write("${_show.network}");
    summary.write(" (${_show.year})");
    summary.write(" - ${_show.sizeOnDisk}");

    if (_profile.isNotEmpty) {
      summary.write(" - $_profile");
    }

    summary.write(" - $status");

    Widget seasonOrLoading = _loadingShow
        ? new Container(
            height: 110.0,
            child: new Center(child: new CircularProgressIndicator()))
        : new Column(
            children: _seasons.values.map((Season season) {
            String seasonLabel = getSeasonLabel(season.number);

            List<Widget> episodesOrLoading = (_loadingAllEpisodes)
                ? <Widget>[
                    new Container(
                        height: 110.0,
                        child:
                            new Center(child: new CircularProgressIndicator()))
                  ]
                : season.episodes.map((Episode ep) {
                    Widget deleteButton;

                    if (_episodesBeingDeleted.contains(ep.id)) {
                      deleteButton = new Container(
                          padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                          height: 22.0,
                          width: 22.0,
                          child: new Center(
                              child: new CircularProgressIndicator()));
                    } else if (ep.hasFile) {
                      deleteButton = new Chip(
                        label: new Text(
                          "${ep.downloadedQuality}",
                          style: new TextStyle(fontSize: 10.0),
                        ),
                        onDeleted: () => _deleteEpisodeFile(ep),
                      );
                    }

                    String tooltip = season.monitored
                        ? "Stop monitoring"
                        : "Start monitoring";

                    Widget monitorEpOrLoading;

                    if (_episodesChangingMonitorStatus.contains(ep.id)) {
                      monitorEpOrLoading = new Container(
                          margin: const EdgeInsets.only(right: 8.0, left: 18.0),
                          height: 22.0,
                          width: 22.0,
                          child: new Center(
                              child: new CircularProgressIndicator()));
                    } else {
                      IconData monitorEp =
                          ep.monitored ? Icons.bookmark : Icons.bookmark_border;

                      monitorEpOrLoading = new IconButton(
                          padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                          icon: new Icon(monitorEp),
                          tooltip: tooltip,
                          onPressed: () => _monitorEpisode(ep));
                    }

                    Color bgColor = (season.episodes.indexOf(ep) % 2 == 0)
                        ? Colors.black54
                        : Colors.black12;

                    List<Widget> actionButtons = [];

                    actionButtons.add(monitorEpOrLoading);
                    actionButtons.add(new IconButton(
                        icon: const Icon(Icons.get_app),
                        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                        tooltip: "Automatic search",
                        onPressed: () => _autoSearch(ep)));
                    actionButtons.add(new IconButton(
                        icon: const Icon(Icons.face),
                        padding: const EdgeInsets.only(top: 0.0, bottom: 0.0),
                        tooltip: "Manual search",
                        onPressed: () => _manualSearch(ep)));

                    if (deleteButton != null) actionButtons.add(deleteButton);

                    List<Widget> texts = [];

                    if (ep.airDate != null) {
                      DateTime airDate = ep.airDate.toLocal();

                      texts.add(new Text(
                        "${airDate.year}-${twoDigits(airDate.month)}-${twoDigits(airDate.day)}",
                        overflow: TextOverflow.clip,
                        softWrap: true,
                        style:
                            new TextStyle(fontSize: 11.0, color: Colors.grey),
                      ));
                    }

                    texts.add(new Text(
                      "${ep.episodeNumber} - ${ep.title}",
                      overflow: TextOverflow.clip,
                      softWrap: true,
                      style: new TextStyle(fontSize: 16.0),
                    ));

                    return new Container(
                        color: bgColor,
                        child: new Column(
                          children: <Widget>[
                            new Container(
                                margin: const EdgeInsets.fromLTRB(
                                    32.0, 12.0, 12.0, 6.0),
                                child: new Align(
                                    alignment: FractionalOffset.centerLeft,
                                    child: new Column(
                                      children: texts,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                    ))),
                            new Center(
                                child: new Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: actionButtons,
                            )),
                          ],
                        ));
                  }).toList();

            Widget monitorEpOrLoading;

            if (_seasonsChangingMonitorStatus.contains(season.number)) {
              monitorEpOrLoading = new Container(
                  margin: const EdgeInsets.only(right: 8.0, left: 18.0),
                  height: 22.0,
                  width: 22.0,
                  child: new Center(child: new CircularProgressIndicator()));
            } else {
              String tooltip =
                  season.monitored ? "Stop monitoring" : "Start monitoring";

              IconData monitoredSeason =
                  season.monitored ? Icons.bookmark : Icons.bookmark_border;

              monitorEpOrLoading = new IconButton(
                  icon: new Icon(monitoredSeason),
                  tooltip: tooltip,
                  onPressed: () => _monitorSeason(season));
            }

            //bool hasEpsToDelete = false;

            PopupMenuButton<SeasonAction> seasonMenu = new PopupMenuButton(
                onSelected: (seasonAction) =>
                    _executeSeasonAction(seasonAction, season),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuItem<SeasonAction>>[
                      const PopupMenuItem<SeasonAction>(
                          value: SeasonAction.RENAME_EPISODES,
                          child: const Text('Rename Episodes')),
                      const PopupMenuItem<SeasonAction>(
                          value: SeasonAction.DELETE_EPISODES,
                          //enabled: hasEpsToDelete,
                          child: const Text('Delete Episodes')),
                    ]);

            Row title = new Row(
              children: <Widget>[
                seasonMenu,
                monitorEpOrLoading,
                new Text(seasonLabel),
              ],
            );

            return new ExpansionTile(
                title: title,
                backgroundColor: Colors.black12,
                children: episodesOrLoading);
          }).toList());

    return new Scaffold(
        key: _scaffoldKey,
        body: new RefreshIndicator(
            onRefresh: () => _refreshShow(),
            child: new CustomScrollView(
              slivers: <Widget>[
                new SliverAppBar(
                    expandedHeight: _appBarHeight,
                    pinned: true,
                    forceElevated: true,
                    flexibleSpace: new FlexibleSpaceBar(
                        title: new Text(_show.title,
                            overflow: TextOverflow.clip,
                            softWrap: true,
                            textAlign: TextAlign.left),
                        background: new Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            new Image.network(_getImageUrl(_show),
                                fit: BoxFit.cover,
                                scale: 0.8,
                                alignment: new FractionalOffset(0.5, 0.5),
                                height: _appBarHeight),
                            new DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: const FractionalOffset(0.5, 0.999),
                                  end: const FractionalOffset(0.5, 0.0),
                                  colors: const <Color>[
                                    const Color(0x60000000),
                                    const Color(0x00000000)
                                  ],
                                ),
                              ),
                            )
                          ],
                        )),
                    actions: <Widget>[
                      new PopupMenuButton<Action>(
                        onSelected: (action) => _executeAction(action),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuItem<Action>>[
                              const PopupMenuItem<Action>(
                                  value: Action.EDIT,
                                  child: const Text('Edit')),
                              const PopupMenuItem<Action>(
                                  value: Action.DELETE,
                                  child: const Text('Delete')),
                              const PopupMenuItem<Action>(
                                  value: Action.SEARCH_MONITORED,
                                  child: const Text('Search monitored')),
                              const PopupMenuItem<Action>(
                                  value: Action.RENAME_EPISODES,
                                  child: const Text('Rename files')),
                            ],
                      ),
                    ]),
                new SliverToBoxAdapter(
                    child: new Container(
                        margin:
                            const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
                        child: new Column(children: [
                          new Container(
                            alignment: FractionalOffset.topLeft,
                            margin: const EdgeInsets.only(top: 8.0),
                            child: new Text(summary.toString(),
                                overflow: TextOverflow.clip,
                                softWrap: true,
                                style: new TextStyle(
                                    fontSize: 11.0, color: Colors.grey)),
                          ),
                          new Container(
                            margin:
                                const EdgeInsets.only(top: 6.0, bottom: 12.0),
                            child: new Text(
                              _show.overview,
                              softWrap: true,
                              textAlign: TextAlign.justify,
                            ),
                          ),
                          seasonOrLoading
                        ]))),
              ],
            )));
  }

  String _getImageUrl(Show show) {
    return "${_server.getApiUrl("")}${_show.fanartUrl}${_server
        .getApiQueryParam()}";
  }
}

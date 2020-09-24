// Show all missions of this user.
// Mission Detail page - edit delete
// Add new mission fab
// View Users - delete

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trash_troopers/models/mission.dart';
import 'package:trash_troopers/models/user.dart';
import 'package:trash_troopers/screens/mission/missionform.dart';
import 'package:trash_troopers/services/mission_api.dart';

class MyOrgMissions extends StatefulWidget {
  final User user;
  const MyOrgMissions({Key key, this.user}) : super(key: key);

  @override
  _MyOrgMissionsState createState() => _MyOrgMissionsState();
}

class _MyOrgMissionsState extends State<MyOrgMissions> {
  final searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    List<Mission> missions;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add your onPressed code here!

          // Get lat long input
          double lat;
          double lng;

          showDialog(
            context: context,
            builder: (_) => new AlertDialog(
              title: new Text("Enter Location"),
              content: Container(
                height: 200,
                child: new Column(
                  children: [
                    new TextField(
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: new InputDecoration(
                        labelText: 'Latitude',
                      ),
                      onChanged: (value) {
                        lat = double.parse(value);
                      },
                    ),
                    new TextField(
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: new InputDecoration(
                        labelText: 'Longitude',
                      ),
                      onChanged: (value) {
                        lng = double.parse(value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text('CLOSE'),
                  onPressed: () {
                   Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text('NEXT'),
                  onPressed: () {
                    if(lat != null && lng != null)
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => MissionForm(
                        location: LatLng(lat, lng),
                      ),
                    );
                  },
                )
              ],
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      appBar: AppBar(
        title: Text(
          "${this.widget.user.name} Missions",
        ),
        // Create Mission
      ),
      body: Container(
        child: StreamBuilder(
            stream:
                MissionApi().fetchMissionsAsStreamByLeader(this.widget.user),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: Text('No Organization Missions.'));
              // else if (snapshot.data.length < 1)
              //   return Center(child: Text('No Organization Missions.'));
              else {
                print(snapshot.data.length);
                missions = (snapshot.data as List<Mission>);
                print(missions.toList());
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      // Search: https://blog.usejournal.com/flutter-search-in-listview-1ffa40956685
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          onChanged: (value) {},
                          onSubmitted: (value) {
                            Scaffold.of(context).showSnackBar(SnackBar(
                              content:
                                  Text("You searched $value, Coming Soon..."),
                              action: SnackBarAction(
                                label: 'HIDE',
                                onPressed: () {
                                  Scaffold.of(context).hideCurrentSnackBar();
                                },
                              ),
                            ));
                            searchController.text = '';
                          },
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: "Search",
                            suffixIcon: Icon(Icons.search),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12.0)),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.text,
                          maxLines: 1,
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return missionCard(
                                context,
                                missions[index],
                              );
                            }),
                      ),
                    ],
                  ),
                );
              }
            }),
      ),
    );
  }

  Widget missionCard(BuildContext context, Mission mission) {
    User user = Provider.of<User>(context);
    return Container(
      height: 160,
      margin: EdgeInsets.all(8.0),
      child: Stack(
        children: <Widget>[
          Center(
            child: Dismissible(
              secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 50, horizontal: 10),
                  alignment: AlignmentDirectional.centerEnd,
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.exit_to_app,
                        color: Colors.white,
                      ),
                      SizedBox(height: 3),
                      Text("Leave", style: TextStyle(color: Colors.white)),
                    ],
                  )),
              key: Key(mission.missionID),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  if (user.uid != mission.leader.uid) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content:
                          Text("Sorry, only the leader can delete missions"),
                      action: SnackBarAction(
                        label: 'HIDE',
                        onPressed: () {
                          Scaffold.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ));
                    return;
                  }
                  MissionApi().removeMission(mission.docID);
                } else {
                  mission.troops.removeWhere((t) => t.email == user.email);
                  MissionApi().updateMissionByName(mission, mission.missionID);
                }
              },
              background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 50, horizontal: 10),
                  alignment: AlignmentDirectional.centerStart,
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                      SizedBox(height: 3),
                      Text("Delete", style: TextStyle(color: Colors.white)),
                    ],
                  )),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                margin: EdgeInsets.all(0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: EdgeInsets.all(0),
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0),
                          ),
                          child: Center(
                            child: CachedNetworkImage(
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              imageUrl: mission.siteImage,
                              placeholder: (context, url) =>
                                  new CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  new Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, left: 8.0, right: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // missionName
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.map,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    mission.missionName,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black45,
                                    ),
                                    maxLines: 1,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Mission address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.place,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    mission.address,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Mission address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.details,
                                  color: Theme.of(context).primaryColor,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: Text(
                                    mission.details,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Troop count and Danger Level
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                // Troop Count
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.group,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      '${mission.troops.length}/${mission.expectedCapacity}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),

                                // Danger Level
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.delete,
                                      color: mission.dangerLevel < 3
                                          ? Theme.of(context).primaryColor
                                          : mission.dangerLevel == 3
                                              ? Colors.orangeAccent
                                              : Colors.red,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      '${mission.dangerLevel}/${5}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black45,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

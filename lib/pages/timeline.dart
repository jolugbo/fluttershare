import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

import 'home.dart';


class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<dynamic> users = [];
  List<String> followingList = [];
  List<Post> posts;
  @override
  void initState(){
    //createUser2();
    //deleteUser();
    //updateUser();
    //getUsers();
    //getUser();
    getTimeLine();
    getFollowing();
    super.initState();
  }

  // getAdminUsers() async{
  //   QuerySnapshot snapshot = await userRef.where('postCount',isLessThan: 3)
  //       .where('username',isEqualTo: 'femi').limit(1).getDocuments();
  //   snapshot.documents.forEach((element) {
  //     //print(element.data);
  //   });
  // }
  // getUser() async{
  //   String userId = "j4ShIOR5lcXFMkcLwStk";
  // DocumentSnapshot element = await userRef.document(userId).get();
  //       //print(element.data['username']);
  //       //print(element.documentID);
  //       //print(element.exists);
  // }
  getUsers()async{
    QuerySnapshot snapshot = await userRef.get();
    setState(() {
      users = snapshot.docs;
    });
  }
  createUser1(){
    userRef.add({
      "username":"Luke",
      "isAdmin":true,
      "postCount":3
    });
  }
  createUser2(){
    userRef.doc("fdjfkshj").set({
      "username":"Luke",
      "isAdmin":true,
      "postCount":3
    });
  }
  updateUser() async{
    final doc = await userRef.doc("fdjfkshj").get();
    if(doc.exists)
    userRef.doc("fdjfkshj").update({
      "username": "Jude",
      "isAdmin": true,
      "postCount": 3
    });
  }
  deleteUser()async{
      final doc = await userRef.doc("fdjfkshj").get();
      if(doc.exists)
      userRef.doc("fdjfkshj").delete();
  }
  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }
  getTimeLine() async{
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp',descending: true)
        .get();
    List<Post> posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  buildUsersToFollow(){
    return StreamBuilder(
        stream: userRef.snapshots(),//.orderBy('timeStamp',descending: true).limit(20)
      builder:(context,snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.docs.forEach((doc){
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool ifFollowingUser = followingList.contains(user.id);
          if(isAuthUser){
            return;
          }
          else if(ifFollowingUser){
            return;
          }
          else{
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          };
        });
        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.3),
          child: Column(children: [
            Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, color: Theme.of(context).primaryColor,size: 30,),
                    SizedBox(width:8.0),
                    Text("Users to follow",style: TextStyle(color:  Theme.of(context).primaryColor,fontSize: 30,)),
                  ],
                )
            ),
            Column(children: userResults,)
          ],),
        );
      }
    );
  }

  buildTimeline(){
    if(posts == null){
      return circularProgress();
    }
    else if(posts.isEmpty){
      return buildUsersToFollow();
    }
    return ListView(children: posts);
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeLine(),
        child: buildTimeline()
      )
    );
  }
}

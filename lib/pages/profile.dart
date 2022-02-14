import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

import 'edit_profile.dart';

class Profile extends StatefulWidget {
  String profileId;
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  bool isFollowing = false;

  buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Container(
            margin: EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey),
            )),
      ],
    );
  }

  @override
  void initState(){
    super.initState();
    getProfilePost();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }
  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection("userFollowers")
        .get();
    setState(() {
      followersCount = snapshot.docs.length;
    });
  }
  getFollowing() async{
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection("userFollowing")
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }
  checkIfFollowing() async{
    DocumentSnapshot doc = await followersRef
    .doc(widget.profileId)
        .collection("userFollowers")
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }
  getProfilePost() async{
    setState(() {
      isLoading = true;
    });
   QuerySnapshot snapshot =  await postRef
        .doc(widget.profileId)
    .collection("userPost")
    .orderBy('timestamp',descending: true)
    .get();
   //print(snapshot.docs.length);
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc))
      .toList();
    });
  }

  editProfile(){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfile(currentUserId)));
  }

  buildButton({String text, Function function}){
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: TextButton(
          onPressed: function,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              border: Border.all(
                color: isFollowing ? Colors.grey : Colors.blue,
            ),
              borderRadius: BorderRadius.circular(5)
            ),alignment:Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                  color: isFollowing ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,),
            width: 250,height: 27,
          )
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = currentUser?.id == widget.profileId;
    if(isProfileOwner){
      return buildButton(
        text: "Edit profile",function: editProfile
      );
    }
    else if (isFollowing){
      return buildButton(text: "Unfollow", function: handleUnfollowUser);
    }
    else if (!isFollowing){
      return buildButton(text: "Follow", function: handleFollowUser);
    }
  }

  handleUnfollowUser(){
    setState(() {
      isFollowing = false;
    });

    followersRef.doc(widget.profileId)
        .collection("userFollowers")
        .doc(currentUserId)
        .get().then((doc){
          if(doc.exists){
            doc.reference.delete();
          }
    });

    followingRef.doc(currentUserId)
        .collection("userFollowing")
        .doc(widget.profileId)
        .get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });

    activityFeedRef.doc(widget.profileId)
        .collection("feedItems")
        .doc(currentUserId)
        .get().then((doc){
      if(doc.exists){
        doc.reference.delete();
      }
    });
  }

  handleFollowUser(){
    setState(() {
      isFollowing = true;
    });

    followersRef.doc(widget.profileId)
    .collection("userFollowers")
    .doc(currentUserId)
    .set({});

    followingRef.doc(currentUserId)
    .collection("userFollowing")
    .doc(widget.profileId)
    .set({});

    activityFeedRef.doc(widget.profileId)
    .collection("feedItems")
    .doc(currentUserId)
    .set({
      "type":"follow",
      "ownerId":widget.profileId,
      "username":currentUser.username,
      "userId":currentUserId,
      "userProfileImg":currentUser.photoUrl,
      "timestamp":timeStamp,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
        future: userRef.doc(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                buildCountColumn("post", postCount),
                                buildCountColumn("followers", followersCount),
                                buildCountColumn("following", followingCount),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                buildProfileButton(),
                              ],
                            ),
                          ],
                        )),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    user.username,
                    style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    user.displayName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    user.bio,
                  ),
                )
              ],
            ),
          );
        });
  }

  buildProfilePost(){
    if(isLoading)
    {
      return circularProgress();
    }
    else if (posts.isEmpty){
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/no_content.svg",height: 260,),
            Padding(
              padding: EdgeInsets.only(top: 30),
              child: Text("No Post",style: TextStyle(color: Colors.red,fontSize: 40.0,fontWeight:  FontWeight.bold),),
            )
          ],
        ),
      );
    }
    else if (postOrientation == "grid"){
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
          child: PostTile(post),
        ));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    }
    else if(postOrientation == "list"){
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation){
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
            icon: Icon(Icons.grid_on),
            color: postOrientation == "grid" ? Theme.of(context).primaryColor : Colors.grey,
            onPressed: () => setPostOrientation("grid")),
        IconButton(
            icon: Icon(Icons.list),
            color: postOrientation == "list" ? Theme.of(context).primaryColor : Colors.grey,
            onPressed: () => setPostOrientation("list")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePost()
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

import 'home.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> with AutomaticKeepAliveClientMixin<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultSnapshot;

  clearSearch(){
    searchController.clear();
  }
  handleSearch(String query){
    final Future<QuerySnapshot> docs = userRef.where("username",isGreaterThanOrEqualTo: query).get();
    setState(() {
      searchResultSnapshot = docs;
    });
  }

  AppBar buildSearchField(){
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Search for a user...",
          filled: true,
          prefixIcon: Icon(Icons.account_box,size: 28,),
          suffixIcon: IconButton(icon: Icon(Icons.clear), onPressed: ()=> clearSearch())
        ),onFieldSubmitted: handleSearch,
      ),
    );
  }

  Container buildNoContent(){
    final orientation = MediaQuery.of(context).orientation;
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            SvgPicture.asset("assets/images/search.svg",height: orientation == Orientation.portrait ? 300: 200,),
            Text("Find Users",textAlign: TextAlign.center,style: TextStyle(
              color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 60,
                fontWeight: FontWeight.w600
            ),)
          ],
        ),
      ),
    );
  }

  buildSearchResult(){
    return FutureBuilder(
        future: searchResultSnapshot,
        builder: (context,snapshot){
          if(!snapshot.hasData){
            return circularProgress();
          }
          List<UserResult> searchResult = [];
          snapshot.data.docs.forEach((doc){
            User user = User.fromDocument(doc);
            //print(user.displayName);
            searchResult.add(UserResult(user));
          });
          return ListView(
            children: searchResult,
          );
        },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
      appBar: buildSearchField(),
      body: searchResultSnapshot == null ? buildNoContent() : buildSearchResult(),
    );
  }
}

class UserResult extends StatelessWidget{
  User user;
  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    var size =  MediaQuery.of(context).size;
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.8),width: size.width,
      child: Column(
        children: [
          GestureDetector(
            onTap: ()=> showProfile(context, profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey,
              ),
              title: Text(user.displayName,style: TextStyle(
                color: Colors.white,fontWeight: FontWeight.bold
              ),),
              subtitle: Text(user.username,style: TextStyle(color:Colors.white),),
            ),
          ),
          Divider(
            height: 2.0,color: Colors.white54,
          )
        ],
      ),
    );
  }
}

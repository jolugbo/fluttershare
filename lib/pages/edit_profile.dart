import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  String profileId;
  EditProfile(this.profileId);

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  bool _bioValid = true;
  bool _displayNameValid = true;
  User user;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController =TextEditingController();
  TextEditingController bioController=TextEditingController();

  @override
  void initState(){
    super.initState();
    getUser();
  }
  getUser() async{
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await userRef.doc(widget.profileId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  buildDisplayNameField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top:12),
          child: Text(
            "Display Name",textAlign: TextAlign.left,
            style: TextStyle(
                color: Colors.grey
            ),),
        ),
        TextField(
          decoration: InputDecoration(
              hintText: "Update Display Name",errorText: _displayNameValid? null:"display name too short")
          ,controller: displayNameController,)
      ],
    );
  }

  buildBioField(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top:12),
          child: Text(
            "Bio",
            style: TextStyle(
                color: Colors.grey
            ),),
        ),
        TextField(decoration: InputDecoration(
            hintText: "Update Bio",errorText: _bioValid? null:"Bio data too long"),
            controller: bioController)
      ],
    );
  }

  updateProfileData(){
    setState(() {
      displayNameController.text.trim().length < 3 || displayNameController.text.isEmpty ?_displayNameValid = false: _displayNameValid = true;
      bioController.text.trim().length > 100 ?_bioValid = false: _bioValid = true;
    });
    if(_displayNameValid && _bioValid){
      userRef.doc(widget.profileId).
      update(
        {
          "displayName": displayNameController.text.trim(),
          "bio": bioController.text.trim()
        },);
      SnackBar snackBar = SnackBar(content: Text("Profile Updated"));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }

  }

  logout() async{
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key : _scaffoldKey,
      appBar: AppBar(
        title: Text('Edit Profile',style: TextStyle(color: Colors.black),),backgroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.done),iconSize: 30,color: Colors.green, onPressed:()=> Navigator.pop(context))
        ],
      ),
      body: isLoading ?
      circularProgress():
      ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.only(top: 18,bottom: 8),
                  child: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.photoUrl),radius: 35.0,),
                ),
                Padding(
                    padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildDisplayNameField(),
                      buildBioField(),
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: updateProfileData ,color: Colors.grey,
                  child: Text(
                    "update profile",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      fontSize: 20
                    ),
                  ),),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: FlatButton.icon(
                      onPressed: logout,
                      icon: Icon(Icons.cancel,color: Colors.red,),label: Text("Log out",style:TextStyle(color: Colors.red,fontSize: 20),),
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

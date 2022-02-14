import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'create_account.dart';

final userRef =  FirebaseFirestore.instance.collection('users');
final postRef =  FirebaseFirestore.instance.collection('posts');
final commentsRef =  FirebaseFirestore.instance.collection('comments');
final activityFeedRef =  FirebaseFirestore.instance.collection('feeds');
final followersRef =  FirebaseFirestore.instance.collection('followers');
final followingRef =  FirebaseFirestore.instance.collection('following');
final timelineRef =  FirebaseFirestore.instance.collection('timeline');
final storageRef = FirebaseStorage.instance.ref();
User currentUser;
final GoogleSignIn googleSignIn = GoogleSignIn();
DateTime timeStamp = DateTime.now();
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageViewController;
  int pageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState(){
    super.initState();
    pageViewController = new PageController(initialPage: 0);
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      handleSignIn(account);
    },onError: (err){
      ////print('Error signing in: $err');
    });

    googleSignIn.signInSilently(suppressErrors: false)
    .then((GoogleSignInAccount account) => handleSignIn(account))
        .catchError((err){
      ////print('Error signing in: $err');
    });
  }

  @override
  void dispose(){
    pageViewController.dispose();
    super.initState();
  }

  handleSignIn(GoogleSignInAccount account) async {
    if(account != null){
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();//_firebaseMessaging
    }else{
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if(Platform.isIOS)getiOSPermission();
    _firebaseMessaging.getToken().then((token) {
      ////print("Firebase Messaging Token $token\n");
      userRef.doc(user.id).update({"androidNotificationToken": token});
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      //print(user.id);
      //print('${message.data}');
          final String recipientId = message.data['recipient'];
          final String body = message.notification.body;
          if(recipientId == user.id){
            SnackBar snackbar = SnackBar(content: Text(body,overflow: TextOverflow.ellipsis,));
            ScaffoldMessenger.of(context).showSnackBar(snackbar);
            //_scaffoldKey.currentState.showSnackBar(snackbar);
          }

      if (message.notification != null) {
        //print('Message also contained a notification: ${message.notification}');
      }
    });

    // _firebaseMessaging.configure(
    //   // onLaunch: (Map<String, dynamic> message) async {},
    //   // onResume: (Map<String, dynamic> message) async {},
    //   onMessage: (Map<String, dynamic> message) async {
    //     //print("on Message $message\n");
    //     final String recipientId = message['data']['recipient'];
    //     final String body = message['notification']['body'];
    //     if(recipientId == user.id){
    //       //print("Notification Shown");
    //       SnackBar snackbar = SnackBar(content: Text(body,overflow: TextOverflow.ellipsis,));
    //       _scaffoldKey.currentState.showSnackBar(snackbar);
    //     }
    //     //print("Notification Not Shown");
    //   },
    //   onLaunch: (Map<String, dynamic> message) async {
    //   //PushServices.managePushesLinkToProject(message);
    // },
    //   onResume: (Map<String, dynamic> message) async {
    //     //PushServices.managePushesLinkToProject(message);
    //   },
    // );
  }

  getiOSPermission(){
    _firebaseMessaging.requestPermission(alert: true,badge: true,sound: true,);
    // _firebaseMessaging..onIosSettingsRegistered.listen((settings) {
    //   //print("Settings registered: $settings");
    // });
  }

  createUserInFireStore() async{
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await userRef.doc(user.id).get();

    if(!doc.exists){
      final userName = await Navigator.push(context, MaterialPageRoute(builder: (context) => CreateAccount()));
      //print(userName);
      userRef.doc(user.id).set({
        "id":user.id,
        "username":userName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timeStamp": timeStamp
      });
      await followersRef.doc(user.id)
          .collection("userFollowers")
          .doc(user.id)
          .set({});
      doc = await userRef.doc(user.id).get();
    }
    currentUser = User.fromDocument(doc);
    //print(currentUser);
    //print(currentUser.displayName);
  }

  login(){
    googleSignIn.signIn();
  }

  logout(){
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex){
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int index){
    pageViewController.animateToPage(index,duration: Duration(milliseconds: 200),curve: Curves.easeInOut);
  }

  Widget buildAuthScreen(){
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: [
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageViewController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: onPageChanged,
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
          activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera,size: 35.0,)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
      //RaisedButton(onPressed: logout,child: Text('log out'),);
  }

  Scaffold buildUnAuthScreen(){
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ]
          )
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Flutter Share',style:TextStyle(
                fontFamily: "Signatra",
                fontSize: 90.0,
                color: Colors.white
              ),),
            GestureDetector(
              onTap: login,
              child:Container(
                width: 260.0,
                height:60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover
                  )
                ),
              )
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}

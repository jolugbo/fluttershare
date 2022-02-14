import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;
  Post({this.postId,this.ownerId,this.username,this.location,this.description,this.mediaUrl,this.likes});

  factory Post.fromDocument(DocumentSnapshot doc){
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikCount(likes){
    if(likes == null){
      return 0;
    }
    int count = 0;
    likes.values.forEach((val){
      if(val == true){
        count+=1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likesCount: this.getLikCount(this.likes),
    likes: this.likes,
  );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likesCount;
  Map likes;
  bool isLiked;
  bool showHeart = false;
  _PostState({this.postId,this.ownerId,this.username,this.location,this.description,this.mediaUrl,this.likesCount,this.likes});

  addLikeToActivityFeed(){
    bool isNotPostOwner = currentUserId != ownerId;
    if(isNotPostOwner){
      activityFeedRef.doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .set({
        "type":"like",
        "username":currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId":postId,
        "mediaUrl":mediaUrl,
        "timestamp":timeStamp
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if(isNotPostOwner){
      activityFeedRef.doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get().then((doc) {
        if(doc.exists){
          doc.reference.delete();
        }
      });
    }
  }

  handleLikePost(){
    bool _isLiked = likes[currentUserId] == true;
    //print(_isLiked);
    if(_isLiked){
      postRef
          .doc(ownerId)
          .collection('userPost')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likesCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    }
    else if(!_isLiked){
      postRef
          .doc(ownerId)
          .collection('userPost')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likesCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500),
      (){
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  deletePost() async{
    postRef
      .doc(ownerId)
      .collection('userPost')
      .doc(postId)
    .get().then((doc) {
      if(doc.exists){
        doc.reference.delete();
      }
    });
    storageRef.child("post_$postId.jpg").delete();
    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection('feedItems')
        .where('postId',isEqualTo: postId)
        .get();
    activityFeedSnapshot.docs.forEach((document) {
      if(document.exists){
        document.reference.delete();
      }
    });
    QuerySnapshot commentsSnapshot = await commentsRef
        .doc(postId)
        .collection('comments')
        .get();
    commentsSnapshot.docs.forEach((document) {
      if(document.exists){
        document.reference.delete();
      }
    });
  }

  handleDeletePost(BuildContext parentContext){
    showDialog(context: parentContext, builder: (context){
      return SimpleDialog(
        title: Text('Remove this post'),
        children: [
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context);
              deletePost();
            },
            child: Text('Delete',style: TextStyle(color: Colors.red),),
          ),
          SimpleDialogOption(
            onPressed: (){
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          )
        ],
      );
    });
  }

  buildPostHeader(){
    return FutureBuilder(
      future: userRef.doc(ownerId).get(),
        builder: (context,snapshot){
        if(!snapshot.hasData)
          return circularProgress();
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = ownerId == currentUserId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: ()=> showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style:TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
              )
            ),
          ),
          subtitle: Text("location"),
          trailing: isPostOwner ? IconButton(
            onPressed: ()=> handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          ): Text(''),
        );
        }
    );
  }

  buildPostImage(){
    return GestureDetector(
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(mediaUrl),
      showHeart ? Animator(
        duration: Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0.8,end: 1.4),
        curve: Curves.elasticOut,
        cycles: 0,
        builder: (context, animatorState, child) => Transform.scale(
              scale: animatorState.value,
              child: Icon(
                Icons.favorite,
                color: Colors.red,size: 80,
              )),
          ):Text(""),

        ],
      ),
      onDoubleTap:  handleLikePost,
    );
  }

  buildPostFooter(){
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top:40,left:20),
            ),
            GestureDetector(
              onTap: () => handleLikePost(),
              child: Icon(
                isLiked? Icons.favorite: Icons.favorite_border,size: 28,color: Colors.pink,),
            ),
            Padding(padding:EdgeInsets.only(right:20)),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(Icons.chat,size: 28,color: Colors.blue[900],),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text("$likesCount likes",style: TextStyle(color: Colors.black,fontWeight:FontWeight.bold)),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text("$username ",style: TextStyle(color: Colors.black,fontWeight:FontWeight.bold)),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
showComments(BuildContext context,{String postId,String ownerId,String mediaUrl}){
Navigator.push(context, MaterialPageRoute(builder: (context){
  return Comments(
    postId:postId,
    postOwnerId: ownerId,
    postMediaUrl: mediaUrl,
  );
}));
}

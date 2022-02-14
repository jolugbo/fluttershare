import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({Key key, this.postId, this.postOwnerId, this.postMediaUrl});


  @override
  CommentsState createState() => CommentsState(
      postId: this.postId,
      postOwnerId: this.postOwnerId,
      postMediaUrl: this.postMediaUrl
  );
}

class CommentsState extends State<Comments> {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;
  TextEditingController commentController = new TextEditingController();
  CommentsState({Key key, this.postId, this.postOwnerId, this.postMediaUrl});

  buildComments(){
    return StreamBuilder(
      stream: commentsRef.doc(postId)
          .collection("comments").orderBy("timestamp",descending: false).snapshots(),
      builder: (context, snapshot){
        if(!snapshot.hasData){
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.docs.forEach((doc){
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComments() {
    commentsRef.doc(postId)
        .collection("comments")
        .add({
      "username": currentUser.username,
      "comment": commentController.text,
      "timestamp": timeStamp,
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id,
    });
    bool isNotPostOwner = currentUser.id != postOwnerId;
    if(isNotPostOwner){
      activityFeedRef.doc(postOwnerId)
          .collection("feedItems")
          .add({
        "type":"comment",
        "commentData":commentController.text,
        "username":currentUser.username,
        "userId": currentUser.id,
        "userProfileImg": currentUser.photoUrl,
        "postId":postId,
        "mediaUrl":postMediaUrl,
        "timestamp":timeStamp
      });
    }
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,titleText: "Comments",),
      body: Column(
        children:[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(labelText: "Write a comment..."),
            ),
            trailing: OutlineButton(
              onPressed: addComments,
              borderSide: BorderSide.none,
              child: Text("Post"),
            ),
          )
        ],
      )
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  Comment({this.username,this.userId,this.avatarUrl, this.comment,this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider()
      ],
    );
  }
}

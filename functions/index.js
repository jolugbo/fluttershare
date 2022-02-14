/* eslint-disable eol-last */
/* eslint require-await: "error"*/
/* eslint require-jsdoc: "error"*/
/* eslint max-len: ["error", { "ignoreComments": true }] */
/* eslint max-len: ["error", { "ignoreTemplateLiterals": true }] */
/* eslint max-len: ["error", { "code": 120 }] */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// exports.helloWorld = functions.https.onRequest((request, response) => {
//  functions.logger.info("Hello logs!", {structuredData: true});
//  response.send("Hello from Firebase!");
// });

exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snap, context) => {
      console.log("Follower Created", snap.data());
      const userId = context.params.userId;
      const followerId = context.params.followerId;
      console.log(followerId + "follower");
      console.log(userId + "followed");

      // create followed user post ref
      const followedUserPostsRef = admin.firestore().collection("posts")
          .doc(userId).collection("userPost");

      // create following user's timeline post ref
      const timelinePostsRef = admin.firestore().collection("timeline")
          .doc(followerId).collection("timelinePosts");

      // get the followed users posts
      const querySnapshot = await followedUserPostsRef.get();
      querySnapshot.forEach((doc) => {
        if (doc.exists) {
          const postId = doc.id;
          const postData = doc.data();
          timelinePostsRef.doc(postId).set(postData);
        }
      });
      console.log(userId);
      console.log(followerId);
      console.log(timelinePostsRef);
    });

exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
      console.log("Follower deleted", snapshot.id);
      const userId = context.params.userId;
      const followerId = context.params.followerId;

      // create following user's timeline post ref
      const timelinePostsRef = admin.firestore().collection("timeline")
          .doc(followerId).collection("timelinePosts")
          .where("ownerId", "==", userId);

      const querySnapshot = await timelinePostsRef.get();
      querySnapshot.forEach((doc) => {
        if (doc.exists) {
          doc.ref.delete();
        }
      });
    });

exports.onCreatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onCreate(async (snap, context) => {
      console.log("Post Created", snap.data());
      const postCreated = snap.data();
      const userId = context.params.userId;
      const postId = context.params.postId;

      // create followed user post ref
      const userFollowersRef = admin.firestore().collection("followers")
          .doc(userId).collection("userFollowers");

      // get the followed users posts
      const querySnapshot = await userFollowersRef.get();
      querySnapshot.forEach((doc) => {
        const followerId = doc.id;
        admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .doc(postId)
            .set(postCreated);
      });
    });

exports.onUpdatePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onUpdate(async (change, context) => {
      const postUpdated = change.after.data();
      const postId = context.params.postId;
      const userId = context.params.userId;

      // create followed user post ref
      const userFollowersRef = admin.firestore().collection("followers")
          .doc(userId).collection("userFollowers");

      // get the followed users posts
      const querySnapshot = await userFollowersRef.get();
      querySnapshot.forEach((doc) => {
        const followerId = doc.id;
        admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .doc(postId)
            .get().then((doc) => {
              if (doc.exists) {
                doc.ref.update(postUpdated);
              }
            });
      });
    });

exports.onDeletePost = functions.firestore
    .document("/posts/{userId}/userPosts/{postId}")
    .onDelete(async (change, context) => {
      const userId = context.params.userId;
      const postId = context.params.postId;

      // create followed user post ref
      const userFollowersRef = admin.firestore().collection("followers")
          .doc(userId).collection("userFollowers");

      // get the followed users posts
      const querySnapshot = await userFollowersRef.get();
      querySnapshot.forEach((doc) => {
        const followerId = doc.id;
        admin
            .firestore()
            .collection("timeline")
            .doc(followerId)
            .collection("timelinePosts")
            .doc(postId)
            .get().then((doc) => {
              if (doc.exists) {
                doc.ref.delete();
              }
            });
      });
    });

exports.onCreateActivityFeedItems = functions.firestore
    .document("/feeds/{userId}/feedItems/{activityFeedItem}")
    .onCreate(async (snap, context) => {
      console.log("Activity  Feed Item Created");

      const userId = context.params.userId;
      const userRef = admin.firestore().doc(`users/${userId}`);
      const doc = await userRef.get();
      const androidNotificationToken = doc.data().androidNotificationToken;
      const createdActivityFeedItem = snap.data();
      if (androidNotificationToken) {
        sendNotification(androidNotificationToken, createdActivityFeedItem);
      } else {
        console.log("No token for user,cannot send notification");
      }
      /**
       * code determines appropriate push notification messages before sending
       * @param {androidNotificationToken} androidNotificationToken The notification Token.
       * @param {activityFeedItem} activityFeedItem The action behind the token.
      */
      function sendNotification(androidNotificationToken, activityFeedItem) {
        let body;
        switch (activityFeedItem.type) {
          case "comment":
            body =
           `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
            break;
          case "like":
            body = `${activityFeedItem.username} liked your post`;
            break;
          case "follow":
            body = `${activityFeedItem.username} started following you`;
            break;
        }

        const message = {
          notification: {body},
          token: androidNotificationToken,
          data: {recipient: userId},
        };

        admin
            .messaging()
            .send(message)
            .then((response) => {
              console.log("Successfully sent message", body);
            })
            .catch((error) =>{
              console.log("Error sending message", error);
            });
      }
    });
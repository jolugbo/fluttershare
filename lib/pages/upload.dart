import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as im;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'home.dart';

class Upload extends StatefulWidget {
  User currentUser;
  Upload(this.currentUser);
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload>{
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();

  selectImage(parentContext){
    return showDialog(
        context: parentContext,
      builder: (context){
          return SimpleDialog(
            title: Text("Create Post"),
            children: [
              SimpleDialogOption(
                child: Text("Photo with Camera"),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: Text("Photo From Gallery"),
                onPressed: handlePickPhoto,
              ),
              SimpleDialogOption(
                child: Text("Cancle"),
                onPressed: ()=>Navigator.pop(context),
              ),
            ],
          );
      }
    );
  }

  handleTakePhoto()async{
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.camera,maxHeight: 675,maxWidth: 960);
    setState(() {
      this.file = file;
    });
  }

  handlePickPhoto()async{
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery,maxHeight: 675,maxWidth: 960);
    setState(() {
      this.file = file;
    });
  }

  clearImage(){
    setState(() {
      file = null;
    });
  }

  handleSubmit() async{
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFireStore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        description: captionController.text
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  Future<String> uploadImage(imageFile) async {
    var uploadTask = await storageRef.child("post_$postId.jpg").putFile(imageFile);
    String downloadUrl = await storageRef.child("post_$postId.jpg").getDownloadURL();
    return downloadUrl;
  }

  createPostInFireStore({String mediaUrl,String location,String description}){
    postRef.doc(
        widget.currentUser.id)
        .collection("userPost")
        .doc(postId)
        .set({
      "postId":postId,
      "ownerId":widget.currentUser.id,
      "username":widget.currentUser.username,
      "mediaUrl":mediaUrl,
      "description":description,
      "location":location,
      "timestamp": timeStamp,
      "likes":{}
    });
  }

  compressImage() async{
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    im.Image imageFile = im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(im.encodeJpg(imageFile,quality:85));
    setState(() {
      file = compressedImageFile;
    });
  }

  Container buildSplashScreen(){
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset("assets/images/upload.svg",height: 260,),
          Padding(
              padding: EdgeInsets.only(top: 30),
            child: RaisedButton(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Text("Upload Image",style: TextStyle(color: Colors.white,fontSize: 22.0),),
              color: Colors.deepOrange,
              onPressed: () => selectImage(context),
            ),
          )
        ],
      ),
    );
  }

  buildUploadScreen(){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(icon: Icon(Icons.arrow_back),color: Colors.black,onPressed: clearImage,),
        title: Text("Caption Post",style: TextStyle(color: Colors.black),textAlign: TextAlign.center,),
        actions: [
          FlatButton(
              onPressed: isUploading == true ? null : () => handleSubmit(),
              child: Text("Post",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blueAccent,fontSize: 20),))
        ],
      ),
      body: ListView(
        children: [
          isUploading? linearProgress() : Container(),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width *0.8,
            child: Center(
              child: AspectRatio(
                  aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(fit: BoxFit.cover,image: FileImage(file))
                  )
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top:10),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250,
              child: TextField(decoration: InputDecoration(
                hintText: "Write a caption...",border: InputBorder.none
              ),controller: captionController,),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop,color: Colors.orange,size: 25,),
            title: Container(
              width: 250,
              child: TextField(decoration: InputDecoration(
                  hintText: "Where was this photo taken?",border: InputBorder.none,
              ),controller: locationController,),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: RaisedButton.icon(
                onPressed: getCurrentLocation,
                icon: Icon(Icons.my_location,color:Colors.white),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                label: Text("Use Current Location",style: TextStyle(color: Colors.white),),
              color: Colors.blue,
            )
          ),
        ],
      ),
    );
  }

  getCurrentLocation() async{
   Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
   List<Placemark> placemarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
   Placemark placemark = placemarks[0];
   String completeAddress = '${placemark.subThoroughfare}, ${placemark.thoroughfare}, ${placemark.subLocality}, '
       '${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea}, ${placemark.postalCode}, '
       '${placemark.country}';
   //print(completeAddress);
   String formattedAddress = "${placemark.locality}, ${placemark.country}";
   locationController.text = formattedAddress;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadScreen();
  }

}

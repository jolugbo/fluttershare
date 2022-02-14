import 'package:flutter/material.dart';

AppBar header(context,{bool isAppTitle = false,String titleText,bool removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text( isAppTitle? "FlutterShare": titleText,style: TextStyle(
        fontFamily: isAppTitle? "Signatra": "",
        fontSize: isAppTitle? 50.0: 22.0,
        color: Colors.white,
    ),overflow: TextOverflow.ellipsis,),centerTitle: true,backgroundColor: Theme.of(context).accentColor,
  );
}

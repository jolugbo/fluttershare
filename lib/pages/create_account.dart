import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String userName;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  submit(){
    final form = _formKey.currentState;
    if(form.validate()){
      form.save();
      SnackBar _snackBar = SnackBar(content: Text("Welcome $userName"),);
      _scaffoldKey.currentState.showSnackBar(_snackBar);
      Timer(Duration(seconds: 2), (){
        Navigator.pop(context,userName);
      })
      ;
    }
  }
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context,titleText: 'Set up your profile',removeBackButton: true),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Center(
                    child: Text('Create A Username',style: TextStyle(fontSize: 25),),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        validator: (val){
                          if(val.trim().length <3 || val.isEmpty){
                            return "Username too short";
                          }
                          else if(val.trim().length > 12){
                            return "Username too long";
                          }
                          else{
                            return null;
                          }
                        },
                        onSaved: (val) => userName = val,
                        decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "User Name",
                        hintText: "Username must be at least 3 characters",
                        labelStyle: TextStyle(fontSize: 15)
                      ),),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 350,
                    child: Center(
                      child: Text(
                        "Submit",style: TextStyle(
                          fontSize: 15,color: Colors.white,fontWeight: FontWeight.bold
                      ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(7)
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

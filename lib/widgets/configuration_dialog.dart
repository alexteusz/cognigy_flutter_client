import 'package:cognigy_flutter_client/cognigy/socket_service.dart';
import 'package:cognigy_flutter_client/helper/config_helper.dart';
import 'package:cognigy_flutter_client/main.dart';
import 'package:flutter/material.dart';

class ConfigurationDialog extends StatefulWidget {
  @override
  _ConfigurationDialogState createState() => _ConfigurationDialogState();
}

class _ConfigurationDialogState extends State<ConfigurationDialog> {
  final SocketService socketService = injector.get<SocketService>();

  TextEditingController _socketUrlTextController;
  TextEditingController _urlTokenTextController;

  String _socketUrlValue;
  String _urlTokenValue;

  @override
  void initState() {

    _socketUrlTextController = new TextEditingController();
    _urlTokenTextController = new TextEditingController();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getCognigyConfig(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          
          _socketUrlTextController.text = snapshot.data['socketUrl'];
          _urlTokenTextController.text = snapshot.data['urlToken'];

          return Center(
            child: Dialog(
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.only(
                      left: 20.0, right: 20.0, top: 20, bottom: 20),
                  height: 340,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    children: <Widget>[
                      Text(
                        "Configuration",
                        style: Theme.of(context).textTheme.title,
                      ),
                      SizedBox(height: 10.0),
                      Flexible(
                        child: Text(
                            "Insert your AI's Endpoint URL and URL Token."),
                      ),
                      SizedBox(height: 30.0),
                      TextField(
                        controller: _socketUrlTextController,
                        onChanged: (value) {
                          setState(() {
                            _socketUrlValue = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Endpoint URL',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                              borderSide:
                                  BorderSide(width: 1, color: Colors.black)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                              borderSide:
                                  BorderSide(width: 1, color: Colors.black)),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                          controller: _urlTokenTextController,
                          onChanged: (value) {
                            setState(() {
                              _urlTokenValue = value;
                            });
                          },
                          decoration: InputDecoration(
                        labelText: 'URL Token',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            borderSide:
                                BorderSide(width: 1, color: Colors.black)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(4)),
                            borderSide:
                                BorderSide(width: 1, color: Colors.black)),
                      )),
                      SizedBox(height: 20.0),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: RaisedButton(
                              padding: EdgeInsets.all(15),
                              child: Text(
                                "CONNECT TO COGNIGY",
                                style: TextStyle(color: Colors.white),
                              ),
                              color: Colors.blue,
                              colorBrightness: Brightness.light,
                              onPressed: () async {
                                
                                await setCognigyConfig(_socketUrlValue, _urlTokenValue);

                                socketService.createSocketConnection();
                                Navigator.pop(context);
                              },
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )),
          );
        });
  }
}

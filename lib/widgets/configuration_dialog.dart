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

  TextEditingController _socketUrlTextController = TextEditingController();
  TextEditingController _urlTokenTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _socketUrlTextController.dispose();
    _urlTokenTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getCognigyConfig(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]),
              ),
            );
          } else {
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
                          style: TextStyle(color: Colors.black, fontSize: 20.0),
                        ),
                        SizedBox(height: 10.0),
                        Flexible(
                          child: Text(
                              "Insert your AI's Endpoint URL and URL Token.", style: TextStyle(color: Colors.black, fontSize: 15.0),),
                        ),
                        SizedBox(height: 30.0),
                        TextField(
                          controller: _socketUrlTextController,
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
                            decoration: InputDecoration(
                              labelText: 'URL Token',
                              labelStyle: TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  borderSide: BorderSide(
                                      width: 1, color: Colors.black)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  borderSide: BorderSide(
                                      width: 1, color: Colors.black)),
                            )),
                        SizedBox(height: 20.0),
                        Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: OutlineButton(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  "CLOSE",
                                  style: TextStyle(color: Colors.black),
                                ),
                                color: Colors.grey,
                                //colorBrightness: Brightness.light,
                                onPressed: () async {
                                  Navigator.pop(context, true);
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10.0)),
                              ),
                            ),
                            SizedBox(width: 15,),
                            Expanded(
                              flex: 5,
                              child: RaisedButton(
                                padding: EdgeInsets.all(15),
                                child: Text(
                                  "CONNECT",
                                  style: TextStyle(color: Colors.white),
                                ),
                                color: _socketUrlTextController
                                            .text.isNotEmpty &&
                                        _urlTokenTextController
                                            .text.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey,
                                colorBrightness: Brightness.light,
                                onPressed: () async {
                                  if (_urlTokenTextController
                                          .text.isNotEmpty &&
                                      _socketUrlTextController
                                          .text.isNotEmpty) {
                                    setCognigyConfig(
                                        _socketUrlTextController.text,
                                        _urlTokenTextController.text);

                                    // set isConnected to false to force reconnting to Cognigy
                                    Navigator.pop(context, false);
                                  }
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10.0)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  )),
            );
          }
        });
  }
}

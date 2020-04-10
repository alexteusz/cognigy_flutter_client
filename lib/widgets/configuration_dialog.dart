import 'package:cognigy_flutter_client/providers/message_provider.dart';
import 'package:flutter/material.dart';

class ConfigurationDialog extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    MessageProvider messageProvider = new MessageProvider();

    return Center(
      child: Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding:
                EdgeInsets.only(left: 20.0, right: 20.0, top: 20, bottom: 20),
            height: 340,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: <Widget>[
                Text(
                  "Configuration",
                  style: Theme.of(context).textTheme.title,
                ),
                SizedBox(height: 10.0),
                Flexible(
                  child: Text("Insert your AI's Endpoint URL and URLToken."),
                ),
                SizedBox(height: 30.0),
                TextField(
                  onChanged: (value) => messageProvider.setSocketUrl(value),
                  decoration: InputDecoration(
                      labelText: 'Endpoint URL',
                      labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide:
                              BorderSide(width: 1, color: Colors.black)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          borderSide:
                              BorderSide(width: 1, color: Colors.black)),
                    ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  onChanged: (value) => messageProvider.setURLToken(value),
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
                  )
                ),
                SizedBox(height: 20.0),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        child: Text(
                          "SAVE",
                          style: TextStyle(color: Colors.white),
                        ),
                        color: Colors.blue,
                        colorBrightness: Brightness.light,
                        onPressed: () {
                          String socketUrl = messageProvider.getSocketUrl;
                          String urlToken = messageProvider.getUrlToken;
                          
                          messageProvider.setSocketUrl(socketUrl);
                          messageProvider.setURLToken(urlToken);
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
  }
}

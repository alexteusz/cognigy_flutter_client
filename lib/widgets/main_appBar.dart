import 'package:cognigy_flutter_client/providers/message_provider.dart';
import 'package:cognigy_flutter_client/widgets/configuration_dialog.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget with PreferredSizeWidget {
  
  final MessageProvider messageProvider;

  MainAppBar({@required this.messageProvider});


  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

      _configurationDialog(BuildContext context) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return ConfigurationDialog();
          });
    }

  @override
  Widget build(BuildContext context) {

        return AppBar(
           elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.settings, color: Colors.black,),
                onPressed: () => _configurationDialog(context),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Icon(
                Icons.brightness_1, 
              color: messageProvider.socketIsConnected ? Colors.green : Colors.red, 
          size: 10, ),
        )
        
      ],
          backgroundColor: Colors.white,
          title: Image(
            image: AssetImage('assets/images/logo.png'),
            width: 200,
          ),
        );
  }
}
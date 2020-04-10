import 'package:cognigy_flutter_client/widgets/configuration_dialog.dart';
import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget with PreferredSizeWidget {

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
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.black,),
            onPressed: () => _configurationDialog(context),
      ),
          backgroundColor: Colors.white,
          title: Image(
            image: AssetImage('assets/images/logo.png'),
            width: 200,
          ),
        );
  }
}
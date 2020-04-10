import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget with PreferredSizeWidget {

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
          leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.black,),
            onPressed: () { Scaffold.of(context).openDrawer(); },
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
          backgroundColor: Colors.white,
          title: Image(
            image: AssetImage('assets/images/logo.png'),
            width: 200,
          ),
        );
  }
}
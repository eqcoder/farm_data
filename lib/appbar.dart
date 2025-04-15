import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'setting.dart';
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 29, 71, 31),
        title: Text(title, style:TextStyle(color:Colors.white, fontWeight: FontWeight.w600, fontSize: 30)),
         centerTitle: true, 
        elevation: 0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            color:Colors.white,
            onPressed: () {
              windowManager.close();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: const Color.fromARGB(255, 243, 235, 235),
            onPressed: () => showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
          ),
          )
        ],
      );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
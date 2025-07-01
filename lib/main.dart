import 'package:flutter/material.dart';
import 'tea_list_page.dart';
import 'add_tea_page.dart';

Future<void> main() async {
  runApp(TeaApp());
}

class TeaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TNotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: TeaListPage(),
      routes: {
        '/add': (context) => AddTeaPage(),
      },
    );
  }
}



import 'package:flutter/material.dart';
import 'package:open_tv/backend/sql.dart';
import 'package:open_tv/home.dart';
import 'package:open_tv/setup.dart';

Future<void> main() async {
  final hasSources = await Sql.hasSources();
  runApp(MyApp(
    skipSetup: hasSources,
  ));
}

class MyApp extends StatelessWidget {
  final bool skipSetup;
  const MyApp({super.key, required this.skipSetup});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Open TV',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: skipSetup ? const Home() : const Setup());
  }
}

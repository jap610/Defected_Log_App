import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/login_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    const Size fixedSize = Size(1600,940);
    setWindowTitle("Defacted Log App");
    setWindowMinSize(fixedSize);
    setWindowMaxSize(fixedSize);
    setWindowFrame(Rect.fromLTWH(100, 100, fixedSize.width, fixedSize.height));
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
      navigatorObservers: [routeObserver],
    );
  }
}

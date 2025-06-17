import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'pages/home_page.dart';
import 'pages/user_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kişisel Finans Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      routes: {
        '/login': (context) => LoginPage(
          onThemeToggle: _toggleTheme,
          isDarkTheme: _isDarkTheme,
        ),
        '/home': (context) => HomePage(
          onThemeToggle: _toggleTheme,
          isDarkTheme: _isDarkTheme,
        ),
        '/profile': (context) => const UserProfilePage(),
      },
      home: LoginPage(
        onThemeToggle: _toggleTheme,
        isDarkTheme: _isDarkTheme,
      ),
    );
  }
}

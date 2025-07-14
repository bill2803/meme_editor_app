import 'package:flutter/material.dart';
import 'home.dart';
import 'theme.dart'; // import ini

void main() {
  runApp(MemeEditorApp());
}

class MemeEditorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Meme Editor App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: false,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 4,
            ),
          ),
          darkTheme: ThemeData.dark(),
          themeMode: mode,
          home: MemeHomePage(),
        );
      },
    );
  }
}

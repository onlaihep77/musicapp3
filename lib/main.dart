import 'package:flutter/cupertino.dart';
import 'package:musicapp/ui/home/home.dart';
import 'package:flutter/material.dart';
import 'package:musicapp/ui/settings/theme_controller.dart';

void main() => runApp(const MusicApp());
class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (_, themeMode, __) {
        return MaterialApp(
          title: 'Music App',
          themeMode: themeMode, // <- quan trọng
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const MusicHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
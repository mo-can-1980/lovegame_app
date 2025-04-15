import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';

class ThemeProvider extends ChangeNotifier {
    ThemeMode _themeMode = ThemeMode.dark;
    
    ThemeMode get themeMode => _themeMode;
    
    bool get isDarkMode => _themeMode == ThemeMode.dark;
    
    void toggleTheme() {
        _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
        notifyListeners();
    }
    
    static ThemeData darkTheme() {
        return ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            primaryColor: const Color(0xFF94E831),
            colorScheme: const ColorScheme.dark(
                primary: Color(0xFF94E831),
                secondary: Color(0xFFAC49FF),
                background: Colors.black,
                surface: Color(0xFF121212),
            ),
            textTheme: const TextTheme(
                displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.white12,
        );
    }
    
    static ThemeData lightTheme() {
        return ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFF94E831),
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF94E831),
                secondary: Color(0xFFAC49FF),
                background: Colors.white,
                surface: Colors.white,
            ),
            textTheme: const TextTheme(
                displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black54),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            cardColor: Colors.grey[100],
            dividerColor: Colors.black12,
        );
    }
    
    static ThemeProvider of(BuildContext context) {
        return Provider.of<ThemeProvider>(context, listen: false);
    }
} 
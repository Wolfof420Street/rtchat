import 'package:flutter/material.dart';

class Themes {
  static final lightTheme = ThemeData(
      fontFamily: GoogleFonts.poppins().fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: primarySwatch,
        accentColor: lightAccentColor,
      ).copyWith(
        primary: lightAccentColor,
        secondary: lightAccentColor,
        tertiary: detailColor,
        background: Colors.white,
      ),
      indicatorColor: lightAccentColor,
      inputDecorationTheme: const InputDecorationTheme(
        fillColor: lightTextFieldColor,
      ),
      appBarTheme: const AppBarTheme(
          color: detailColor,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(
            color: Colors.white,
          )),
      tabBarTheme: const TabBarTheme(labelColor: lightAccentColor),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return lightAccentColor;
          }
          return null;
        }),
      ));

  static final darkTheme = ThemeData(
    useMaterial3: false,
    fontFamily: GoogleFonts.poppins().fontFamily,
    canvasColor: Colors.black,
    cardColor: Colors.black,
    appBarTheme: const AppBarTheme(
        color: detailColor,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: IconThemeData(
          color: Colors.white,
        )),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(headlineMedium: TextStyle(color: Colors.white)),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
        if (states.contains(MaterialState.disabled)) {
          return null;
        }
        if (states.contains(MaterialState.selected)) {
          return accentColor;
        }
        return null;
      }),
    ),
  );
}

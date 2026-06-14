import 'package:flutter/material.dart';
import 'package:maucoffee/ui/color.dart';
import 'package:maucoffee/ui/style.dart';
import 'package:maucoffee/ui/typography.dart';

class AppTheme {
  // Settings Light Theme
  static ThemeData get light {
    return ThemeData(
      fontFamily: "poppins",
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: black50,
        primaryContainer: primaryColor,
        onPrimaryContainer: black50,
        secondary: secondaryColor,
        onSecondary: black50,
        secondaryContainer: secondaryColor,
        onSecondaryContainer: black50,
        error: errorColor,
        onError: black50,
        surface: bg,
        onSurface: textNeutralPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: lBold.copyWith(color: textNeutralPrimary),
        displayMedium: mlBold.copyWith(color: textNeutralPrimary),
        displaySmall: mBold.copyWith(color: textNeutralPrimary),
        headlineLarge: lSemiBold.copyWith(color: textNeutralPrimary),
        headlineMedium: mlSemiBold.copyWith(color: textNeutralPrimary),
        headlineSmall: mSemiBold.copyWith(color: textNeutralPrimary),
        titleLarge: smMedium.copyWith(color: textNeutralPrimary),
        titleMedium: sMedium.copyWith(color: textNeutralPrimary),
        titleSmall: xsMedium.copyWith(color: textNeutralPrimary),
        bodyLarge: smRegular.copyWith(color: textNeutralPrimary),
        bodyMedium: sRegular.copyWith(color: textNeutralPrimary),
        bodySmall: xsRegular.copyWith(color: textNeutralPrimary),
        labelLarge: sRegular.copyWith(color: textNeutralPrimary),
        labelMedium: xsRegular.copyWith(color: textNeutralPrimary),
        labelSmall: xxsRegular.copyWith(color: textNeutralPrimary),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      outlinedButtonTheme: outlinedButtonThemeData,
      scaffoldBackgroundColor: bg,
      inputDecorationTheme: inputDecorationTheme,
      appBarTheme: appbarTheme,
      //actionIconTheme: actionIconThemeData,
      textButtonTheme: textButtonThemeData,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      fontFamily: "poppins",
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: black50,
        primaryContainer: primaryColor,
        onPrimaryContainer: black50,
        secondary: secondaryColor,
        onSecondary: black50,
        secondaryContainer: secondaryColor,
        onSecondaryContainer: black50,
        error: errorColor,
        onError: black50,
        surface: bg,
        onSurface: textNeutralPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: lBold.copyWith(color: textNeutralPrimary),
        displayMedium: mlBold.copyWith(color: textNeutralPrimary),
        displaySmall: mBold.copyWith(color: textNeutralPrimary),
        headlineLarge: lSemiBold.copyWith(color: textNeutralPrimary),
        headlineMedium: mlSemiBold.copyWith(color: textNeutralPrimary),
        headlineSmall: mSemiBold.copyWith(color: textNeutralPrimary),
        titleLarge: smMedium.copyWith(color: textNeutralPrimary),
        titleMedium: sMedium.copyWith(color: textNeutralPrimary),
        titleSmall: xsMedium.copyWith(color: textNeutralPrimary),
        bodyLarge: smRegular.copyWith(color: textNeutralPrimary),
        bodyMedium: sRegular.copyWith(color: textNeutralPrimary),
        bodySmall: xsRegular.copyWith(color: textNeutralPrimary),
        labelLarge: sRegular.copyWith(color: textNeutralPrimary),
        labelMedium: xsRegular.copyWith(color: textNeutralPrimary),
        labelSmall: xxsRegular.copyWith(color: textNeutralPrimary),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      outlinedButtonTheme: outlinedButtonThemeData,
      scaffoldBackgroundColor: bg,
      inputDecorationTheme: inputDecorationTheme,
      appBarTheme: appbarTheme,
      //actionIconTheme: actionIconThemeData,
      textButtonTheme: textButtonThemeData,
    );
  }
}

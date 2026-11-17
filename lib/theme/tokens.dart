import 'package:flutter/material.dart';

/// پالت ثابت (سیستم طراحی نارنجی)؛ رنگ دیگری اضافه نشود.
/// نام‌های قدیمی (bg, sec, glass, line, acc, tx, tx2, hi) برای سازگاری با صفحه‌های دیگر حفظ شده‌اند.
class T {
  static final themeId = ValueNotifier<int>(0);
  static const themeNames = ['نارنجی', 'اقیانوس', 'یاقوت'];

  static Color bg = const Color(0xFF161316);
  static Color sec = const Color(0xFF1E1A1B);
  static Color surfaceHi = const Color(0xFF2A2123);
  static Color line = const Color(0xFF2D2426);
  static Color line2 = const Color(0xFF3A2E2F);
  static Color acc = const Color(0xFFFF6D29);
  static Color brown = const Color(0xFF453027);
  static Color get glass => brown;
  static Color tx = const Color(0xFFFFFFFF);
  static Color tx2 = const Color(0xFFBABABA);
  static Color hi = const Color(0xFFFFFFFF);
  static Color onAcc = const Color(0xFF161316);

  /// تعویض تم: 0 نارنجی (پیش‌فرض)، 1 اقیانوس، 2 یاقوت
  static void use(int i) {
    Color d(Color a, double t) => Color.lerp(bg, a, t)!;
    if (i == 1) {
      bg = const Color(0xFF071952); acc = const Color(0xFF97FEED); brown = const Color(0xFF0B666A);
      onAcc = bg; tx2 = const Color(0xFFB4DCD8);
    } else if (i == 2) {
      bg = const Color(0xFF000000); acc = const Color(0xFFFF0B55); brown = const Color(0xFF5E0B22);
      onAcc = const Color(0xFFFFFFFF); tx2 = const Color(0xFFFFDEDE).withOpacity(.72);
    } else {
      i = 0;
      bg = const Color(0xFF161316); sec = const Color(0xFF1E1A1B); surfaceHi = const Color(0xFF2A2123);
      line = const Color(0xFF2D2426); line2 = const Color(0xFF3A2E2F); acc = const Color(0xFFFF6D29);
      brown = const Color(0xFF453027); onAcc = const Color(0xFF161316); tx2 = const Color(0xFFBABABA);
      themeId.value = i;
      return;
    }
    sec = d(brown, .18); surfaceHi = d(brown, .38); line = d(brown, .30); line2 = d(brown, .5);
    themeId.value = i;
  }

  static const ok = Color(0xFF6FCF97); // طبق برنامه
  static const warn = Color(0xFFF5C451); // کمی عقب
  static const bad = Color(0xFFEB5757); // عقب‌افتاده / گیر کرده / خطر

  static const font = 'Vazirmatn';
  static const rCard = 16.0;
  static const rButton = 14.0;

  static TextTheme _lh(TextTheme t) => TextTheme(
        displayLarge: t.displayLarge?.copyWith(height: 1.6),
        displayMedium: t.displayMedium?.copyWith(height: 1.6),
        displaySmall: t.displaySmall?.copyWith(height: 1.6),
        headlineLarge: t.headlineLarge?.copyWith(height: 1.6),
        headlineMedium: t.headlineMedium?.copyWith(height: 1.6),
        headlineSmall: t.headlineSmall?.copyWith(height: 1.6),
        titleLarge: t.titleLarge?.copyWith(height: 1.6),
        titleMedium: t.titleMedium?.copyWith(height: 1.6),
        titleSmall: t.titleSmall?.copyWith(height: 1.6),
        bodyLarge: t.bodyLarge?.copyWith(height: 1.6),
        bodyMedium: t.bodyMedium?.copyWith(height: 1.6),
        bodySmall: t.bodySmall?.copyWith(height: 1.6),
        labelLarge: t.labelLarge?.copyWith(height: 1.6),
        labelMedium: t.labelMedium?.copyWith(height: 1.6),
        labelSmall: t.labelSmall?.copyWith(height: 1.6),
      );

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: acc, brightness: Brightness.dark).copyWith(
      primary: acc,
      onPrimary: onAcc,
      secondary: acc,
      onSecondary: onAcc,
      surface: sec,
      surfaceContainer: sec,
      surfaceContainerHigh: surfaceHi,
      onSurface: tx,
      error: bad,
      outline: line2,
    );
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: font,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
    );
    OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(rButton), borderSide: BorderSide(color: c));
    return base.copyWith(
      textTheme: _lh(base.textTheme.apply(bodyColor: tx, displayColor: tx, fontFamily: font)),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle:
            TextStyle(fontFamily: font, fontWeight: FontWeight.w700, fontSize: 18, color: tx),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sec,
        border: b(line2),
        enabledBorder: b(line2),
        focusedBorder: b(acc),
        labelStyle: TextStyle(color: tx2),
        hintStyle: TextStyle(color: tx2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sec,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: line2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: sec,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rCard)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceHi,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rButton)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceHi,
        contentTextStyle: TextStyle(fontFamily: font, color: tx),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rButton)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        indicatorColor: brown,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: font,
            fontSize: 11,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? tx : tx2)),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? acc : tx2)),
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: acc,
        labelColor: tx,
        unselectedLabelColor: tx2,
        dividerColor: line,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: acc, linearTrackColor: brown),
      dividerColor: line,
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? onAcc : tx2),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? acc : brown),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

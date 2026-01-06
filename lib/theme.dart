import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

/// =============================================================================
/// REVOLUT-INSPIRED PREMIUM PALETTE - Medical-Tech Edition
/// Minimalist, elegant, professional - Dark mode first
/// =============================================================================

class LightModeColors {
  // Brand: Premium Blue - Trust, calm, professional
  static const Color accent = Color(0xFF0066FF);  // Revolut blue
  
  // Primary
  static const lightPrimary = accent;
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE6F0FF);
  static const lightOnPrimaryContainer = Color(0xFF001A40);

  // Secondary: Subtle variation
  static const lightSecondary = Color(0xFF0052CC);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  // Tertiary: Soft accent
  static const lightTertiary = Color(0xFF3385FF);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Success: Medical green
  static const lightSuccess = Color(0xFF00C48C);
  static const lightOnSuccess = Color(0xFFFFFFFF);

  // Error: Soft red
  static const lightError = Color(0xFFFF3B30);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFE5E5);
  static const lightOnErrorContainer = Color(0xFF5C0000);

  // Warning
  static const lightWarning = Color(0xFFFFB800);

  // Surface: Clean whites
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1A1A1A);
  static const lightBackground = Color(0xFFF7F7F7);
  static const lightSurfaceVariant = Color(0xFFF2F2F7);
  static const lightOnSurfaceVariant = Color(0xFF8E8E93);

  // Outline
  static const lightOutline = Color(0xFFE5E5EA);
  static const lightShadow = Color(0x1A000000);
  static const lightInversePrimary = Color(0xFF99C2FF);
}

/// Dark mode - Revolut-inspired premium dark theme
/// Deep blacks, subtle cards, elegant accent
class DarkModeColors {
  // Brand: Luminous blue for dark mode
  static const Color accent = Color(0xFF0A84FF);  // iOS blue for dark
  
  // Primary
  static const darkPrimary = accent;
  static const darkOnPrimary = Color(0xFFFFFFFF);
  static const darkPrimaryContainer = Color(0xFF003D99);
  static const darkOnPrimaryContainer = Color(0xFFCCE0FF);

  // Secondary
  static const darkSecondary = Color(0xFF5AC8FA);
  static const darkOnSecondary = Color(0xFF003355);

  // Tertiary
  static const darkTertiary = Color(0xFF64D2FF);
  static const darkOnTertiary = Color(0xFF003340);

  // Success: Vibrant medical green
  static const darkSuccess = Color(0xFF30D158);
  static const darkOnSuccess = Color(0xFF003314);

  // Error
  static const darkError = Color(0xFFFF453A);
  static const darkOnError = Color(0xFFFFFFFF);
  static const darkErrorContainer = Color(0xFF5C0000);
  static const darkOnErrorContainer = Color(0xFFFFCCCC);

  // Warning
  static const darkWarning = Color(0xFFFFD60A);

  // Surface: True black with elevated cards
  static const darkSurface = Color(0xFF000000);  // True black like Revolut
  static const darkOnSurface = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF000000);
  static const darkSurfaceVariant = Color(0xFF1C1C1E);  // Elevated card
  static const darkSurfaceElevated = Color(0xFF2C2C2E);  // Higher elevation
  static const darkOnSurfaceVariant = Color(0xFF8E8E93);

  // Outline
  static const darkOutline = Color(0xFF38383A);
  static const darkOutlineVariant = Color(0xFF2C2C2E);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF0066FF);
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// =============================================================================
// THEMES
// =============================================================================

/// Light theme with modern, neutral aesthetic
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  splashFactory: NoSplash.splashFactory, // No splash effects per design
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: LightModeColors.lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      elevation: const MaterialStatePropertyAll(0),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      minimumSize: const MaterialStatePropertyAll(Size(48, 44)),
      foregroundColor: const MaterialStatePropertyAll(LightModeColors.lightOnPrimary),
      backgroundColor: const MaterialStatePropertyAll(LightModeColors.lightPrimary),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      side: const MaterialStatePropertyAll(BorderSide(color: LightModeColors.lightPrimary, width: 1.2)),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
      foregroundColor: const MaterialStatePropertyAll(LightModeColors.lightPrimary),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      padding: const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      foregroundColor: const MaterialStatePropertyAll(LightModeColors.lightPrimary),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      padding: const MaterialStatePropertyAll(EdgeInsets.all(10)),
      minimumSize: const MaterialStatePropertyAll(Size(40, 40)),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: const MaterialStatePropertyAll(LightModeColors.lightSurfaceVariant),
      foregroundColor: const MaterialStatePropertyAll(LightModeColors.lightOnSurface),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 0,
    backgroundColor: LightModeColors.lightPrimary,
    foregroundColor: LightModeColors.lightOnPrimary,
    shape: StadiumBorder(),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: LightModeColors.lightOutline.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: LightModeColors.lightSurfaceVariant,
    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: LightModeColors.lightOutline.withValues(alpha: 0.22)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: LightModeColors.lightPrimary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: LightModeColors.lightError),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIconColor: LightModeColors.lightPrimary,
  ),
  textTheme: _buildTextTheme(Brightness.light),
);

/// =============================================================================
/// DARK THEME - Revolut-inspired premium dark mode (DEFAULT)
/// True black background, elevated cards, subtle shadows, elegant accent
/// =============================================================================
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  splashFactory: InkSparkle.splashFactory,  // Subtle splash effect
  colorScheme: ColorScheme.dark(
    primary: DarkModeColors.darkPrimary,
    onPrimary: DarkModeColors.darkOnPrimary,
    primaryContainer: DarkModeColors.darkPrimaryContainer,
    onPrimaryContainer: DarkModeColors.darkOnPrimaryContainer,
    secondary: DarkModeColors.darkSecondary,
    onSecondary: DarkModeColors.darkOnSecondary,
    tertiary: DarkModeColors.darkTertiary,
    onTertiary: DarkModeColors.darkOnTertiary,
    error: DarkModeColors.darkError,
    onError: DarkModeColors.darkOnError,
    errorContainer: DarkModeColors.darkErrorContainer,
    onErrorContainer: DarkModeColors.darkOnErrorContainer,
    surface: DarkModeColors.darkSurface,
    onSurface: DarkModeColors.darkOnSurface,
    surfaceContainerHighest: DarkModeColors.darkSurfaceVariant,
    onSurfaceVariant: DarkModeColors.darkOnSurfaceVariant,
    outline: DarkModeColors.darkOutline,
    shadow: DarkModeColors.darkShadow,
    inversePrimary: DarkModeColors.darkInversePrimary,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DarkModeColors.darkSurface,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: DarkModeColors.darkOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: DarkModeColors.darkOnSurface,
    ),
  ),
  // Premium filled button - rounded, solid accent
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      backgroundColor: const WidgetStatePropertyAll(DarkModeColors.darkPrimary),
      textStyle: const WidgetStatePropertyAll(TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      )),
    ),
  ),
  // Outlined button - subtle border
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      side: WidgetStatePropertyAll(BorderSide(color: DarkModeColors.darkOutline, width: 1)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkOnSurface),
      textStyle: const WidgetStatePropertyAll(TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      )),
    ),
  ),
  // Text button - minimal
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkPrimary),
      textStyle: const WidgetStatePropertyAll(TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      )),
    ),
  ),
  // Icon button - subtle background
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
      minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: const WidgetStatePropertyAll(DarkModeColors.darkSurfaceVariant),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkOnSurface),
    ),
  ),
  // FAB - accent color
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    elevation: 0,
    highlightElevation: 0,
    backgroundColor: DarkModeColors.darkPrimary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  // Cards - elevated dark surfaces with subtle border
  cardTheme: CardThemeData(
    elevation: 0,
    color: DarkModeColors.darkSurfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: EdgeInsets.zero,
  ),
  // Inputs - clean dark style
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkModeColors.darkSurfaceVariant,
    labelStyle: TextStyle(
      fontWeight: FontWeight.w500,
      color: DarkModeColors.darkOnSurfaceVariant,
    ),
    hintStyle: TextStyle(
      color: DarkModeColors.darkOnSurfaceVariant.withValues(alpha: 0.6),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DarkModeColors.darkPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: DarkModeColors.darkError, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    prefixIconColor: DarkModeColors.darkOnSurfaceVariant,
  ),
  // Bottom navigation - clean
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: DarkModeColors.darkSurface,
    selectedItemColor: DarkModeColors.darkPrimary,
    unselectedItemColor: DarkModeColors.darkOnSurfaceVariant,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  // Divider
  dividerTheme: DividerThemeData(
    color: DarkModeColors.darkOutline.withValues(alpha: 0.5),
    thickness: 0.5,
  ),
  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: DarkModeColors.darkSurfaceVariant,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 0,
  ),
  // Bottom sheet
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: DarkModeColors.darkSurfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
  // Snackbar
  snackBarTheme: SnackBarThemeData(
    backgroundColor: DarkModeColors.darkSurfaceElevated,
    contentTextStyle: const TextStyle(color: Colors.white),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    behavior: SnackBarBehavior.floating,
  ),
  textTheme: _buildTextTheme(Brightness.dark),
);

/// Build text theme using Inter font family
TextTheme _buildTextTheme(Brightness brightness) {
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
  );
}

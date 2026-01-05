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

/// Modern, medical-inspired color palette for light mode
/// Professional blues and teals for healthcare/technology feel
class LightModeColors {
  // Primary: Deep professional blue
  static const lightPrimary = Color(0xFF0052CC);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFE3F2FD);
  static const lightOnPrimaryContainer = Color(0xFF001D35);

  // Secondary: Teal accent for medical/tech feel
  static const lightSecondary = Color(0xFF00BFA5);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  // Tertiary: Soft purple for highlights
  static const lightTertiary = Color(0xFF7C4DFF);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Error colors
  static const lightError = Color(0xFFE53935);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFEBEE);
  static const lightOnErrorContainer = Color(0xFF410002);

  // Surface and background: Clean white with subtle variations
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1A1C1E);
  static const lightBackground = Color(0xFFF8FAFB);
  static const lightSurfaceVariant = Color(0xFFF5F7FA);
  static const lightOnSurfaceVariant = Color(0xFF4A5568);

  // Outline and shadow
  static const lightOutline = Color(0xFFCBD5E0);
  static const lightShadow = Color(0xFF000000);
  static const lightInversePrimary = Color(0xFF90CAF9);
}

/// Dark mode colors with good contrast
class DarkModeColors {
  // Primary: Lighter blue for dark background
  static const darkPrimary = Color(0xFF90CAF9);
  static const darkOnPrimary = Color(0xFF001D35);
  static const darkPrimaryContainer = Color(0xFF003D75);
  static const darkOnPrimaryContainer = Color(0xFFE3F2FD);

  // Secondary: Bright teal
  static const darkSecondary = Color(0xFF64FFDA);
  static const darkOnSecondary = Color(0xFF003D33);

  // Tertiary: Bright purple
  static const darkTertiary = Color(0xFFB388FF);
  static const darkOnTertiary = Color(0xFF3E1F7A);

  // Error colors
  static const darkError = Color(0xFFFF5252);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFEBEE);

  // Surface and background: True dark mode
  static const darkSurface = Color(0xFF121212);
  static const darkOnSurface = Color(0xFFE1E4E8);
  static const darkSurfaceVariant = Color(0xFF1E1E1E);
  static const darkOnSurfaceVariant = Color(0xFFCBD5E0);

  // Outline and shadow
  static const darkOutline = Color(0xFF4A5568);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF0052CC);
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
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      foregroundColor: const WidgetStatePropertyAll(LightModeColors.lightOnPrimary),
      backgroundColor: const WidgetStatePropertyAll(LightModeColors.lightPrimary),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      side: const WidgetStatePropertyAll(BorderSide(color: LightModeColors.lightPrimary, width: 1.2)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
      foregroundColor: const WidgetStatePropertyAll(LightModeColors.lightPrimary),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      foregroundColor: const WidgetStatePropertyAll(LightModeColors.lightPrimary),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: const WidgetStatePropertyAll(LightModeColors.lightSurfaceVariant),
      foregroundColor: const WidgetStatePropertyAll(LightModeColors.lightOnSurface),
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

/// Dark theme with good contrast and readability
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  splashFactory: NoSplash.splashFactory,
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
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkOnPrimary),
      backgroundColor: const WidgetStatePropertyAll(DarkModeColors.darkPrimary),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      side: const WidgetStatePropertyAll(BorderSide(color: DarkModeColors.darkPrimary, width: 1.2)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkPrimary),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkPrimary),
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
      minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: const WidgetStatePropertyAll(DarkModeColors.darkSurfaceVariant),
      foregroundColor: const WidgetStatePropertyAll(DarkModeColors.darkOnSurface),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    elevation: 0,
    backgroundColor: DarkModeColors.darkPrimary,
    foregroundColor: DarkModeColors.darkOnPrimary,
    shape: StadiumBorder(),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: DarkModeColors.darkOutline.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: DarkModeColors.darkSurfaceVariant,
    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: DarkModeColors.darkOutline.withValues(alpha: 0.22)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: DarkModeColors.darkPrimary, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: DarkModeColors.darkError),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    prefixIconColor: DarkModeColors.darkPrimary,
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

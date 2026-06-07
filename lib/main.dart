import 'package:flutter/material.dart';
import 'package:retailpos/controllers/security/recovery_controller.dart';
import 'package:provider/provider.dart';

import 'controllers/security/user_controller.dart';
import 'controllers/settings/notification_services.dart';
import 'controllers/settings/app_branding_controller.dart';
import 'controllers/settings/system_settings_controller.dart';
import 'controllers/settings/theme_controller.dart';
import 'controllers/settings/ui_preferences_controller.dart';
import 'core/config/app_config.dart';
import 'core/config/app_brand.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

final GlobalKey<ScaffoldMessengerState> globalSnackbarKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await AppConfig.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SystemSettingsController()),
        ChangeNotifierProvider(create: (_) => ThemeController()..load()),
        ChangeNotifierProvider(create: (_) => UiPreferencesController()..load()),
        ChangeNotifierProvider(create: (_) => AppBrandingController()..loadLocal()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => RecoveryController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final uiPrefs = context.watch<UiPreferencesController>();
    final brandingCtrl = context.watch<AppBrandingController>();
    final baseTheme = AppTheme.getTheme(themeCtrl.themeKey);
    final scheme = baseTheme.colorScheme;

    EdgeInsets textFieldPadding;
    double minInputHeight;
    switch (uiPrefs.textfieldSize) {
      case 'extra_compact':
        textFieldPadding = const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        );
        minInputHeight = 36;
        break;
      case 'compact':
        textFieldPadding = const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        );
        minInputHeight = 42;
        break;
      case 'comfortable':
        textFieldPadding = const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        );
        minInputHeight = 56;
        break;
      case 'normal':
      default:
        textFieldPadding = const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        );
        minInputHeight = 48;
        break;
    }

    Color resolvedCardColor;
    switch (uiPrefs.cardColorStyle) {
      case 'white':
        resolvedCardColor = scheme.surface;
        break;
      case 'tint':
        resolvedCardColor = scheme.surfaceContainer;
        break;
      case 'soft':
      default:
        resolvedCardColor = scheme.surfaceContainerLow;
        break;
    }

    final borderStyle = uiPrefs.textfieldBorderStyle;
    InputBorder border;
    InputBorder enabledBorder;
    InputBorder focusedBorder;
    InputBorder errorBorder;

    if (borderStyle == 'none') {
      border = InputBorder.none;
      enabledBorder = InputBorder.none;
      focusedBorder = InputBorder.none;
      errorBorder = InputBorder.none;
    } else if (borderStyle == 'underlined') {
      border = UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.outlineVariant),
      );
      enabledBorder = UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.outlineVariant),
      );
      focusedBorder = UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 2.0),
      );
      errorBorder = UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      );
    } else {
      final double fieldRadius = borderStyle == 'rectangular' ? 0.0 : 10.0;
      border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      );
      enabledBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.outlineVariant),
      );
      focusedBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.primary, width: 2.0),
      );
      errorBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      );
    }

    final dynamicInputDecorationTheme = baseTheme.inputDecorationTheme.copyWith(
      contentPadding: textFieldPadding,
      constraints: BoxConstraints(minHeight: minInputHeight),
      border: border,
      enabledBorder: enabledBorder,
      focusedBorder: focusedBorder,
      errorBorder: errorBorder,
    );

    final theme = uiPrefs.touchMode
        ? baseTheme.copyWith(
            visualDensity: VisualDensity.comfortable,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            inputDecorationTheme: dynamicInputDecorationTheme,
            cardTheme: baseTheme.cardTheme.copyWith(color: resolvedCardColor),
            filledButtonTheme: FilledButtonThemeData(
              style: baseTheme.filledButtonTheme.style?.copyWith(
                minimumSize: WidgetStateProperty.all(const Size(0, 52)),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: baseTheme.outlinedButtonTheme.style?.copyWith(
                minimumSize: WidgetStateProperty.all(const Size(0, 52)),
              ),
            ),
          )
        : baseTheme.copyWith(
            inputDecorationTheme: dynamicInputDecorationTheme,
            cardTheme: baseTheme.cardTheme.copyWith(color: resolvedCardColor),
          );

    return MaterialApp(
      scaffoldMessengerKey: globalSnackbarKey,
      debugShowCheckedModeBanner: false,
      title: brandingCtrl.branding.productName,
      theme: theme,
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}


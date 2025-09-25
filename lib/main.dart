import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:gallos_app_new/shared/theme/app_colors.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/perfil/screens/perfil_screen.dart';
import 'features/pedigri/screens/pedigri_screen.dart';
import 'features/pedigri/screens/add_gallo_multistep_screen.dart';
import 'features/reportes/screens/reportes_screen.dart';
import 'features/inversiones/screens/inversiones_screen.dart';
import 'features/planes/screens/planes_screen.dart';
import 'features/vacunas/screens/vacunas_screen_real.dart';
import 'features/topes/screens/topes_gallos_screen.dart';
import 'features/peleas/screens/peleas_gallos_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_transmisiones_screen.dart';
import 'features/transmisiones/screens/transmisiones_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'services/auth_service.dart';
import 'services/connection_service.dart';
import 'services/platform_factory.dart';
import 'services/platform_implementations/platform_service_base.dart';

// 🚀 CONFIGURACIÓN MULTIPLATAFORMA CON CONDITIONAL IMPORTS
// ✅ iOS: Funcionalidades básicas (sin PDF, Firebase limitado)
// ✅ Android: Todas las funcionalidades (PDF, Firebase, etc)  
// ✅ Web: Funcionalidades web nativas

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 === INICIANDO CASTA DE GALLOS - MULTIPLATAFORMA ===');

  // 📺 Inicializar WebView Platform
  if (WebViewPlatform.instance == null) {
    // En plataformas que soporten WebView
    try {
      // WebView se inicializará automáticamente en Android/iOS
      print('📺 [WEBVIEW] Platform será inicializado automáticamente');
    } catch (e) {
      print('⚠️ [WEBVIEW] No disponible en esta plataforma: $e');
    }
  }

  // 🌐 Crear platform service usando factory
  final platformService = PlatformFactory.createPlatformService();
  print('📱 Plataforma detectada: ${_getPlatformName(platformService)}');

  // 🔔 Inicializar Firebase si es soportado
  try {
    await platformService.initializeFirebase();
    final token = await platformService.getFirebaseToken();
    if (token != null) {
      print('🎯 TOKEN FCM: ${token.substring(0, 20)}...');
    }
  } catch (e) {
    print('⚠️ Firebase no disponible en esta plataforma: $e');
  }

  // 🚀 Inicializar servicios básicos
  await AuthService.instance.initialize();
  await ConnectionService().initialize();

  runApp(const CastaDeGallosApp());
}

String _getPlatformName(PlatformServiceBase platform) {
  if (platform.isWeb) return 'Web 🌐';
  if (platform.isIOS) return 'iOS 🍎';
  if (platform.isAndroid) return 'Android 🤖';
  return 'Desconocido ❓';
}

class CastaDeGallosApp extends StatelessWidget {
  const CastaDeGallosApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configurar statusBar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Casta de Gallos - iOS Clean Build',
      debugShowCheckedModeBanner: false,
      
      // 🌐 LOCALIZACIONES HABILITADAS
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.red,
          accentColor: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        // ✅ CardTheme temporalmente comentado para compatibilidad
        // cardTheme: CardTheme(
        //   elevation: 4,
        //   margin: EdgeInsets.all(8),
        // ),
      ),
      
      // 🔐 NAVEGACIÓN SIMPLE Y DIRECTA
      initialRoute: AuthService.instance.isAuthenticated ? '/home' : '/login',
      
      // 🛣️ Rutas iOS LIMPIAS (sin funcionalidades problemáticas)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/pedigri': (context) => const PedigriScreen(),
        '/add-gallo-multistep': (context) => const AddGalloMultistepScreen(),
        '/reportes': (context) => const ReportesScreen(),
        '/inversiones': (context) => const InversionesScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/planes': (context) => const PlanesScreen(),
        // ✅ RESTAURADAS - AHORA CON PLATFORM SERVICE
        '/vacunas': (context) => const VacunasScreenReal(),
        '/topes': (context) => const TopesGallosScreen(),
        '/peleas': (context) => const PeleasGallosScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-transmisiones': (context) => const AdminTransmisionesScreen(),
        '/transmisiones': (context) => const TransmisionesScreen(),
        '/marketplace': (context) => const MarketplaceScreen(),
      },
    );
  }
}
// 🔥 AUTHSERVICE PRINCIPAL - SOLO DATOS REALES (Railway Backend)
// Este es el AuthService definitivo que conecta al backend de Railway
// Mock comentado como backup para v2 cuando implemente fallback

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'admin_notification_service.dart';
import 'user_notification_service.dart';
import 'firebase_notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  // Estado del usuario actual
  UserModel? _currentUser;
  ProfileModel? _currentProfile;
  bool _isAuthenticated = false;
  bool _isAdmin = false;  // 👑 NUEVO: Estado de admin

  // Stream controllers para notificar cambios
  final StreamController<bool> _authStateController = StreamController<bool>.broadcast();
  final StreamController<UserModel?> _userController = StreamController<UserModel?>.broadcast();
  final StreamController<bool> _adminStateController = StreamController<bool>.broadcast(); // 👑 NUEVO

  // Getters
  UserModel? get currentUser => _currentUser;
  ProfileModel? get currentProfile => _currentProfile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin; // 👑 NUEVO
  Stream<bool> get authStateStream => _authStateController.stream;
  Stream<UserModel?> get userStream => _userController.stream;
  Stream<bool> get adminStateStream => _adminStateController.stream; // 👑 NUEVO

  // 🔑 OBTENER TOKEN GUARDADO (ASÍNCRONO)
  Future<String?> getTokenAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 🔥 TÉCNICA ÉPICA DE ALAN: REGISTRAR TOKEN FCM CON CAPTURA DE ERRORES
  Future<void> _registrarTokenFCMConCapturError() async {
    print('🔥 === INICIANDO REGISTRO TOKEN FCM (CON CAPTURA ERROR) ===');
    
    String tokenToSave;
    String deviceInfo = 'Flutter App - Token Real';
    
    try {
      // INTENTAR GENERAR TOKEN REAL
      print('📱 Intentando generar token FCM...');
      String? realToken = await FirebaseMessaging.instance.getToken();
      
      if (realToken != null && realToken.isNotEmpty) {
        tokenToSave = realToken;
        deviceInfo = 'Flutter App - Token Real Generado';
        print('✅ TOKEN FCM REAL GENERADO:');
        print(realToken);
        print('📋 COPIA ESTE TOKEN PARA FIREBASE CONSOLE');
      } else {
        tokenToSave = 'ERROR: Token null o vacío - Firebase no generó token';
        deviceInfo = 'Flutter App - Error: Token nulo';
        print('❌ Token null o vacío');
      }
      
    } catch (e) {
      // CAPTURAR CUALQUIER ERROR Y GUARDARLO
      tokenToSave = 'ERROR EXCEPTION: ${e.toString()}';
      deviceInfo = 'Flutter App - Error: ${e.runtimeType}';
      print('❌ ERROR generando token FCM: $e');
    }
    
    // SIEMPRE ENVIAR AL BACKEND (TOKEN REAL O ERROR)
    try {
      print('🚀 Enviando al backend: ${tokenToSave.length > 50 ? tokenToSave.substring(0, 50) + "..." : tokenToSave}');
      await _enviarTokenAlBackend(tokenToSave, deviceInfo);
      print('✅ Token registrado en backend exitosamente');
    } catch (e) {
      print('❌ Error enviando token al backend: $e');
      // NO FALLAR EL LOGIN POR ESTO
    }
  }
  
  // 🚀 ENVIAR TOKEN AL BACKEND
  Future<void> _enviarTokenAlBackend(String token, String deviceInfo) async {
    try {
      final authToken = await getTokenAsync();
      if (authToken == null) {
        print('❌ No hay token de autenticación');
        return;
      }
      
      final response = await http.post(
        Uri.parse('https://gallerappback-production.up.railway.app/auth/register-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fcm_token': token,
          'platform': 'android',
          'device_info': deviceInfo,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Respuesta backend: ${responseData['message']}');
      } else {
        print('❌ Error backend: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      print('❌ Error en _enviarTokenAlBackend: $e');
      rethrow;
    }
  }

  // 🔑 OBTENER TOKEN GUARDADO (SÍNCRONO - SOLO SI YA ESTÁ EN MEMORIA)
  String? getToken() {
    // Para compatibilidad con código síncrono, retornamos null por ahora
    // El código debe usar getTokenAsync() para obtener el token real
    return null;
  }

  // 👑 VERIFICAR SI ES ADMINISTRADOR (MEJORADO CON BD)
  bool _esUsuarioAdmin() {
    // Usar el campo es_admin de la base de datos en lugar de email hardcodeado
    final esAdmin = _currentUser?.esAdmin ?? false;
    print('🔍 _esUsuarioAdmin() - currentUser: ${_currentUser?.email}');
    print('🔍 _esUsuarioAdmin() - esAdmin field: ${_currentUser?.esAdmin}');
    print('🔍 _esUsuarioAdmin() - resultado: $esAdmin');
    return esAdmin;
  }
  
  // 👑 MÉTODO LEGACY PARA COMPATIBILIDAD (DEPRECADO)
  bool _esEmailAdmin(String email) {
    // DEPRECADO: Solo como fallback si no hay campo es_admin
    const emailsAdmin = [
      'juan.salas.nuevo@galloapp.com',
      'admin@galloapp.com', 
      'administrador@galloapp.com',
    ];
    return emailsAdmin.contains(email.toLowerCase());
  }

  // 🔔 INICIAR SERVICIOS DE ADMIN
  Future<void> _iniciarServiciosAdmin() async {
    print('👑 Iniciando servicios de administrador...');
    // El contexto se pasará desde el login screen
    // AdminNotificationService.iniciarPolling(context);
  }

  // 📧 Obtener email del usuario actual
  Future<String?> getCurrentUserEmail() async {
    if (_currentUser != null) {
      return _currentUser!.email;
    }
    
    // Si no está en memoria, cargar desde token
    try {
      await loadCurrentUser();
      return _currentUser?.email;
    } catch (e) {
      print('⚠️ Error obteniendo email del usuario: $e');
      return null;
    }
  }

  // 🚀 INICIALIZAR - Verificar si ya está logueado
  Future<void> initialize() async {
    print('🔥 === AUTHSERVICE INICIALIZANDO (SOLO MODO REAL) ===');
    try {
      final isLoggedIn = await hasValidToken();
      print('🔑 Token válido encontrado: $isLoggedIn');
      if (isLoggedIn) {
        await loadCurrentUser();
        
        // 👑 DETECTAR SI ES ADMIN TAMBIÉN AL INICIALIZAR
        if (_currentUser != null) {
          _isAdmin = _esUsuarioAdmin();
          print('👑 Admin detectado en initialize: $_isAdmin');
          _adminStateController.add(_isAdmin);
        }
      }
    } catch (e) {
      print('❌ Error inicializando AuthService: $e');
    }
  }
  
  // 🔍 VERIFICAR TOKEN
  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('🔑 Token verificado: ${token != null ? "SÍ" : "NO"}');
    return token != null;
  }

  // 📧 LOGIN con backend real - CON DETECCIÓN ADMIN AUTOMÁTICA
  Future<bool> login(String email, String password) async {
    print('🔐 === LOGIN INICIADO (MODO REAL) ===');
    print('📧 Email: $email');
    print('🌐 Backend: https://gallerappback-production.up.railway.app');
    
    try {
      final authResponse = await ApiService.login(email, password);
      print('✅ Login exitoso - Usuario recibido');
      
      _currentUser = authResponse.user;
      _isAuthenticated = true;
      
      // 👑 DETECTAR SI ES ADMINISTRADOR
      _isAdmin = _esUsuarioAdmin();
      print('👑 Es administrador: $_isAdmin');
      
      // Cargar perfil (puede venir en la respuesta o cargar separadamente)
      if (authResponse.profile != null) {
        _currentProfile = authResponse.profile;
        print('✅ Perfil cargado desde respuesta');
      } else {
        print('🔄 Cargando perfil separadamente...');
        await loadCurrentProfile();
      }
      
      // Notificar cambios
      _authStateController.add(true);
      _userController.add(_currentUser);
      _adminStateController.add(_isAdmin); // 👑 NUEVO
      
      // 🔔 INICIALIZAR FIREBASE NOTIFICATIONS Y REGISTRAR TOKEN
      print('🔔 === INICIANDO REGISTRO FCM TOKEN ===');
      print('🔔 Usuario: ${_currentUser?.email}');
      print('🔔 Token guardado: ${authResponse.token?.accessToken != null}');
      
      try {
        print('🔔 Llamando FirebaseNotificationService.initialize()...');
        await FirebaseNotificationService.initialize();
        print('✅ Firebase notifications inicializado exitosamente');
        
        // 🔥 TÉCNICA ÉPICA DE ALAN: SIEMPRE REGISTRAR TOKEN (REAL O ERROR)
        await _registrarTokenFCMConCapturError();
        
      } catch (e) {
        print('❌ ERROR CRÍTICO en Firebase notifications:');
        print('❌ Tipo: ${e.runtimeType}');
        print('❌ Mensaje: $e');
        // NO FALLAR EL LOGIN POR ESTO
        
        // 🔥 AUN CON ERROR, INTENTAR REGISTRAR EL ERROR EN BD
        await _registrarTokenFCMConCapturError();
      }
      
      // 👑 INICIAR SERVICIOS DE ADMIN SI ES NECESARIO
      if (_isAdmin) {
        await _iniciarServiciosAdmin();
      }
      
      print('✅ === LOGIN COMPLETADO EXITOSAMENTE ===');
      print('👤 Usuario: ${_currentUser?.email}');
      print('🔑 Autenticado: $_isAuthenticated');
      print('👑 Admin: $_isAdmin');
      
      return true;
    } catch (e) {
      print('❌ === ERROR EN LOGIN ===');
      print('💥 Error: $e');
      return false;
    }
  }

  // 🆕 REGISTRO con backend real
  Future<String?> register({
    required String email,
    required String password,
    required String nombreCompleto,
    String? telefono,
    String? nombreGalpon,
  }) async {
    print('🆕 === REGISTRO INICIADO (MODO REAL) ===');
    print('📧 Email: $email');
    print('👤 Nombre: $nombreCompleto');
    
    try {
      final registerResponse = await ApiService.register(
        email: email,
        password: password,
        nombreCompleto: nombreCompleto,
        telefono: telefono,
        nombreGalpon: nombreGalpon,
      );
      
      print('✅ Registro exitoso: ${registerResponse.message}');
      return registerResponse.message;
    } catch (e) {
      print('❌ Error en registro: $e');
      // Re-lanzar la excepción para que el UI pueda manejarla
      rethrow;
    }
  }

  // 👤 CARGAR USUARIO ACTUAL
  Future<void> loadCurrentUser() async {
    print('👤 Cargando usuario actual...');
    try {
      _currentUser = await ApiService.getCurrentUser();
      _isAuthenticated = true;
      
      // 👑 ACTUALIZAR ESTADO DE ADMIN DESPUÉS DE CARGAR USUARIO
      _isAdmin = _esUsuarioAdmin();
      print('👑 Admin detectado en loadCurrentUser: $_isAdmin');
      _adminStateController.add(_isAdmin);
      
      await loadCurrentProfile();
      
      _authStateController.add(true);
      _userController.add(_currentUser);
      
      print('✅ Usuario cargado: ${_currentUser?.email}');
    } catch (e) {
      print('❌ Error cargando usuario: $e');
      await logout();
    }
  }

  // 👤 CARGAR PERFIL ACTUAL
  Future<void> loadCurrentProfile() async {
    try {
      _currentProfile = await ApiService.getMyProfile();
      print('✅ Perfil cargado correctamente');
    } catch (e) {
      print('❌ Error cargando perfil: $e');
    }
  }

  // ✏️ ACTUALIZAR PERFIL
  Future<bool> updateProfile({
    String? nombreCompleto,
    String? telefono,
    String? nombreGalpon,
    String? direccion,
    String? ciudad,
    String? biografia,
  }) async {
    try {
      _currentProfile = await ApiService.updateProfile(
        nombreCompleto: nombreCompleto,
        telefono: telefono,
        nombreGalpon: nombreGalpon,
        direccion: direccion,
        ciudad: ciudad,
        biografia: biografia,
      );
      print('✅ Perfil actualizado correctamente');
      return true;
    } catch (e) {
      print('❌ Error actualizando perfil: $e');
      return false;
    }
  }

  // 🚪 LOGOUT MEJORADO - SOLO BACKEND REAL
  Future<LogoutResponse?> logout() async {
    print('🚪 === LOGOUT INICIADO (MODO REAL) ===');
    
    LogoutResponse? logoutResponse;
    
    // 🧙‍♀️ LIMPIAR ESTADO LOCAL PRIMERO (inmediato)
    _currentUser = null;
    _currentProfile = null;
    _isAuthenticated = false;
    _isAdmin = false; // 👑 NUEVO
    
    // 🔔 DETENER POLLING DE NOTIFICACIONES
    AdminNotificationService.detenerPolling();
    UserNotificationService.detenerPolling();
    print('🔔 Polling de notificaciones detenido');
    
    // 📡 Notificar inmediatamente el cambio de estado
    _authStateController.add(false);
    _userController.add(null);
    _adminStateController.add(false); // 👑 NUEVO
    
    print('✅ Estado local limpiado inmediatamente');
    
    // 🌐 Intentar logout del servidor Railway
    try {
      logoutResponse = await ApiService.logout();
      if (logoutResponse != null) {
        print('✅ Logout del servidor Railway exitoso: ${logoutResponse.message}');
      }
    } catch (e) {
      print('⚠️ Error en logout del servidor: $e');
      // Continuamos porque el estado local ya está limpio
    }
    
    print('✅ === LOGOUT COMPLETADO ===');
    return logoutResponse;
  }

  // 📷 SUBIR AVATAR
  Future<bool> uploadAvatar(File imageFile) async {
    try {
      _currentProfile = await ApiService.uploadAvatar(imageFile);
      print('✅ Avatar actualizado en AuthService');
      return true;
    } catch (e) {
      print('❌ Error subiendo avatar: $e');
      return false;
    }
  }
  
  // 🗑️ ELIMINAR AVATAR
  Future<bool> removeAvatar() async {
    try {
      await ApiService.removeAvatar();
      // Recargar perfil para actualizar el avatar a null
      await loadCurrentProfile();
      print('✅ Avatar eliminado en AuthService');
      return true;
    } catch (e) {
      print('❌ Error eliminando avatar: $e');
      return false;
    }
  }
  
  // 🔐 CAMBIAR CONTRASEÑA
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      return await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      return false;
    }
  }
  
  // 🔄 REFRESH TOKEN
  Future<bool> refreshToken() async {
    return await ApiService.refreshToken();
  }

  // 🔥 FORZAR REGISTRO FCM MANUAL
  Future<void> _forzarRegistroFCM() async {
    try {
      print('🔥 === FORZANDO REGISTRO FCM MANUAL ===');
      
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      if (accessToken == null) {
        print('❌ No hay access token para registro FCM');
        return;
      }
      
      print('✅ Access token encontrado: ${accessToken.substring(0, 20)}...');
      
      // Usar token fake si no hay Firebase
      String fcmToken = 'fake_token_${_currentUser?.id}_${DateTime.now().millisecondsSinceEpoch}';
      print('🔑 Usando FCM token: $fcmToken');
      
      final response = await http.post(
        Uri.parse('https://gallerappback-production.up.railway.app/auth/register-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': 'android',
          'device_info': 'Manual Registration - User ${_currentUser?.id}',
        }),
      );
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('✅ FCM TOKEN REGISTRADO MANUALMENTE - ÉXITO!');
      } else {
        print('❌ Error registrando FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en registro manual FCM: $e');
    }
  }
  
  // 🗑️ DELETE ACCOUNT - ELIMINACIÓN PERMANENTE DE CUENTA
  Future<Map<String, dynamic>> deleteAccount({
    required String password,
    required String confirmationText,
  }) async {
    print('🗑️ === DELETE ACCOUNT INICIADO ===');
    print('🔑 Password: ${password.replaceAll(RegExp(r'.'), '*')}');
    print('✅ Confirmation: $confirmationText');
    
    try {
      final response = await ApiService.deleteAccount(
        password: password,
        confirmationText: confirmationText,
      );
      
      if (response['success'] == true) {
        print('✅ Cuenta eliminada exitosamente');
        
        // Limpiar estado local después de eliminación exitosa
        _currentUser = null;
        _currentProfile = null;
        _isAuthenticated = false;
        _isAdmin = false;
        
        // Notificar cambios
        _authStateController.add(false);
        _userController.add(null);
        _adminStateController.add(false);
        
        // Detener servicios
        AdminNotificationService.detenerPolling();
        UserNotificationService.detenerPolling();
        
        print('✅ Estado local limpiado después de eliminación');
        return response;
      } else {
        print('❌ Error eliminando cuenta: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('💥 Error en deleteAccount: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'error_code': 'CONNECTION_ERROR',
      };
    }
  }

  // 🔐 PASSWORD RECOVERY METHODS
  
  // Solicitar código de recuperación de contraseña
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🚀 Solicitando código de recuperación para: $email');
      
      final response = await ApiService.forgotPassword(email);
      
      if (response['success'] == true) {
        print('✅ Código enviado exitosamente');
        return response;
      } else {
        print('❌ Error enviando código: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('💥 Error en forgotPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Verificar código de recuperación
  Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      print('🔍 Verificando código para: $email, código: $code');
      
      final response = await ApiService.verifyResetCode(email, code);
      
      if (response['success'] == true) {
        print('✅ Código verificado correctamente');
        return response;
      } else {
        print('❌ Código inválido: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('💥 Error en verifyResetCode: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Resetear contraseña con código
  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      print('🔐 Reseteando contraseña para: $email');
      
      final response = await ApiService.resetPassword(email, code, newPassword);
      
      if (response['success'] == true) {
        print('✅ Contraseña cambiada exitosamente');
        
        // Limpiar tokens de sesión actual si los hay
        await _clearStoredTokens();
        
        return response;
      } else {
        print('❌ Error cambiando contraseña: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('💥 Error en resetPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
  
  // Limpiar tokens almacenados
  Future<void> _clearStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      print('🗑️ Tokens limpiados de SharedPreferences');
    } catch (e) {
      print('⚠️ Error limpiando tokens: $e');
    }
  }

  // 📧 VERIFICAR EMAIL CON CÓDIGO
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      print('🔍 Verificando email: $email con código: $code');
      
      final response = await ApiService.verifyEmail(email, code);
      
      if (response['success'] == true) {
        print('✅ Email verificado exitosamente');
        return response;
      } else {
        print('❌ Error verificando email: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('💥 Error en verifyEmail: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 📧 REENVIAR CÓDIGO DE VERIFICACIÓN
  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      print('📧 Reenviando código de verificación a: $email');
      
      final response = await ApiService.resendVerificationCode(email);
      
      if (response['success'] == true) {
        print('✅ Código reenviado exitosamente');
        return response;
      } else {
        print('❌ Error reenviando código: ${response['message']}');
        return response;
      }
    } catch (e) {
      print('💥 Error en resendVerificationCode: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 🗑️ LIMPIAR RECURSOS
  void dispose() {
    _authStateController.close();
    _userController.close();
    _adminStateController.close(); // 👑 NUEVO
  }
}

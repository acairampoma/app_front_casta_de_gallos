import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

class ApiService {
  // 🌐 URL del backend Railway
  static const String baseUrl = 'https://gallerappback-production.up.railway.app';
  
  // 🔑 Headers estándar
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 🔐 Headers con token JWT
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    return {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 📧 LOGIN con JWT - VERSIÓN SIMPLIFICADA
  static Future<AuthResponse> login(String email, String password) async {
    try {
      print('🔥 === API SERVICE LOGIN - MODO REAL ===');
      print('🌐 URL: $baseUrl/auth/login');
      print('📧 Email: $email');
      print('🔑 Password: ${password.replaceAll(RegExp(r'.'), '*')}');
      print('🕐 Timestamp: ${DateTime.now()}');
      print('📱 Platform: ${kIsWeb ? "WEB" : Platform.operatingSystem}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📄 Response Body RAW: "${response.body}"');
      print('📄 Response Body Length: ${response.body.length}');

      if (response.statusCode == 200) {
        final responseText = response.body.trim();
        
        if (responseText.isEmpty) {
          throw ApiException('Respuesta vacía del servidor');
        }
        
        // Intentar parsear JSON
        Map<String, dynamic> data;
        try {
          data = jsonDecode(responseText);
          print('📊 JSON parseado exitosamente: $data');
        } catch (e) {
          print('❌ Error parseando JSON: $e');
          throw ApiException('Respuesta inválida del servidor: $responseText');
        }
        
        // 💾 Guardar tokens de manera flexible
        final prefs = await SharedPreferences.getInstance();
        
        try {
          // Intentar diferentes estructuras de respuesta
          String? accessToken;
          String? refreshToken;
          Map<String, dynamic>? userInfo;
          
          if (data['token'] != null && data['token'] is Map) {
            // Estructura: { "token": { "access_token": "...", "refresh_token": "..." } }
            accessToken = data['token']['access_token'];
            refreshToken = data['token']['refresh_token'];
          } else if (data['access_token'] != null) {
            // Estructura: { "access_token": "...", "refresh_token": "..." }
            accessToken = data['access_token'];
            refreshToken = data['refresh_token'];
          } else {
            throw ApiException('No se encontraron tokens en la respuesta');
          }
          
          if (data['user'] != null) {
            userInfo = data['user'];
          } else {
            throw ApiException('No se encontró información del usuario');
          }
          
          // Guardar tokens
          await prefs.setString('access_token', accessToken!);
          if (refreshToken != null) {
            await prefs.setString('refresh_token', refreshToken);
          }
          await prefs.setInt('user_id', userInfo!['id']);
          await prefs.setString('user_email', userInfo['email']);
          
          print('✅ Tokens guardados exitosamente');
          
          return AuthResponse.fromJson(data);
        } catch (e) {
          print('❌ Error procesando datos: $e');
          throw ApiException('Error procesando respuesta del servidor: $e');
        }
      } else {
        final errorText = response.body;
        print('❌ Error HTTP ${response.statusCode}: $errorText');
        
        if (errorText.isNotEmpty) {
          try {
            final error = jsonDecode(errorText);
            throw ApiException(error['message'] ?? error['detail'] ?? 'Error de login');
          } catch (e) {
            throw ApiException('Error del servidor (${response.statusCode}): $errorText');
          }
        } else {
          throw ApiException('Error del servidor (${response.statusCode})');
        }
      }
    } catch (e) {
      print('💥 Exception en login: $e');
      if (e is ApiException) {
        rethrow;
      } else {
        throw ApiException('Error de conexión: $e');
      }
    }
  }

  // 🆕 REGISTRO con perfil automático
  static Future<RegisterResponse> register({
    required String email,
    required String password,
    required String nombreCompleto,
    String? telefono,
    String? nombreGalpon,
    String ciudad = 'Lima',
    String ubigeo = '150101',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'nombre_completo': nombreCompleto,
          'telefono': telefono,
          'nombre_galpon': nombreGalpon,
          'ciudad': ciudad,
          'ubigeo': ubigeo,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return RegisterResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Error de registro');
      }
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // 👤 OBTENER USUARIO ACTUAL
  static Future<UserModel> getCurrentUser() async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw ApiException('Error obteniendo usuario');
      }
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // 👤 OBTENER MI PERFIL
  static Future<ProfileModel> getMyProfile() async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/me'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProfileModel.fromJson(data);
      } else {
        throw ApiException('Error obteniendo perfil');
      }
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // ✏️ ACTUALIZAR PERFIL
  static Future<ProfileModel> updateProfile({
    String? nombreCompleto,
    String? telefono,
    String? nombreGalpon,
    String? direccion,
    String? ciudad,
    String? biografia,
  }) async {
    try {
      final authHeaders = await _getAuthHeaders();
      
      // Solo enviar campos que no son null
      final body = <String, dynamic>{};
      if (nombreCompleto != null) body['nombre_completo'] = nombreCompleto;
      if (telefono != null) body['telefono'] = telefono;
      if (nombreGalpon != null) body['nombre_galpon'] = nombreGalpon;
      if (direccion != null) body['direccion'] = direccion;
      if (ciudad != null) body['ciudad'] = ciudad;
      if (biografia != null) body['biografia'] = biografia;

      final response = await http.put(
        Uri.parse('$baseUrl/profiles/me'),
        headers: authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ProfileModel.fromJson(data);
      } else {
        throw ApiException('Error actualizando perfil');
      }
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // 🚪 LOGOUT MEJORADO con respuesta del servidor
  static Future<LogoutResponse?> logout() async {
    LogoutResponse? logoutResponse;
    
    try {
      // 🌐 Logout en el servidor con respuesta mejorada
      final authHeaders = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: authHeaders,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        logoutResponse = LogoutResponse.fromJson(data);
        print('✅ Logout del servidor exitoso: ${logoutResponse.message}');
      }
    } catch (e) {
      // Si falla el logout del servidor, seguimos limpiando local
      print('⚠️ Error en logout del servidor: $e');
    } finally {
      // 🗑️ SIEMPRE limpiar tokens locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      
      print('✅ Tokens limpiados correctamente');
    }
    
    return logoutResponse;
  }

  // 🔄 REFRESH TOKEN
  static Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: headers,
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 💾 Actualizar tokens
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 📷 SUBIR AVATAR a Cloudinary - VERSIÓN UNIVERSAL (Móvil + Web)
  static Future<ProfileModel> uploadAvatar(File imageFile) async {
    try {
      final authHeaders = await _getAuthHeaders();
      
      // 🌍 SOLUCIÓN UNIVERSAL: Detectar plataforma
      if (kIsWeb) {
        // 🔄 VERSIÓN WEB: Usar bytes en lugar de MultipartFile
        print('🌍 Subiendo avatar desde WEB...');
        
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Enviar como JSON con base64
        final response = await http.post(
          Uri.parse('$baseUrl/profiles/avatar/web'),
          headers: authHeaders,
          body: jsonEncode({
            'image_data': base64Image,
            'filename': 'avatar.jpg',
          }),
        );
        
        print('📷 Web response status: ${response.statusCode}');
        print('📷 Web response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Avatar subido exitosamente desde WEB: ${data['avatar_url']}');
          return ProfileModel.fromJson(data);
        } else {
          final error = jsonDecode(response.body);
          throw ApiException(error['message'] ?? 'Error subiendo avatar desde WEB');
        }
      } else {
        // 📱 VERSIÓN MÓVIL: Usar MultipartFile tradicional
        print('📱 Subiendo avatar desde MÓVIL...');
        
        // Crear FormData para multipart
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/profiles/avatar'),
        );
        
        // Agregar headers de autenticación
        request.headers.addAll(authHeaders);
        
        // Agregar archivo
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: 'avatar.jpg',
        );
        request.files.add(multipartFile);
        
        print('📷 Subiendo avatar móvil: ${imageFile.path}');
        
        // Enviar request
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        print('📷 Mobile response status: ${response.statusCode}');
        print('📷 Mobile response body: ${response.body}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Avatar subido exitosamente desde MÓVIL: ${data['avatar_url']}');
          return ProfileModel.fromJson(data);
        } else {
          final error = jsonDecode(response.body);
          throw ApiException(error['message'] ?? 'Error subiendo avatar desde MÓVIL');
        }
      }
    } catch (e) {
      print('💥 Error subiendo avatar: $e');
      throw ApiException('Error subiendo avatar: $e');
    }
  }
  
  // 🗑️ ELIMINAR AVATAR
  static Future<void> removeAvatar() async {
    try {
      final authHeaders = await _getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/profiles/avatar'),
        headers: authHeaders,
      );
      
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Error eliminando avatar');
      }
      
      print('✅ Avatar eliminado exitosamente');
    } catch (e) {
      throw ApiException('Error eliminando avatar: $e');
    }
  }
  
  // 🔐 CAMBIAR CONTRASEÑA
  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final authHeaders = await _getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: authHeaders,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Contraseña cambiada exitosamente');
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? 'Error cambiando contraseña');
      }
    } catch (e) {
      print('💥 Error cambiando contraseña: $e');
      throw ApiException('Error cambiando contraseña: $e');
    }
  }
  
  // 🔍 VERIFICAR TOKEN
  static Future<bool> hasValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }

  // 🗑️ DELETE ACCOUNT - ELIMINACIÓN PERMANENTE DE CUENTA
  static Future<Map<String, dynamic>> deleteAccount({
    required String password,
    required String confirmationText,
  }) async {
    try {
      print('🗑️ API: Eliminando cuenta de usuario');
      print('🔑 Password: ${password.replaceAll(RegExp(r'.'), '*')}');
      print('✅ Confirmation: $confirmationText');
      
      final authHeaders = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: authHeaders,
        body: jsonEncode({
          'password': password,
          'confirmation_text': confirmationText,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Limpiar tokens locales después de eliminación exitosa
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        print('✅ Cuenta eliminada exitosamente');
        return {
          'success': true,
          'account_deleted': data['account_deleted'] ?? true,
          'message': data['message'] ?? 'Cuenta eliminada exitosamente',
          'redirect_to': data['redirect_to'] ?? 'login',
        };
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['detail']['message'] ?? 'Error en los datos proporcionados',
          'error_code': data['detail']['error_code'] ?? 'AUTH_ERROR',
        };
      } else if (response.statusCode == 500) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['detail']['message'] ?? 'Error interno del servidor',
          'error_code': data['detail']['error_code'] ?? 'INTERNAL_ERROR',
        };
      } else {
        return {
          'success': false,
          'message': 'Error eliminando cuenta (${response.statusCode})',
          'error_code': 'HTTP_ERROR',
        };
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

  // ========================================
  // 🥊 PELEAS DE EVENTO - EVENT FIGHTS API
  // ========================================

  // 📋 Listar peleas de un evento
  static Future<List<Map<String, dynamic>>> getPeleasEvento(int eventoId) async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/$eventoId/peleas'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw ApiException('Error obteniendo peleas del evento');
      }
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // ➕ Crear pelea de evento
  static Future<Map<String, dynamic>> crearPeleaEvento({
    required int eventoId,
    required int numeroPelea,
    required String tituloPelea,
    required String galponIzquierda,
    required String galloIzquierdaNombre,
    required String galponDerecha,
    required String galloDerechaNombre,
    String? descripcionPelea,
    String? horaInicioEstimada,
    File? video,
  }) async {
    try {
      final authHeaders = await _getAuthHeaders();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/$eventoId/peleas'),
      );

      request.headers.addAll(authHeaders);

      // Campos obligatorios
      request.fields['numero_pelea'] = numeroPelea.toString();
      request.fields['titulo_pelea'] = tituloPelea;
      request.fields['galpon_izquierda'] = galponIzquierda;
      request.fields['gallo_izquierda_nombre'] = galloIzquierdaNombre;
      request.fields['galpon_derecha'] = galponDerecha;
      request.fields['gallo_derecha_nombre'] = galloDerechaNombre;

      // Campos opcionales
      if (descripcionPelea != null) {
        request.fields['descripcion_pelea'] = descripcionPelea;
      }
      if (horaInicioEstimada != null) {
        request.fields['hora_inicio_estimada'] = horaInicioEstimada;
      }

      // Video opcional
      if (video != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'video',
          video.path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? error['detail'] ?? 'Error creando pelea');
      }
    } catch (e) {
      throw ApiException('Error creando pelea: $e');
    }
  }

  // 🔍 Obtener pelea específica
  static Future<Map<String, dynamic>> getPeleaEvento(int peleaId) async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/peleas/$peleaId'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw ApiException('Error obteniendo pelea');
      }
    } catch (e) {
      throw ApiException('Error de conexión: $e');
    }
  }

  // ✏️ Actualizar pelea de evento
  static Future<Map<String, dynamic>> actualizarPeleaEvento({
    required int peleaId,
    String? tituloPelea,
    String? descripcionPelea,
    String? galponIzquierda,
    String? galloIzquierdaNombre,
    String? galponDerecha,
    String? galloDerechaNombre,
    String? horaInicioEstimada,
    String? resultado,
    File? video,
  }) async {
    try {
      final authHeaders = await _getAuthHeaders();

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/peleas/$peleaId'),
      );

      request.headers.addAll(authHeaders);

      // Solo agregar campos que no son null
      if (tituloPelea != null) request.fields['titulo_pelea'] = tituloPelea;
      if (descripcionPelea != null) request.fields['descripcion_pelea'] = descripcionPelea;
      if (galponIzquierda != null) request.fields['galpon_izquierda'] = galponIzquierda;
      if (galloIzquierdaNombre != null) request.fields['gallo_izquierda_nombre'] = galloIzquierdaNombre;
      if (galponDerecha != null) request.fields['galpon_derecha'] = galponDerecha;
      if (galloDerechaNombre != null) request.fields['gallo_derecha_nombre'] = galloDerechaNombre;
      if (horaInicioEstimada != null) request.fields['hora_inicio_estimada'] = horaInicioEstimada;
      if (resultado != null) request.fields['resultado'] = resultado;

      // Video opcional
      if (video != null) {
        final multipartFile = await http.MultipartFile.fromPath(
          'video',
          video.path,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? error['detail'] ?? 'Error actualizando pelea');
      }
    } catch (e) {
      throw ApiException('Error actualizando pelea: $e');
    }
  }

  // 🔄 Actualizar orden de pelea
  static Future<Map<String, dynamic>> actualizarOrdenPelea({
    required int peleaId,
    required int nuevoNumero,
  }) async {
    try {
      final authHeaders = await _getAuthHeaders();

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/peleas/$peleaId/orden'),
      );

      request.headers.addAll(authHeaders);
      request.fields['nuevo_numero'] = nuevoNumero.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? error['detail'] ?? 'Error actualizando orden');
      }
    } catch (e) {
      throw ApiException('Error actualizando orden: $e');
    }
  }

  // 🗑️ Eliminar pelea de evento
  static Future<void> deletePeleaEvento(int peleaId) async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/peleas/$peleaId'),
        headers: authHeaders,
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? error['detail'] ?? 'Error eliminando pelea');
      }
    } catch (e) {
      throw ApiException('Error eliminando pelea: $e');
    }
  }

  // 📄 Generar PDF de relación de peleas
  static Future<Map<String, dynamic>> getPDFRelacionPeleas(int eventoId) async {
    try {
      final authHeaders = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/transmisiones/eventos/$eventoId/pdf'),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? error['detail'] ?? 'Error generando PDF');
      }
    } catch (e) {
      throw ApiException('Error generando PDF: $e');
    }
  }

  // ========================================
  // 📹 VIDEOTECA METHODS
  // ========================================

  /// Obtener videoteca con filtros
  static Future<List<Map<String, dynamic>>> getVideoteca({
    String? fechaInicio,
    String? fechaFin,
    int? coliseoId,
  }) async {
    try {
      // Construir query params
      final queryParams = <String, String>{};
      if (fechaInicio != null && fechaInicio.isNotEmpty) {
        queryParams['fecha_inicio'] = fechaInicio;
      }
      if (fechaFin != null && fechaFin.isNotEmpty) {
        queryParams['fecha_fin'] = fechaFin;
      }
      if (coliseoId != null) {
        queryParams['coliseo_id'] = coliseoId.toString();
      }

      // Construir URL con query string manualmente
      String url = '$baseUrl/api/v1/transmisiones/eventos/videoteca';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      print('🎬 API: Llamando videoteca: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('🎬 API: Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('🎬 API: Eventos encontrados: ${data.length}');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('❌ API Error: ${response.body}');
        final error = jsonDecode(response.body);
        throw ApiException(error['message'] ?? error['detail'] ?? 'Error obteniendo videoteca');
      }
    } catch (e) {
      print('❌ API Exception: $e');
      throw ApiException('Error obteniendo videoteca: $e');
    }
  }

  // ========================================
  // 🔐 PASSWORD RECOVERY METHODS
  // ========================================

  // Solicitar código de recuperación de contraseña
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🚀 API: Enviando forgot-password para $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código enviado exitosamente',
          'next_step': data['next_step'] ?? 'verify_code',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error enviando código',
        };
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
  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    try {
      print('🔍 API: Verificando código $code para $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código verificado correctamente',
          'next_step': data['next_step'] ?? 'reset_password',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Código inválido o expirado',
        };
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
  static Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      print('🔐 API: Reseteando contraseña para $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña cambiada exitosamente',
          'next_step': data['next_step'] ?? 'login',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error cambiando contraseña',
        };
      }
    } catch (e) {
      print('💥 Error en resetPassword: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // 📧 VERIFICAR EMAIL CON CÓDIGO
  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      print('🔍 API: Verificando email $email con código $code');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Email verificado exitosamente',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Código inválido o expirado',
        };
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
  static Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      print('📧 API: Reenviando código de verificación a $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código reenviado exitosamente',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error reenviando código',
        };
      }
    } catch (e) {
      print('💥 Error en resendVerificationCode: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}

// 🔥 MODELOS DE DATOS

class AuthResponse {
  final UserModel user;
  final ProfileModel? profile;
  final TokenModel? token;

  AuthResponse({
    required this.user,
    this.profile,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      profile: json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null,
      token: json['token'] != null ? TokenModel.fromJson(json['token']) : null,
    );
  }
}

class RegisterResponse {
  final UserModel user;
  final ProfileModel? profile;
  final String message;
  final Map<String, dynamic>? loginCredentials;
  final String redirectTo;

  RegisterResponse({
    required this.user,
    this.profile,
    required this.message,
    this.loginCredentials,
    this.redirectTo = 'login',
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      user: UserModel.fromJson(json['user']),
      profile: json['profile'] != null ? ProfileModel.fromJson(json['profile']) : null,
      message: json['message'],
      loginCredentials: json['login_credentials'],
      redirectTo: json['redirect_to'] ?? 'login',
    );
  }
}

class UserModel {
  final int id;
  final String email;
  final bool isActive;
  final bool isVerified;
  final bool isPremium;
  final bool esAdmin;  // 👑 NUEVO: Campo de admin desde BD
  final DateTime? lastLogin;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.isActive,
    required this.isVerified,
    required this.isPremium,
    required this.esAdmin,  // 👑 NUEVO
    this.lastLogin,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      isActive: json['is_active'],
      isVerified: json['is_verified'],
      isPremium: json['is_premium'],
      esAdmin: json['es_admin'] ?? false,  // 👑 NUEVO: Con fallback a false
      lastLogin: json['last_login'] != null 
          ? DateTime.parse(json['last_login']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ProfileModel {
  final int id;
  final int userId;
  final String nombreCompleto;
  final String? telefono;
  final String? nombreGalpon;
  final String? direccion;
  final String? ciudad;
  final String? ubigeo;
  final String? pais;
  final String? avatarUrl;
  final DateTime? fechaNacimiento;
  final String? biografia;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.nombreCompleto,
    this.telefono,
    this.nombreGalpon,
    this.direccion,
    this.ciudad,
    this.ubigeo,
    this.pais,
    this.avatarUrl,
    this.fechaNacimiento,
    this.biografia,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      userId: json['user_id'],
      nombreCompleto: json['nombre_completo'],
      telefono: json['telefono'],
      nombreGalpon: json['nombre_galpon'],
      direccion: json['direccion'],
      ciudad: json['ciudad'],
      ubigeo: json['ubigeo'],
      pais: json['pais'],
      avatarUrl: json['avatar_url'],
      fechaNacimiento: json['fecha_nacimiento'] != null 
          ? DateTime.parse(json['fecha_nacimiento']) 
          : null,
      biografia: json['biografia'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class TokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
    );
  }
}

class LogoutResponse {
  final String message;
  final bool success;
  final String redirectTo;
  final bool clearSession;

  LogoutResponse({
    required this.message,
    this.success = true,
    this.redirectTo = 'login',
    this.clearSession = true,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      message: json['message'],
      success: json['success'] ?? true,
      redirectTo: json['redirect_to'] ?? 'login',
      clearSession: json['clear_session'] ?? true,
    );
  }
}

class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => message;
}

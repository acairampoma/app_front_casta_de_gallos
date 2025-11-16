// 📁 lib/services/gallo_service_v2.dart
// 🔥 GALLO SERVICE V2 COMPACTO - SOLO 50 LÍNEAS ÉPICAS
// Integración directa con tu backend Railway probado

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class GalloServiceV2 {
  static const String baseUrl = 'https://gallerappback-production.up.railway.app';

  // 🔥 MÉTODO ÉPICO PRINCIPAL - CREAR GALLO CON GENEALOGÍA
  static Future<Map<String, dynamic>> createGalloConGenealogiaEpico({
    required Map<String, dynamic> galloData,
    dynamic foto, // File o XFile (principal)
    List<dynamic>? fotosAdicionales, // Archivos adicionales
  }) async {
    try {
      print('🚀 Iniciando creación épica con genealogía...');
      
      // 1. Crear MultipartRequest
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/gallos/con-pedigri'));
      
      // 2. Agregar JWT token
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('🔑 Token JWT agregado');
      } else {
        print('⚠️ No se encontró token JWT');
      }
      
      // 3. Mapear datos al formato backend
      _buildFormDataEpico(request, galloData);
      
      // 4. Agregar foto principal y adicionales si existen
      if (foto != null) {
        print('📸 Procesando foto principal...');
        await _addFotoToRequest(request, foto);
      } else {
        print('📸 No hay foto principal para subir');
      }
      if (fotosAdicionales != null && fotosAdicionales.isNotEmpty) {
        print('🖼️ Procesando ${fotosAdicionales.length} fotos adicionales...');
        await _addMultipleFotosToRequest(request, fotosAdicionales);
      }
      
      print('📦 Request preparado - Fields: ${request.fields.length}, Files: ${request.files.length}');
      
      // 5. Enviar request
      final streamedResponse = await request.send().timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Response: ${response.statusCode} - ${response.body}');
      
      // 6. Procesar respuesta
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Éxito - Gallo creado con genealogía');
        return {'success': true, 'data': data, 'message': '🎉 Gallo creado exitosamente!'};
      } else {
        final errorData = json.decode(response.body);
        print('❌ Error del servidor: ${errorData['message'] ?? 'Error desconocido'}');
        return {'success': false, 'message': errorData['message'] ?? 'Error del servidor'};
      }
      
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 🔥 MÉTODO ÉPICO - ACTUALIZAR GALLO CON EXPANSIÓN GENEALÓGICA
  static Future<Map<String, dynamic>> updateGalloConExpansionEpico({
    required int galloId,
    required Map<String, dynamic> galloData,
    dynamic foto, // File o XFile - NUEVA FOTO PRINCIPAL (opcional)
    List<dynamic>? fotosAdicionales, // Nuevas fotos adicionales (opcional)
  }) async {
    try {
      print('✏️ Iniciando actualización épica con expansión genealógica...');
      
      // 1. Crear MultipartRequest para PUT
      final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/api/v1/gallos/$galloId'));
      
      // 2. Agregar JWT token
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('🔑 Token JWT agregado');
      } else {
        print('⚠️ No se encontró token JWT');
      }
      
      // 3. Mapear datos actualizados al formato backend
      _buildFormDataEpico(request, galloData);
      
      // 4. Agregar nuevas fotos si existen
      if (foto != null) {
        print('📸 Procesando nueva foto principal...');
        await _addFotoToRequest(request, foto);
      } else {
        print('📸 No hay nueva foto principal para subir');
      }
      if (fotosAdicionales != null && fotosAdicionales.isNotEmpty) {
        print('🖼️ Procesando ${fotosAdicionales.length} fotos adicionales para update...');
        await _addMultipleFotosToRequest(request, fotosAdicionales);
      }
      
      print('📦 Update request preparado - Fields: ${request.fields.length}, Files: ${request.files.length}');
    print('🔍 DEBUG - Campos enviados al backend:');
    request.fields.forEach((key, value) {
      print('  $key: $value');
    });
      
      // 5. Enviar request
      final streamedResponse = await request.send().timeout(Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📡 Response: ${response.statusCode} - ${response.body}');
      
      // 6. Procesar respuesta
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Éxito - Gallo actualizado con expansión genealógica');
        return {'success': true, 'data': data, 'message': '🎉 Gallo actualizado exitosamente!'};
      } else {
        final errorData = json.decode(response.body);
        print('❌ Error del servidor: ${errorData['message'] ?? 'Error desconocido'}');
        return {'success': false, 'message': errorData['message'] ?? 'Error del servidor'};
      }
      
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // 🔑 Helper: Obtener JWT Token
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // 📤 Helper: Construir FormData según backend
  static void _buildFormDataEpico(http.MultipartRequest request, Map<String, dynamic> data) {
    // 🔍 DEBUG: Ver datos de entrada
    print('📊 === DEBUG _buildFormDataEpico ===');
    print('📝 Datos recibidos: ${data.keys.toList()}');
    data.forEach((key, value) {
      print('  $key: $value (${value.runtimeType})');
    });
    
    // OBLIGATORIOS
    request.fields['nombre'] = data['nombre']?.toString() ?? '';
    request.fields['codigo_identificacion'] = data['codigo_identificacion']?.toString() ?? 
        'AUTO_${DateTime.now().millisecondsSinceEpoch}';
    
    // OPCIONALES - Solo agregar si tienen valor
    final optionalFields = {
      'fecha_nacimiento': data['fecha_nacimiento'] is DateTime 
          ? (data['fecha_nacimiento'] as DateTime).toIso8601String().split('T')[0]
          : data['fecha_nacimiento']?.toString(),
      'peso': data['peso']?.toString(),
      'altura': data['altura']?.toString(),
      'color': data['color']?.toString(),
      'raza_id': data['raza_id']?.toString(), // 🔥 CORREGIDO: Enviar raza_id, no raza
      'color_patas': data['color_patas']?.toString(),
      'color_plumaje': data['color_plumaje']?.toString(), // Agregado campo faltante
      'color_placa': data['color_placa']?.toString(),
      'ubicacion_placa': data['ubicacion_placa']?.toString(),
      'criador': data['criador']?.toString(),
      'propietario_actual': data['propietario_actual']?.toString(),
      'observaciones': data['observaciones']?.toString(),
      'notas': data['notas']?.toString(),
      'estado': 'activo',
    };

    // 🔍 DEBUG: Ver campos antes de agregar
    print('🔍 === OPCIONAL FIELDS DEBUG ===');
    optionalFields.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        print('  ✅ $key: $value (agregando)');
        request.fields[key] = value;
      } else {
        print('  ❌ $key: $value (omitiendo)');
      }
    });

    // GENEALOGÍA
    request.fields['crear_padre'] = (data['crear_padre'] == true).toString();
    request.fields['crear_madre'] = (data['crear_madre'] == true).toString();
    
    if (data['crear_padre'] == true && data['padre_nombre']?.toString().isNotEmpty == true) {
      request.fields['padre_nombre'] = data['padre_nombre'].toString();
      if (data['padre_codigo']?.toString().isNotEmpty == true) {
        request.fields['padre_codigo'] = data['padre_codigo'].toString();
      }
      if (data['padre_fecha_nacimiento'] != null) {
        request.fields['padre_fecha_nacimiento'] = data['padre_fecha_nacimiento'] is DateTime
            ? (data['padre_fecha_nacimiento'] as DateTime).toIso8601String().split('T')[0]
            : data['padre_fecha_nacimiento'].toString();
      }
    }
    
    if (data['crear_madre'] == true && data['madre_nombre']?.toString().isNotEmpty == true) {
      request.fields['madre_nombre'] = data['madre_nombre'].toString();
      if (data['madre_codigo']?.toString().isNotEmpty == true) {
        request.fields['madre_codigo'] = data['madre_codigo'].toString();
      }
      if (data['madre_fecha_nacimiento'] != null) {
        request.fields['madre_fecha_nacimiento'] = data['madre_fecha_nacimiento'] is DateTime
            ? (data['madre_fecha_nacimiento'] as DateTime).toIso8601String().split('T')[0]
            : data['madre_fecha_nacimiento'].toString();
      }
    }
    
    // 🔍 DEBUG FINAL: Campos que se van a enviar
    print('🚀 === CAMPOS FINALES AL BACKEND ===');
    request.fields.forEach((key, value) {
      if (key == 'raza_id') {
        print('  🔥 $key: $value (¡CAMPO PROBLEMA!)');
      } else {
        print('  🔑 $key: $value');
      }
    });
    print('==========================================');
  }

  // 📸🔥 NUEVO: Enviar fotos múltiples usando el endpoint especializado /fotos-multiples
  static Future<Map<String, dynamic>> uploadMultipleFotos({
    required int galloId,
    required List<dynamic> fotos, // Máximo 4 fotos: File o XFile
    bool tieneFotoPrincipal = false, // ✅ NUEVO: Indica si la primera foto es la principal
  }) async {
    try {
      // 🚫 VALIDAR LÍMITE ESTRICTO DE 4 FOTOS
      if (fotos.length > 4) {
        return {'success': false, 'message': 'Máximo 4 fotos permitidas. Se enviaron ${fotos.length} fotos.'};
      }

      print('📸 Enviando ${fotos.length} fotos para gallo ID: $galloId');
      print('📸 Tiene foto principal: $tieneFotoPrincipal');

      // 1. Crear MultipartRequest al endpoint correcto
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/v1/gallos/$galloId/fotos-multiples'));

      // 2. Agregar JWT token
      final token = await _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
        print('🔑 Token JWT agregado');
      }

      // 3. Agregar fotos con nombres correctos
      for (int i = 0; i < fotos.length && i < 4; i++) {
        final foto = fotos[i];
        
        // 🔥 LÓGICA MEJORADA: Determinar el nombre del campo
        String fieldName;
        if (tieneFotoPrincipal) {
          // Si tiene foto principal, la primera es foto_1, las demás foto_2, foto_3, foto_4
          fieldName = 'foto_${i + 1}';
        } else {
          // Si NO tiene foto principal, todas son adicionales: foto_2, foto_3, foto_4
          fieldName = 'foto_${i + 2}'; // Empieza desde foto_2
        }

        try {
          if (kIsWeb && foto is XFile) {
            final bytes = await foto.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              fieldName,
              bytes,
              filename: foto.name.isNotEmpty ? foto.name : '$fieldName.jpg',
            ));
          } else if (foto is File) {
            request.files.add(await http.MultipartFile.fromPath(
              fieldName,
              foto.path,
              filename: '$fieldName.jpg',
            ));
          }
          print('✅ Foto agregada como $fieldName');
        } catch (e) {
          print('❌ Error agregando foto $fieldName: $e');
          continue;
        }
      }

      print('📦 Request preparado con ${request.files.length} fotos');

      // 4. Enviar request
      final streamedResponse = await request.send().timeout(Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Response /fotos-multiples: ${response.statusCode}');

      // 5. Procesar respuesta
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data["data"]["fotos_subidas"]} fotos guardadas en fotos_adicionales JSON');
        return {'success': true, 'data': data, 'message': 'Fotos actualizadas exitosamente'};
      } else {
        final errorData = json.decode(response.body);
        print('❌ Error subiendo fotos: ${errorData["detail"] ?? "Error desconocido"}');
        return {'success': false, 'message': errorData["detail"] ?? 'Error del servidor'};
      }

    } catch (e) {
      print('💥 Error en uploadMultipleFotos: $e');
      return {'success': false, 'message': 'Error subiendo fotos: $e'};
    }
  }

  // 📸 Helper: Agregar múltiples fotos adicionales con nombres específicos (foto_2, foto_3, foto_4)
  static Future<void> _addMultipleFotosToRequest(http.MultipartRequest request, List<dynamic> fotos) async {
    // 🚫 VALIDAR LÍMITE DE 3 FOTOS ADICIONALES (foto_2, foto_3, foto_4)
    if (fotos.length > 3) {
      print('⚠️ ADVERTENCIA: Intentando subir ${fotos.length} fotos adicionales, máximo permitido: 3');
      fotos = fotos.take(3).toList(); // Limitar a las primeras 3
    }

    for (int i = 0; i < fotos.length; i++) {
      final foto = fotos[i];
      final fieldName = 'foto_${i + 2}'; // foto_2, foto_3, foto_4

      try {
        if (kIsWeb && foto is XFile) {
          final bytes = await foto.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            fieldName,
            bytes,
            filename: foto.name.isNotEmpty ? foto.name : '${fieldName}.jpg',
          ));
        } else if (foto is File) {
          request.files.add(await http.MultipartFile.fromPath(
            fieldName,
            foto.path,
            filename: '${fieldName}.jpg',
          ));
        }
        print('✅ Foto adicional agregada como $fieldName');
      } catch (e) {
        print('⚠️ Error agregando foto adicional #${i + 2}: $e');
        continue;
      }
    }
    print('✅ Total fotos adicionales agregadas: ${fotos.length}');
  }

  // 📸 Helper: Agregar foto al request
  static Future<void> _addFotoToRequest(http.MultipartRequest request, dynamic foto) async {
    try {
      if (kIsWeb && foto is XFile) {
        // WEB - XFile (blob URL)
        final bytes = await foto.readAsBytes();
        
        // Campo correcto para el backend
        request.files.add(http.MultipartFile.fromBytes(
          'file', // Campo que espera el backend
          bytes, 
          filename: foto.name ?? 'gallo.jpg',
        ));
        
        print('📸 Foto WEB agregada: ${foto.name} (${bytes.length} bytes)');
        
      } else if (foto is File) {
        // MÓVIL - File path
        request.files.add(await http.MultipartFile.fromPath(
          'file', // Campo que espera el backend
          foto.path,
          filename: 'gallo.jpg'
        ));
        print('📸 Foto MÓVIL agregada: ${foto.path}');
      }
      
      print('✅ Foto agregada al request - Total archivos: ${request.files.length}');
      
    } catch (e) {
      print('⚠️ Error agregando foto: $e');
      // No bloquear la creación si falla la foto
    }
  }
}

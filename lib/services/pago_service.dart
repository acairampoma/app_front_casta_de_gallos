// 💳 Servicio de Pagos - QR Yape y Cloudinary
// Compatible con: https://gallerappback-production.up.railway.app

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import '../models/pago_models.dart';

class PagoService {
  static const String baseUrl = 'https://gallerappback-production.up.railway.app';
  
  // 🔑 Headers con JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 🔑 Headers para multipart (sin Content-Type)
  static Future<Map<String, String>> _getMultipartAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      // NO incluir Content-Type para multipart
    };
  }

  // ========================================
  // GENERACIÓN QR YAPE
  // ========================================

  /// 📱 Generar QR para pago con Yape
  static Future<QRYapeResponse> generarQRYape(String planCodigo) async {
    try {
      print('💳 [PagoService] Generando QR para plan: $planCodigo');
      
      final headers = await _getAuthHeaders();
      final body = jsonEncode({'plan_codigo': planCodigo});

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/pagos/generar-qr'),
        headers: headers,
        body: body,
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final qrResponse = QRYapeResponse.fromJson(jsonData);
        
        // Guardar el pago en cache para seguimiento
        await _guardarPagoCache(qrResponse.pagoId, planCodigo);
        
        print('✅ QR generado exitosamente');
        print('🖼️ QR URL: ${qrResponse.qrUrl}');
        print('💰 Monto: ${qrResponse.montoFormateado}');
        
        return qrResponse;
      } else if (response.statusCode == 402) {
        // Plan no encontrado o error de validación
        throw PagoException('Plan no válido o error de validación', response.statusCode);
      } else {
        throw PagoException('Error ${response.statusCode}: ${response.body}', response.statusCode);
      }
    } catch (e) {
      print('❌ Error generando QR: $e');
      rethrow;
    }
  }

  // ========================================
  // CONFIRMACIÓN DE PAGOS
  // ========================================

  /// ✅ Confirmar que el pago fue realizado
  static Future<ConfirmarPagoResponse> confirmarPago({
    required int pagoId,
    String? referenciaYape,
    XFile? comprobanteImagen,
  }) async {
    try {
      print('✅ [PagoService] Confirmando pago ID: $pagoId');
      
      final headers = await _getAuthHeaders();
      
      // Convertir imagen a Base64 si existe
      String? comprobanteBase64;
      if (comprobanteImagen != null) {
        print('📸 Procesando comprobante de imagen...');
        comprobanteBase64 = await _convertirImagenABase64(comprobanteImagen);
        print('✅ Imagen convertida a Base64 (${comprobanteBase64.length} chars)');
      }

      final request = ConfirmarPagoRequest(
        pagoId: pagoId,
        referenciaYape: referenciaYape,
        comprobanteBase64: comprobanteBase64,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/pagos/confirmar'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final confirmacion = ConfirmarPagoResponse.fromJson(jsonData);
        
        // Actualizar cache con estado de confirmación
        await _actualizarEstadoPagoCache(pagoId, 'verificando');
        
        print('✅ Pago confirmado exitosamente');
        print('📝 Mensaje: ${confirmacion.mensaje}');
        
        return confirmacion;
      } else {
        throw PagoException('Error ${response.statusCode}: ${response.body}', response.statusCode);
      }
    } catch (e) {
      print('❌ Error confirmando pago: $e');
      rethrow;
    }
  }

  /// 📸 Subir comprobante como archivo separado
  static Future<String> subirComprobante(int pagoId, XFile imagen) async {
    try {
      print('📸 [PagoService] Subiendo comprobante para pago ID: $pagoId');
      print('📸 [PagoService] Ruta de imagen: ${imagen.path}');
      print('📸 [PagoService] Nombre: ${imagen.name}');

      // 🔍 Validar que el archivo existe
      final file = File(imagen.path);
      if (!await file.exists()) {
        throw PagoException('El archivo de imagen no existe en la ruta especificada', 400);
      }

      // 🔍 Validar tamaño del archivo
      final fileSize = await file.length();
      print('📸 [PagoService] Tamaño del archivo: ${fileSize} bytes');
      if (fileSize > 10 * 1024 * 1024) { // 10MB máximo
        throw PagoException('La imagen es demasiado grande (máximo 10MB)', 400);
      }
      if (fileSize == 0) {
        throw PagoException('El archivo de imagen está vacío', 400);
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw PagoException('Token de autenticación no encontrado', 401);
      }

      // Crear multipart request
      final uri = Uri.parse('$baseUrl/api/v1/pagos/$pagoId/subir-comprobante');
      final request = http.MultipartRequest('POST', uri);

      // ✅ HEADERS CORRECTOS PARA MULTIPART (sin Content-Type)
      final headers = await _getMultipartAuthHeaders();
      request.headers.addAll(headers);
      
      print('📸 [PagoService] Preparando archivo multipart...');

      // 🔍 Detectar tipo MIME basado en extensión
      String? mimeType;
      final extension = imagen.path.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Fallback
      }

      print('📸 [PagoService] Extensión detectada: $extension, MIME: $mimeType');

      // ✅ Crear MultipartFile con tipo MIME explícito
      final multipartFile = await http.MultipartFile.fromPath(
        'comprobante', // Campo esperado por el backend
        imagen.path,
        filename: 'comprobante_${pagoId}_${DateTime.now().millisecondsSinceEpoch}.$extension',
        contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
      );

      request.files.add(multipartFile);
      print('📸 [PagoService] Archivo agregado: ${multipartFile.filename} (${multipartFile.contentType})');

      // Enviar request
      print('📡 [PagoService] Enviando petición multipart...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Status Code: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');
      print('📡 Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final comprobanteUrl = jsonData['comprobante_url'] ?? '';

        print('✅ Comprobante subido exitosamente');
        print('🔗 URL: $comprobanteUrl');

        return comprobanteUrl;
      } else {
        print('❌ [PagoService] Error ${response.statusCode}');
        print('❌ [PagoService] Body: ${response.body}');
        throw PagoException('Error ${response.statusCode}: ${response.body}', response.statusCode);
      }
    } catch (e) {
      print('❌ Error subiendo comprobante: $e');
      rethrow;
    }
  }

  // ========================================
  // CONSULTA DE PAGOS
  // ========================================

  /// 📋 Obtener historial de mis pagos
  static Future<List<PagoPendiente>> obtenerMisPagos({String? estado, int limit = 20}) async {
    try {
      print('📋 [PagoService] Obteniendo mis pagos${estado != null ? ' (estado: $estado)' : ''}');
      
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (estado != null) 'estado': estado,
      };
      
      final uri = Uri.parse('$baseUrl/api/v1/pagos/mis-pagos')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final pagos = jsonList.map((json) => PagoPendiente.fromJson(json)).toList();
        
        print('✅ ${pagos.length} pagos obtenidos');
        return pagos;
      } else {
        throw PagoException('Error ${response.statusCode}: ${response.body}', response.statusCode);
      }
    } catch (e) {
      print('❌ Error obteniendo pagos: $e');
      rethrow;
    }
  }

  /// 🔍 Obtener detalles de un pago específico
  static Future<PagoPendiente> obtenerDetallePago(int pagoId) async {
    try {
      print('🔍 [PagoService] Obteniendo detalle del pago ID: $pagoId');
      
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/pagos/$pagoId'),
        headers: headers,
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final pago = PagoPendiente.fromJson(jsonData);
        
        print('✅ Pago obtenido: ${pago.estado}');
        return pago;
      } else {
        throw PagoException('Error ${response.statusCode}: ${response.body}', response.statusCode);
      }
    } catch (e) {
      print('❌ Error obteniendo detalle de pago: $e');
      rethrow;
    }
  }

  // ========================================
  // POLLING - VERIFICAR ESTADO DE PAGO
  // ========================================

  /// 🔄 Polling para verificar cambios en el estado del pago
  static Stream<PagoPendiente> monitearPago(int pagoId, {Duration intervalo = const Duration(seconds: 30)}) async* {
    while (true) {
      try {
        final pago = await obtenerDetallePago(pagoId);
        yield pago;
        
        // Si el pago ya fue aprobado o rechazado, detener polling
        if (pago.estaAprobado || pago.estaRechazado) {
          break;
        }
        
        await Future.delayed(intervalo);
      } catch (e) {
        print('⚠️ Error en polling de pago: $e');
        await Future.delayed(intervalo);
      }
    }
  }

  // ========================================
  // UTILIDADES PRIVADAS
  // ========================================

  /// 📸 Convertir imagen a Base64
  static Future<String> _convertirImagenABase64(XFile imagen) async {
    try {
      final bytes = await imagen.readAsBytes();
      
      // Comprimir si es muy grande (más de 1MB)
      Uint8List processedBytes = bytes;
      if (bytes.length > 1024 * 1024) {
        print('⚠️ Imagen muy grande (${bytes.length} bytes), comprimiendo...');
        // Aquí podrías agregar lógica de compresión
        // Por ahora solo truncamos
        processedBytes = Uint8List.fromList(bytes.take(1024 * 1024).toList());
      }
      
      final base64String = base64Encode(processedBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('❌ Error convirtiendo imagen a Base64: $e');
      rethrow;
    }
  }

  /// 💾 Guardar pago en cache local
  static Future<void> _guardarPagoCache(int pagoId, String planCodigo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagoData = {
        'pago_id': pagoId,
        'plan_codigo': planCodigo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('ultimo_pago', jsonEncode(pagoData));
    } catch (e) {
      print('⚠️ Error guardando cache de pago: $e');
    }
  }

  /// 🔄 Actualizar estado de pago en cache
  static Future<void> _actualizarEstadoPagoCache(int pagoId, String estado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagoJson = prefs.getString('ultimo_pago');
      
      if (pagoJson != null) {
        final pagoData = jsonDecode(pagoJson);
        if (pagoData['pago_id'] == pagoId) {
          pagoData['estado'] = estado;
          pagoData['updated'] = DateTime.now().toIso8601String();
          await prefs.setString('ultimo_pago', jsonEncode(pagoData));
        }
      }
    } catch (e) {
      print('⚠️ Error actualizando cache de pago: $e');
    }
  }

  /// 📱 Obtener último pago desde cache
  static Future<Map<String, dynamic>?> obtenerUltimoPagoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pagoJson = prefs.getString('ultimo_pago');
      
      if (pagoJson != null) {
        return jsonDecode(pagoJson);
      }
      return null;
    } catch (e) {
      print('⚠️ Error obteniendo cache de pago: $e');
      return null;
    }
  }

  // ========================================
  // VALIDACIONES Y UTILIDADES
  // ========================================

  /// 💰 Validar monto para Yape (límites reales)
  static bool validarMontoYape(double monto) {
    return monto >= 1.0 && monto <= 500.0;
  }

  /// 📱 Detectar si Yape está instalado
  static Future<bool> yapaEstaInstalado() async {
    // En una implementación real, usarías url_launcher para detectar
    // si el esquema yape:// es soportado
    return true; // Por ahora asumimos que sí
  }

  /// 🔗 Abrir Yape con datos del QR
  static Future<void> abrirYape(String qrData) async {
    try {
      // En una implementación real, usarías url_launcher
      // await launch(qrData);
      print('📱 Abriendo Yape con: $qrData');
    } catch (e) {
      print('❌ Error abriendo Yape: $e');
      throw PagoException('No se pudo abrir Yape', 0);
    }
  }
}

// ========================================
// EXCEPCIONES PERSONALIZADAS
// ========================================

class PagoException implements Exception {
  final String message;
  final int? statusCode;

  PagoException(this.message, [this.statusCode]);

  @override
  String toString() => 'PagoException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';

  /// Es un error de límite alcanzado
  bool get esLimiteAlcanzado => statusCode == 402;

  /// Es un error de autenticación
  bool get esErrorAuth => statusCode == 401;

  /// Es un error de servidor
  bool get esErrorServidor => statusCode != null && statusCode! >= 500;
}
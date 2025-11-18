// 💳 Servicio de Mercado Pago - Frontend
// Integración con API de Mercado Pago

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MercadoPagoService {
  static const String baseUrl = 'https://gallerappback-production.up.railway.app';

  // 🔑 Headers con JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json; charset=utf-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 💳 Crear preferencia de pago
  static Future<Map<String, dynamic>> crearPreferenciaPago(
    String planCodigo,
  ) async {
    try {
      print('💳 [MercadoPagoService] Creando preferencia para plan: $planCodigo');

      final headers = await _getAuthHeaders();
      final body = jsonEncode({'plan_codigo': planCodigo});

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/mercadopago/crear-preferencia'),
        headers: headers,
        body: body,
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('✅ Preferencia creada exitosamente');
        return jsonData;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error creando preferencia: $e');
      rethrow;
    }
  }

  /// 📊 Obtener estado de un pago
  static Future<Map<String, dynamic>> obtenerEstadoPago(
    String paymentId,
  ) async {
    try {
      print('📊 [MercadoPagoService] Obteniendo estado del pago: $paymentId');

      final headers = await _getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/mercadopago/pago/$paymentId'),
        headers: headers,
      );

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('✅ Estado del pago obtenido');
        return jsonData;
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error obteniendo estado del pago: $e');
      rethrow;
    }
  }

  /// 📱 Pagar con Yape usando Mercado Pago
  static Future<Map<String, dynamic>> pagarConYape({
    required String numeroTelefono,
    required String otp,
    required String planCodigo,
    required double monto,
  }) async {
    try {
      print('📱 [MercadoPagoService] Procesando pago con Yape');
      print('   Teléfono: $numeroTelefono');
      print('   Plan: $planCodigo');
      print('   Monto: S/. $monto');

      final headers = await _getAuthHeaders();
      final body = jsonEncode({
        'numero_telefono': numeroTelefono,
        'otp': otp,
        'plan_codigo': planCodigo,
        'monto': monto,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/mercadopago/pagar-con-yape'),
        headers: headers,
        body: body,
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body);
        print('✅ Pago con Yape procesado exitosamente');
        return jsonData;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error procesando pago con Yape');
      }
    } catch (e) {
      print('❌ Error procesando pago con Yape: $e');
      rethrow;
    }
  }
}

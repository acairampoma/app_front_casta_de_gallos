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

  /// 📱 Crear preferencia de pago con Yape
  static Future<Map<String, dynamic>> crearPreferenciaYape({
    required String planCodigo,
  }) async {
    try {
      print('📱 [MercadoPagoService] Creando preferencia de pago con Yape');
      print('   Plan: $planCodigo');

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/mercadopago/pagar-con-yape?plan_codigo=$planCodigo'),
        headers: await _getAuthHeaders(),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Preferencia de Yape creada exitosamente');
        print('🔗 Init Point: ${data['init_point']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error creando preferencia de Yape');
      }
    } catch (e) {
      print('❌ Error creando preferencia de Yape: $e');
      rethrow;
    }
  }
}

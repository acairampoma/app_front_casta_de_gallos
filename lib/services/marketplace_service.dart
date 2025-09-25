import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class MarketplaceService {
  final String baseUrl;
  MarketplaceService({String? baseUrl}) : baseUrl = baseUrl ?? Constants.baseApiUrl;

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    // Decodificar JWT para obtener user ID
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      return int.tryParse(payloadMap['sub']?.toString() ?? '');
    } catch (e) {
      print('❌ Error decodificando token: $e');
      return null;
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    });
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    print('🔍 _extractList recibió: ${body.runtimeType}');

    if (body is Map) {
      // Estructura Railway: {success: true, data: {publicaciones: [...]}}
      if (body['data'] is Map && body['data']['publicaciones'] is List) {
        final extracted = List<Map<String, dynamic>>.from(body['data']['publicaciones']);
        print('✅ Extraído desde data.publicaciones: ${extracted.length} elementos');
        return extracted;
      }
      // Estructura favoritos: {success: true, data: {favoritos: [{publicacion: {...}}]}}
      if (body['data'] is Map && body['data']['favoritos'] is List) {
        final favoritos = body['data']['favoritos'] as List;
        final extracted = favoritos.map((fav) {
          if (fav is Map && fav['publicacion'] is Map) {
            return fav['publicacion'] as Map<String, dynamic>;
          }
          return fav as Map<String, dynamic>;
        }).toList();
        print('✅ Extraído desde data.favoritos: ${extracted.length} elementos');
        return extracted;
      }
      // Estructura simple: {data: [...]}
      if (body['data'] is List) {
        final extracted = List<Map<String, dynamic>>.from(body['data']);
        print('✅ Extraído desde data: ${extracted.length} elementos');
        return extracted;
      }
      // Estructura directa: {items: [...]}
      if (body['items'] is List) {
        final extracted = List<Map<String, dynamic>>.from(body['items']);
        print('✅ Extraído desde items: ${extracted.length} elementos');
        return extracted;
      }
      // Estructura directa: {publicaciones: [...]}
      if (body['publicaciones'] is List) {
        final extracted = List<Map<String, dynamic>>.from(body['publicaciones']);
        print('✅ Extraído desde publicaciones: ${extracted.length} elementos');
        return extracted;
      }
      // Estructura directa: {favoritos: [...]}
      if (body['favoritos'] is List) {
        final favoritos = body['favoritos'] as List;
        final extracted = favoritos.map((fav) {
          if (fav is Map && fav['publicacion'] is Map) {
            return fav['publicacion'] as Map<String, dynamic>;
          }
          return fav as Map<String, dynamic>;
        }).toList();
        print('✅ Extraído desde favoritos: ${extracted.length} elementos');
        return extracted;
      }
      print('❌ No se encontró estructura conocida en Map: ${body.keys}');
    }
    if (body is List) {
      final extracted = List<Map<String, dynamic>>.from(body);
      print('✅ Extraído desde List directa: ${extracted.length} elementos');
      return extracted;
    }

    print('❌ No se pudo extraer lista de: ${body.runtimeType}');
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getPublicaciones({
    Map<String, dynamic>? filtros,
    int page = 1,
    int pageSize = 20,
  }) async {
    print('🔥 === MARKETPLACE SERVICE - OBTENIENDO PUBLICACIONES ===');
    print('🌐 Conectando a Railway backend...');

    final headers = await _authHeaders();
    // Probemos diferentes endpoints posibles en tu backend
    final uri = _buildUri('/marketplace/publicaciones', query: {
      'page': page,
      'page_size': pageSize,
      if (filtros != null) ...filtros,
    });
    // Alternativas que podríamos probar:
    // '/publicaciones'
    // '/marketplace'
    // '/api/marketplace/publicaciones'

    print('🔑 Token presente: ${headers['Authorization'] != null ? "SÍ" : "NO"}');
    print('🔍 Llamando: $uri');

    final res = await http.get(uri, headers: headers);

    print('📡 Status: ${res.statusCode}');
    print('📝 Response Body: ${res.body.length > 500 ? res.body.substring(0, 500) + "..." : res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      print('📊 JSON parseado exitosamente');
      final extracted = _extractList(data);
      print('✅ === PUBLICACIONES EXTRAÍDAS: ${extracted.length} ===');
      return extracted;
    } else {
      print('❌ Error ${res.statusCode}: ${res.body}');
      throw Exception('Error obteniendo publicaciones (${res.statusCode}): ${res.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getFavoritos({int page = 1, int pageSize = 20}) async {
    print('🔥 === MARKETPLACE SERVICE - OBTENIENDO FAVORITOS ===');

    final headers = await _authHeaders();
    final uri = _buildUri('/marketplace/favoritos', query: {
      'page': page,
      'page_size': pageSize,
    });

    print('🔍 Llamando: $uri');
    final res = await http.get(uri, headers: headers);

    print('📡 Status: ${res.statusCode}');
    print('📝 Response Body: ${res.body.length > 500 ? res.body.substring(0, 500) + "..." : res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final extracted = _extractList(data);
      print('✅ === FAVORITOS EXTRAÍDOS: ${extracted.length} ===');
      return extracted;
    }
    print('❌ Error ${res.statusCode}: ${res.body}');
    throw Exception('Error obteniendo favoritos (${res.statusCode}): ${res.body}');
  }

  Future<List<Map<String, dynamic>>> getMisPublicaciones({int page = 1, int pageSize = 20}) async {
    print('🔥 === MARKETPLACE SERVICE - OBTENIENDO MIS PUBLICACIONES ===');

    final headers = await _authHeaders();
    final uri = _buildUri('/marketplace/mis-publicaciones', query: {
      'page': page,
      'page_size': pageSize,
    });

    print('🔍 Llamando: $uri');
    final res = await http.get(uri, headers: headers);

    print('📡 Status: ${res.statusCode}');
    print('📝 Response Body: ${res.body.length > 500 ? res.body.substring(0, 500) + "..." : res.body}');

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final extracted = _extractList(data);
      print('✅ === MIS PUBLICACIONES EXTRAÍDAS: ${extracted.length} ===');
      return extracted;
    }
    print('❌ Error ${res.statusCode}: ${res.body}');
    throw Exception('Error obteniendo mis publicaciones (${res.statusCode}): ${res.body}');
  }

  Future<Map<String, dynamic>> crearPublicacion({
    required int galloId,
    required double precio,
    String? descripcion,
  }) async {
    print('🔥 === CREANDO PUBLICACIÓN ===');
    print('🐓 Gallo ID: $galloId');
    print('💰 Precio: $precio');
    print('📝 Descripción: ${descripcion ?? 'ninguna'}');

    final headers = await _authHeaders();
    final uri = _buildUri('/marketplace/publicaciones');

    final body = {
      'gallo_id': galloId,
      'precio': precio,
      if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
    };

    print('🔍 Llamando POST: $uri');
    print('📦 Body: ${json.encode(body)}');
    print('🔑 Headers: $headers');

    final res = await http.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    print('📡 Status: ${res.statusCode}');
    print('📝 Response: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    throw Exception('Error creando publicación (${res.statusCode}): ${res.body}');
  }

  Future<Map<String, dynamic>> toggleFavorito(int publicacionId) async {
    print('🔥 === TOGGLE FAVORITO ===');
    print('📝 Publicación ID: $publicacionId');

    final headers = await _authHeaders();
    final uri = _buildUri('/marketplace/publicaciones/$publicacionId/favorito');

    print('🔍 Llamando POST: $uri');

    final res = await http.post(uri, headers: headers);

    print('📡 Status: ${res.statusCode}');
    print('📝 Response: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final response = json.decode(res.body);
      print('🔥 Respuesta parseada: ${response.toString()}');

      // El backend devuelve la estructura: {success: true, data: {es_favorito: true}}
      final success = response['success'] ?? false;
      final data = response['data'] ?? {};
      final esFavorito = data['es_favorito'] ?? data['is_favorite'] ?? false;

      print('🔥 Success: $success, EsFavorito: $esFavorito');

      return {
        'success': success,
        'is_favorite': esFavorito,
        'message': response['message'] ?? 'Favorito actualizado'
      };
    }
    throw Exception('Error toggle favorito (${res.statusCode}): ${res.body}');
  }

  Future<Map<String, dynamic>> actualizarPublicacion(
    int publicacionId, {
    double? precio,
    String? estado,
  }) async {
    print('🔥 === ACTUALIZAR PUBLICACIÓN ===');
    print('📝 Publicación ID: $publicacionId');
    print('💰 Nuevo precio: ${precio ?? "sin cambios"}');
    print('📊 Nuevo estado: ${estado ?? "sin cambios"}');

    final headers = await _authHeaders();
    final uri = _buildUri('/marketplace/publicaciones/$publicacionId');

    final body = <String, dynamic>{};
    if (precio != null) body['precio'] = precio;
    if (estado != null) body['estado'] = estado;

    print('🔍 Llamando PUT: $uri');
    print('📦 Body: ${json.encode(body)}');

    final res = await http.put(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    print('📡 Status: ${res.statusCode}');
    print('📝 Response: ${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    throw Exception('Error actualizando publicación (${res.statusCode}): ${res.body}');
  }
}

class Publicacion {
  final int id;
  final int? userId;
  final String nombre;
  final String raza;
  final double precio;
  final bool esFavorito;
  final List<String> fotos;
  // Detalles del gallo
  final String? codigoIdentificacion;
  final String? fechaNacimiento;
  final double? peso;
  final int? altura;
  final String? color;
  final String? colorPatas;
  final String? colorPlumaje;
  final String? observaciones;
  // Vendedor / propietario
  final String? vendedorNombre;
  final String? vendedorTelefono;
  final String? vendedorEmail;
  final String? vendedorUbicacion;

  Publicacion({
    required this.id,
    this.userId,
    required this.nombre,
    required this.raza,
    required this.precio,
    required this.esFavorito,
    required this.fotos,
    this.codigoIdentificacion,
    this.fechaNacimiento,
    this.peso,
    this.altura,
    this.color,
    this.colorPatas,
    this.colorPlumaje,
    this.observaciones,
    this.vendedorNombre,
    this.vendedorTelefono,
    this.vendedorEmail,
    this.vendedorUbicacion,
  });

  factory Publicacion.fromJson(Map<String, dynamic> json) {
    print('🔥 PARSING PUBLICACION: ${json.toString()}');

    // Railway backend usa 'gallo_info' en lugar de 'gallo'
    final gallo = json['gallo_info'] ?? json['gallo'] ?? {};
    print('🐓 Gallo data: ${gallo.toString()}');
    print('🔍 Buscando fotos en: fotos_adicionales=${gallo['fotos_adicionales']}, foto_principal_url=${gallo['foto_principal_url']}');

    double? toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
    int? toInt(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

    // Manejo mejorado de fotos - Railway backend usa 'fotos_adicionales'
    List<String> fotosList = [];

    if (gallo is Map && gallo['fotos_adicionales'] is List) {
      // Railway: fotos_adicionales es array de objetos {url: "..."}
      fotosList = (gallo['fotos_adicionales'] as List)
          .map((foto) => foto is Map ? (foto['url']?.toString() ?? '') : foto.toString())
          .where((url) => url.isNotEmpty)
          .toList().cast<String>();
    } else if (gallo is Map && gallo['fotos'] is List) {
      // Estructura legacy: fotos como array simple
      fotosList = List<String>.from((gallo['fotos'] as List).map((e) => e.toString()));
    } else if (json['fotos'] is List) {
      // Fotos directamente en json
      fotosList = List<String>.from((json['fotos'] as List).map((e) => e.toString()));
    }

    // Si no hay fotos_adicionales, buscar foto_principal_url (para favoritos)
    if (fotosList.isEmpty && gallo is Map && gallo['foto_principal_url'] != null) {
      final fotoPrincipal = gallo['foto_principal_url'].toString();
      if (fotoPrincipal.isNotEmpty && fotoPrincipal != 'null') {
        fotosList = [fotoPrincipal];
      }
    }

    // Si aún no hay fotos, buscar en el nivel raíz
    if (fotosList.isEmpty && json['foto_principal_url'] != null) {
      final fotoPrincipal = json['foto_principal_url'].toString();
      if (fotoPrincipal.isNotEmpty && fotoPrincipal != 'null') {
        fotosList = [fotoPrincipal];
      }
    }

    print('📷 Fotos encontradas: ${fotosList.length} - ${fotosList.take(2).toList()}');

    // Vendedor data - mejorado para backend Railway
    String? vNombre;
    String? vTelefono;
    String? vEmail;
    String? vUbicacion;

    final vendedor = json['vendedor_info'] ?? json['vendedor'] ?? json['propietario'] ?? json['owner'];
    if (vendedor is Map) {
      vNombre = (vendedor['nombre'] ?? vendedor['nombre_completo'] ?? vendedor['owner_name'])?.toString();
      vTelefono = (vendedor['telefono'] ?? vendedor['phone'] ?? vendedor['celular'])?.toString();
      vEmail = (vendedor['email'] ?? vendedor['correo'])?.toString();
      vUbicacion = (vendedor['ubicacion'] ?? vendedor['ciudad'])?.toString();
    } else {
      // Si no hay vendedor_info, usar valores por defecto para favoritos
      vNombre = 'Vendedor';
      vTelefono = '';
      vEmail = '';
      vUbicacion = '';
    }

    // Manejo de raza mejorado para Railway backend
    String raza = '';
    if (gallo is Map) {
      if (gallo['raza_nombre'] != null) {
        raza = gallo['raza_nombre'].toString();
      } else if (gallo['raza'] is Map) {
        raza = gallo['raza']['nombre']?.toString() ?? '';
      } else if (gallo['raza_id'] != null) {
        raza = gallo['raza_id'].toString().replaceAll('_', ' ');
      }
    } else if (json['raza'] != null) {
      raza = json['raza'].toString();
    }

    print('🏷️ Raza identificada: "$raza"');

    // Debug de toda la estructura
    print('🔍 JSON COMPLETO KEYS: ${json.keys.toList()}');
    if (gallo is Map) {
      print('🔍 GALLO KEYS: ${gallo.keys.toList()}');
    }

    // Los datos completos pueden venir de dos formas:
    // 1. Desde endpoint /publicaciones: dentro de gallo_info
    // 2. Desde otros endpoints: muy limitados

    // Buscar campos de color y datos completos en diferentes ubicaciones
    String? color;
    String? colorPatas;
    String? colorPlumaje;
    double? peso;
    int? altura;

    if (gallo is Map) {
      // Si gallo tiene los campos directamente
      color = gallo['color']?.toString() ?? gallo['color_placa']?.toString();
      colorPatas = gallo['color_patas']?.toString();
      colorPlumaje = gallo['color_plumaje']?.toString();
      peso = toDouble(gallo['peso']);
      altura = toInt(gallo['altura']);
    }

    // Fallback: intentar obtener desde JSON raíz si no están en gallo_info
    if (color == null) color = json['color']?.toString();
    if (colorPatas == null) colorPatas = json['color_patas']?.toString();
    if (colorPlumaje == null) colorPlumaje = json['color_plumaje']?.toString();
    if (peso == null) peso = toDouble(json['peso']);
    if (altura == null) altura = toInt(json['altura']);

    print('🎨 COLORES Y DATOS ENCONTRADOS:');
    print('   - color: $color');
    print('   - color_patas: $colorPatas');
    print('   - color_plumaje: $colorPlumaje');
    print('   - peso: $peso');
    print('   - altura: $altura');

    final publicacion = Publicacion(
      id: toInt(json['id']) ?? 0,
      userId: toInt(json['user_id'] ?? json['userId']),
      nombre: gallo is Map ? (gallo['nombre']?.toString() ?? 'Gallo sin nombre') : (json['nombre']?.toString() ?? 'Gallo sin nombre'),
      raza: raza,
      precio: toDouble(json['precio']) ?? 0.0,
      esFavorito: json['es_favorito'] == true || json['is_favorite'] == true,
      fotos: fotosList,
      codigoIdentificacion: gallo is Map ? gallo['codigo_identificacion']?.toString() : json['codigo_identificacion']?.toString(),
      fechaNacimiento: gallo is Map ? gallo['fecha_nacimiento']?.toString() : json['fecha_nacimiento']?.toString(),
      peso: peso,
      altura: altura,
      color: color,
      colorPatas: colorPatas,
      colorPlumaje: colorPlumaje,
      observaciones: (gallo is Map ? gallo['observaciones'] : json['descripcion'])?.toString(),
      vendedorNombre: vNombre,
      vendedorTelefono: vTelefono,
      vendedorEmail: vEmail,
      vendedorUbicacion: vUbicacion,
    );

    print('✅ PUBLICACION CREADA: ID=${publicacion.id}, UserId=${publicacion.userId}, Nombre=${publicacion.nombre}, Precio=${publicacion.precio}');
    print('🎨 COLORES ASIGNADOS: color="${publicacion.color}", colorPatas="${publicacion.colorPatas}", colorPlumaje="${publicacion.colorPlumaje}"');
    return publicacion;
  }
}

// 📋 Modelos para Sistema de Suscripciones - NUEVOS
// Compatible con API Railway: https://gallerappback-production.up.railway.app

import 'dart:convert';
import 'pago_models.dart';

// ========================================
// MODELO DE SUSCRIPCION ACTUAL
// ========================================

class Suscripcion {
  final int id;
  final int userId;
  final String planType;
  final String planName;
  final double precio;
  final String status;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int gallosMaximo;
  final int topesPorGallo;
  final int peleasPorGallo;
  final int vacunasPorGallo;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Campos calculados
  final int? diasRestantes;
  final bool estaActiva;
  final bool esPremium;
  
  // 🔄 NUEVO: Pago pendiente
  final PagoPendienteInfo? pagoPendiente;

  Suscripcion({
    required this.id,
    required this.userId,
    required this.planType,
    required this.planName,
    required this.precio,
    required this.status,
    this.fechaInicio,
    this.fechaFin,
    required this.gallosMaximo,
    required this.topesPorGallo,
    required this.peleasPorGallo,
    required this.vacunasPorGallo,
    required this.createdAt,
    required this.updatedAt,
    this.diasRestantes,
    this.estaActiva = true,
    this.esPremium = false,
    this.pagoPendiente,
  });

  factory Suscripcion.fromJson(Map<String, dynamic> json) {
    return Suscripcion(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      planType: json['plan_type'] ?? 'gratuito',
      planName: json['plan_name'] ?? 'Plan Gratuito',
      precio: _parseDouble(json['precio']),
      status: json['status'] ?? 'active',
      fechaInicio: json['fecha_inicio'] != null 
          ? DateTime.parse(json['fecha_inicio']) 
          : null,
      fechaFin: json['fecha_fin'] != null 
          ? DateTime.parse(json['fecha_fin']) 
          : null,
      gallosMaximo: json['gallos_maximo'] ?? 5,
      topesPorGallo: json['topes_por_gallo'] ?? 2,
      peleasPorGallo: json['peleas_por_gallo'] ?? 2,
      vacunasPorGallo: json['vacunas_por_gallo'] ?? 2,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      diasRestantes: json['dias_restantes'],
      estaActiva: json['esta_activa'] ?? true,
      esPremium: json['es_premium'] ?? false,
      pagoPendiente: json['pago_pendiente'] != null 
          ? PagoPendienteInfo.fromJson(json['pago_pendiente'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_type': planType,
      'plan_name': planName,
      'precio': precio,
      'status': status,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'gallos_maximo': gallosMaximo,
      'topes_por_gallo': topesPorGallo,
      'peleas_por_gallo': peleasPorGallo,
      'vacunas_por_gallo': vacunasPorGallo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 🔧 Helper para parsear precio que puede venir como string o double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Indica si es plan premium
  bool get esGratuito => planType == 'gratuito';
  bool get esBasico => planType == 'basico';
  bool get esPremiumPlan => planType == 'premium';
  bool get esProfesional => planType == 'profesional';

  /// Color del badge según el plan
  String get colorPlan {
    switch (planType) {
      case 'gratuito': return '#95a5a6';  // Gris
      case 'basico': return '#3498db';    // Azul
      case 'premium': return '#e74c3c';   // Rojo
      case 'profesional': return '#f39c12'; // Dorado
      default: return '#95a5a6';
    }
  }

  /// Icono del plan
  String get iconoPlan {
    switch (planType) {
      case 'gratuito': return '🆓';
      case 'basico': return '⭐';
      case 'premium': return '💎';
      case 'profesional': return '👑';
      default: return '📋';
    }
  }
}

// ========================================
// MODELO DE PLAN DEL CATÁLOGO
// ========================================

class PlanCatalogo {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int duracionDias;
  final int gallosMaximo;
  final int topesPorGallo;
  final int peleasPorGallo;
  final int vacunasPorGallo;
  final int? marketplacePublicacionesMax;
  final bool soportePremium;
  final bool respaldoNube;
  final bool estadisticasAvanzadas;
  final bool videosIlimitados;
  final bool activo;
  final int orden;
  final bool destacado;
  final int? duracionSemanas;
  final List<String> caracteristicas;

  PlanCatalogo({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.duracionDias,
    required this.gallosMaximo,
    required this.topesPorGallo,
    required this.peleasPorGallo,
    required this.vacunasPorGallo,
    this.marketplacePublicacionesMax,
    this.soportePremium = false,
    this.respaldoNube = false,
    this.estadisticasAvanzadas = false,
    this.videosIlimitados = false,
    this.activo = true,
    this.orden = 0,
    this.destacado = false,
    this.duracionSemanas,
    this.caracteristicas = const [],
  });

  // ✅ Helper para determinar si es popular
  bool get esPopular => destacado;

  factory PlanCatalogo.fromJson(Map<String, dynamic> json) {
    return PlanCatalogo(
      id: json['id'] ?? 0,
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      precio: PlanCatalogo._parseDouble(json['precio']),
      duracionDias: json['duracion_dias'] ?? 30,
      gallosMaximo: json['gallos_maximo'] ?? 5,
      topesPorGallo: json['topes_por_gallo'] ?? 2,
      peleasPorGallo: json['peleas_por_gallo'] ?? 2,
      vacunasPorGallo: json['vacunas_por_gallo'] ?? 2,
      marketplacePublicacionesMax: json['marketplace_publicaciones_max'],
      soportePremium: json['soporte_premium'] ?? false,
      respaldoNube: json['respaldo_nube'] ?? false,
      estadisticasAvanzadas: json['estadisticas_avanzadas'] ?? false,
      videosIlimitados: json['videos_ilimitados'] ?? false,
      activo: json['activo'] ?? true,
      orden: json['orden'] ?? 0,
      destacado: json['destacado'] ?? false,
      duracionSemanas: json['duracion_semanas'],
      caracteristicas: json['caracteristicas'] != null
          ? List<String>.from(json['caracteristicas'])
          : [],
    );
  }

  /// Precio formateado con moneda
  String get precioFormateado {
    if (precio == 0) return 'Gratis';
    return 'S/. ${precio.toStringAsFixed(2)}';
  }

  // 🔧 Helper para parsear precio que puede venir como string o double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Es el plan más caro
  bool get esPlanProfesional => codigo == 'profesional';

  /// ✅ Duración de streaming basada en duracionSemanas de la BD
  String get duracionStreaming {
    if (duracionSemanas == null || duracionSemanas == 0) {
      return 'No incluido';
    } else if (duracionSemanas == 1) {
      return '1 semana';
    } else if (duracionSemanas! < 4) {
      return '$duracionSemanas semanas';
    } else {
      final meses = (duracionSemanas! / 4).round();
      return meses == 1 ? '1 mes' : '$meses meses';
    }
  }

  /// ✅ Color de la tarjeta según el plan
  String get colorTarjeta {
    switch (codigo) {
      case 'gratuito': return '#ecf0f1';   // Gris claro
      case 'basico': return '#e3f2fd';     // Azul claro
      case 'premium': return '#ffebee';    // Rojo claro
      case 'profesional': return '#fff8e1'; // Dorado claro
      default: return '#f5f5f5';
    }
  }
}

// ========================================
// MODELO DE LÍMITES DE USUARIO
// ========================================

class EstadoLimites {
  final int userId;
  final String planActual;
  final bool suscripcionActiva;
  final DateTime? fechaVencimiento;
  final LimiteRecurso gallos;
  final Map<int, LimiteRecurso>? topesPorGallo;
  final Map<int, LimiteRecurso>? peleasPorGallo;
  final Map<int, LimiteRecurso>? vacunasPorGallo;
  final bool tieneLimitesSuperados;
  final List<String> recursosEnLimite;

  EstadoLimites({
    required this.userId,
    required this.planActual,
    required this.suscripcionActiva,
    this.fechaVencimiento,
    required this.gallos,
    this.topesPorGallo,
    this.peleasPorGallo,
    this.vacunasPorGallo,
    this.tieneLimitesSuperados = false,
    this.recursosEnLimite = const [],
  });

  factory EstadoLimites.fromJson(Map<String, dynamic> json) {
    return EstadoLimites(
      userId: json['user_id'] ?? 0,
      planActual: json['plan_actual'] ?? 'gratuito',
      suscripcionActiva: json['suscripcion_activa'] ?? true,
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.parse(json['fecha_vencimiento'])
          : null,
      gallos: LimiteRecurso.fromJson(json['gallos'] ?? {}),
      tieneLimitesSuperados: json['tiene_limites_superados'] ?? false,
      recursosEnLimite: json['recursos_en_limite'] != null
          ? List<String>.from(json['recursos_en_limite'])
          : [],
    );
  }
}

class LimiteRecurso {
  final String tipo;
  final int limite;
  final int usado;

  LimiteRecurso({
    required this.tipo,
    required this.limite,
    required this.usado,
  });

  factory LimiteRecurso.fromJson(Map<String, dynamic> json) {
    return LimiteRecurso(
      tipo: json['tipo'] ?? '',
      limite: json['limite'] ?? 0,
      usado: json['usado'] ?? 0,
    );
  }

  /// Porcentaje usado (0.0 a 1.0)
  double get porcentajeUsado {
    if (limite == 0) return 0.0;
    return (usado / limite).clamp(0.0, 1.0);
  }

  /// Puede crear más recursos
  bool get puedeCrear => usado < limite;

  /// Recursos disponibles
  int get disponibles => (limite - usado).clamp(0, limite);

  /// Color del progreso según el uso
  String get colorProgreso {
    final porcentaje = porcentajeUsado;
    if (porcentaje >= 0.9) return '#e74c3c'; // Rojo (90%+)
    if (porcentaje >= 0.7) return '#f39c12'; // Amarillo (70%+)
    return '#27ae60'; // Verde (menos del 70%)
  }
}

// ========================================
// MODELO DE VALIDACIÓN DE LÍMITE
// ========================================

class ValidacionLimite {
  final bool puedeCrear;
  final String recursoTipo;
  final int limiteActual;
  final int cantidadUsada;
  final int? galloId;
  final String? mensajeError;
  final String? planRecomendado;
  final bool upgradeDisponible;

  ValidacionLimite({
    required this.puedeCrear,
    required this.recursoTipo,
    required this.limiteActual,
    required this.cantidadUsada,
    this.galloId,
    this.mensajeError,
    this.planRecomendado,
    this.upgradeDisponible = true,
  });

  factory ValidacionLimite.fromJson(Map<String, dynamic> json) {
    return ValidacionLimite(
      puedeCrear: json['puede_crear'] ?? false,
      recursoTipo: json['recurso_tipo'] ?? '',
      limiteActual: json['limite_actual'] ?? 0,
      cantidadUsada: json['cantidad_usada'] ?? 0,
      galloId: json['gallo_id'],
      mensajeError: json['mensaje_error'],
      planRecomendado: json['plan_recomendado'],
      upgradeDisponible: json['upgrade_disponible'] ?? true,
    );
  }
}

// ========================================
// TIPOS DE RECURSO
// ========================================

enum RecursoTipo {
  gallos('gallos'),
  topes('topes'),
  peleas('peleas'),
  vacunas('vacunas');

  const RecursoTipo(this.value);
  final String value;

  String get nombre {
    switch (this) {
      case RecursoTipo.gallos: return 'Gallos';
      case RecursoTipo.topes: return 'Entrenamientos';
      case RecursoTipo.peleas: return 'Peleas';
      case RecursoTipo.vacunas: return 'Vacunas';
    }
  }

  String get icono {
    switch (this) {
      case RecursoTipo.gallos: return '🐓';
      case RecursoTipo.topes: return '🏋️';
      case RecursoTipo.peleas: return '🥊';
      case RecursoTipo.vacunas: return '💉';
    }
  }
}

// ========================================
// MODELO DE SOLICITUD DE VALIDACIÓN
// ========================================

class ValidacionLimiteRequest {
  final String recursoTipo;
  final int? galloId;

  ValidacionLimiteRequest({
    required this.recursoTipo,
    this.galloId,
  });

  Map<String, dynamic> toJson() {
    return {
      'recurso_tipo': recursoTipo,
      if (galloId != null) 'gallo_id': galloId,
    };
  }
}

// ========================================
// MODELO DE SOLICITUD DE UPGRADE
// ========================================

class UpgradeRequest {
  final String planCodigo;

  UpgradeRequest({
    required this.planCodigo,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan_codigo': planCodigo,
    };
  }
}

// ========================================
// MODELO DE RESPUESTA DE UPGRADE
// ========================================

class UpgradeResponse {
  final bool success;
  final String mensaje;
  final String? planCodigo;
  final double? precioTotal;
  final List<String> beneficios;
  final QRYapeResponse? qrPago;
  final int? pagoId;

  UpgradeResponse({
    required this.success,
    required this.mensaje,
    this.planCodigo,
    this.precioTotal,
    this.beneficios = const [],
    this.qrPago,
    this.pagoId,
  });

  factory UpgradeResponse.fromJson(Map<String, dynamic> json) {
    return UpgradeResponse(
      success: json['success'] ?? false,
      mensaje: json['mensaje'] ?? '',
      planCodigo: json['plan_codigo'],
      precioTotal: UpgradeResponse._parseDouble(json['precio_total']),
      beneficios: json['beneficios'] != null
          ? List<String>.from(json['beneficios'])
          : [],
      qrPago: json['qr_pago'] != null
          ? QRYapeResponse.fromJson(json['qr_pago'])
          : null,
      pagoId: json['pago_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'mensaje': mensaje,
      'plan_codigo': planCodigo,
      'precio_total': precioTotal,
      'beneficios': beneficios,
      'qr_pago': qrPago?.toJson(),
      'pago_id': pagoId,
    };
  }

  /// Precio formateado con moneda
  String get precioFormateado {
    if (precioTotal == null || precioTotal == 0) return 'Gratis';
    return 'S/. ${precioTotal!.toStringAsFixed(2)}';
  }

  // 🔧 Helper para parsear precio que puede venir como string o double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

// ========================================
// MODELO DE PAGO PENDIENTE INFO
// ========================================

class PagoPendienteInfo {
  final int id;
  final String planCodigo;
  final double monto;
  final String estado;
  final DateTime? fechaPago;
  final DateTime createdAt;

  PagoPendienteInfo({
    required this.id,
    required this.planCodigo,
    required this.monto,
    required this.estado,
    this.fechaPago,
    required this.createdAt,
  });

  factory PagoPendienteInfo.fromJson(Map<String, dynamic> json) {
    return PagoPendienteInfo(
      id: json['id'] ?? 0,
      planCodigo: json['plan_codigo'] ?? '',
      monto: PagoPendienteInfo._parseDouble(json['monto']),
      estado: json['estado'] ?? 'pendiente',
      fechaPago: json['fecha_pago'] != null
          ? DateTime.parse(json['fecha_pago'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_codigo': planCodigo,
      'monto': monto,
      'estado': estado,
      'fecha_pago': fechaPago?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Estado del pago en español
  String get estadoTexto {
    switch (estado.toLowerCase()) {
      case 'pendiente': return 'Pendiente';
      case 'verificando': return 'Verificando';
      case 'aprobado': return 'Aprobado';
      case 'rechazado': return 'Rechazado';
      default: return estado;
    }
  }

  /// Color del estado
  String get estadoColor {
    switch (estado.toLowerCase()) {
      case 'pendiente':
      case 'verificando': 
        return '#f39c12'; // Naranja
      case 'aprobado': 
        return '#27ae60'; // Verde
      case 'rechazado': 
        return '#e74c3c'; // Rojo
      default: 
        return '#95a5a6'; // Gris
    }
  }

  /// Icono del estado
  String get estadoIcono {
    switch (estado.toLowerCase()) {
      case 'pendiente': return '⏳';
      case 'verificando': return '🔍';
      case 'aprobado': return '✅';
      case 'rechazado': return '❌';
      default: return '❓';
    }
  }

  /// Precio formateado
  String get montoFormateado {
    return 'S/. ${monto.toStringAsFixed(2)}';
  }

  // 🔧 Helper para parsear precio que puede venir como string o double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
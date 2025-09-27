// 🏆 Pantalla de Planes Premium - VERSIÓN MEJORADA Y CORREGIDA
// Compatible con: https://gallerappback-production.up.railway.app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/base_screen.dart';
import '../../../models/suscripcion_models.dart';
import '../../../models/pago_models.dart';
import '../../../services/suscripcion_service.dart';
import '../../../services/pago_service.dart';
import '../widgets/plan_card.dart';
import '../widgets/limite_progress_widget.dart';
import '../../suscripcion/screens/proceso_pago_screen.dart';
import '../../../config/adaptive_ui_config.dart'; // 🎨 SISTEMA ADAPTATIVO PARA DISPOSITIVOS CHINOS

class PlanesScreen extends StatefulWidget {
  final String? planRecomendado;
  final String? origenUpgrade;
  final bool abrirMiSuscripcion;

  const PlanesScreen({
    Key? key,
    this.planRecomendado,
    this.origenUpgrade,
    this.abrirMiSuscripcion = false,
  }) : super(key: key);

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<PlanCatalogo> _planes = [];
  Suscripcion? _suscripcionActual;
  EstadoLimites? _limitesActuales;
  bool _isLoading = true;
  String? _error;
  
  // Estados de carga individual para mejor UX
  bool _planesLoaded = false;
  bool _suscripcionLoaded = false;
  bool _limitesLoaded = false;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _cargarDatosRobusto();
  }

  void _setupControllers() {
    int initialIndex = widget.abrirMiSuscripcion ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  /// 🔧 MÉTODO CORREGIDO: Carga datos de forma robusta e independiente
  Future<void> _cargarDatosRobusto() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 1. CARGAR PLANES (CRÍTICO)
    try {
      print('🔍 Cargando planes disponibles desde API...');
      _planes = await SuscripcionService.obtenerPlanesDisponibles(incluirGratuito: true);
      _planesLoaded = true;
      print('✅ Planes API cargados exitosamente: ${_planes.length}');

      // Debug: mostrar datos de los planes
      for (var plan in _planes) {
        print('📋 Plan: ${plan.nombre} - Gallos: ${plan.gallosMaximo} - Marketplace: ${plan.marketplacePublicacionesMax} - Streaming: ${plan.duracionSemanas} semanas');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR cargando planes desde API: $e');
      print('📍 StackTrace: $stackTrace');
      print('⚡ Usando planes por defecto como fallback...');
      _planes = _getPlanesDefault();
      _planesLoaded = true;
      print('✅ Planes fallback cargados: ${_planes.length}');
    }

    // 2. CARGAR SUSCRIPCIÓN ACTUAL (NO CRÍTICO)
    try {
      print('🔍 Cargando suscripción actual...');
      _suscripcionActual = await SuscripcionService.obtenerSuscripcionActual();
      
      // 🔄 COMBINAR CON PAGOS PENDIENTES DE LA API EXISTENTE
      try {
        print('💳 Verificando pagos pendientes...');
        final misPagos = await PagoService.obtenerMisPagos();
        
        // Buscar pago pendiente o verificando
        final pagosPendientes = misPagos.where((pago) => 
          pago.estado.toLowerCase() == 'pendiente' || 
          pago.estado.toLowerCase() == 'verificando'
        ).toList();
        
        final pagoPendiente = pagosPendientes.isNotEmpty ? pagosPendientes.first : null;
        
        if (pagoPendiente != null) {
          print('🔥 PAGO PENDIENTE ENCONTRADO: ${pagoPendiente.planCodigo} - ${pagoPendiente.estado}');
          
          // Convertir PagoPendiente a PagoPendienteInfo
          final pagoPendienteInfo = PagoPendienteInfo(
            id: pagoPendiente.id,
            planCodigo: pagoPendiente.planCodigo,
            monto: pagoPendiente.monto,
            estado: pagoPendiente.estado,
            fechaPago: pagoPendiente.fechaPagoUsuario,
            createdAt: pagoPendiente.createdAt,
          );
          
          // Crear nueva suscripción con pago pendiente
          _suscripcionActual = Suscripcion(
            id: _suscripcionActual!.id,
            userId: _suscripcionActual!.userId,
            planType: _suscripcionActual!.planType,
            planName: _suscripcionActual!.planName,
            precio: _suscripcionActual!.precio,
            status: _suscripcionActual!.status,
            fechaInicio: _suscripcionActual!.fechaInicio,
            fechaFin: _suscripcionActual!.fechaFin,
            gallosMaximo: _suscripcionActual!.gallosMaximo,
            topesPorGallo: _suscripcionActual!.topesPorGallo,
            peleasPorGallo: _suscripcionActual!.peleasPorGallo,
            vacunasPorGallo: _suscripcionActual!.vacunasPorGallo,
            createdAt: _suscripcionActual!.createdAt,
            updatedAt: _suscripcionActual!.updatedAt,
            diasRestantes: _suscripcionActual!.diasRestantes,
            estaActiva: _suscripcionActual!.estaActiva,
            esPremium: _suscripcionActual!.esPremium,
            pagoPendiente: pagoPendienteInfo, // 🔄 PAGO DE LA API REAL
          );
        } else {
          print('✅ No hay pagos pendientes');
        }
      } catch (e) {
        print('⚠️ Error verificando pagos: $e');
      }
      
      _suscripcionLoaded = true;
      print('✅ Suscripción cargada: ${_suscripcionActual?.planName}');
    } catch (e) {
      print('⚠️ Error cargando suscripción: $e');
      // 🔥 MOSTRAR ERROR EN LUGAR DE PLAN FALSO - MEJOR UX
      _suscripcionActual = null; // No mostrar plan falso
      _suscripcionLoaded = false; // Marcar como fallida para mostrar banner de error
    }

    // 3. CARGAR LÍMITES (NO CRÍTICO)
    try {
      print('🔍 Cargando límites actuales...');
      _limitesActuales = await SuscripcionService.obtenerLimitesActuales();
      _limitesLoaded = true;
      print('✅ Límites cargados');
    } catch (e) {
      print('⚠️ Error cargando límites: $e');
      _limitesActuales = _getLimitesDefault();
      _limitesLoaded = false; // Marcar como fallida
    }

    setState(() {
      _isLoading = false;
    });

    // Iniciar animaciones
    _animationController.forward();

    // Vibración si viene de upgrade
    if (widget.origenUpgrade != null) {
      HapticFeedback.mediumImpact();
    }
  }

  /// 📋 Planes por defecto si el API falla - valores reales BD
  List<PlanCatalogo> _getPlanesDefault() {
    return [
      PlanCatalogo(
        id: 1,
        codigo: 'gratuito',
        nombre: 'Plan Gratuito',
        descripcion: 'Ideal para comenzar',
        precio: 0.0,
        duracionDias: 30,
        duracionSemanas: 0,
        gallosMaximo: 5,
        topesPorGallo: 2,
        peleasPorGallo: 2,
        vacunasPorGallo: 2,
        marketplacePublicacionesMax: 0,
        caracteristicas: [
          'Gallos: 5',
          'Peleas: 2 por gallo',
          'Topes: 2 por gallo',
          'Vacunas: 2 por gallo',
          'Marketplace: 0 publicaciones',
          'Streaming: Sin acceso'
        ],
      ),
      PlanCatalogo(
        id: 2,
        codigo: 'basico',
        nombre: 'Plan Básico',
        descripcion: 'Para criadores en crecimiento',
        precio: 50.0,
        duracionDias: 7,
        duracionSemanas: 1,
        gallosMaximo: 50,
        topesPorGallo: 2,
        peleasPorGallo: 2,
        vacunasPorGallo: 4,
        marketplacePublicacionesMax: 3,
        caracteristicas: [
          'Gallos: 50',
          'Peleas: 2 por gallo',
          'Topes: 2 por gallo',
          'Vacunas: 4 por gallo',
          'Marketplace: 3 publicaciones',
          'Streaming: 1 semana'
        ],
      ),
      PlanCatalogo(
        id: 3,
        codigo: 'premium',
        nombre: 'Plan Premium',
        descripcion: 'Para criadores profesionales',
        precio: 80.0,
        duracionDias: 15,
        duracionSemanas: 2,
        gallosMaximo: 100,
        topesPorGallo: 3,
        peleasPorGallo: 3,
        vacunasPorGallo: 4,
        marketplacePublicacionesMax: 5,
        destacado: true,
        caracteristicas: [
          'Gallos: 100',
          'Peleas: 3 por gallo',
          'Topes: 3 por gallo',
          'Vacunas: 4 por gallo',
          'Marketplace: 5 publicaciones',
          'Streaming: 2 semanas'
        ],
      ),
      PlanCatalogo(
        id: 4,
        codigo: 'profesional',
        nombre: 'Plan Profesional',
        descripcion: 'Para profesionales',
        precio: 100.0,
        duracionDias: 30,
        duracionSemanas: 4,
        gallosMaximo: 150,
        topesPorGallo: 4,
        peleasPorGallo: 4,
        vacunasPorGallo: 4,
        marketplacePublicacionesMax: 10,
        caracteristicas: [
          'Gallos: 150',
          'Peleas: 4 por gallo',
          'Topes: 4 por gallo',
          'Vacunas: 4 por gallo',
          'Marketplace: 10 publicaciones',
          'Streaming: 4 semanas'
        ],
      ),
    ];
  }

  /// 📋 Suscripción por defecto si el API falla
  Suscripcion _getSuscripcionDefault() {
    // 🔥 SIMULACIÓN TEMPORAL: Crear pago pendiente para probar
    final pagoPendienteSimulado = PagoPendienteInfo(
      id: 999,
      planCodigo: 'basico',
      monto: 15.0,
      estado: 'verificando',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    
    return Suscripcion(
      id: 0,
      userId: 0,
      planType: 'gratuito',
      planName: 'Plan Gratuito',
      precio: 0.0,
      status: 'active',
      gallosMaximo: 5,
      topesPorGallo: 2,
      peleasPorGallo: 2,
      vacunasPorGallo: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      estaActiva: true,
      esPremium: false,
      pagoPendiente: pagoPendienteSimulado, // 🔥 AQUÍ ESTÁ LA SIMULACIÓN
    );
  }

  /// 📊 Límites por defecto si el API falla
  EstadoLimites _getLimitesDefault() {
    return EstadoLimites(
      userId: 0,
      planActual: 'gratuito',
      suscripcionActiva: true,
      gallos: LimiteRecurso(
        tipo: 'gallos',
        limite: 5,
        usado: 0,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Planes',
      subtitle: 'Gestiona tu suscripción',
      currentIndex: 3,
      showAppBar: false,
      child: Container(
        color: const Color(0xFFF8F9FA),
        child: _isLoading
            ? _buildLoadingState()
            : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Cargando planes disponibles...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildCompactAppBar(),
                _buildCompactTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlanesTab(),
                      _buildMiSuscripcionTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🎨 NUEVO: AppBar más compacto y elegante
  Widget _buildCompactAppBar() {
    print('🔥🔥🔥 USANDO NUEVO APPBAR COMPACTO 🔥🔥🔥');
    return Container(
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.9),
            Colors.blue.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón de retroceso Material Design
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back, 
                          color: Colors.white, 
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Suscripción y Planes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Badge de estado
                  if (!_planesLoaded || !_suscripcionLoaded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Icon(
                        Icons.cloud_off,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Subtítulo
              if (widget.origenUpgrade != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Límite alcanzado en ${widget.origenUpgrade}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Gestiona tu plan y desbloquea todas las funcionalidades',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 NUEVO: TabBar más compacto y moderno
  Widget _buildCompactTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(23),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 18),
                SizedBox(width: 6),
                Text('🌟 Planes'),
              ],
            ),
          ),
          Tab(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 18),
                SizedBox(width: 6),
                Text('💳 Mi Suscripción'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanesTab() {
    return Column(
      children: [
        // Banner de estado de conexión
        if (!_planesLoaded) _buildConnectionBanner(),
        
        // Lista de planes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _planes.length,
            itemBuilder: (context, index) {
              final plan = _planes[index];
              final esRecomendado = plan.codigo == widget.planRecomendado;
              final esPlanActual = _suscripcionActual?.planType == plan.codigo;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PlanCard(
                  plan: plan,
                  esRecomendado: esRecomendado,
                  esPlanActual: esPlanActual,
                  onSeleccionado: () => _seleccionarPlan(plan),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo sin conexión',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  'Mostrando planes locales. Algunas funciones pueden estar limitadas.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _cargarDatosRobusto,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔧 MÉTODO MEJORADO: Mi Suscripción Tab
  Widget _buildMiSuscripcionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado de conexión si hay problemas
          if (!_suscripcionLoaded) _buildSuscripcionErrorBanner(),
          
          // 🔄 MANEJO MEJORADO DE ESTADOS
          if (_suscripcionActual?.pagoPendiente != null)
            _buildPagoPendienteCard(_suscripcionActual!.pagoPendiente!)
          else if (_suscripcionActual == null && !_suscripcionLoaded)
            _buildErrorCargandoSuscripcion() // Error de conexión
          else if (_suscripcionActual == null && _suscripcionLoaded) 
            _buildVerificarPagosPendientes() // Sin suscripción activa
          else ..._buildSuscripcionNormalCards(),
        ],
      ),
    );
  }
  
  List<Widget> _buildSuscripcionNormalCards() {
    return [
      _buildSuscripcionActualCard(),
      const SizedBox(height: 16),
      _limitesActuales != null 
          ? _buildLimitesCard()
          : _buildLimitesErrorCard(),
      const SizedBox(height: 16),
      _buildEstadisticasCard(),
    ];
  }

  /// ❌ Error crítico cargando suscripción
  Widget _buildErrorCargandoSuscripcion() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.red.shade50, Colors.orange.shade50],
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error cargando suscripción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudo conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatosRobusto,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuscripcionErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información de suscripción',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  'No se pudo conectar al servidor. Se muestra información por defecto.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 🔄 NUEVO: Tarjeta para mostrar pago pendiente
  Widget _buildPagoPendienteCard(PagoPendienteInfo pago) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CARD PRINCIPAL DE PAGO PENDIENTE
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100],
              ),
              border: Border.all(color: Colors.orange.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER CON ICONO Y ESTADO
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pago.estadoIcono,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAGO ${pago.estadoTexto.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Tu suscripción está siendo procesada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // DETALLES DEL PAGO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Plan solicitado', pago.planCodigo.toUpperCase()),
                      _buildInfoRow('Monto pagado', pago.montoFormateado),
                      _buildInfoRow('Fecha de pago', _formatearFecha(pago.createdAt)),
                      _buildEstadoRowCustom(pago.estado, pago.estadoTexto, pago.estadoIcono),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // INFORMACIÓN ADICIONAL
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '¿Qué sigue?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• El administrador verificará tu comprobante de pago\n'
                        '• Recibirás una notificación cuando sea aprobado\n'
                        '• Tu plan se activará automáticamente\n'
                        '• Tiempo estimado: 24 horas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // LIMITES ACTUALES
        if (_limitesActuales != null) _buildLimitesCard(),
      ],
    );
  }
  
  Widget _buildEstadoRowPago(String estado, String estadoTexto, String estadoIcono) {
    Color estadoColor;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
      case 'verificando': 
        estadoColor = Colors.orange;
        break;
      case 'aprobado': 
        estadoColor = Colors.green;
        break;
      case 'rechazado': 
        estadoColor = Colors.red;
        break;
      default: 
        estadoColor = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Estado',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: estadoColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(estadoIcono, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  estadoTexto.toUpperCase(),
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuscripcionActualCard() {
    final suscripcion = _suscripcionActual!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    suscripcion.iconoPlan,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suscripcion.planName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (suscripcion.precio > 0) ...[
                        Text(
                          'S/. ${suscripcion.precio.toStringAsFixed(2)}/mes',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Plan Gratuito',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: suscripcion.estaActiva ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    suscripcion.estaActiva ? 'Activo' : 'Inactivo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (suscripcion.fechaFin != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    suscripcion.diasRestantes != null
                        ? 'Vence en ${suscripcion.diasRestantes} días'
                        : 'Fecha de vencimiento: ${suscripcion.fechaFin!.day}/${suscripcion.fechaFin!.month}/${suscripcion.fechaFin!.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitesErrorCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Uso de Recursos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo cargar la información de límites desde el servidor.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatosRobusto,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitesCard() {
    final limites = _limitesActuales!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Uso Actual de Recursos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LimiteProgressWidget(
              titulo: 'Gallos',
              icono: '🐓',
              usado: limites.gallos.usado,
              limite: limites.gallos.limite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificarPagosPendientes() {
    return FutureBuilder<List<PagoPendiente>>(
      future: PagoService.obtenerMisPagos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Si hay pagos pendientes, mostrar estado PENDIENTE
        final pagosPendientes = snapshot.data?.where((p) => 
          p.estado.toLowerCase() == 'verificando' || 
          p.estado.toLowerCase() == 'pendiente'
        ).toList() ?? [];
        
        if (pagosPendientes.isNotEmpty) {
          return _buildSuscripcionPendiente(pagosPendientes.first);
        }
        
        // Si no hay pagos pendientes, mostrar por defecto
        return _buildSuscripcionPorDefecto();
      },
    );
  }

  Widget _buildSuscripcionPendiente(PagoPendiente pago) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ESTADO PENDIENTE DESTACADO
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100],
              ),
              border: Border.all(color: Colors.orange.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pending, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PAGO PENDIENTE',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'Tu suscripción está siendo procesada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Plan solicitado', pago.planCodigo.toUpperCase()),
                      _buildInfoRow('Monto pagado', 'S/. ${pago.monto.toStringAsFixed(2)}'),
                      _buildInfoRow('Fecha de pago', _formatearFecha(pago.createdAt)),
                      _buildEstadoRow(pago.estado),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '¿Qué sigue?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• El administrador verificará tu comprobante de pago\n'
                        '• Recibirás una notificación cuando sea aprobado\n'
                        '• Tu plan se activará automáticamente\n'
                        '• Tiempo estimado: 24 horas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_limitesActuales != null) _buildLimitesCard(),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSuscripcionPorDefecto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🆓',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Plan Gratuito',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Sin costo',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Activo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No se pudo cargar la información de tu suscripción desde el servidor. Se muestra información por defecto.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Límites Por Defecto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLimiteDefault('Gallos', '🐓', 0, 5),
                const SizedBox(height: 12),
                _buildLimiteDefault('Entrenamientos', '💪', 0, 2),
                const SizedBox(height: 12),
                _buildLimiteDefault('Peleas', '⚔️', 0, 2),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  '¿Quieres actualizar tu plan?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ve a la pestaña "Planes Disponibles" para elegir el plan que mejor se adapte a tus necesidades.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Ver Planes Disponibles'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLimiteDefault(String titulo, String icono, int usado, int limite) {
    final porcentaje = limite > 0 ? (usado / limite) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icono, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '$usado / $limite',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: porcentaje,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            porcentaje >= 0.8 ? Colors.red : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasCard() {
    final suscripcion = _suscripcionActual!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Cuenta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Miembro desde', suscripcion.createdAt),
            _buildInfoRow('Última actualización', suscripcion.updatedAt),
            _buildEstadoRow(suscripcion.status),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue;
    if (value is DateTime) {
      displayValue = '${value.day}/${value.month}/${value.year}';
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            displayValue,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEstadoRow(String estado) {
    Color estadoColor;
    String estadoTexto;
    IconData estadoIcon;
    
    switch (estado.toLowerCase()) {
      case 'activo':
      case 'active':
        estadoColor = Colors.green;
        estadoTexto = 'ACTIVO';
        estadoIcon = Icons.check_circle;
        break;
      case 'pendiente':
      case 'verificando':
      case 'pending':
        estadoColor = Colors.orange;
        estadoTexto = 'PENDIENTE DE APROBACIÓN';
        estadoIcon = Icons.pending;
        break;
      case 'rechazado':
      case 'rejected':
        estadoColor = Colors.red;
        estadoTexto = 'RECHAZADO';
        estadoIcon = Icons.cancel;
        break;
      case 'expirado':
      case 'expired':
        estadoColor = Colors.grey;
        estadoTexto = 'EXPIRADO';
        estadoIcon = Icons.schedule;
        break;
      default:
        estadoColor = Colors.grey;
        estadoTexto = estado.toUpperCase();
        estadoIcon = Icons.info;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estado', style: TextStyle(color: Colors.grey.shade600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: estadoColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(estadoIcon, color: estadoColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  estadoTexto,
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEstadoRowCustom(String estado, String estadoTexto, String estadoIcono) {
    Color estadoColor;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
      case 'verificando': 
        estadoColor = Colors.orange;
        break;
      case 'aprobado': 
        estadoColor = Colors.green;
        break;
      case 'rechazado': 
        estadoColor = Colors.red;
        break;
      default: 
        estadoColor = Colors.grey;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Estado', style: TextStyle(color: Colors.grey.shade600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: estadoColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(estadoIcono, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  estadoTexto.toUpperCase(),
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _seleccionarPlan(PlanCatalogo plan) async {
    // Vibración de feedback
    HapticFeedback.selectionClick();

    // Verificar si es el plan actual
    if (_suscripcionActual?.planType == plan.codigo) {
      _mostrarPlanActual(plan);
      return;
    }

    // Verificar si es downgrade
    if (_esDowngrade(plan)) {
      _mostrarAdvertenciaDowngrade(plan);
      return;
    }

    // Proceder con upgrade
    _procesarUpgrade(plan);
  }

  bool _esDowngrade(PlanCatalogo plan) {
    final planActual = _suscripcionActual?.planType ?? 'gratuito';
    final Map<String, int> jerarquia = {
      'gratuito': 0,
      'basico': 1,
      'premium': 2,
      'profesional': 3,
    };

    return (jerarquia[plan.codigo] ?? 0) <= (jerarquia[planActual] ?? 0);
  }

  void _mostrarPlanActual(PlanCatalogo plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(plan.codigo == 'gratuito' ? '🆓' : '⭐'),
            const SizedBox(width: 8),
            const Text('Plan Actual'),
          ],
        ),
        content: Text('Ya tienes activo el ${plan.nombre}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _mostrarAdvertenciaDowngrade(PlanCatalogo plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Downgrade'),
          ],
        ),
        content: const Text(
          'No puedes cambiar a un plan de menor categoría desde la app. '
          'Contacta al soporte para realizar este cambio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _procesarUpgrade(PlanCatalogo plan) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Solicitar upgrade
      final upgradeResponse = await SuscripcionService.solicitarUpgrade(plan.codigo);
      
      // Cerrar loading
      if (mounted) Navigator.of(context).pop();

      // Navegar a proceso de pago
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProcesoPagoScreen(
              plan: plan,
              upgradeResponse: upgradeResponse,
            ),
          ),
        );
      }
    } catch (e) {
      // Cerrar loading
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar upgrade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ========================================
// DELEGATE PARA TAB BAR
// ========================================

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
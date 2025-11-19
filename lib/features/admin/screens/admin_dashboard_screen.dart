// 🚀 ADMIN DASHBOARD ÉPICO - VERSIÓN FINAL
// Implementa las mejores prácticas y recomendaciones épicas

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/base_screen.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/admin_notification_service.dart';
import '../../../services/admin_service.dart';
import '../../../config/adaptive_ui_config.dart'; // 🎨 SISTEMA ADAPTATIVO PARA DISPOSITIVOS CHINOS

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  
  // 🎛️ CONTROLADORES
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  
  // 📊 ESTADO DE DATOS
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _pagosPendientes = [];
  List<Map<String, dynamic>> _usuarios = [];
  Map<String, dynamic> _estadisticasUsuarios = {};
  int _totalUsuarios = 0;
  int _paginaActual = 0;
  int _usuariosPorPagina = 20;
  
  // 🔄 ESTADOS DE CARGA
  bool _isLoadingDashboard = false;
  bool _isLoadingPagos = false;
  bool _isLoadingUsuarios = false;
  
  String? _errorDashboard;
  String? _errorPagos;
  String? _errorUsuarios;
  
  // 🎯 FILTROS
  String _filtroActual = "hoy";
  String _searchQuery = "";
  bool _soloUsuariosPremium = false;

  @override
  void initState() {
    super.initState();
    print('🚀 [ADMIN-EPIC] === INICIANDO PANEL ADMIN ÉPICO ===');
    _tabController = TabController(length: 3, vsync: this);
    
    // Pausar notificaciones al entrar
    AdminNotificationService.pausarEnPanelAdmin();
    print('⏸️ [ADMIN-EPIC] Timer de notificaciones PAUSADO');
    
    _setupAutoRefresh();
    _cargarDatosIniciales();
    
    _tabController.addListener(() {
      print('📑 [ADMIN-EPIC] Tab cambiado a: ${_tabController.index}');
      _cargarDatosPorTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    
    // Reanudar notificaciones al salir
    AdminNotificationService.reanudarEnHome();
    print('▶️ [ADMIN-EPIC] Timer de notificaciones REANUDADO');
    super.dispose();
  }

  // 🔄 Configurar auto-refresh
  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30), 
      (_) => _refreshCurrentTab(),
    );
  }

  // 🔄 Refresh del tab actual
  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _cargarDashboard();
        break;
      case 1:
        _cargarPagosPendientes();
        break;
      case 2:
        _cargarUsuarios();
        break;
    }
  }

  // 📊 Cargar datos iniciales
  void _cargarDatosIniciales() async {
    print('📊 [ADMIN-EPIC] Cargando datos iniciales...');
    await _cargarDashboard();
  }

  // 🔄 Cargar datos por tab
  void _cargarDatosPorTab() async {
    switch (_tabController.index) {
      case 0:
        if (_dashboardData == null) await _cargarDashboard();
        break;
      case 1:
        await _cargarPagosPendientes();
        break;
      case 2:
        await _cargarUsuarios();
        break;
    }
  }

  // 📊 TAB 1: Cargar Dashboard
  Future<void> _cargarDashboard() async {
    if (_isLoadingDashboard) return;
    
    print('📊 [ADMIN-EPIC-TAB1] Cargando dashboard...');
    setState(() {
      _isLoadingDashboard = true;
      _errorDashboard = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 [ADMIN-EPIC-TAB1] Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dashboardData = data;
          _isLoadingDashboard = false;
        });
        print('✅ [ADMIN-EPIC-TAB1] Dashboard cargado: ${data.keys.toList()}');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ADMIN-EPIC-TAB1] Error: $e');
      setState(() {
        _errorDashboard = e.toString();
        _isLoadingDashboard = false;
      });
    }
  }

  // 💳 TAB 2: Cargar Pagos Pendientes
  Future<void> _cargarPagosPendientes() async {
    if (_isLoadingPagos) return;
    
    print('💳 [ADMIN-EPIC-TAB2] Cargando pagos pendientes...');
    setState(() {
      _isLoadingPagos = true;
      _errorPagos = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      String url;
      
      // Solo usar el endpoint disponible y filtrar en cliente
      url = 'https://gallerappback-production.up.railway.app/api/v1/admin/pagos/pendientes';
      
      // Agregar parámetros según el filtro (si el backend los soporta)
      switch (_filtroActual) {
        case "hoy":
          final today = DateTime.now().toIso8601String().split('T')[0];
          url += '?fecha=$today';
          break;
        case "pendientes":
          // Sin filtros adicionales, mostrar todos los pendientes
          break;
        case "aprobados":
          // Intentar filtro por estado aprobado
          url += '?estado=aprobado';
          break;
        case "rechazados":
          // Intentar filtro por estado rechazado
          url += '?estado=rechazado';
          break;
      }
      
      print('🔍 [ADMIN-TAB2] URL construida: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('💳 [ADMIN-EPIC-TAB2] Response: ${response.statusCode}');
      print('💳 [ADMIN-EPIC-TAB2] Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('pagos')) {
          data = responseData['pagos'];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }
        
        // Aplicar filtro adicional en cliente si es necesario
        List<Map<String, dynamic>> pagosFiltrados = List<Map<String, dynamic>>.from(data);
        
        if (_filtroActual == "hoy") {
          final today = DateTime.now().toIso8601String().split('T')[0];
          pagosFiltrados = pagosFiltrados.where((pago) {
            final fechaCreacion = pago['created_at'] ?? pago['fecha_pago_usuario'] ?? '';
            return fechaCreacion.startsWith(today);
          }).toList();
        } else if (_filtroActual == "aprobados") {
          pagosFiltrados = pagosFiltrados.where((pago) {
            final estado = (pago['estado'] ?? '').toString().toLowerCase();
            return estado == 'aprobado' || estado == 'activo';
          }).toList();
        } else if (_filtroActual == "rechazados") {
          pagosFiltrados = pagosFiltrados.where((pago) {
            final estado = (pago['estado'] ?? '').toString().toLowerCase();
            return estado == 'rechazado';
          }).toList();
        } else if (_filtroActual == "pendientes") {
          pagosFiltrados = pagosFiltrados.where((pago) {
            final estado = (pago['estado'] ?? '').toString().toLowerCase();
            return estado == 'verificando' || estado == 'pendiente';
          }).toList();
        }
        
        setState(() {
          _pagosPendientes = pagosFiltrados;
          _isLoadingPagos = false;
        });
        print('✅ [ADMIN-EPIC-TAB2] Pagos cargados: ${data.length}, filtrados: ${pagosFiltrados.length}');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ADMIN-EPIC-TAB2] Error: $e');
      setState(() {
        _errorPagos = e.toString();
        _isLoadingPagos = false;
      });
    }
  }

  // 👥 TAB 3: Cargar Estadísticas de Usuarios
  Future<void> _cargarEstadisticasUsuarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final response = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/admin/usuarios/estadisticas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _estadisticasUsuarios = data;
        });
        print('✅ [ADMIN-EPIC-TAB3] Estadísticas cargadas: $data');
      }
    } catch (e) {
      print('❌ [ADMIN-EPIC-TAB3] Error cargando estadísticas: $e');
    }
  }

  // 👥 TAB 3: Cargar Usuarios con Paginación
  Future<void> _cargarUsuarios() async {
    if (_isLoadingUsuarios) return;
    
    print('👥 [ADMIN-EPIC-TAB3] Cargando usuarios página ${_paginaActual + 1}...');
    setState(() {
      _isLoadingUsuarios = true;
      _errorUsuarios = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final skip = _paginaActual * _usuariosPorPagina;
      final response = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/admin/usuarios?limit=$_usuariosPorPagina&skip=$skip'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('👥 [ADMIN-EPIC-TAB3] Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _usuarios = List<Map<String, dynamic>>.from(data['usuarios']);
          _totalUsuarios = data['total'];
          _isLoadingUsuarios = false;
        });
        print('✅ [ADMIN-EPIC-TAB3] Usuarios cargados: ${_usuarios.length} de $_totalUsuarios');
        
        // Cargar estadísticas también
        _cargarEstadisticasUsuarios();
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ADMIN-EPIC-TAB3] Error: $e');
      setState(() {
        _errorUsuarios = e.toString();
        _isLoadingUsuarios = false;
      });
    }
  }

  // 👥 Cambiar de página
  void _cambiarPagina(int nuevaPagina) {
    setState(() {
      _paginaActual = nuevaPagina;
    });
    _cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: '👑 Panel Administrativo Épico',
      currentIndex: -1,
      showBottomNavBar: false,
      child: Column(
        children: [
          // 🎨 TAB BAR ÉPICO
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard),
                  text: 'Dashboard',
                ),
                Tab(
                  icon: Icon(Icons.payment),
                  text: 'Pagos',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Usuarios',
                ),
              ],
            ),
          ),
          
          // 📱 TAB VIEWS ÉPICOS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTabEpic(),
                _buildPagosTabEpic(),
                _buildUsuariosTabEpic(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 TAB 1: Dashboard Épico
  Widget _buildDashboardTabEpic() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorDashboard != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            AdaptiveText('Error: $_errorDashboard'),
            const SizedBox(height: 16),
            FutureBuilder<AdaptiveUIConfig>(
              future: AdaptiveUIManager.getOptimalConfig(),
              builder: (context, snapshot) {
                final config = snapshot.data ?? AdaptiveUIConfig.standard();
                
                return ElevatedButton(
                  onPressed: _cargarDashboard,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: config.borderRadius,
                    ),
                    minimumSize: Size(0, config.buttonHeight),
                  ),
                  child: Text(
                    'Reintentar',
                    style: TextStyle(
                      fontSize: config.fontSize,
                      fontWeight: config.fontWeight,
                      letterSpacing: config.letterSpacing,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricsGridEpic(),
            const SizedBox(height: 24),
            _buildRevenueSectionEpic(),
            const SizedBox(height: 24),
            _buildAccesosRapidosEpic(),
            const SizedBox(height: 24),
            _buildRecentActivityEpic(),
          ],
        ),
      ),
    );
  }

  // 📊 Grid de Métricas Épico
  Widget _buildMetricsGridEpic() {
    final data = _dashboardData ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header épico
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.dashboard, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Panel de Control en Vivo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'En vivo',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Grid 2x2 épico
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildEpicMetricCard(
              title: 'Usuarios Hoy',
              value: '${data['usuarios_nuevos_hoy'] ?? 0}',
              icon: Icons.person_add_alt_1,
              color: Colors.blue,
              subtitle: 'Nuevos registros',
              trend: '+${data['usuarios_nuevos_hoy'] ?? 0}',
            ),
            _buildEpicMetricCard(
              title: 'Ingresos Hoy',
              value: 'S/. ${data['ingresos_hoy'] ?? 0}',
              icon: Icons.trending_up,
              color: Colors.green,
              subtitle: 'Revenue diario',
              trend: data['ingresos_hoy'] != null && data['ingresos_hoy'] > 0 ? '+${data['ingresos_hoy']}' : '0',
            ),
            _buildEpicMetricCard(
              title: 'Notificaciones',
              value: '${data['notificaciones_no_leidas'] ?? 0}',
              icon: Icons.notifications_active,
              color: data['notificaciones_no_leidas'] > 0 ? Colors.orange : Colors.grey,
              subtitle: 'Pendientes',
              trend: data['notificaciones_no_leidas'] > 0 ? 'Urgente' : 'Al día',
            ),
            _buildEpicMetricCard(
              title: 'Pagos Pendientes',
              value: '${data['pagos_requieren_atencion'] ?? 0}',
              icon: Icons.pending_actions,
              color: data['pagos_requieren_atencion'] > 0 ? Colors.red : Colors.green,
              subtitle: 'Por aprobar',
              trend: data['pagos_requieren_atencion'] > 0 ? 'Acción requerida' : '¡Perfecto!',
            ),
          ],
        ),
      ],
    );
  }

  // 🎨 Card de Métrica Épica
  Widget _buildEpicMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 💰 Sección de Ingresos Épica
  Widget _buildRevenueSectionEpic() {
    final data = _dashboardData ?? {};
    final pagosUltimos7Dias = data['pagos_ultimos_7_dias'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                '📈 Actividad de Pagos - Últimos 7 días',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (pagosUltimos7Dias.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: pagosUltimos7Dias.length,
                itemBuilder: (context, index) {
                  final dia = pagosUltimos7Dias[index];
                  final fecha = dia['fecha'] as String;
                  final cantidad = dia['cantidad'] as int;
                  
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$cantidad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cantidad > 0 ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fecha.split('-')[2], // Solo el día
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'pagos',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 60,
              alignment: Alignment.center,
              child: Text(
                '📊 No hay datos de pagos disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  // 🚀 Accesos Rápidos Épicos
  Widget _buildAccesosRapidosEpic() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 8),
              const Text(
                '🚀 Módulos Administrativos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid 2x2 de accesos rápidos
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildAccesoRapidoCard(
                title: 'Transmisiones',
                subtitle: 'Gestión de eventos',
                icon: Icons.live_tv,
                color: Colors.red,
                onTap: () => Navigator.pushNamed(context, '/admin-transmisiones'),
              ),
              _buildAccesoRapidoCard(
                title: 'Suscripciones',
                subtitle: 'Planes y pagos',
                icon: Icons.payment,
                color: Colors.green,
                onTap: () {
                  // Ya están en este dashboard, mostrar mensaje
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ya estás en el dashboard principal'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              _buildAccesoRapidoCard(
                title: 'Usuarios',
                subtitle: 'Gestión de usuarios',
                icon: Icons.people,
                color: Colors.blue,
                onTap: () {
                  // Cambiar al tab de usuarios
                  _tabController.animateTo(2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navegando a gestión de usuarios'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              _buildAccesoRapidoCard(
                title: 'Estadísticas',
                subtitle: 'Métricas y reportes',
                icon: Icons.analytics,
                color: Colors.orange,
                onTap: () {
                  // Cambiar al tab de dashboard
                  _tabController.animateTo(0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navegando a estadísticas generales'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 Card de Acceso Rápido
  Widget _buildAccesoRapidoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  // ⚡ Actividad Reciente Épica
  Widget _buildRecentActivityEpic() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                '⚡ Actividad Reciente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Actualizado ahora',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Actividades demo épicas
          _buildActivityItem(
            icon: Icons.person_add,
            title: 'Nuevo usuario registrado',
            subtitle: 'Usuario se registró hace 2 horas',
            color: Colors.blue,
          ),
          _buildActivityItem(
            icon: Icons.payment,
            title: 'Pago procesado exitosamente',
            subtitle: 'Plan básico - S/15.00',
            color: Colors.green,
          ),
          _buildActivityItem(
            icon: Icons.notifications,
            title: 'Nueva notificación generada',
            subtitle: 'Pago pendiente de verificación',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  // 📋 Item de Actividad
  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💳 TAB 2: Pagos Épico
  Widget _buildPagosTabEpic() {
    return Column(
      children: [
        // Filtros épicos
        _buildPagosFiltersEpic(),
        
        // Contenido
        Expanded(
          child: _isLoadingPagos
              ? const Center(child: CircularProgressIndicator())
              : _errorPagos != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_errorPagos'),
                          ElevatedButton(
                            onPressed: _cargarPagosPendientes,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _pagosPendientes.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 64, color: Colors.green),
                              SizedBox(height: 16),
                              Text('¡No hay pagos pendientes!', 
                                   style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarPagosPendientes,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pagosPendientes.length,
                            itemBuilder: (context, index) {
                              final pago = _pagosPendientes[index];
                              return _buildPagoCardEpic(pago);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  // 🎛️ Filtros de Pagos Épicos
  Widget _buildPagosFiltersEpic() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Filtrar:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Hoy', 'hoy', Icons.today),
                  _buildFilterChip('Pendientes', 'pendientes', Icons.pending),
                  _buildFilterChip('Aprobados', 'aprobados', Icons.check_circle),
                  _buildFilterChip('Rechazados', 'rechazados', Icons.cancel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🏷️ Chip de Filtro Épico
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filtroActual == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _filtroActual = value;
          });
          _cargarPagosPendientes();
        },
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }

  // 💳 Card de Pago Épico
  Widget _buildPagoCardEpic(Map<String, dynamic> pago) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header épico con estado dinámico
            Row(
              children: [
                _buildEstadoChip(pago),
                const Spacer(),
                Text(
                  'S/. ${pago['monto'] ?? 0}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Información épica
            _buildInfoRow(Icons.person, 'Usuario', 
                         pago['usuario_nombre'] ?? pago['usuario_email'] ?? 'N/A'),
            _buildInfoRow(Icons.email, 'Email', 
                         pago['usuario_email'] ?? 'N/A'),
            _buildInfoRow(Icons.star, 'Plan', 
                         pago['plan_nombre_completo'] ?? pago['plan_nombre'] ?? 'N/A'),
            _buildInfoRow(Icons.calendar_today, 'Fecha', 
                         pago['fecha_pago_usuario'] ?? pago['fecha_pago'] ?? 'N/A'),
            
            const SizedBox(height: 16),
            
            // Botones épicos - solo para pagos pendientes
            _buildBotonesPago(pago),
          ],
        ),
      ),
    );
  }

  // 🎛️ Botones del pago según estado
  Widget _buildBotonesPago(Map<String, dynamic> pago) {
    final estado = (pago['estado'] ?? 'verificando').toString().toLowerCase();
    final esPendiente = estado == 'verificando' || estado == 'pendiente';
    
    return Row(
      children: [
        // Botón ver comprobante (siempre visible si existe)
        if (pago['comprobante_url'] != null && 
            pago['comprobante_url'].toString().isNotEmpty)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _verComprobante(pago['comprobante_url']),
              icon: const Icon(Icons.image, size: 18),
              label: const Text('Ver Comprobante'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                '📷 Sin comprobante',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        
        // Botones de acción según estado
        if (esPendiente) ...[
          // Botón aprobar (solo para pendientes) - ADAPTATIVO
          Expanded(
            child: FutureBuilder<AdaptiveUIConfig>(
              future: AdaptiveUIManager.getOptimalConfig(),
              builder: (context, snapshot) {
                final config = snapshot.data ?? AdaptiveUIConfig.standard();
                
                return ElevatedButton.icon(
                  onPressed: () => _aprobarPago(pago),
                  icon: Icon(Icons.check, size: config.iconSize * 0.75),
                  label: Text(
                    'APROBAR',
                    style: TextStyle(
                      fontSize: config.fontSize * 0.85,
                      fontWeight: config.fontWeight,
                      letterSpacing: config.letterSpacing,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: config.borderRadius * 0.6,
                    ),
                    minimumSize: Size(0, config.buttonHeight * 0.8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Botón rechazar (solo para pendientes) - ADAPTATIVO
          Expanded(
            child: FutureBuilder<AdaptiveUIConfig>(
              future: AdaptiveUIManager.getOptimalConfig(),
              builder: (context, snapshot) {
                final config = snapshot.data ?? AdaptiveUIConfig.standard();
                
                return OutlinedButton.icon(
                  onPressed: () => _rechazarPago(pago),
                  icon: Icon(Icons.close, size: config.iconSize * 0.75),
                  label: Text(
                    'Rechazar',
                    style: TextStyle(
                      fontSize: config.fontSize * 0.85,
                      fontWeight: config.fontWeight,
                      letterSpacing: config.letterSpacing,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: config.borderRadius * 0.6,
                    ),
                    minimumSize: Size(0, config.buttonHeight * 0.8),
                  ),
                );
              },
            ),
          ),
        ] else ...[
          // Para pagos ya procesados, mostrar estado final
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: estado == 'aprobado' 
                    ? Colors.green.withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: estado == 'aprobado' 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                estado == 'aprobado' 
                    ? '✅ Ya fue aprobado'
                    : '❌ Fue rechazado',
                style: TextStyle(
                  color: estado == 'aprobado' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 🏷️ Estado del pago épico
  Widget _buildEstadoChip(Map<String, dynamic> pago) {
    final estado = (pago['estado'] ?? 'verificando').toString().toLowerCase();
    
    Color color;
    String texto;
    IconData icono;
    
    switch (estado) {
      case 'verificando':
      case 'pendiente':
        color = Colors.orange;
        texto = '⏳ PENDIENTE';
        icono = Icons.schedule;
        break;
      case 'aprobado':
      case 'activo':
        color = Colors.green;
        texto = '✅ APROBADO';
        icono = Icons.check_circle;
        break;
      case 'rechazado':
        color = Colors.red;
        texto = '❌ RECHAZADO';
        icono = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        texto = '❓ DESCONOCIDO';
        icono = Icons.help;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 📋 Fila de información
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 👥 TAB 3: Usuarios Épico
  Widget _buildUsuariosTabEpic() {
    final totalPaginas = (_totalUsuarios / _usuariosPorPagina).ceil();
    
    return Column(
      children: [
        // Filtros y búsqueda épicos
        _buildUsuariosFiltersEpic(),
        
        // Contenido
        Expanded(
          child: _isLoadingUsuarios
              ? const Center(child: CircularProgressIndicator())
              : _errorUsuarios != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_errorUsuarios'),
                          ElevatedButton(
                            onPressed: _cargarUsuarios,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _cargarUsuarios,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _usuariosFiltrados().length,
                              itemBuilder: (context, index) {
                                final usuario = _usuariosFiltrados()[index];
                                return _buildUsuarioCardEpic(usuario);
                              },
                            ),
                          ),
                        ),
                        // Controles de paginación
                        if (totalPaginas > 1)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _paginaActual > 0
                                      ? () => _cambiarPagina(_paginaActual - 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                  label: const Text('Anterior'),
                                ),
                                Text(
                                  'Página ${_paginaActual + 1} de $totalPaginas',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _paginaActual < totalPaginas - 1
                                      ? () => _cambiarPagina(_paginaActual + 1)
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                  label: const Text('Siguiente'),
                                  iconAlignment: IconAlignment.end,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  // 🔍 Filtros de Usuarios Épicos
  Widget _buildUsuariosFiltersEpic() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda épica
          Row(
            children: [
              Icon(Icons.search, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por email o nombre...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                selected: _soloUsuariosPremium,
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16),
                    SizedBox(width: 4),
                    Text('Solo Premium'),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _soloUsuariosPremium = selected;
                  });
                },
                selectedColor: Colors.amber.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Métricas de usuarios por tipo de plan (desde endpoint de estadísticas)
          Column(
            children: [
              Row(
                children: [
                  _buildUsuarioMetric(
                    'Total', 
                    '${_estadisticasUsuarios['total'] ?? 0}', 
                    Colors.blue,
                  ),
                  _buildUsuarioMetric(
                    'Premium', 
                    '${_estadisticasUsuarios['premium'] ?? 0}', 
                    Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildUsuarioMetric(
                    'Básico', 
                    '${_estadisticasUsuarios['basico'] ?? 0}', 
                    Colors.green,
                  ),
                  _buildUsuarioMetric(
                    'Gratuitos', 
                    '${_estadisticasUsuarios['gratuito'] ?? 0}', 
                    Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 Métrica de Usuario
  Widget _buildUsuarioMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👤 Card de Usuario Épico
  Widget _buildUsuarioCardEpic(Map<String, dynamic> usuario) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: usuario['is_premium'] ? Colors.amber : AppColors.primary,
          child: Text(
            (usuario['email'] ?? 'U')[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                usuario['email'] ?? 'Sin email',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (usuario['is_premium'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '👑 Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${usuario['id']}'),
            Text('Registro: ${usuario['created_at']?.split('T')[0] ?? 'N/A'}'),
            if (usuario['suscripcion'] != null)
              Text(
                'Plan: ${usuario['suscripcion']['plan']} - Expira: ${usuario['suscripcion']['fecha_fin'] ?? 'Sin fecha'}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detalle',
              child: Row(
                children: [
                  Icon(Icons.info, size: 18),
                  SizedBox(width: 8),
                  Text('Ver Detalle'),
                ],
              ),
            ),
            if (usuario['is_premium'] == false)
              const PopupMenuItem(
                value: 'premium',
                child: Row(
                  children: [
                    Icon(Icons.star, size: 18),
                    SizedBox(width: 8),
                    Text('Activar Premium'),
                  ],
                ),
              ),
          ],
          onSelected: (value) => _accionUsuario(usuario, value.toString()),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUsuarioDetalle('Estado', usuario['is_active'] ? '✅ Activo' : '❌ Inactivo'),
                _buildUsuarioDetalle('Premium', usuario['is_premium'] ? '👑 Sí' : '📝 No'),
                _buildUsuarioDetalle('Último login', usuario['last_login'] ?? 'Nunca'),
                if (usuario['suscripcion'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '📋 Información de Suscripción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildUsuarioDetalle('Plan actual', usuario['suscripcion']['plan'] ?? 'Sin plan'),
                  _buildUsuarioDetalle('Fecha de expiración', usuario['suscripcion']['fecha_fin'] ?? 'Sin fecha'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📋 Detalle de Usuario
  Widget _buildUsuarioDetalle(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Filtrar usuarios
  List<Map<String, dynamic>> _usuariosFiltrados() {
    var usuarios = _usuarios;
    
    // Filtro por texto
    if (_searchQuery.isNotEmpty) {
      usuarios = usuarios.where((u) {
        final email = (u['email'] ?? '').toLowerCase();
        return email.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filtro por premium
    if (_soloUsuariosPremium) {
      usuarios = usuarios.where((u) => u['is_premium'] == true).toList();
    }
    
    return usuarios;
  }

  // 🎯 MÉTODOS DE ACCIÓN

  // 🖼️ Ver comprobante
  void _verComprobante(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Comprobante de Pago'),
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error cargando imagen'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Aprobar pago
  Future<void> _aprobarPago(Map<String, dynamic> pago) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Aprobación'),
        content: Text('¿Aprobar pago de S/. ${pago['monto']} para ${pago['usuario_email']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('APROBAR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        print('🚀 [FLUTTER-ADMIN] === USANDO ADMIN SERVICE ===');
        print('🚀 [FLUTTER-ADMIN] Pago ID: ${pago['id']}');
        
        // USAR EL AdminService que tiene los mismos headers que suscripciones
        final result = await AdminService.aprobarPago(pago['id']);
        
        print('✅ [FLUTTER-ADMIN] ¡APROBACIÓN EXITOSA!');
        print('✅ [FLUTTER-ADMIN] Resultado: $result');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pago aprobado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarPagosPendientes();
      } catch (e) {
        print('💥 [FLUTTER-ADMIN] Exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ❌ Rechazar pago
  Future<void> _rechazarPago(Map<String, dynamic> pago) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Rechazo'),
        content: Text('¿Rechazar pago de S/. ${pago['monto']} para ${pago['usuario_email']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('RECHAZAR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        
        final response = await http.post(
          Uri.parse('https://gallerappback-production.up.railway.app/api/v1/admin/pagos/${pago['id']}/rechazar'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: json.encode({
            'accion': 'rechazar',
            'notas': 'Pago rechazado - Comprobante no válido'
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pago rechazado'),
              backgroundColor: Colors.orange,
            ),
          );
          _cargarPagosPendientes();
        } else {
          throw Exception('Error: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 👤 Acción de usuario
  void _accionUsuario(Map<String, dynamic> usuario, String accion) {
    switch (accion) {
      case 'detalle':
        _mostrarDetalleUsuario(usuario);
        break;
      case 'premium':
        _activarPremium(usuario);
        break;
    }
  }

  // 👁️ Mostrar detalle de usuario
  void _mostrarDetalleUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle: ${usuario['email']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${usuario['id']}'),
              Text('Email: ${usuario['email']}'),
              Text('Activo: ${usuario['is_active'] ? 'Sí' : 'No'}'),
              Text('Premium: ${usuario['is_premium'] ? 'Sí' : 'No'}'),
              Text('Registro: ${usuario['created_at']}'),
              Text('Último login: ${usuario['last_login'] ?? 'Nunca'}'),
              if (usuario['suscripcion'] != null) ...[
                const SizedBox(height: 12),
                const Text('SUSCRIPCIÓN:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Plan: ${usuario['suscripcion']['plan']}'),
                Text('Expira: ${usuario['suscripcion']['fecha_fin']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // 👑 Activar premium
  void _activarPremium(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activar Premium'),
        content: Text('¿Activar premium para ${usuario['email']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función próximamente disponible'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }
}
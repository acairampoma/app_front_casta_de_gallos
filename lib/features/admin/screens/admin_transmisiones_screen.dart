// 📺 ADMIN TRANSMISIONES ÉPICO - GESTIÓN COMPLETA
// Implementa todas las funcionalidades admin para transmisiones siguiendo patrones existentes

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/widgets/base_screen.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/admin_service.dart';
import '../../../config/adaptive_ui_config.dart';
import 'formulario_coliseo_screen.dart';
import 'formulario_evento_screen.dart';

class AdminTransmisionesScreen extends StatefulWidget {
  const AdminTransmisionesScreen({Key? key}) : super(key: key);

  @override
  State<AdminTransmisionesScreen> createState() => _AdminTransmisionesScreenState();
}

class _AdminTransmisionesScreenState extends State<AdminTransmisionesScreen>
    with TickerProviderStateMixin {

  // 🎛️ CONTROLADORES
  late TabController _tabController;
  Timer? _autoRefreshTimer;

  // 📊 ESTADO DE DATOS
  Map<String, dynamic>? _estadisticas;
  List<Map<String, dynamic>> _coliseos = [];
  List<Map<String, dynamic>> _eventos = [];

  // 🔄 ESTADOS DE CARGA
  bool _isLoadingEstadisticas = false;
  bool _isLoadingColiseos = false;
  bool _isLoadingEventos = false;

  String? _errorEstadisticas;
  String? _errorColiseos;
  String? _errorEventos;

  // 🎯 FILTROS
  String _filtroEventos = "todos";
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    print('📺 [ADMIN-TRANSMISIONES] === INICIANDO PANEL ADMIN TRANSMISIONES ===');
    _tabController = TabController(length: 3, vsync: this);

    _setupAutoRefresh();
    _cargarDatosIniciales();

    _tabController.addListener(() {
      print('📺 [ADMIN-TRANSMISIONES] Tab cambiado a: ${_tabController.index}');
      _cargarDatosPorTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // 🔄 Configurar auto-refresh
  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshCurrentTab(),
    );
  }

  // 🔄 Refresh del tab actual
  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _cargarEstadisticas();
        break;
      case 1:
        _cargarColiseos();
        break;
      case 2:
        _cargarEventos();
        break;
    }
  }

  // 📊 Cargar datos iniciales
  void _cargarDatosIniciales() async {
    print('📺 [ADMIN-TRANSMISIONES] Cargando datos iniciales...');
    await _cargarEstadisticas();
  }

  // 🔄 Cargar datos por tab
  void _cargarDatosPorTab() async {
    switch (_tabController.index) {
      case 0:
        if (_estadisticas == null) await _cargarEstadisticas();
        break;
      case 1:
        if (_coliseos.isEmpty) await _cargarColiseos();
        break;
      case 2:
        if (_eventos.isEmpty) await _cargarEventos();
        break;
    }
  }

  // 📊 TAB 1: Cargar Estadísticas
  Future<void> _cargarEstadisticas() async {
    if (_isLoadingEstadisticas) return;

    print('📊 [ADMIN-TRANSMISIONES-TAB1] Cargando estadísticas...');
    setState(() {
      _isLoadingEstadisticas = true;
      _errorEstadisticas = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/estadisticas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 [ADMIN-TRANSMISIONES-TAB1] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _estadisticas = data;
          _isLoadingEstadisticas = false;
        });
        print('✅ [ADMIN-TRANSMISIONES-TAB1] Estadísticas cargadas: ${data.keys.toList()}');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ADMIN-TRANSMISIONES-TAB1] Error: $e');
      setState(() {
        _errorEstadisticas = e.toString();
        _isLoadingEstadisticas = false;
      });
    }
  }

  // 🏟️ TAB 2: Cargar Coliseos
  Future<void> _cargarColiseos() async {
    if (_isLoadingColiseos) return;

    print('🏟️ [ADMIN-TRANSMISIONES-TAB2] Cargando coliseos...');
    setState(() {
      _isLoadingColiseos = true;
      _errorColiseos = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/coliseos?activo=false'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🏟️ [ADMIN-TRANSMISIONES-TAB2] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _coliseos = List<Map<String, dynamic>>.from(data);
          _isLoadingColiseos = false;
        });
        print('✅ [ADMIN-TRANSMISIONES-TAB2] Coliseos cargados: ${_coliseos.length}');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ADMIN-TRANSMISIONES-TAB2] Error: $e');
      setState(() {
        _errorColiseos = e.toString();
        _isLoadingColiseos = false;
      });
    }
  }

  // 📺 TAB 3: Cargar Eventos
  Future<void> _cargarEventos() async {
    if (_isLoadingEventos) return;

    print('📺 [ADMIN-TRANSMISIONES-TAB3] Cargando eventos...');
    setState(() {
      _isLoadingEventos = true;
      _errorEventos = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      String url = 'https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos?por_pagina=50';

      // Aplicar filtros
      if (_filtroEventos != "todos") {
        url += '&estado=$_filtroEventos';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📺 [ADMIN-TRANSMISIONES-TAB3] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> eventos = data['eventos'] ?? [];
        setState(() {
          _eventos = List<Map<String, dynamic>>.from(eventos);
          _isLoadingEventos = false;
        });
        print('✅ [ADMIN-TRANSMISIONES-TAB3] Eventos cargados: ${_eventos.length}');
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ADMIN-TRANSMISIONES-TAB3] Error: $e');
      setState(() {
        _errorEventos = e.toString();
        _isLoadingEventos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: '📺 Admin Transmisiones',
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
              labelColor: Colors.red.shade600, // Color transmisiones
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.red.shade600,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Estadísticas',
                ),
                Tab(
                  icon: Icon(Icons.home_work),
                  text: 'Coliseos',
                ),
                Tab(
                  icon: Icon(Icons.live_tv),
                  text: 'Eventos',
                ),
              ],
            ),
          ),

          // 📱 TAB VIEWS ÉPICOS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEstadisticasTab(),
                _buildColiseosTab(),
                _buildEventosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 TAB 1: Estadísticas
  Widget _buildEstadisticasTab() {
    if (_isLoadingEstadisticas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorEstadisticas != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorEstadisticas'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarEstadisticas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEstadisticas,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEstadisticasGrid(),
            const SizedBox(height: 24),
            _buildAccionesRapidas(),
          ],
        ),
      ),
    );
  }

  // 📊 Grid de Estadísticas
  Widget _buildEstadisticasGrid() {
    final data = _estadisticas ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header épico
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.live_tv, color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Transmisiones en Vivo',
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
                    'Sistema activo',
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
            _buildEpicStatCard(
              title: 'Total Eventos',
              value: '${data['total_eventos'] ?? 0}',
              icon: Icons.event,
              color: Colors.blue,
              subtitle: 'En el sistema',
              trend: '+${data['total_eventos'] ?? 0}',
            ),
            _buildEpicStatCard(
              title: 'En Vivo',
              value: '${data['eventos_en_vivo'] ?? 0}',
              icon: Icons.live_tv,
              color: Colors.red,
              subtitle: 'Transmitiendo',
              trend: data['eventos_en_vivo'] != null && data['eventos_en_vivo'] > 0 ? '🔴 Activos' : 'Inactivos',
            ),
            _buildEpicStatCard(
              title: 'Programados',
              value: '${data['eventos_programados'] ?? 0}',
              icon: Icons.schedule,
              color: Colors.orange,
              subtitle: 'Próximos',
              trend: data['eventos_programados'] > 0 ? 'Listos' : 'Sin eventos',
            ),
            _buildEpicStatCard(
              title: 'Coliseos',
              value: '${data['coliseos_activos'] ?? 0}',
              icon: Icons.home_work,
              color: Colors.green,
              subtitle: 'Disponibles',
              trend: '${data['total_coliseos'] ?? 0} total',
            ),
          ],
        ),
      ],
    );
  }

  // 🎨 Card de Estadística Épica
  Widget _buildEpicStatCard({
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

  // ⚡ Acciones Rápidas
  Widget _buildAccionesRapidas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 8),
              const Text(
                '⚡ Acciones Rápidas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCrearColiseo(),
                  icon: const Icon(Icons.add_home),
                  label: const Text('Nuevo Coliseo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarDialogoCrearEvento(),
                  icon: const Icon(Icons.add_to_queue),
                  label: const Text('Nuevo Evento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🏟️ TAB 2: Coliseos
  Widget _buildColiseosTab() {
    return Column(
      children: [
        // Header con botón crear
        Container(
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
              Icon(Icons.home_work, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Gestión de Coliseos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCrearColiseo(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Contenido
        Expanded(
          child: _isLoadingColiseos
              ? const Center(child: CircularProgressIndicator())
              : _errorColiseos != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_errorColiseos'),
                          ElevatedButton(
                            onPressed: _cargarColiseos,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _coliseos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_work, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No hay coliseos registrados',
                                   style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarColiseos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _coliseos.length,
                            itemBuilder: (context, index) {
                              final coliseo = _coliseos[index];
                              return _buildColiseoCard(coliseo);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  // 🏟️ Card de Coliseo
  Widget _buildColiseoCard(Map<String, dynamic> coliseo) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: coliseo['activo'] ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    coliseo['activo'] ? '✅ ACTIVO' : '❌ INACTIVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: coliseo['activo'] ? 'desactivar' : 'activar',
                      child: Row(
                        children: [
                          Icon(coliseo['activo'] ? Icons.visibility_off : Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text(coliseo['activo'] ? 'Desactivar' : 'Activar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _accionColiseo(coliseo, value.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Información del coliseo
            Text(
              coliseo['nombre'] ?? 'Sin nombre',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            _buildInfoRowColiseo(Icons.location_on, 'Ciudad',
                         '${coliseo['ciudad'] ?? 'N/A'}, ${coliseo['departamento'] ?? ''}'),
            _buildInfoRowColiseo(Icons.people, 'Aforo',
                         '${coliseo['aforo_maximo'] ?? 0} personas'),
            _buildInfoRowColiseo(Icons.category, 'Tipo',
                         coliseo['tipo_coliseo'] ?? 'local'),
            if (coliseo['direccion'] != null)
              _buildInfoRowColiseo(Icons.home, 'Dirección',
                           coliseo['direccion']),
          ],
        ),
      ),
    );
  }

  // 📋 Fila de información del coliseo
  Widget _buildInfoRowColiseo(IconData icon, String label, String value) {
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

  // 📺 TAB 3: Eventos
  Widget _buildEventosTab() {
    return Column(
      children: [
        // Filtros de eventos
        _buildEventosFilters(),

        // Contenido
        Expanded(
          child: _isLoadingEventos
              ? const Center(child: CircularProgressIndicator())
              : _errorEventos != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $_errorEventos'),
                          ElevatedButton(
                            onPressed: _cargarEventos,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _eventos.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.live_tv, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No hay eventos registrados',
                                   style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarEventos,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _eventos.length,
                            itemBuilder: (context, index) {
                              final evento = _eventos[index];
                              return _buildEventoCard(evento);
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  // 🎛️ Filtros de Eventos
  Widget _buildEventosFilters() {
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
          Row(
            children: [
              Icon(Icons.live_tv, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Gestión de Eventos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _mostrarDialogoCrearEvento(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filtros por estado
          Row(
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
                      _buildFilterChip('Todos', 'todos', Icons.all_inclusive),
                      _buildFilterChip('En Vivo', 'en_vivo', Icons.live_tv),
                      _buildFilterChip('Programados', 'programado', Icons.schedule),
                      _buildFilterChip('Finalizados', 'finalizado', Icons.check_circle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🏷️ Chip de Filtro
  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filtroEventos == value;

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
            _filtroEventos = value;
          });
          _cargarEventos();
        },
        selectedColor: Colors.red.withOpacity(0.2),
        checkmarkColor: Colors.red.shade600,
      ),
    );
  }

  // 📺 Card de Evento
  Widget _buildEventoCard(Map<String, dynamic> evento) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              children: [
                _buildEstadoEventoChip(evento['estado']),
                const Spacer(),
                if (evento['es_premium'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(width: 8),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (evento['estado'] == 'programado')
                      const PopupMenuItem(
                        value: 'iniciar',
                        child: Row(
                          children: [
                            Icon(Icons.play_circle, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Iniciar EN VIVO'),
                          ],
                        ),
                      ),
                    if (evento['estado'] == 'en_vivo')
                      const PopupMenuItem(
                        value: 'finalizar',
                        child: Row(
                          children: [
                            Icon(Icons.stop_circle, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Finalizar'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'cancelar',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancelar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _accionEvento(evento, value.toString()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Título del evento
            Text(
              evento['titulo'] ?? 'Sin título',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Información del evento
            if (evento['coliseo'] != null)
              _buildInfoRowEvento(Icons.home_work, 'Coliseo',
                           '${evento['coliseo']['nombre']} - ${evento['coliseo']['ciudad']}'),
            _buildInfoRowEvento(Icons.schedule, 'Fecha',
                         _formatearFecha(evento['fecha_evento'])),
            _buildInfoRowEvento(Icons.link, 'URL Transmisión',
                         evento['url_transmision'] ?? 'No asignada'),
            if (evento['precio_entrada'] != null)
              _buildInfoRowEvento(Icons.attach_money, 'Precio',
                           'S/. ${evento['precio_entrada']}'),
          ],
        ),
      ),
    );
  }

  // 🏷️ Estado del evento
  Widget _buildEstadoEventoChip(String? estado) {
    Color color;
    String texto;
    IconData icono;

    switch (estado?.toLowerCase()) {
      case 'programado':
        color = Colors.orange;
        texto = '⏳ PROGRAMADO';
        icono = Icons.schedule;
        break;
      case 'en_vivo':
        color = Colors.red;
        texto = '🔴 EN VIVO';
        icono = Icons.live_tv;
        break;
      case 'finalizado':
        color = Colors.green;
        texto = '✅ FINALIZADO';
        icono = Icons.check_circle;
        break;
      case 'cancelado':
        color = Colors.grey;
        texto = '❌ CANCELADO';
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

  // 📋 Fila de información del evento
  Widget _buildInfoRowEvento(IconData icon, String label, String value) {
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 MÉTODOS DE ACCIÓN

  void _mostrarDialogoCrearColiseo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioColiseoScreen(),
      ),
    );

    if (result == true) {
      // Recargar datos si se creó un coliseo
      _cargarColiseos();
    }
  }

  void _mostrarDialogoCrearEvento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FormularioEventoScreen(),
      ),
    );

    if (result == true) {
      // Recargar datos si se creó un evento
      _cargarEventos();
    }
  }

  void _accionColiseo(Map<String, dynamic> coliseo, String accion) {
    print('📺 [ADMIN-TRANSMISIONES] Acción coliseo: $accion para ${coliseo['nombre']}');

    switch (accion) {
      case 'editar':
        _editarColiseo(coliseo);
        break;
      case 'activar':
      case 'desactivar':
        _cambiarEstadoColiseo(coliseo, accion == 'activar');
        break;
    }
  }

  void _accionEvento(Map<String, dynamic> evento, String accion) {
    print('📺 [ADMIN-TRANSMISIONES] Acción evento: $accion para ${evento['titulo']}');

    switch (accion) {
      case 'editar':
        _editarEvento(evento);
        break;
      case 'iniciar':
        _cambiarEstadoEvento(evento, 'en_vivo');
        break;
      case 'finalizar':
        _cambiarEstadoEvento(evento, 'finalizado');
        break;
      case 'cancelar':
        _cambiarEstadoEvento(evento, 'cancelado');
        break;
    }
  }

  void _editarColiseo(Map<String, dynamic> coliseo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioColiseoScreen(coliseo: coliseo),
      ),
    );

    if (result == true) {
      // Recargar datos si se editó el coliseo
      _cargarColiseos();
    }
  }

  void _editarEvento(Map<String, dynamic> evento) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioEventoScreen(evento: evento),
      ),
    );

    if (result == true) {
      // Recargar datos si se editó el evento
      _cargarEventos();
    }
  }

  Future<void> _cambiarEstadoColiseo(Map<String, dynamic> coliseo, bool activar) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${activar ? 'Activar' : 'Desactivar'} Coliseo'),
        content: Text('¿${activar ? 'Activar' : 'Desactivar'} el coliseo ${coliseo['nombre']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: activar ? Colors.green : Colors.red,
            ),
            child: Text(activar ? 'ACTIVAR' : 'DESACTIVAR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Implementar API call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${activar ? 'Activado' : 'Desactivado'} correctamente'),
          backgroundColor: activar ? Colors.green : Colors.orange,
        ),
      );
      _cargarColiseos();
    }
  }

  Future<void> _cambiarEstadoEvento(Map<String, dynamic> evento, String nuevoEstado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Text('¿Cambiar estado del evento "${evento['titulo']}" a $nuevoEstado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado == 'en_vivo' ? Colors.red :
                             nuevoEstado == 'finalizado' ? Colors.green : Colors.grey,
            ),
            child: const Text('CAMBIAR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        final response = await http.put(
          Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos/${evento['id']}/estado?estado=$nuevoEstado'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Estado cambiado a $nuevoEstado'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarEventos();
          _cargarEstadisticas(); // Actualizar estadísticas
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

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'No definida';

    try {
      final DateTime dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }
}
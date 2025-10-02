// 📺 lib/features/transmisiones/screens/transmisiones_screen.dart
// 📡 Pantalla de transmisiones para usuarios - Ver eventos en vivo

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/base_screen.dart';
import '../../../shared/widgets/video_player_widget.dart';
import '../../../config/adaptive_ui_config.dart';
import '../../../services/api_service.dart';
import 'transmision_en_vivo_screen.dart';
import 'videoteca_peleas_screen.dart';

class TransmisionesScreen extends StatefulWidget {
  const TransmisionesScreen({Key? key}) : super(key: key);

  @override
  State<TransmisionesScreen> createState() => _TransmisionesScreenState();
}

class _TransmisionesScreenState extends State<TransmisionesScreen>
    with TickerProviderStateMixin {
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  // 🎛️ TAB CONTROLLER
  late TabController _tabController;

  // 📊 ESTADO DE DATOS
  List<Map<String, dynamic>> _eventos = [];
  List<Map<String, dynamic>> _eventosHoy = [];
  List<Map<String, dynamic>> _coliseos = [];
  List<Map<String, dynamic>> _videoteca = [];

  // 🔄 ESTADOS DE CARGA
  bool _isLoadingEventos = false;
  bool _isLoadingColiseos = false;
  bool _isLoadingVideoteca = false;
  String? _errorEventos;
  String? _errorVideoteca;

  // 🎯 FILTROS
  String _filtroEventos = "todos";
  String? _coliseoSeleccionado;
  DateTime? _fechaSeleccionada;

  // 🎯 FILTROS VIDEOTECA
  DateTime? _fechaInicioVideoteca;
  DateTime? _fechaFinVideoteca;
  int? _coliseoVideoteca;

  @override
  void initState() {
    super.initState();
    print('📺 [TRANSMISIONES-USER] === INICIANDO TRANSMISIONES USUARIOS ===');
    _tabController = TabController(length: 2, vsync: this);
    _cargarColiseos();
    _cargarEventos();

    _tabController.addListener(() {
      if (_tabController.index == 1 && _videoteca.isEmpty) {
        _cargarVideoteca();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Transmisiones',
      child: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                  icon: Icon(Icons.live_tv),
                  text: 'En Vivo',
                ),
                Tab(
                  icon: Icon(Icons.video_library),
                  text: 'Videoteca',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEnVivoTab(),
                _buildVideotecaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📺 TAB 1: En Vivo
  Widget _buildEnVivoTab() {
    return Column(
      children: [
        // Header con bienvenida y filtros
        _buildHeaderSection(),

        // Contenido principal
        Expanded(
          child: _buildEventosContent(),
        ),
      ],
    );
  }

  // 🎨 Header Section
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida
          Row(
            children: [
              const Icon(
                Icons.live_tv,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Bienvenido a Transmisiones!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Disfruta de los mejores eventos en vivo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtros
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtrar por:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('hoy', 'Hoy', Icons.today),
                      const SizedBox(width: 8),
                      _buildFilterChip('en_vivo', 'En Vivo', Icons.radio_button_checked),
                      const SizedBox(width: 8),
                      _buildFilterChip('todos', 'Todos', Icons.list),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🎯 FILTROS ADICIONALES (Coliseo y Fecha)
          Row(
            children: [
              // 🏟️ FILTRO COLISEO
              Expanded(
                child: _buildColiseoDropdown(),
              ),
              const SizedBox(width: 12),
              // 📅 FILTRO FECHA
              _buildDatePicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filtro, String label, IconData icon) {
    final isSelected = _filtroEventos == filtro;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.primary : Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroEventos = filtro;
          });
          _cargarEventos();
        }
      },
      backgroundColor: Colors.transparent,
      selectedColor: Colors.white,
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
        width: 1,
      ),
    );
  }

  // 🏟️ DROPDOWN COLISEO
  Widget _buildColiseoDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: _coliseoSeleccionado,
        hint: const Text(
          'Seleccionar Coliseo',
          style: TextStyle(color: Colors.white70),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        iconSize: 24,
        elevation: 16,
        style: const TextStyle(color: Colors.white),
        underline: Container(),
        dropdownColor: AppColors.primary,
        isExpanded: true,
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Todos los Coliseos', style: TextStyle(color: Colors.white)),
          ),
          ..._coliseos.map<DropdownMenuItem<String>>((coliseo) {
            return DropdownMenuItem<String>(
              value: coliseo['id'].toString(),
              child: Text(
                '${coliseo['nombre']} - ${coliseo['ciudad']}',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _coliseoSeleccionado = newValue;
          });
          _cargarEventos();
        },
      ),
    );
  }

  // 📅 DATE PICKER
  Widget _buildDatePicker() {
    return InkWell(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _fechaSeleccionada != null
                  ? _dateFormatter.format(_fechaSeleccionada!)
                  : 'Fecha',
              style: const TextStyle(color: Colors.white),
            ),
            if (_fechaSeleccionada != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    _fechaSeleccionada = null;
                  });
                  _cargarEventos();
                },
                child: const Icon(Icons.clear, color: Colors.white, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 📅 SELECCIONAR FECHA
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      _cargarEventos();
    }
  }

  // 📺 Contenido de eventos
  Widget _buildEventosContent() {
    if (_isLoadingEventos) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Cargando eventos...'),
          ],
        ),
      );
    }

    if (_errorEventos != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_errorEventos'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarEventos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final eventos = _getEventosFiltrados();

    if (eventos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _filtroEventos == 'en_vivo' ? Icons.tv_off : Icons.event_busy,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _filtroEventos == 'hoy'
                  ? 'No hay eventos programados para hoy'
                  : _filtroEventos == 'en_vivo'
                      ? 'No hay transmisiones en vivo'
                      : 'No hay eventos disponibles',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarEventos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: eventos.length,
        itemBuilder: (context, index) {
          final evento = eventos[index];
          return _buildEventoCard(evento);
        },
      ),
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final DateTime fechaEvento = DateTime.parse(evento['fecha_evento']);
    final String estado = evento['estado'] ?? 'programado';
    final bool isEnVivo = estado == 'en_vivo';
    final bool esPremium = evento['es_premium'] ?? false;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _verEvento(evento),
        onDoubleTap: () => _verTransmisionEnVivo(evento),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del evento
              Row(
                children: [
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(estado),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEstadoIcon(estado),
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getEstadoText(estado),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (esPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (isEnVivo)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.live_tv,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Título del evento
              Text(
                evento['titulo'] ?? 'Evento sin título',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Coliseo
              if (evento['coliseo'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.home_work, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${evento['coliseo']['nombre']} - ${evento['coliseo']['ciudad']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Fecha y hora
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${_dateFormatter.format(fechaEvento)} - ${_timeFormatter.format(fechaEvento)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              // Precio
              if (evento['precio_entrada'] != null && _getPrecioNumerico(evento['precio_entrada']) > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'S/ ${evento['precio_entrada']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Acciones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _verEvento(evento),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Ver Detalles'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isEnVivo
                        ? () => _verTransmisionEnVivo(evento)
                        : null,
                      icon: Icon(isEnVivo ? Icons.live_tv : Icons.schedule),
                      label: Text(isEnVivo ? 'Ver en Vivo' : 'Próximamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnVivo ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Hint doble tap
              if (isEnVivo) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.double_arrow, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Doble tap para ver transmisión',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'en_vivo':
        return Colors.red;
      case 'programado':
        return Colors.blue;
      case 'finalizado':
        return Colors.green;
      case 'cancelado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'en_vivo':
        return Icons.radio_button_checked;
      case 'programado':
        return Icons.schedule;
      case 'finalizado':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'en_vivo':
        return 'EN VIVO';
      case 'programado':
        return 'PROGRAMADO';
      case 'finalizado':
        return 'FINALIZADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return 'DESCONOCIDO';
    }
  }

  List<Map<String, dynamic>> _getEventosFiltrados() {
    List<Map<String, dynamic>> eventos;

    // 1. Filtro base por estado
    switch (_filtroEventos) {
      case 'hoy':
        eventos = _eventosHoy;
        break;
      case 'en_vivo':
        eventos = _eventos.where((evento) => evento['estado'] == 'en_vivo').toList();
        break;
      case 'todos':
        eventos = _eventos;
        break;
      default:
        eventos = _eventos;
        break;
    }

    // 2. Filtro por coliseo
    if (_coliseoSeleccionado != null) {
      eventos = eventos.where((evento) {
        return evento['coliseo']?['id']?.toString() == _coliseoSeleccionado;
      }).toList();
    }

    // 3. Filtro por fecha
    if (_fechaSeleccionada != null) {
      final fechaSeleccionada = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada!);
      eventos = eventos.where((evento) {
        final fechaEvento = evento['fecha_evento'];
        if (fechaEvento != null) {
          // Comparar solo la fecha (sin hora)
          return fechaEvento.substring(0, 10) == fechaSeleccionada;
        }
        return false;
      }).toList();
    }

    return eventos;
  }

  Future<void> _cargarEventos() async {
    if (_isLoadingEventos) return;

    print('📺 [TRANSMISIONES-USER] Cargando eventos...');
    setState(() {
      _isLoadingEventos = true;
      _errorEventos = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('📺 [DEBUG] Token encontrado: ${token != null ? "SÍ (${token?.substring(0, 20)}...)" : "NO"}');

      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      // Cargar todos los eventos
      final responseEventos = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/eventos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📺 [TRANSMISIONES-USER] Response eventos: ${responseEventos.statusCode}');

      if (responseEventos.statusCode == 200) {
        final dataEventos = jsonDecode(responseEventos.body);

        setState(() {
          // Para eventos generales, extraer la lista de eventos si viene paginada
          if (dataEventos is Map && dataEventos.containsKey('eventos')) {
            _eventos = List<Map<String, dynamic>>.from(dataEventos['eventos']);
          } else {
            _eventos = List<Map<String, dynamic>>.from(dataEventos);
          }

          // 🔄 CALCULAR EVENTOS DE HOY DESDE _eventos en lugar de usar endpoint separado
          final hoy = DateTime.now();
          final fechaHoy = DateFormat('yyyy-MM-dd').format(hoy);

          print('📺 [DEBUG] Fecha actual calculada: $fechaHoy');

          _eventosHoy = _eventos.where((evento) {
            final fechaEvento = evento['fecha_evento'];
            if (fechaEvento != null) {
              final fechaEventoString = fechaEvento.substring(0, 10);
              print('📺 [DEBUG] Comparando: $fechaEventoString == $fechaHoy');
              // Comparar solo la fecha (sin hora)
              return fechaEventoString == fechaHoy;
            }
            return false;
          }).toList();

          _isLoadingEventos = false;
        });

        print('📺 [TRANSMISIONES-USER] Eventos cargados: ${_eventos.length}');
        print('📺 [TRANSMISIONES-USER] Eventos hoy calculados: ${_eventosHoy.length}');

        // 🐛 Debug: Mostrar eventos de hoy encontrados
        for (var evento in _eventosHoy) {
          print('📺 [DEBUG] Evento hoy: ${evento['titulo']} - ${evento['fecha_evento']}');
        }
      } else {
        throw Exception('Error del servidor: ${responseEventos.statusCode}');
      }
    } catch (e) {
      print('📺 [TRANSMISIONES-USER] Error: $e');
      setState(() {
        _errorEventos = e.toString();
        _isLoadingEventos = false;
      });
    }
  }

  // 🏟️ CARGAR COLISEOS
  Future<void> _cargarColiseos() async {
    if (_isLoadingColiseos) return;

    print('📺 [TRANSMISIONES-USER] Cargando coliseos...');
    setState(() {
      _isLoadingColiseos = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      final response = await http.get(
        Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/coliseos?activo=false'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📺 [TRANSMISIONES-USER] Response coliseos: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _coliseos = List<Map<String, dynamic>>.from(data);
          _isLoadingColiseos = false;
        });

        print('📺 [TRANSMISIONES-USER] Coliseos cargados: ${_coliseos.length}');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('📺 [TRANSMISIONES-USER] Error cargando coliseos: $e');
      setState(() {
        _isLoadingColiseos = false;
      });
    }
  }

  // 💰 HELPER: Convertir precio string a double
  double _getPrecioNumerico(dynamic precio) {
    if (precio == null) return 0.0;
    if (precio is double) return precio;
    if (precio is int) return precio.toDouble();
    if (precio is String) {
      return double.tryParse(precio) ?? 0.0;
    }
    return 0.0;
  }

  void _verEvento(Map<String, dynamic> evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(evento['titulo'] ?? 'Evento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (evento['descripcion'] != null) ...[
                const Text(
                  'Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(evento['descripcion']),
                const SizedBox(height: 12),
              ],

              if (evento['coliseo'] != null) ...[
                const Text(
                  'Coliseo:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('${evento['coliseo']['nombre']} - ${evento['coliseo']['ciudad']}'),
                const SizedBox(height: 12),
              ],

              const Text(
                'Estado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_getEstadoText(evento['estado'] ?? 'programado')),
              const SizedBox(height: 12),

              if (evento['precio_entrada'] != null && _getPrecioNumerico(evento['precio_entrada']) > 0) ...[
                const Text(
                  'Precio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('S/ ${evento['precio_entrada']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (evento['estado'] == 'en_vivo')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _verTransmisionEnVivo(evento);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Ver en Vivo', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  void _verTransmisionEnVivo(Map<String, dynamic> evento) {
    if (evento['estado'] != 'en_vivo') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este evento no está en vivo actualmente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransmisionEnVivoScreen(evento: evento),
      ),
    );
  }

  // ========================================
  // 📹 VIDEOTECA TAB
  // ========================================

  Widget _buildVideotecaTab() {
    return Column(
      children: [
        _buildFiltrosVideoteca(),
        Expanded(
          child: _isLoadingVideoteca
              ? const Center(child: CircularProgressIndicator())
              : _errorVideoteca != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(_errorVideoteca!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _cargarVideoteca,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _videoteca.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No hay videos disponibles',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _videoteca.length,
                          itemBuilder: (context, index) {
                            final evento = _videoteca[index];
                            return _buildVideotecaEventoCard(evento);
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildFiltrosVideoteca() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtrar videos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filtro por fechas
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFechaVideoteca(true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _fechaInicioVideoteca != null
                              ? _dateFormatter.format(_fechaInicioVideoteca!)
                              : 'Fecha inicio',
                          style: TextStyle(
                            color: _fechaInicioVideoteca != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('—'),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _seleccionarFechaVideoteca(false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _fechaFinVideoteca != null
                              ? _dateFormatter.format(_fechaFinVideoteca!)
                              : 'Fecha fin',
                          style: TextStyle(
                            color: _fechaFinVideoteca != null
                                ? Colors.black
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filtro por coliseo
          DropdownButtonFormField<int>(
            value: _coliseoVideoteca,
            decoration: const InputDecoration(
              labelText: 'Coliseo',
              prefixIcon: Icon(Icons.home_work),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos los coliseos'),
              ),
              ..._coliseos.map((c) => DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text(c['nombre']),
                  )),
            ],
            onChanged: (value) {
              setState(() => _coliseoVideoteca = value);
              _cargarVideoteca();
            },
          ),
          const SizedBox(height: 12),

          // Botones
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cargarVideoteca,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _fechaInicioVideoteca = null;
                    _fechaFinVideoteca = null;
                    _coliseoVideoteca = null;
                  });
                  _cargarVideoteca();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideotecaContent() {
    if (_isLoadingVideoteca) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorVideoteca != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _errorVideoteca!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarVideoteca,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_videoteca.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay videos disponibles',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta los filtros para buscar otros eventos',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videoteca.length,
      itemBuilder: (context, index) {
        final evento = _videoteca[index];
        return _buildVideotecaEventoCard(evento);
      },
    );
  }

  Widget _buildVideotecaEventoCard(Map<String, dynamic> evento) {
    final DateTime? fechaEvento = evento['fecha_evento'] != null
        ? DateTime.tryParse(evento['fecha_evento'])
        : null;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onDoubleTap: () => _verPeleasEvento(evento),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con badge de archivo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_library, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'VIDEOTECA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Título
              Text(
                evento['titulo'] ?? 'Evento sin título',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Coliseo
              if (evento['coliseo'] != null) ...[
                Row(
                  children: [
                    const Icon(Icons.home_work, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${evento['coliseo']['nombre']} - ${evento['coliseo']['ciudad']}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Fecha
              if (fechaEvento != null) ...[
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _dateFormatter.format(fechaEvento),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Botón para ver peleas
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _verPeleasEvento(evento),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Ver Peleas Grabadas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              // Hint doble click
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Doble click para ver peleas',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // 🎬 MÉTODOS DE VIDEOTECA
  // ========================================

  Future<void> _cargarVideoteca() async {
    setState(() {
      _isLoadingVideoteca = true;
      _errorVideoteca = null;
    });

    try {
      final videoteca = await ApiService.getVideoteca(
        fechaInicio: _fechaInicioVideoteca != null
            ? DateFormat('yyyy-MM-dd').format(_fechaInicioVideoteca!)
            : null,
        fechaFin: _fechaFinVideoteca != null
            ? DateFormat('yyyy-MM-dd').format(_fechaFinVideoteca!)
            : null,
        coliseoId: _coliseoVideoteca,
      );

      setState(() {
        _videoteca = videoteca;
        _isLoadingVideoteca = false;
      });
    } catch (e) {
      setState(() {
        _errorVideoteca = 'Error cargando videoteca: $e';
        _isLoadingVideoteca = false;
      });
    }
  }

  void _verPeleasEvento(Map<String, dynamic> evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideotecaPeleasScreen(evento: evento),
      ),
    );
  }

  Future<void> _seleccionarFechaVideoteca(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          _fechaInicioVideoteca = fecha;
        } else {
          _fechaFinVideoteca = fecha;
        }
      });
    }
  }

  void _reproducirVideo(Map<String, dynamic> pelea) {
    final videoUrl = pelea['video_url'];
    if (videoUrl == null || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video no disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    VideoPlayerModal.show(
      context,
      videoUrl: videoUrl,
      title: '${pelea['numero_pelea']}. ${pelea['titulo_pelea']}',
    );
  }
}
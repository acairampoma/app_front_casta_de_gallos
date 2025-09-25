// 📁 lib/features/admin/screens/formulario_evento_screen.dart
// 📺 Formulario para crear/editar eventos de transmisión

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/theme/app_colors.dart';

class FormularioEventoScreen extends StatefulWidget {
  final Map<String, dynamic>? evento;

  const FormularioEventoScreen({
    Key? key,
    this.evento,
  }) : super(key: key);

  @override
  State<FormularioEventoScreen> createState() => _FormularioEventoScreenState();
}

class _FormularioEventoScreenState extends State<FormularioEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  // Controladores
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _urlTransmisionController = TextEditingController();
  final _precioEntradaController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();

  // Estado
  List<Map<String, dynamic>> coliseos = [];
  int? coliseoSeleccionado;
  String estadoSeleccionado = 'programado';
  String tipoEventoSeleccionado = 'local';
  bool esPremium = false;
  DateTime fechaEvento = DateTime.now().add(const Duration(days: 1));
  TimeOfDay horaEvento = const TimeOfDay(hour: 20, minute: 0);
  DateTime? fechaFinEvento;
  TimeOfDay? horaFinEvento;
  bool isLoading = false;
  bool isLoadingColiseos = true;

  final List<Map<String, String>> estadosEvento = [
    {'codigo': 'programado', 'nombre': '📅 Programado'},
    {'codigo': 'en_vivo', 'nombre': '🔴 En Vivo'},
    {'codigo': 'finalizado', 'nombre': '✅ Finalizado'},
    {'codigo': 'cancelado', 'nombre': '❌ Cancelado'},
  ];

  final List<Map<String, String>> tiposEvento = [
    {'codigo': 'local', 'nombre': '🏠 Local'},
    {'codigo': 'grande', 'nombre': '🏟️ Grande'},
    {'codigo': 'especial', 'nombre': '👑 Especial'},
  ];

  @override
  void initState() {
    super.initState();
    _loadColiseos();
    _initializeFormData();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _urlTransmisionController.dispose();
    _precioEntradaController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadColiseos() async {
    print('🏟️ [FORM-EVENTO] === INICIANDO CARGA DE COLISEOS ===');
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

      print('🏟️ [FORM-EVENTO] Response coliseos: ${response.statusCode}');
      print('🏟️ [FORM-EVENTO] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          coliseos = data.map((item) => item as Map<String, dynamic>).toList();
          isLoadingColiseos = false;
        });
        print('🏟️ [FORM-EVENTO] Coliseos cargados: ${coliseos.length}');
      } else {
        throw Exception('Error cargando coliseos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando coliseos: $e');
      setState(() => isLoadingColiseos = false);
    }
  }

  void _initializeFormData() {
    if (widget.evento != null) {
      final evento = widget.evento!;

      _tituloController.text = evento['titulo'] ?? '';
      _descripcionController.text = evento['descripcion'] ?? '';
      _urlTransmisionController.text = evento['url_transmision'] ?? '';
      _precioEntradaController.text = evento['precio_entrada']?.toString() ?? '';
      _thumbnailUrlController.text = evento['thumbnail_url'] ?? '';

      coliseoSeleccionado = evento['coliseo']?['id'];
      estadoSeleccionado = evento['estado'] ?? 'programado';
      tipoEventoSeleccionado = evento['tipo_evento'] ?? 'local';
      esPremium = evento['es_premium'] ?? false;

      // Parsear fechas
      if (evento['fecha_evento'] != null) {
        fechaEvento = DateTime.parse(evento['fecha_evento']);
        horaEvento = TimeOfDay.fromDateTime(fechaEvento);
      }

      if (evento['fecha_fin_evento'] != null) {
        fechaFinEvento = DateTime.parse(evento['fecha_fin_evento']);
        horaFinEvento = TimeOfDay.fromDateTime(fechaFinEvento!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.evento != null ? 'Editar Evento' : 'Nuevo Evento',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isLoadingColiseos
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInformacionBasicaSection(),
                      const SizedBox(height: 20),
                      _buildProgramacionSection(),
                      const SizedBox(height: 20),
                      _buildTransmisionSection(),
                      const SizedBox(height: 20),
                      _buildConfiguracionSection(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // 📺 SECCIÓN 1: INFORMACIÓN BÁSICA
  Widget _buildInformacionBasicaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📺 INFORMACIÓN BÁSICA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 16),

          // Coliseo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coliseo *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: coliseoSeleccionado,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text('Seleccione el coliseo'),
                    ),
                    isExpanded: true,
                    onChanged: (int? value) {
                      setState(() {
                        coliseoSeleccionado = value;
                      });
                    },
                    items: coliseos.map<DropdownMenuItem<int>>((coliseo) {
                      return DropdownMenuItem<int>(
                        value: coliseo['id'],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            '${coliseo['nombre']} - ${coliseo['ciudad']}',
                            style: const TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Título
          TextFormField(
            controller: _tituloController,
            decoration: InputDecoration(
              labelText: 'Título del Evento *',
              hintText: 'Ej: Gran Pelea de Gallos - Sábado',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El título es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descripcionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Descripción del evento, detalles especiales...',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📅 SECCIÓN 2: PROGRAMACIÓN
  Widget _buildProgramacionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 PROGRAMACIÓN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),

          // Fecha y hora de inicio
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de Inicio *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: fechaEvento,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => fechaEvento = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _dateFormatter.format(fechaEvento),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hora *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: horaEvento,
                        );
                        if (time != null) {
                          setState(() => horaEvento = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              _timeFormatter.format(DateTime(2021, 1, 1, horaEvento.hour, horaEvento.minute)),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fecha y hora de fin (opcional)
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de Fin (opcional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: fechaFinEvento ?? fechaEvento.add(const Duration(hours: 3)),
                          firstDate: fechaEvento,
                          lastDate: fechaEvento.add(const Duration(days: 1)),
                        );
                        if (date != null) {
                          setState(() => fechaFinEvento = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              fechaFinEvento != null
                                ? _dateFormatter.format(fechaFinEvento!)
                                : 'Sin fecha fin',
                              style: TextStyle(
                                fontSize: 16,
                                color: fechaFinEvento != null ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hora Fin',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: fechaFinEvento != null ? () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: horaFinEvento ?? TimeOfDay(hour: horaEvento.hour + 3, minute: horaEvento.minute),
                        );
                        if (time != null) {
                          setState(() => horaFinEvento = time);
                        }
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: fechaFinEvento != null ? Colors.white : Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_outlined, size: 20, color: fechaFinEvento != null ? Colors.grey : Colors.grey[400]),
                            const SizedBox(width: 8),
                            Text(
                              (fechaFinEvento != null && horaFinEvento != null)
                                ? _timeFormatter.format(DateTime(2021, 1, 1, horaFinEvento!.hour, horaFinEvento!.minute))
                                : '--:--',
                              style: TextStyle(
                                fontSize: 16,
                                color: (fechaFinEvento != null && horaFinEvento != null) ? Colors.black : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📡 SECCIÓN 3: TRANSMISIÓN
  Widget _buildTransmisionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📡 TRANSMISIÓN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          const SizedBox(height: 16),

          // URL de transmisión
          TextFormField(
            controller: _urlTransmisionController,
            decoration: InputDecoration(
              labelText: 'URL de Transmisión *',
              hintText: 'https://player.kick.com/mi_canal',
              prefixIcon: const Icon(Icons.live_tv),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La URL de transmisión es obligatoria';
              }
              if (!value.trim().startsWith('http')) {
                return 'Ingrese una URL válida (http:// o https://)';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // URL del thumbnail (opcional)
          TextFormField(
            controller: _thumbnailUrlController,
            decoration: InputDecoration(
              labelText: 'URL de Imagen (opcional)',
              hintText: 'https://ejemplo.com/imagen.jpg',
              prefixIcon: const Icon(Icons.image),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!value.trim().startsWith('http')) {
                  return 'Ingrese una URL válida';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ⚙️ SECCIÓN 4: CONFIGURACIÓN
  Widget _buildConfiguracionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ CONFIGURACIÓN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),

          // Estado del evento
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estado del Evento *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: estadoSeleccionado,
                    isExpanded: true,
                    onChanged: (String? value) {
                      setState(() {
                        estadoSeleccionado = value!;
                      });
                    },
                    items: estadosEvento.map((estado) {
                      return DropdownMenuItem(
                        value: estado['codigo'],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            estado['nombre']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de evento y precio
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Evento *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: tipoEventoSeleccionado,
                          isExpanded: true,
                          onChanged: (String? value) {
                            setState(() {
                              tipoEventoSeleccionado = value!;
                            });
                          },
                          items: tiposEvento.map((tipo) {
                            return DropdownMenuItem(
                              value: tipo['codigo'],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Text(
                                  tipo['nombre']!,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _precioEntradaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio Entrada',
                    hintText: '0.00',
                    prefixText: 'S/ ',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final precio = double.tryParse(value.trim());
                      if (precio == null || precio < 0) {
                        return 'Ingrese un precio válido';
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Evento premium
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: esPremium ? Colors.yellow[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: esPremium ? Colors.yellow[300]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  esPremium ? Icons.star : Icons.star_border,
                  color: esPremium ? Colors.yellow[700] : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evento Premium',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esPremium ? Colors.yellow[700] : Colors.grey[700],
                    ),
                  ),
                ),
                Switch(
                  value: esPremium,
                  onChanged: (value) {
                    setState(() {
                      esPremium = value;
                    });
                  },
                  activeColor: Colors.yellow[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _guardarEvento,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.evento != null ? 'Actualizar Evento' : 'Crear Evento',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _guardarEvento() async {
    print('🚀 [GUARDAR-EVENTO] === INICIANDO GUARDADO DE EVENTO ===');

    if (!_formKey.currentState!.validate()) {
      print('❌ [GUARDAR-EVENTO] Validación del formulario falló');
      return;
    }

    if (coliseoSeleccionado == null) {
      print('❌ [GUARDAR-EVENTO] No se seleccionó coliseo');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un coliseo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('✅ [GUARDAR-EVENTO] Validaciones OK - Iniciando guardado...');
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🔑 [GUARDAR-EVENTO] Token: ${token != null ? "OK (${token.substring(0, 20)}...)" : "NO ENCONTRADO"}');

      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      // Combinar fecha y hora de inicio
      final fechaEventoCompleta = DateTime(
        fechaEvento.year,
        fechaEvento.month,
        fechaEvento.day,
        horaEvento.hour,
        horaEvento.minute,
      );

      // Combinar fecha y hora de fin (opcional)
      DateTime? fechaFinEventoCompleta;
      if (fechaFinEvento != null && horaFinEvento != null) {
        fechaFinEventoCompleta = DateTime(
          fechaFinEvento!.year,
          fechaFinEvento!.month,
          fechaFinEvento!.day,
          horaFinEvento!.hour,
          horaFinEvento!.minute,
        );
      }

      final Map<String, dynamic> eventoData = {
        'coliseo_id': coliseoSeleccionado,
        'titulo': _tituloController.text.trim(),
        'fecha_evento': fechaEventoCompleta.toIso8601String(),
        'url_transmision': _urlTransmisionController.text.trim(),
        'estado': estadoSeleccionado,
        'tipo_evento': tipoEventoSeleccionado,
        'es_premium': esPremium,
      };

      // Agregar campos opcionales
      if (_descripcionController.text.trim().isNotEmpty) {
        eventoData['descripcion'] = _descripcionController.text.trim();
      }
      if (fechaFinEventoCompleta != null) {
        eventoData['fecha_fin_evento'] = fechaFinEventoCompleta.toIso8601String();
      }
      if (_precioEntradaController.text.trim().isNotEmpty) {
        eventoData['precio_entrada'] = double.parse(_precioEntradaController.text.trim());
      }
      if (_thumbnailUrlController.text.trim().isNotEmpty) {
        eventoData['thumbnail_url'] = _thumbnailUrlController.text.trim();
      }

      print('📝 [GUARDAR-EVENTO] Datos a enviar: ${jsonEncode(eventoData)}');

      final isUpdate = widget.evento != null;
      final url = isUpdate
        ? 'https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos/${widget.evento!['id']}'
        : 'https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/eventos';

      print('🌐 [GUARDAR-EVENTO] ${isUpdate ? "PUT" : "POST"} a: $url');

      final response = isUpdate
        ? await http.put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(eventoData),
          )
        : await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(eventoData),
          );

      print('📡 [GUARDAR-EVENTO] Response status: ${response.statusCode}');
      print('📡 [GUARDAR-EVENTO] Response headers: ${response.headers}');
      print('📡 [GUARDAR-EVENTO] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [GUARDAR-EVENTO] Evento guardado exitosamente');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUpdate
                ? 'Evento actualizado exitosamente'
                : 'Evento creado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['detail'] ?? errorData['message'] ?? 'Error del servidor');
        } catch (_) {
          throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ [GUARDAR-EVENTO] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando evento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      print('🏁 [GUARDAR-EVENTO] Finalizando...');
      setState(() => isLoading = false);
    }
  }
}
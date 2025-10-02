// 🥊 Gestión de Peleas de Evento - Admin
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../../shared/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/native_share_service.dart';

class GestionPeleasEventoScreen extends StatefulWidget {
  final Map<String, dynamic> evento;

  const GestionPeleasEventoScreen({Key? key, required this.evento}) : super(key: key);

  @override
  State<GestionPeleasEventoScreen> createState() => _GestionPeleasEventoScreenState();
}

class _GestionPeleasEventoScreenState extends State<GestionPeleasEventoScreen> {
  List<Map<String, dynamic>> _peleas = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPeleas();
  }

  Future<void> _cargarPeleas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final peleas = await ApiService.getPeleasEvento(widget.evento['id']);
      setState(() {
        _peleas = peleas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarPelea(int peleaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar'),
          ],
        ),
        content: const Text('¿Eliminar esta pelea permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deletePeleaEvento(peleaId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pelea eliminada'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarPeleas();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirFormulario([Map<String, dynamic>? pelea]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FormularioPeleaEvento(
          evento: widget.evento,
          pelea: pelea,
        ),
      ),
    ).then((_) => _cargarPeleas());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🥊 Gestión de Peleas', style: TextStyle(fontSize: 18)),
            Text(
              widget.evento['titulo'] ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Botón Imprimir PDF
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Relación',
            onPressed: _peleas.isEmpty ? null : () => _imprimirRelacion(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _peleas.isEmpty
                  ? _buildEmpty()
                  : _buildLista(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Pelea'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _cargarPeleas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_mma, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Sin peleas registradas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega la primera pelea del evento',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _peleas.length,
      onReorder: _reordenar,
      itemBuilder: (ctx, index) {
        final pelea = _peleas[index];
        return _buildPeleaCard(pelea, key: ValueKey(pelea['id']));
      },
    );
  }

  Widget _buildPeleaCard(Map<String, dynamic> pelea, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _abrirFormulario(pelea),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Número de pelea
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#${pelea['numero_pelea']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Info pelea
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pelea['titulo_pelea'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildGalloChip(
                            pelea['galpon_izquierda'],
                            pelea['gallo_izquierda_nombre'],
                            Colors.blue,
                            '←',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('VS', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildGalloChip(
                            pelea['galpon_derecha'],
                            pelea['gallo_derecha_nombre'],
                            Colors.orange,
                            '→',
                          ),
                        ),
                      ],
                    ),
                    if (pelea['video_url'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.videocam, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Con video',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'editar') {
                    _abrirFormulario(pelea);
                  } else if (value == 'eliminar') {
                    _eliminarPelea(pelea['id']);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'editar', child: Text('✏️ Editar')),
                  const PopupMenuItem(value: 'eliminar', child: Text('🗑️ Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalloChip(String galpon, String gallo, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $galpon',
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            gallo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _reordenar(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;

    final pelea = _peleas.removeAt(oldIndex);
    _peleas.insert(newIndex, pelea);

    // Actualizar números
    for (int i = 0; i < _peleas.length; i++) {
      if (_peleas[i]['numero_pelea'] != i + 1) {
        try {
          await ApiService.actualizarOrdenPelea(
            peleaId: _peleas[i]['id'],
            nuevoNumero: i + 1,
          );
        } catch (e) {
          print('Error actualizando orden: $e');
        }
      }
    }

    setState(() {});
    _cargarPeleas(); // Recargar para confirmar
  }

  Future<void> _imprimirRelacion() async {
    try {
      print('📄 Iniciando generación de PDF de relación de peleas...');

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Llamar al endpoint
      final response = await ApiService.getPDFRelacionPeleas(widget.evento['id']);

      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();

      print('✅ PDF generado exitosamente');

      // Mostrar diálogo con opciones
      _mostrarDialogoPDFListo(response);
    } catch (e) {
      print('❌ Error generando PDF: $e');

      // Cerrar indicador de carga si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error generando PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoPDFListo(Map<String, dynamic> response) {
    final eventoTitulo = response['evento_titulo'] ?? widget.evento['titulo'] ?? 'Evento';
    final totalPeleas = response['total_peleas'] ?? _peleas.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('PDF Generado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📄 Relación de Peleas',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Evento: $eventoTitulo'),
            Text('Total peleas: $totalPeleas'),
            const SizedBox(height: 16),
            const Text(
              'Selecciona una opción:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Botón Compartir PDF
          ElevatedButton.icon(
            onPressed: () async {
              print('🔥 Compartiendo PDF con NativeShareService...');
              Navigator.of(context).pop();

              final pdfBase64 = response['pdf_base64'] as String;
              final fileName = 'relacion_peleas_${eventoTitulo.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

              try {
                // Decodificar base64 a bytes
                final pdfBytes = base64Decode(pdfBase64);

                // Usar el servicio nativo para compartir
                await NativeShareService.sharePDF(
                  pdfBytes: pdfBytes,
                  fileName: fileName,
                  nombreGallo: eventoTitulo, // Usar título del evento
                );

                print('✅ PDF compartido exitosamente');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ PDF compartido exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('❌ Error compartiendo PDF: $e');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error compartiendo PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('📄 Compartir PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          // Botón Cerrar
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📝 FORMULARIO DE PELEA
// ============================================================================

class FormularioPeleaEvento extends StatefulWidget {
  final Map<String, dynamic> evento;
  final Map<String, dynamic>? pelea;

  const FormularioPeleaEvento({
    Key? key,
    required this.evento,
    this.pelea,
  }) : super(key: key);

  @override
  State<FormularioPeleaEvento> createState() => _FormularioPeleaEventoState();
}

class _FormularioPeleaEventoState extends State<FormularioPeleaEvento> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _galponIzqCtrl = TextEditingController();
  final _galloIzqCtrl = TextEditingController();
  final _galponDerCtrl = TextEditingController();
  final _galloDerCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();

  File? _video;
  String? _videoUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.pelea != null) {
      _cargarDatos();
    }
  }

  void _cargarDatos() {
    final p = widget.pelea!;
    _tituloCtrl.text = p['titulo_pelea'] ?? '';
    _descripcionCtrl.text = p['descripcion_pelea'] ?? '';
    _galponIzqCtrl.text = p['galpon_izquierda'] ?? '';
    _galloIzqCtrl.text = p['gallo_izquierda_nombre'] ?? '';
    _galponDerCtrl.text = p['galpon_derecha'] ?? '';
    _galloDerCtrl.text = p['gallo_derecha_nombre'] ?? '';
    _horaCtrl.text = p['hora_inicio_estimada'] ?? '';
    _videoUrl = p['video_url'];
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _galponIzqCtrl.dispose();
    _galloIzqCtrl.dispose();
    _galponDerCtrl.dispose();
    _galloDerCtrl.dispose();
    _horaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      print('📹 Video seleccionado: ${video.path}');
      final file = File(video.path);
      final fileSize = await file.length();
      print('📏 Tamaño del video: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      setState(() {
        _video = file;
        _videoUrl = null;
      });
    }
  }

  Future<int> _obtenerSiguienteNumero() async {
    try {
      final peleas = await ApiService.getPeleasEvento(widget.evento['id']);
      if (peleas.isEmpty) return 1;

      int maxNumero = 0;
      for (var pelea in peleas) {
        if (pelea['numero_pelea'] > maxNumero) {
          maxNumero = pelea['numero_pelea'];
        }
      }
      return maxNumero + 1;
    } catch (e) {
      print('Error obteniendo siguiente número: $e');
      return 1;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      print('💾 Guardando pelea... Video: ${_video != null ? "SÍ (${_video!.path})" : "NO"}');

      if (widget.pelea == null) {
        // Crear
        final numeroPelea = await _obtenerSiguienteNumero();
        print('🆕 Creando pelea #$numeroPelea con video: ${_video != null}');
        await ApiService.crearPeleaEvento(
          eventoId: widget.evento['id'],
          numeroPelea: numeroPelea,
          tituloPelea: _tituloCtrl.text,
          galponIzquierda: _galponIzqCtrl.text,
          galloIzquierdaNombre: _galloIzqCtrl.text,
          galponDerecha: _galponDerCtrl.text,
          galloDerechaNombre: _galloDerCtrl.text,
          descripcionPelea: _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
          horaInicioEstimada: _horaCtrl.text.isEmpty ? null : _horaCtrl.text,
          video: _video,
        );
      } else {
        // Actualizar
        print('✏️ Actualizando pelea #${widget.pelea!['id']} con video: ${_video != null}');
        await ApiService.actualizarPeleaEvento(
          peleaId: widget.pelea!['id'],
          tituloPelea: _tituloCtrl.text,
          galponIzquierda: _galponIzqCtrl.text,
          galloIzquierdaNombre: _galloIzqCtrl.text,
          galponDerecha: _galponDerCtrl.text,
          galloDerechaNombre: _galloDerCtrl.text,
          descripcionPelea: _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
          horaInicioEstimada: _horaCtrl.text.isEmpty ? null : _horaCtrl.text,
          video: _video,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pelea guardada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pelea == null ? '➕ Nueva Pelea' : '✏️ Editar Pelea'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(
                labelText: 'Título de la Pelea *',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Título sección
            const Text(
              '← IZQUIERDA DEL JUEZ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),

            // Galpón Izquierda
            TextFormField(
              controller: _galponIzqCtrl,
              decoration: const InputDecoration(
                labelText: 'Galpón *',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            // Gallo Izquierda
            TextFormField(
              controller: _galloIzqCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Gallo *',
                prefixIcon: Icon(Icons.pets),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 24),

            // Título sección
            const Text(
              '→ DERECHA DEL JUEZ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),

            // Galpón Derecha
            TextFormField(
              controller: _galponDerCtrl,
              decoration: const InputDecoration(
                labelText: 'Galpón *',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),

            // Gallo Derecha
            TextFormField(
              controller: _galloDerCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del Gallo *',
                prefixIcon: Icon(Icons.pets),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 24),

            // Hora estimada
            TextFormField(
              controller: _horaCtrl,
              decoration: const InputDecoration(
                labelText: 'Hora Estimada (HH:MM)',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
                hintText: '15:30',
              ),
            ),
            const SizedBox(height: 24),

            // Video
            if (_video != null || _videoUrl != null) ...[
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.green),
                  title: Text(_video != null ? 'Video seleccionado' : 'Video actual'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _video = null;
                      _videoUrl = null;
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón seleccionar video
            OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: Text(_video == null && _videoUrl == null
                  ? 'Seleccionar Video'
                  : 'Cambiar Video'),
            ),
            const SizedBox(height: 32),

            // Botón guardar
            ElevatedButton(
              onPressed: _isSaving ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.pelea == null ? 'CREAR PELEA' : 'GUARDAR CAMBIOS',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

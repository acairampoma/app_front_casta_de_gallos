// 🎬 Videoteca - Consulta de Peleas Grabadas
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../shared/widgets/video_player_widget.dart';

class VideotecaPeleasScreen extends StatefulWidget {
  final Map<String, dynamic> evento;

  const VideotecaPeleasScreen({Key? key, required this.evento}) : super(key: key);

  @override
  State<VideotecaPeleasScreen> createState() => _VideotecaPeleasScreenState();
}

class _VideotecaPeleasScreenState extends State<VideotecaPeleasScreen> {
  List<Map<String, dynamic>> _peleas = [];
  bool _isLoading = true;
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

  void _reproducirVideo(Map<String, dynamic> pelea) {
    final videoUrl = pelea['video_url'];
    if (videoUrl == null || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Video no disponible'),
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

  @override
  Widget build(BuildContext context) {
    final DateTime? fechaEvento = widget.evento['fecha_evento'] != null
        ? DateTime.tryParse(widget.evento['fecha_evento'])
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📹 Videoteca - Peleas', style: TextStyle(fontSize: 18)),
            Text(
              widget.evento['titulo'] ?? '',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _peleas.isEmpty
                  ? _buildEmpty()
                  : _buildLista(),
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
          Icon(Icons.video_library_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Sin peleas grabadas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay peleas disponibles en este evento',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _peleas.length,
      itemBuilder: (ctx, index) {
        final pelea = _peleas[index];
        return _buildPeleaCard(pelea);
      },
    );
  }

  Widget _buildPeleaCard(Map<String, dynamic> pelea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _reproducirVideo(pelea),
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
                  ],
                ),
              ),

              // Icono de reproducción
              IconButton(
                icon: const Icon(Icons.play_circle_filled, size: 40),
                color: AppColors.primary,
                onPressed: () => _reproducirVideo(pelea),
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
}

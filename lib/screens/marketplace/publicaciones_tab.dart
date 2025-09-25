import 'package:flutter/material.dart';
import '../../widgets/marketplace/publicacion_card.dart';
import '../../models/publicacion_model.dart';
import '../../services/marketplace_service.dart';

class PublicacionesTab extends StatefulWidget {
  const PublicacionesTab({Key? key}) : super(key: key);

  @override
  PublicacionesTabState createState() => PublicacionesTabState();
}

class PublicacionesTabState extends State<PublicacionesTab> {
  late final MarketplaceService _service;
  late Future<List<Publicacion>> _future;
  final _searchCtrl = TextEditingController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _service = MarketplaceService();
    _future = _load();
    _loadCurrentUserId();
  }

  void _loadCurrentUserId() async {
    _currentUserId = await _service.getCurrentUserId();
    if (mounted) setState(() {});
  }

  Future<List<Publicacion>> _load({Map<String, dynamic>? filtros}) async {
    print('🔥 PUBLICACIONES TAB - INICIANDO CARGA');
    print('🔍 Filtros aplicados: ${filtros?.toString() ?? 'ninguno'}');

    try {
      final raw = await _service.getPublicaciones(filtros: filtros);
      print('📦 Raw data recibida: ${raw.length} elementos');

      final publicaciones = raw.map((e) => Publicacion.fromJson(e)).toList();
      print('✅ PUBLICACIONES TAB - CARGADAS: ${publicaciones.length}');

      return publicaciones;
    } catch (e) {
      print('❌ ERROR en PublicacionesTab._load: $e');
      rethrow;
    }
  }

  void _buscar() {
    final q = _searchCtrl.text.trim();
    setState(() {
      _future = _load(filtros: q.isNotEmpty ? {'buscar': q} : null);
    });
  }

  void refresh() {
    final q = _searchCtrl.text.trim();
    setState(() {
      _future = _load(filtros: q.isNotEmpty ? {'buscar': q} : null);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtros básicos
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _buscar(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.red),
                    hintText: 'Buscar gallo...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _buscar,
                icon: const Icon(Icons.filter_alt, color: Colors.red),
                label: const Text('Filtros'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Publicacion>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Sin publicaciones'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65, // Más largo para que se vean los botones
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => PublicacionCard(
                  data: items[index],
                  currentUserId: _currentUserId,
                  mostrarOpcionesEdicion: false, // Primera pestaña: solo ver y favoritos
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

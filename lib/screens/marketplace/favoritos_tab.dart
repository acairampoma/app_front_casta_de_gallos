import 'package:flutter/material.dart';
import '../../widgets/marketplace/publicacion_card.dart';
import '../../models/publicacion_model.dart';
import '../../services/marketplace_service.dart';

class FavoritosTab extends StatefulWidget {
  const FavoritosTab({Key? key}) : super(key: key);

  @override
  State<FavoritosTab> createState() => _FavoritosTabState();
}

class _FavoritosTabState extends State<FavoritosTab> {
  late final MarketplaceService _service;
  late Future<List<Publicacion>> _future;
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

  Future<List<Publicacion>> _load() async {
    final raw = await _service.getFavoritos();
    return raw.map((e) => Publicacion.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Publicacion>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.red),
                SizedBox(height: 12),
                Text('Aún no tienes favoritos', style: TextStyle(color: Colors.black54)),
              ],
            ),
          );
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
            mostrarOpcionesEdicion: false, // Segunda pestaña: solo favoritos
          ),
        );
      },
    );
  }
}

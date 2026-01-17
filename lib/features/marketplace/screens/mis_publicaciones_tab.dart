import 'package:flutter/material.dart';
import '../widgets/publicacion_card.dart';
import '../../../models/publicacion_model.dart';
import '../services/marketplace_service.dart';
import 'crear_publicacion_screen.dart';

class MisPublicacionesTab extends StatefulWidget {
  final VoidCallback? onPublicacionCreada;
  const MisPublicacionesTab({Key? key, this.onPublicacionCreada}) : super(key: key);

  @override
  MisPublicacionesTabState createState() => MisPublicacionesTabState();
}

class MisPublicacionesTabState extends State<MisPublicacionesTab> {
  late final MarketplaceService _service;
  late Future<List<Publicacion>> _future;

  @override
  void initState() {
    super.initState();
    _service = MarketplaceService();
    _future = _load();
  }

  Future<List<Publicacion>> _load() async {
    final raw = await _service.getMisPublicaciones();
    return raw.map((e) => Publicacion.fromJson(e)).toList();
  }

  void _refreshList() {
    setState(() {
      _future = _load();
    });
  }

  void refresh() {
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const CrearPublicacionScreen(),
            ),
          );
          if (result == true) {
            _refreshList();
            widget.onPublicacionCreada?.call();
          }
        },
        backgroundColor: Colors.red,
        label: const Text('Publicar'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Publicacion>>(
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
            return const Center(child: Text('No tienes publicaciones'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) => PublicacionCard(
              compact: true,
              data: items[index],
              esMiaPublicacion: true,
              onEstadoChanged: _refreshList,
              mostrarOpcionesEdicion: true, // Tercera pestaña: mostrar opciones de edición
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}

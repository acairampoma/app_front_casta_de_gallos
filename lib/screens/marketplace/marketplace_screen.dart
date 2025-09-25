import 'package:flutter/material.dart';
import 'publicaciones_tab.dart';
import 'favoritos_tab.dart';
import 'mis_publicaciones_tab.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<PublicacionesTabState> _publicacionesKey = GlobalKey<PublicacionesTabState>();
  final GlobalKey<MisPublicacionesTabState> _misPublicacionesKey = GlobalKey<MisPublicacionesTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _onPublicacionCreada() {
    // Refresca ambos tabs
    _publicacionesKey.currentState?.refresh();
    _misPublicacionesKey.currentState?.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Marketplace'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.view_comfy), text: 'Publicaciones'),
            Tab(icon: Icon(Icons.favorite), text: 'Favoritos'),
            Tab(icon: Icon(Icons.store), text: 'Mis Publicaciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PublicacionesTab(key: _publicacionesKey),
          const FavoritosTab(),
          MisPublicacionesTab(key: _misPublicacionesKey, onPublicacionCreada: _onPublicacionCreada),
        ],
      ),
    );
  }
}

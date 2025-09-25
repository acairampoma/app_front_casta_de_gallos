import 'package:flutter/foundation.dart';
import '../models/publicacion_model.dart';
import '../services/marketplace_service.dart';

class MarketplaceProvider extends ChangeNotifier {
  final MarketplaceService service;
  MarketplaceProvider({required this.service});

  bool _loading = false;
  List<Publicacion> _publicaciones = [];
  List<Publicacion> _favoritos = [];
  List<Publicacion> _misPublicaciones = [];

  bool get loading => _loading;
  List<Publicacion> get publicaciones => _publicaciones;
  List<Publicacion> get favoritos => _favoritos;
  List<Publicacion> get misPublicaciones => _misPublicaciones;

  Future<void> cargarPublicaciones() async {
    _loading = true; notifyListeners();
    try {
      final data = await service.getPublicaciones();
      _publicaciones = data.map((e) => Publicacion.fromJson(e)).toList();
    } finally {
      _loading = false; notifyListeners();
    }
  }
}

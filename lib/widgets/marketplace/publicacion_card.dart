import 'package:flutter/material.dart';
import '../../models/publicacion_model.dart';
import '../../screens/marketplace/detalle_publicacion_screen.dart';
import '../../services/whatsapp_service.dart';
import '../../services/marketplace_service.dart';

class PublicacionCard extends StatefulWidget {
  final bool compact;
  final Publicacion? data;
  final bool? esMiaPublicacion;
  final int? currentUserId;
  final VoidCallback? onEstadoChanged;
  final bool mostrarOpcionesEdicion; // Nueva: solo para pestaña "Mis Publicaciones"
  const PublicacionCard({
    Key? key,
    this.compact = false,
    this.data,
    this.esMiaPublicacion,
    this.currentUserId,
    this.onEstadoChanged,
    this.mostrarOpcionesEdicion = false, // Por defecto no mostrar
  }) : super(key: key);

  @override
  State<PublicacionCard> createState() => _PublicacionCardState();
}

class _PublicacionCardState extends State<PublicacionCard> {
  late bool _esFavorito;
  bool _isUpdatingFavorito = false;

  bool get _esMiaPublicacion {
    // Si se especifica explícitamente, usar ese valor (para MisPublicacionesTab)
    if (widget.esMiaPublicacion != null) {
      print('🔍 USANDO esMiaPublicacion EXPLÍCITO: ${widget.esMiaPublicacion}');
      return widget.esMiaPublicacion!;
    }
    // Si no, determinar comparando user IDs
    if (widget.data?.userId != null && widget.currentUserId != null) {
      final esPropia = widget.data!.userId == widget.currentUserId;
      print('🔍 VERIFICANDO PROPIEDAD: userID=${widget.data!.userId}, currentUser=${widget.currentUserId}, esPropia=$esPropia');
      return esPropia;
    }
    print('🔍 NO SE PUEDE VERIFICAR PROPIEDAD: userID=${widget.data?.userId}, currentUser=${widget.currentUserId}');
    return false;
  }

  @override
  void initState() {
    super.initState();
    _esFavorito = widget.data?.esFavorito ?? false;
  }

  void _showEstadoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.store, color: Colors.green),
              title: const Text('En Venta'),
              onTap: () => _cambiarEstado('venta'),
            ),
            ListTile(
              leading: const Icon(Icons.pause, color: Colors.orange),
              title: const Text('Pausado'),
              onTap: () => _cambiarEstado('pausado'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.blue),
              title: const Text('Vendido'),
              onTap: () => _cambiarEstado('vendido'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    Navigator.pop(context);
    try {
      final service = MarketplaceService();
      await service.actualizarPublicacion(
        widget.data!.id,
        estado: nuevoEstado,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado cambiado a: $nuevoEstado')),
      );
      widget.onEstadoChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showEditarPrecioDialog() {
    final controller = TextEditingController(text: widget.data?.precio.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Precio'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nuevo precio (S/)',
            prefixText: 'S/ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _cambiarPrecio(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarPrecio(String nuevoPrecioStr) async {
    Navigator.pop(context);
    final nuevoPrecio = double.tryParse(nuevoPrecioStr);

    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio inválido')),
      );
      return;
    }

    try {
      final service = MarketplaceService();
      await service.actualizarPublicacion(
        widget.data!.id,
        precio: nuevoPrecio,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Precio actualizado a S/ ${nuevoPrecio.toStringAsFixed(2)}')),
      );
      widget.onEstadoChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar la publicación de "${widget.data?.nombre ?? 'este gallo'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarPublicacion();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarPublicacion() async {
    try {
      final service = MarketplaceService();
      await service.eliminarPublicacion(widget.data!.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Publicación eliminada exitosamente')),
      );
      widget.onEstadoChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando publicación: $e')),
      );
    }
  }

  void _mostrarCarruselFotos(BuildContext context, int initialIndex) {
    if (widget.data == null || widget.data!.fotos.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: widget.data!.fotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.data!.fotos[index],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Botón cerrar
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              // Indicador de foto actual
              if (widget.data!.fotos.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${initialIndex + 1} / ${widget.data!.fotos.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotones() {
    print('🔥 _buildBotones: esMiaPublicacion=$_esMiaPublicacion, mostrarOpcionesEdicion=${widget.mostrarOpcionesEdicion}');

    // SI es mi publicación Y se permiten opciones de edición -> botones de edición
    if (_esMiaPublicacion && widget.mostrarOpcionesEdicion) {
      print('✅ Mostrando botones de EDICIÓN');
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showEstadoDialog,
                  icon: const Icon(Icons.edit, size: 16), // Más pequeño
                  label: const Text('Estado', style: TextStyle(fontSize: 11)), // Más pequeño
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30), // Más compacto
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
              const SizedBox(width: 4), // Menos espacio
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showEditarPrecioDialog,
                  icon: const Icon(Icons.attach_money, size: 16), // Más pequeño
                  label: const Text('Precio', style: TextStyle(fontSize: 11)), // Más pequeño
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30), // Más compacto
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Menos espacio
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmarEliminar(),
              icon: const Icon(Icons.delete_outline, size: 16), // Más pequeño
              label: const Text('Eliminar', style: TextStyle(fontSize: 11)), // Más pequeño
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(0, 30), // Más compacto
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      );
    }

    // SI NO es mi publicación O NO se permiten opciones de edición -> botones estándar (favorito + contactar)
    else {
      print('✅ Mostrando botones de FAVORITO + CONTACTAR');
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isUpdatingFavorito ? null : _toggleFavorito,
              icon: _isUpdatingFavorito
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_esFavorito ? Icons.favorite : Icons.favorite_border, size: 16), // Más pequeño
              label: Text(_esFavorito ? 'Favorito' : 'Favorito', style: const TextStyle(fontSize: 11)), // Más pequeño
              style: OutlinedButton.styleFrom(
                foregroundColor: _esFavorito ? Colors.red : Colors.grey,
                minimumSize: const Size(0, 30), // Más compacto
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
          const SizedBox(width: 4), // Menos espacio
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (widget.data?.vendedorTelefono ?? '').isEmpty
                  ? null
                  : () async {
                      // 🔥 CAMBIO: Ahora sí abrir WhatsApp en pestaña 1
                      try {
                        await WhatsappService.openChat(
                          phone: widget.data!.vendedorTelefono!,
                          message: 'Hola, estoy interesado en ${widget.data!.nombre}',
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error abriendo WhatsApp: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.chat, size: 16), // WhatsApp
              label: const Text('Chat', style: TextStyle(fontSize: 11)), // WhatsApp
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green, // Color verde como WhatsApp
                side: const BorderSide(color: Colors.green), // Borde verde
                minimumSize: const Size(0, 30), // Más compacto
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _toggleFavorito() async {
    if (widget.data == null || _isUpdatingFavorito) return;

    print('🔥 TOGGLE FAVORITO - Publicacion ID: ${widget.data!.id}');
    print('🔥 Estado actual: $_esFavorito');

    setState(() {
      _isUpdatingFavorito = true;
    });

    try {
      final service = MarketplaceService();
      final result = await service.toggleFavorito(widget.data!.id);

      print('🔥 RESULTADO: ${result.toString()}');

      if (result['success']) {
        setState(() {
          _esFavorito = result['is_favorite'] ?? !_esFavorito;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_esFavorito ? '❤️ Agregado a favoritos' : '💔 Eliminado de favoritos'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR EN TOGGLE FAVORITO: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUpdatingFavorito = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔥 BUILD PublicacionCard: compact=${widget.compact}, esMiaPublicacion=$_esMiaPublicacion, mostrarOpcionesEdicion=${widget.mostrarOpcionesEdicion}');

    return InkWell(
      onTap: widget.data == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetallePublicacionScreen(pub: widget.data!),
                ),
              ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrusel de fotos
            AspectRatio(
              aspectRatio: widget.compact ? 1.5 : 1.2, // Más compacto para mostrar botones
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: widget.data != null && widget.data!.fotos.isNotEmpty
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: PageView.builder(
                            itemCount: widget.data!.fotos.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _mostrarCarruselFotos(context, index),
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: Image.network(
                                    widget.data!.fotos[index],
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) {
                                      print('❌ Error cargando imagen: ${widget.data!.fotos[index]}');
                                      return const Icon(Icons.broken_image, size: 48, color: Colors.grey);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Indicador de fotos (contador)
                        if (widget.data!.fotos.length > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.data!.fotos.length} fotos',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        // Icono de cámara para indicar que es clickeable
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Builder(
                      builder: (context) {
                        if (widget.data != null) {
                          print('📷 PublicacionCard: ID=${widget.data!.id}, Fotos=${widget.data!.fotos.length}');
                        }
                        return const Icon(Icons.image, size: 48, color: Colors.grey);
                      },
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0), // Más compacto: 8->6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre - más pequeño
                  Text(
                    widget.data?.nombre ?? 'Gallo Campeón',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), // 14->12
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1), // Más compacto: 2->1

                  // Raza + Código - más pequeño
                  Text(
                    [
                      widget.data?.raza ?? 'Sin raza',
                      if (widget.data?.codigoIdentificacion != null) '• ${widget.data!.codigoIdentificacion}',
                    ].where((e) => (e ?? '').toString().isNotEmpty).join(' '),
                    style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w500), // 11->10
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Peso + Altura + Color - más pequeño
                  if (widget.data?.peso != null || widget.data?.altura != null || widget.data?.color != null)
                    Text(
                      [
                        if (widget.data?.peso != null) '${widget.data!.peso!.toStringAsFixed(1)} kg',
                        if (widget.data?.altura != null) '${widget.data!.altura} cm',
                        if (widget.data?.color != null) widget.data!.color,
                      ].where((e) => (e ?? '').toString().isNotEmpty).join(' • '),
                      style: const TextStyle(color: Colors.black54, fontSize: 9), // 10->9
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Patas + Plumaje - más pequeño
                  if (widget.data?.colorPatas != null || widget.data?.colorPlumaje != null)
                    Text(
                      [
                        if (widget.data?.colorPatas != null) 'Patas: ${widget.data!.colorPatas}',
                        if (widget.data?.colorPlumaje != null) 'Plumaje: ${widget.data!.colorPlumaje}',
                      ].where((e) => (e ?? '').toString().isNotEmpty).join(' • '),
                      style: const TextStyle(color: Colors.black54, fontSize: 9), // 10->9
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 2), // Más compacto: 4->2

                  // Precio - un poco más pequeño
                  Text(
                    widget.data != null ? 'S/ ${widget.data!.precio.toStringAsFixed(2)}' : 'S/ 450.00',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14), // 16->14
                  ),
                ],
              ),
            ),
            // Siempre mostrar botones - solo ajustar padding si es compact
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 6.0, // Más compacto
                vertical: widget.compact ? 4 : 6, // Aún más compacto si es compact
              ),
              child: _buildBotones(),
            ),
          ],
        ),
      ),
    );
  }
}

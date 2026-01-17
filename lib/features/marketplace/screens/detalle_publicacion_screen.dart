import 'package:flutter/material.dart';
import '../../../models/publicacion_model.dart';
import '../widgets/foto_carousel.dart';
import '../../../services/whatsapp_service.dart';

class DetallePublicacionScreen extends StatelessWidget {
  final Publicacion pub;
  const DetallePublicacionScreen({Key? key, required this.pub}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pub.nombre.isNotEmpty ? pub.nombre : 'Detalle del Gallo'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carrusel de fotos
            SizedBox(
              height: 260,
              child: FotoCarousel(fotos: pub.fotos),
            ),
            const SizedBox(height: 12),

            // Cabecera: Nombre + Precio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pub.nombre,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pub.raza.isNotEmpty ? pub.raza : 'Raza no especificada',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'S/ ${pub.precio.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Características importantes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Características', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  if ((pub.codigoIdentificacion ?? '').isNotEmpty)
                    _featureRow(Icons.qr_code, 'Código', pub.codigoIdentificacion!),
                  if ((pub.fechaNacimiento ?? '').isNotEmpty)
                    _featureRow(Icons.cake, 'Fecha Nacimiento', _formatFecha(pub.fechaNacimiento!)),
                  _featureRow(Icons.scale, 'Peso', pub.peso != null ? '${pub.peso!.toStringAsFixed(1)} kg' : 'No especificado'),
                  _featureRow(Icons.height, 'Altura', pub.altura != null ? '${pub.altura} cm' : 'No especificado'),
                  _featureRow(Icons.color_lens, 'Color', pub.color ?? 'No especificado'),
                  _featureRow(Icons.emoji_nature, 'Color de Patas', pub.colorPatas ?? 'No especificado'),
                  _featureRow(Icons.brush, 'Color de Plumaje', pub.colorPlumaje ?? 'No especificado'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Observaciones / descripción
            if ((pub.observaciones ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(pub.observaciones!),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Información del Vendedor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Información del Vendedor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  if ((pub.vendedorNombre ?? '').isNotEmpty)
                    _featureRow(Icons.person, 'Nombre', pub.vendedorNombre!),
                  if ((pub.vendedorTelefono ?? '').isNotEmpty)
                    _featureRow(Icons.phone, 'Teléfono', pub.vendedorTelefono!),
                  if ((pub.vendedorEmail ?? '').isNotEmpty)
                    _featureRow(Icons.email, 'Email', pub.vendedorEmail!),
                  if ((pub.vendedorUbicacion ?? '').isNotEmpty)
                    _featureRow(Icons.location_on, 'Ubicación', pub.vendedorUbicacion!),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favorito'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (pub.vendedorTelefono ?? '').isEmpty
                      ? null
                      : () async {
                          try {
                            await WhatsappService.openChat(
                              phone: pub.vendedorTelefono!,
                              message: 'Hola, estoy interesado en ${pub.nombre}',
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
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(String fecha) {
    try {
      final DateTime fechaDate = DateTime.parse(fecha);
      return '${fechaDate.day}/${fechaDate.month}/${fechaDate.year}';
    } catch (e) {
      return fecha; // Si no se puede parsear, devolver el string original
    }
  }

  Widget _featureRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

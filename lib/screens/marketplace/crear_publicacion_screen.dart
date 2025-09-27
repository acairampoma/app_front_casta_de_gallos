import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/gallo_service.dart';
import '../../services/marketplace_service.dart';

class CrearPublicacionScreen extends StatefulWidget {
  const CrearPublicacionScreen({Key? key}) : super(key: key);

  @override
  State<CrearPublicacionScreen> createState() => _CrearPublicacionScreenState();
}

class _CrearPublicacionScreenState extends State<CrearPublicacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();

  List<Map<String, dynamic>> _gallos = [];
  Map<String, dynamic>? _galloSeleccionado;
  bool _isLoading = false;
  bool _isLoadingGallos = true;

  @override
  void initState() {
    super.initState();
    _cargarGallos();
  }

  Future<void> _cargarGallos() async {
    try {
      // Cargar gallos y publicaciones activas en paralelo
      final futures = await Future.wait([
        GalloService.getGallos(),
        MarketplaceService().getMisPublicaciones(),
      ]);

      final gallos = futures[0] as List<Map<String, dynamic>>;
      final publicacionesRaw = futures[1] as List<Map<String, dynamic>>;

      // Obtener IDs de gallos que ya están publicados
      final gallosPublicados = publicacionesRaw
          .map((p) => p['gallo_info']?['id'] ?? p['gallo_id'])
          .where((id) => id != null)
          .toSet();

      // Filtrar gallos que NO están publicados
      final gallosDisponibles = gallos.where((gallo) {
        final galloId = gallo['id'];
        return !gallosPublicados.contains(galloId);
      }).toList().cast<Map<String, dynamic>>();

      setState(() {
        _gallos = gallosDisponibles;
        _isLoadingGallos = false;
      });

      if (gallosDisponibles.isEmpty && gallos.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todos tus gallos ya están publicados en el marketplace'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingGallos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando gallos: $e')),
      );
    }
  }

  Future<void> _crearPublicacion() async {
    if (!_formKey.currentState!.validate() || _galloSeleccionado == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final service = MarketplaceService();
      await service.crearPublicacion(
        galloId: _galloSeleccionado!['id'],
        precio: double.parse(_precioController.text),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Publicación creada exitosamente!')),
      );

      Navigator.of(context).pop(true); // Regresa true para refrescar la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando publicación: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Publicación'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingGallos
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _gallos.isEmpty
              ? const Center(child: Text('No tienes gallos para publicar'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector de Gallo
                        const Text(
                          'Seleccionar Gallo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Map<String, dynamic>>(
                              hint: const Text('Selecciona un gallo'),
                              value: _galloSeleccionado,
                              isExpanded: true,
                              onChanged: (value) {
                                setState(() {
                                  _galloSeleccionado = value;
                                });
                              },
                              items: _gallos.map((gallo) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: gallo,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            // 🔥 FIX: Buscar foto en estructura nueva fotos_adicionales
                                            String? fotoUrl;

                                            // Primero revisar fotos_adicionales (estructura nueva)
                                            if (gallo['fotos_adicionales'] != null) {
                                              try {
                                                final fotosData = gallo['fotos_adicionales'];
                                                List<dynamic> fotos = [];

                                                if (fotosData is String) {
                                                  // Si es JSON string, parsearlo
                                                  final parsed = json.decode(fotosData);
                                                  fotos = parsed is List ? parsed : [];
                                                } else if (fotosData is List) {
                                                  fotos = fotosData;
                                                }

                                                // Buscar foto principal o tomar la primera
                                                for (var foto in fotos) {
                                                  if (foto is Map && foto['url'] != null) {
                                                    if (foto['es_principal'] == true) {
                                                      fotoUrl = foto['url'];
                                                      break;
                                                    } else if (fotoUrl == null) {
                                                      fotoUrl = foto['url']; // Backup: primera foto encontrada
                                                    }
                                                  }
                                                }
                                              } catch (e) {
                                                print('❌ Error parseando fotos_adicionales: $e');
                                              }
                                            }

                                            // Fallback: revisar campo fotos legacy
                                            if (fotoUrl == null && gallo['fotos'] != null && gallo['fotos'].isNotEmpty) {
                                              fotoUrl = gallo['fotos'][0];
                                            }

                                            // Fallback: revisar foto_principal_url
                                            if (fotoUrl == null && gallo['foto_principal_url'] != null) {
                                              fotoUrl = gallo['foto_principal_url'];
                                            }

                                            return fotoUrl != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.network(
                                                      fotoUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(
                                                        Icons.image,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(Icons.image, color: Colors.grey);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              gallo['nombre'] ?? 'Sin nombre',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (gallo['raza_id'] != null)
                                              Text(
                                                gallo['raza_id'].toString().replaceAll('_', ' '),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Campo de Precio
                        TextFormField(
                          controller: _precioController,
                          decoration: const InputDecoration(
                            labelText: 'Precio (S/)',
                            prefixText: 'S/ ',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'El precio es requerido';
                            }
                            final precio = double.tryParse(value);
                            if (precio == null || precio <= 0) {
                              return 'Ingresa un precio válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo de Descripción (opcional)
                        TextFormField(
                          controller: _descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                            border: OutlineInputBorder(),
                            helperText: 'Describe características especiales del gallo',
                          ),
                          maxLines: 3,
                          maxLength: 500,
                        ),

                        const Spacer(),

                        // Botón Publicar
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _crearPublicacion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text('Crear Publicación'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _precioController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
}
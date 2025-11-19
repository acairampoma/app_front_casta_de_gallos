import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/gallo_service.dart';
import '../../../services/connection_service.dart';
import '../../../shared/constants/app_icons.dart';
import 'edit_gallo_multistep_screen.dart';

class GenealogyTreeScreen extends StatefulWidget {
  final Map<String, dynamic> galloSeleccionado;
  final List<dynamic> todosLosGallos;

  const GenealogyTreeScreen({
    Key? key,
    required this.galloSeleccionado,
    required this.todosLosGallos,
  }) : super(key: key);

  @override
  State<GenealogyTreeScreen> createState() => _GenealogyTreeScreenState();
}

class _GenealogyTreeScreenState extends State<GenealogyTreeScreen> {
  double _scale = 1.0;
  Map<String, dynamic>? _arbolCompleto;
  bool _isLoading = true;
  String? _error;
  
  // Datos del árbol
  Map<String, dynamic>? _galloBase;
  Map<String, dynamic>? _padre;
  Map<String, dynamic>? _madre;
  Map<String, dynamic>? _abueloPaterno;
  Map<String, dynamic>? _abuelaPaterna;
  Map<String, dynamic>? _abueloMaterno;
  Map<String, dynamic>? _abuelaMaterna;

  @override
  void initState() {
    super.initState();
    _cargarArbolGenealogico();
  }

  // 🌳 CARGAR ÁRBOL DESDE BACKEND
  Future<void> _cargarArbolGenealogico() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final galloId = widget.galloSeleccionado['id'];
      print('🌳 Cargando árbol genealógico para gallo ID: $galloId');
      
      final arbolData = await GalloService.getGenealogiaCompleta(galloId);
      
      if (arbolData['success'] == true && arbolData['data'] != null) {
        final data = arbolData['data'];
        final arbol = data['arbol_genealogico']['ancestros'];
        
        setState(() {
          _arbolCompleto = data;
          _galloBase = arbol;
          _padre = arbol['padre'];
          _madre = arbol['madre'];
          
          // Abuelos paternos
          if (_padre != null) {
            _abueloPaterno = _padre!['padre'];
            _abuelaPaterna = _padre!['madre'];
          }
          
          // Abuelos maternos
          if (_madre != null) {
            _abueloMaterno = _madre!['padre'];
            _abuelaMaterna = _madre!['madre'];
          }
          
          _isLoading = false;
        });
        
        print('✅ Árbol genealógico cargado exitosamente');
      } else {
        throw Exception('No se pudo cargar el árbol genealógico');
      }
    } catch (e) {
      print('❌ Error cargando árbol: $e');
      
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      // Fallback a modo local
      _cargarGenealogiaLocal();
    }
  }

  // 📱 FALLBACK: Cargar desde datos locales
  void _cargarGenealogiaLocal() {
    final padreId = widget.galloSeleccionado['padre_id'];
    if (padreId != null) {
      _padre = widget.todosLosGallos.where((g) => g['id'] == padreId).firstOrNull;
    }

    final madreId = widget.galloSeleccionado['madre_id'];
    if (madreId != null) {
      _madre = widget.todosLosGallos.where((g) => g['id'] == madreId).firstOrNull;
    }

    if (_padre != null) {
      final abueloPatId = _padre!['padre_id'];
      final abuelaPatId = _padre!['madre_id'];
      
      if (abueloPatId != null) {
        _abueloPaterno = widget.todosLosGallos.where((g) => g['id'] == abueloPatId).firstOrNull;
      }
      if (abuelaPatId != null) {
        _abuelaPaterna = widget.todosLosGallos.where((g) => g['id'] == abuelaPatId).firstOrNull;
      }
    }

    if (_madre != null) {
      final abueloMatId = _madre!['padre_id'];
      final abuelaMatId = _madre!['madre_id'];
      
      if (abueloMatId != null) {
        _abueloMaterno = widget.todosLosGallos.where((g) => g['id'] == abueloMatId).firstOrNull;
      }
      if (abuelaMatId != null) {
        _abuelaMaterna = widget.todosLosGallos.where((g) => g['id'] == abuelaMatId).firstOrNull;
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }


  // 🖼️ WIDGET PARA MOSTRAR IMAGEN DE CLOUDINARY
  Widget _buildNetworkImage(String? fotoUrl, double iconSize, {String? nodeType}) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      // 🐓 Usar iconos personalizados según el tipo de nodo
      if (nodeType == 'PADRE') {
        return Image.asset(
          'assets/images/icono/galloc.webp',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return AppIcons.gallo(size: iconSize, color: AppColors.primary);
          },
        );
      } else if (nodeType == 'MADRE') {
        return Image.asset(
          'assets/images/icono/gallina.webp',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return AppIcons.gallo(size: iconSize, color: AppColors.primary);
          },
        );
      } else {
        // Default para otros casos
        return AppIcons.gallo(
          size: iconSize,
          color: AppColors.primary,
        );
      }
    }

    // 🔥 MANEJAR URLs DE CLOUDINARY Y ASSETS
    if (fotoUrl.startsWith('http')) {
      // URLs de internet (Cloudinary)
      return Image.network(
        fotoUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 1,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Error cargando imagen en árbol: $fotoUrl - $error');
          return Icon(
            Icons.pets,
            size: iconSize,
            color: AppColors.primary,
          );
        },
      );
    } else if (fotoUrl.startsWith('assets/')) {
      // Assets locales
      return Image.asset(
        fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.pets,
            size: iconSize,
            color: AppColors.primary,
          );
        },
      );
    } else {
      // Fallback para rutas desconocidas
      return AppIcons.gallo(
        size: iconSize,
        color: AppColors.primary,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/icono/padres.webp',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            const Text(
              'Árbol Genealógico',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_isLoading) 
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargarArbolGenealogico,
              tooltip: 'Recargar árbol',
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('🌳 Cargando árbol genealógico...'),
              ],
            ),
          )
        : Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Transform.scale(
                  scale: _scale,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildGenealogyTree(),
                  ),
                ),
              ),
            ],
          ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "zoom_in",
            mini: true,
            onPressed: () {
              setState(() {
                _scale = (_scale + 0.2).clamp(0.5, 2.0);
              });
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.zoom_in, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "zoom_out",
            mini: true,
            onPressed: () {
              setState(() {
                _scale = (_scale - 0.2).clamp(0.5, 2.0);
              });
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.zoom_out, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.galloSeleccionado['nombre'] ?? 'Gallo Seleccionado',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Línea de sangre: ${_getRazaText(widget.galloSeleccionado)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenealogyTree() {
    return Column(
      children: [
        // 1. GALLO PRINCIPAL (ARRIBA)
        _buildGenerationSection(
          '🏆 GALLO PRINCIPAL',
          [_buildGalloCard(widget.galloSeleccionado, '👑 EL CAMPEÓN', isMainGallo: true)],
          AppColors.primary,
        ),
        
        if (_padre != null || _madre != null) ...[
          _buildVerticalConnector(),
          _buildHorizontalSplitter(),
          
          // 2. PADRES (GENERACIÓN -1)
          _buildGenerationSection(
            'PADRES',
            [
              Row(
                children: [
                  Expanded(child: _buildGalloCard(_padre, '🐓 PADRE')),
                  const SizedBox(width: 24),
                  Expanded(child: _buildGalloCard(_madre, '🐔 MADRE')),
                ],
              ),
            ],
            Colors.blue,
            titleIcon: Image.asset(
              'assets/images/icono/padres.webp',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.family_restroom, color: Colors.white, size: 24);
              },
            ),
          ),
          
          if (_abueloPaterno != null || _abuelaPaterna != null || 
              _abueloMaterno != null || _abuelaMaterna != null) ...[
            _buildParentToGrandparentConnectors(),
            
            // 3. ABUELOS (GENERACIÓN -2)
            _buildGenerationSection(
              'ABUELOS',
              [
                Column(
                  children: [
                    if (_abueloPaterno != null || _abuelaPaterna != null) ...[
                      _buildSubGenerationLabel('Línea Paterna'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGalloCard(_abueloPaterno, '👴 ABUELO PAT.')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGalloCard(_abuelaPaterna, '👵 ABUELA PAT.')),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    if (_abueloMaterno != null || _abuelaMaterna != null) ...[
                      _buildSubGenerationLabel('Línea Materna'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildGalloCard(_abueloMaterno, '👴 ABUELO MAT.')),
                          const SizedBox(width: 16),
                          Expanded(child: _buildGalloCard(_abuelaMaterna, '👵 ABUELA MAT.')),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
              Colors.orange,
              titleIcon: Image.asset(
                'assets/images/icono/padres.webp',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.elderly, color: Colors.white, size: 24);
                },
              ),
            ),
          ],
        ],
        
        const SizedBox(height: 32),
        _buildBackToListButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGenerationSection(String title, List<Widget> children, Color color, {Widget? titleIcon}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titleIcon != null) ...[
                  titleIcon,
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildVerticalConnector() {
    return Container(
      width: 4,
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSplitter() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.7), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentToGrandparentConnectors() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: (_abueloPaterno != null || _abuelaPaterna != null)
                ? Column(
                    children: [
                      Container(
                        width: 3,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: (_abueloMaterno != null || _abuelaMaterna != null)
                ? Column(
                    children: [
                      Container(
                        width: 3,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubGenerationLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildBackToListButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.list_alt, size: 24),
        label: const Text(
          '📋 Regresar a la Lista',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: Colors.green.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildGalloCard(Map<String, dynamic>? gallo, String label, {bool isMainGallo = false}) {
    if (gallo == null) {
      return _buildEmptyCard(label);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isMainGallo ? AppColors.primary : 
                   (label.contains('PADRE') || label.contains('MADRE')) ? Colors.blue : Colors.grey[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Agregar icono personalizado para PADRE, MADRE, ABUELO y ABUELA
              if (label.contains('PADRE') && !label.contains('ABUELO')) ...[
                Image.asset(
                  'assets/images/icono/galloc.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.male, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ] else if (label.contains('MADRE') && !label.contains('ABUELA')) ...[
                Image.asset(
                  'assets/images/icono/gallina.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.female, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ] else if (label.contains('ABUELO')) ...[
                Image.asset(
                  'assets/images/icono/galloc.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.male, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ] else if (label.contains('ABUELA')) ...[
                Image.asset(
                  'assets/images/icono/gallina.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.female, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label.replaceAll('🐓 ', '').replaceAll('🐔 ', '').replaceAll('👴 ', '').replaceAll('👵 ', ''), // Quitar emojis del texto
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showGalloDetail(gallo),
          child: Container(
                width: isMainGallo ? 280 : 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isMainGallo ? AppColors.primary : Colors.grey[300]!,
                    width: isMainGallo ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: isMainGallo ? 80 : 60,
                      height: isMainGallo ? 80 : 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildNetworkImage(
                          gallo['foto_principal_url'], 
                          isMainGallo ? 40 : 30,
                          nodeType: label.contains('PADRE') ? 'PADRE' : 
                                   label.contains('MADRE') ? 'MADRE' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      gallo['nombre'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: isMainGallo ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        gallo['codigo_identificacion'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Raza: ${_getRazaText(gallo)}\n'
                      'Peso: ${gallo['peso'] ?? 0}kg\n'
                      'Estado: ${gallo['estado'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildEmptyCard(String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (label.contains('PADRE') || label.contains('MADRE')) ? Colors.blue : Colors.grey[400],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Agregar icono personalizado para PADRE, MADRE, ABUELO y ABUELA vacíos
              if (label.contains('PADRE') && !label.contains('ABUELO')) ...[
                Image.asset(
                  'assets/images/icono/galloc.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.male, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ] else if (label.contains('MADRE') && !label.contains('ABUELA')) ...[
                Image.asset(
                  'assets/images/icono/gallina.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.female, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ] else if (label.contains('ABUELO')) ...[
                Image.asset(
                  'assets/images/icono/galloc.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.male, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ] else if (label.contains('ABUELA')) ...[
                Image.asset(
                  'assets/images/icono/gallina.webp',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.female, color: Colors.white, size: 16);
                  },
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label.replaceAll('🐓 ', '').replaceAll('🐔 ', '').replaceAll('👴 ', '').replaceAll('👵 ', ''),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 240,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                size: 40,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No registrado',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🗑️ ELIMINAR GALLO - MEJORADO CON CONTEOS Y LOADING
  void _eliminarGallo(Map<String, dynamic> gallo) async {
    final galloId = gallo['id'];
    
    if (galloId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede eliminar este gallo (ID no disponible)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Mostrar loading mientras obtenemos los conteos
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Obteniendo información...'),
            ],
          ),
        ),
      );

      // Obtener conteos de relaciones
      final conteos = await GalloService.fetchRelationsCounts(galloId);
      
      // Cerrar loading
      if (mounted) Navigator.pop(context);

      // Mostrar diálogo de confirmación con conteos
      final parentContext = context;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              const Text('⚠️ Eliminar Gallo'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de eliminar a "${gallo['nombre']}"?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (conteos['peleas']! > 0 || conteos['topes']! > 0 || conteos['vacunas']! > 0) ...[
                const Text(
                  'Este gallo tiene:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                if (conteos['peleas']! > 0)
                  Row(
                    children: [
                      const Icon(Icons.sports_mma, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('${conteos['peleas']} peleas'),
                    ],
                  ),
                if (conteos['topes']! > 0)
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('${conteos['topes']} topes'),
                    ],
                  ),
                if (conteos['vacunas']! > 0)
                  Row(
                    children: [
                      const Icon(Icons.vaccines, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('${conteos['vacunas']} vacunas'),
                    ],
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: const Text(
                    'Al eliminar, estos registros dejarán de mostrarse en la app.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: const Text(
                    'Este gallo no tiene peleas, topes o vacunas registradas.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo
                
                // Mostrar overlay de procesamiento
                showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Procesando eliminación de "${gallo['nombre']}"...'),
                      ],
                    ),
                  ),
                );
                
                try {
                  await GalloService.deleteGallo(galloId);
                  
                  // Cerrar loading
                  if (mounted) Navigator.pop(parentContext);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('🗑️ Gallo "${gallo['nombre']}" eliminado correctamente'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                  
                  // Recargar árbol genealógico
                  _cargarArbolGenealogico();
                  
                } catch (e) {
                  // Cerrar loading si hay error
                  if (mounted) Navigator.pop(parentContext);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error eliminando gallo: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar loading si falla obtener conteos
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error obteniendo información: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔧 EDITAR GALLO
  void _editarGallo(Map<String, dynamic> gallo) {
    final galloId = gallo['id'];
    
    if (galloId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede editar este gallo (ID no disponible)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('🔧 Editando gallo ID: $galloId - ${gallo['nombre']}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGalloMultistepScreen(
          gallo: gallo,  // Solo necesita el parámetro gallo
        ),
      ),
    ).then((result) async {
      // EditGalloMultistepScreen devuelve un Map con el resultado, no un bool
      if (result != null) {
        print('✅ Gallo editado, recargando árbol genealógico...');
        
        // Limpiar datos anteriores para forzar actualización visual
        setState(() {
          _isLoading = true;
          _arbolCompleto = null;
          _galloBase = null;
          _padre = null;
          _madre = null;
        });
        
        // Pequeño delay para asegurar que el backend ya actualizó
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Recargar el árbol con datos frescos
        await _cargarArbolGenealogico();
      }
    });
  }

  void _showGalloDetail(Map<String, dynamic> gallo) async {
    // 🔥 SOLUCIÓN SIMPLE: Cargar datos completos del gallo usando su ID
    print('🔍 === CARGANDO DATOS COMPLETOS DEL GALLO ===');
    print('📋 Gallo clickeado: ${gallo['nombre']} (ID: ${gallo['id']})');
    
    // Mostrar loading mientras carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
    
    try {
      // 🎯 USAR EL MISMO SERVICIO QUE LA LISTA PRINCIPAL
      final galloCompleto = await GalloService.getGalloById(gallo['id']);
      
      // Cerrar loading
      if (mounted) Navigator.pop(context);
      
      if (galloCompleto == null) {
        // Si no encuentra el gallo, usar los datos que tenemos
        print('⚠️ No se encontró el gallo, usando datos del árbol');
        _mostrarModalConDatos(gallo);
      } else {
        // 🎉 TENEMOS TODOS LOS DATOS!
        print('✅ DATOS COMPLETOS OBTENIDOS');
        print('📊 Campos disponibles: ${galloCompleto.keys.toList()}');
        print('📝 Peso: ${galloCompleto['peso']}, Altura: ${galloCompleto['altura']}');
        print('📝 Color placa: ${galloCompleto['color_placa']}, Ubicación: ${galloCompleto['ubicacion_placa']}');
        _mostrarModalConDatos(galloCompleto);
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) Navigator.pop(context);
      print('❌ Error cargando datos: $e');
      _mostrarModalConDatos(gallo);
    }
  }
  
  void _mostrarModalConDatos(Map<String, dynamic> galloActualizado) {
    print('🎯 Mostrando modal con datos: ${galloActualizado['nombre']}');
    print('📊 Datos para el modal: peso=${galloActualizado['peso']}, altura=${galloActualizado['altura']}, color_placa=${galloActualizado['color_placa']}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildNetworkImage(galloActualizado['foto_principal_url'], 40),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    galloActualizado['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Código: ${galloActualizado['codigo_identificacion'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Generación: ${galloActualizado['generacion'] ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow('Raza', _getRazaText(galloActualizado)),
                        _buildDetailRow('Peso', '${galloActualizado['peso'] ?? 0} kg'),
                        _buildDetailRow('Color', _getColorText(galloActualizado)),
                        _buildDetailRow('Estado', galloActualizado['estado'] ?? 'N/A'),
                        _buildDetailRow('Fecha Nacimiento', galloActualizado['fecha_nacimiento'] ?? 'N/A'),
                        if (galloActualizado['procedencia'] != null && galloActualizado['procedencia'].toString().isNotEmpty)
                          _buildDetailRow('Procedencia', galloActualizado['procedencia']),
                        if (galloActualizado['notas'] != null && galloActualizado['notas'].toString().isNotEmpty)
                          _buildDetailRow('Notas', galloActualizado['notas']),
                        const SizedBox(height: 20),
                        
                        // 🔧 BOTONES DE ACCIÓN - Solo mostrar editar/eliminar si NO es el gallo principal
                        if (galloActualizado['id'] != widget.galloSeleccionado['id']) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context); // Cerrar modal
                                    print('🔧 Enviando a editar con datos completos');
                                    print('📊 Datos enviados: ${galloActualizado.keys.toList()}');
                                    _editarGallo(galloActualizado); // DATOS COMPLETOS GARANTIZADOS
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    minimumSize: const Size(0, 45),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context); // Cerrar modal
                                    _eliminarGallo(galloActualizado); // Eliminar con datos actualizados
                                  },
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Eliminar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    minimumSize: const Size(0, 45),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Cerrar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 OBTENER TEXTO DE RAZA USANDO LA MISMA LÓGICA QUE LA LISTA PRINCIPAL
  String _getRazaText(Map<String, dynamic> gallo) {
    return _mapRazaIdToDisplayName(gallo['raza_id']?.toString()) ?? 
           gallo['raza']?.toString() ?? 
           gallo['raza_nombre']?.toString() ??
           'Sin especificar';
  }

  // 🎯 OBTENER TEXTO DE COLOR USANDO LA MISMA LÓGICA QUE LA LISTA PRINCIPAL
  String _getColorText(Map<String, dynamic> gallo) {
    return gallo['color_placa']?.toString() ?? 
           gallo['color_plumaje']?.toString() ?? 
           gallo['color']?.toString() ?? 
           'Sin especificar';
  }

  // 🎯 MAPEAR ID DE RAZA A NOMBRE LEGIBLE - IGUAL QUE EN PEDIGRI_SCREEN
  String? _mapRazaIdToDisplayName(String? razaId) {
    if (razaId == null || razaId.isEmpty) return null;
    
    // Mapear IDs del backend a nombres legibles
    switch (razaId.toUpperCase()) {
      case 'KELSO_AMERICANO': return 'Kelso';
      case 'HATCH_AMERICANO': return 'Hatch';
      case 'ALBANY_AMERICANO': return 'Albany';
      case 'SWEATER_AMERICANO': return 'Sweater';
      case 'RADIO_AMERICANO': return 'Radio';
      case 'CLARET_AMERICANO': return 'Claret';
      case 'LAW_AMERICANO': return 'Law';
      case 'GREY_AMERICANO': return 'Grey';
      case 'ROUNDHEAD_AMERICANO': return 'Roundhead';
      case 'BUTCHER_AMERICANO': return 'Butcher';
      case 'MCLEAN_AMERICANO': return 'McLean';
      case 'WHITEHACKLE_AMERICANO': return 'Whitehackle';
      case 'ASIL_PERUANO': return 'Asil';
      case 'SHAMO_JAPONES': return 'Shamo';
      case 'NAVAJERO': return 'Thai';
      default: 
        // Si no coincide con ningún mapeo conocido, formatear el ID para que sea legible
        return razaId.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => 
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
}
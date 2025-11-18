import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/gallo_service_v2.dart';
import '../../../shared/constants/app_icons.dart';

/// 🔥 FORMULARIO ÉPICO DE EDICIÓN DE GALLOS
/// Técnica recursiva genealógica + expansión infinita
/// Mejores prácticas Flutter/Dart + UI de lujo
class EditGalloMultistepScreen extends StatefulWidget {
  final Map<String, dynamic> gallo;

  const EditGalloMultistepScreen({
    super.key, 
    required this.gallo,
  });

  @override
  State<EditGalloMultistepScreen> createState() => _EditGalloMultistepScreenState();
}

class _EditGalloMultistepScreenState extends State<EditGalloMultistepScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  // ===== CONFIGURACIÓN DE FASES =====
  static const int _totalSteps = 4;
  int _currentStep = 0;
  late PageController _pageController;
  late TabController _genealogyTabController;

  // ===== KEYS PARA FORMULARIOS =====
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _formKey4 = GlobalKey<FormState>();

  // ===== CONTROLADORES FASE 1: 📷 Foto y Datos Principales =====
  late TextEditingController _nombreController;
  late TextEditingController _registroController;
  DateTime? _fechaNacimiento;
  String? _colorPlaca;
  String? _ubicacionPlaca;
  dynamic _selectedImage; // File para móvil, XFile para web
  String? _currentPhotoUrl;
  bool _photoChanged = false;
  // NUEVO: Fotos adicionales seleccionadas para update
  final List<dynamic> _extraImages = []; // File (móvil) o XFile (web)
  final List<String> _photosToDelete = []; // IDs de fotos a eliminar del backend

  // ===== CONTROLADORES FASE 2: 📝 Datos Básicos =====
  String? _raza;
  String? _colorPatas;
  String? _colorPlumaje;
  late TextEditingController _pesoController;
  late TextEditingController _alturaController;
  late TextEditingController _criadorController;
  late TextEditingController _propietarioController;
  late TextEditingController _observacionesController;

  // ===== CONTROLADORES FASE 3: 👨‍👩‍👦 Genealogía =====
  late TextEditingController _padreNombreController;
  DateTime? _padreFechaNacimiento;
  late TextEditingController _padreRegistroController;
  String? _padreColorPlaca;
  String? _padreLugarPlaca;
  bool _crearPadre = false;

  late TextEditingController _madreNombreController;
  DateTime? _madreFechaNacimiento;
  late TextEditingController _madreRegistroController;
  String? _madreColorPlaca;
  String? _madreLugarPlaca;
  bool _crearMadre = false;

  // ===== FOTOS DE PADRE Y MADRE =====
  final List<dynamic> _padreFotos = []; // Fotos del padre
  final List<dynamic> _madreFotos = []; // Fotos de la madre

  // ===== CONTROLADORES FASE 4: 📋 Notas Finales =====
  late TextEditingController _notasFinalesController;

  // ===== ESTADOS DE UI =====
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _loadingMessage;

  // ===== SERVICIOS =====
  final ImagePicker _imagePicker = ImagePicker();

  // ===== DATOS DROPDOWN =====
  static const List<String> _coloresPlaca = [
    'Rojo', 'Azul', 'Verde', 'Amarillo', 'Blanco', 'Negro', 'Plateado', 'Dorado'
  ];
  
  static const List<String> _ubicacionesPlaca = [
    'Pata Derecha', 'Pata Izquierda', 'Ambas Patas', 'Cuello', 'Ala Derecha', 'Ala Izquierda'
  ];
  
  static const List<String> _razas = [
    'Kelso', 'Sweater', 'Hatch', 'Grey', 'Roundhead', 'Law', 'Albany', 'Butcher', 
    'Claret', 'McLean', 'Radio', 'Whitehackle', 'Asil', 'Shamo', 'Thai', 'Peruvian'
  ];
  
  static const List<String> _coloresPatas = [
    'Amarillo', 'Verde', 'Blanco', 'Negro', 'Mixto', 'Rojizo', 'Gris'
  ];
  
  static const List<String> _coloresPlumaje = [
    'Colorado', 'Giro', 'Pinto', 'Cenizo', 'Blanco', 'Negro', 'Canela', 
    'Barrado', 'Tricolor', 'Overo', 'Jabao', 'Indio'
  ];

  // ===== TÍTULOS DE FASES =====
  static const List<String> _stepTitles = [
    '📷 Foto y Datos',
    '📝 Datos Básicos', 
    '👨‍👩‍👦 Genealogía',
    '📋 Notas Finales'
  ];

  static const List<IconData> _stepIcons = [
    Icons.photo_camera,
    Icons.info,
    Icons.family_restroom,
    Icons.note_add,
  ];

  @override
  bool get wantKeepAlive => true;

  // 🔥 CONVERTIR RAZA_ID DEL BACKEND AL VALOR DEL DROPDOWN
  String? _convertRazaIdToDropdownValue(String razaId) {
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
      case 'PERUVIAN': return 'Peruvian';
      default:
        // Si no está mapeado, intentar extraer la primera parte
        if (razaId.contains('_')) {
          return razaId.split('_')[0];
        }
        return razaId;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeTabController();
    _initializePageController();
    _preloadFormData();
    // Ya no necesitamos cargar datos extras - vienen completos desde el modal
  }

  void _initializeControllers() {
    _nombreController = TextEditingController();
    _registroController = TextEditingController();
    _pesoController = TextEditingController();
    _alturaController = TextEditingController();
    _criadorController = TextEditingController();
    _propietarioController = TextEditingController();
    _observacionesController = TextEditingController();
    _padreNombreController = TextEditingController();
    _padreRegistroController = TextEditingController();
    _madreNombreController = TextEditingController();
    _madreRegistroController = TextEditingController();
    _notasFinalesController = TextEditingController();
  }

  void _initializeTabController() {
    _genealogyTabController = TabController(
      length: 2, 
      vsync: this,
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  void _initializePageController() {
    _pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
  }

  /// 🔥 CARGAR DATOS COMPLETOS DESDE BACKEND SI ES NECESARIO
  Future<void> _loadCompleteGalloDataIfNeeded() async {
    try {
      final galloId = widget.gallo['id'];
      final tipoRegistro = widget.gallo['tipo_registro'];
      
      // NO cargar datos extras para gallos generados automáticamente
      if (tipoRegistro == 'padre_generado' || tipoRegistro == 'madre_generada') {
        debugPrint('⚠️ Gallo tipo "$tipoRegistro" - no requiere datos adicionales');
        return;
      }
      
      // Solo cargar si tenemos un ID y si parece que faltan datos críticos
      // Y solo para gallos reales (no generados)
      if (galloId != null && 
          widget.gallo['peso'] == null && 
          widget.gallo['altura'] == null &&
          widget.gallo['raza'] == null) {
        
        debugPrint('🔄 Intentando cargar datos completos del gallo $galloId...');
        
        // OPCIÓN 1: Si tenemos los datos en el árbol genealógico, usarlos
        if (widget.gallo['familia_completa'] != null) {
          final familiaCompleta = widget.gallo['familia_completa'] as List<dynamic>;
          for (var g in familiaCompleta) {
            if (g['id'] == galloId) {
              debugPrint('✅ Datos encontrados en familia_completa');
              _updateControllersWithCompleteData(Map<String, dynamic>.from(g));
              return;
            }
          }
        }
        
        // OPCIÓN 2: Obtener desde el endpoint de genealogía (que sí existe)
        debugPrint('🔄 Cargando desde endpoint genealogía...');
        
        setState(() {
          _isLoading = true;
          _loadingMessage = 'Cargando información...';
        });
        
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        
        // Usar el endpoint de genealogía que sí existe
        final response = await http.get(
          Uri.parse('https://gallerappback-production.up.railway.app/api/v1/gallos/$galloId/genealogia'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success'] == true && responseData['data'] != null) {
            final ancestros = responseData['data']['arbol_genealogico']['ancestros'];
            debugPrint('✅ Datos obtenidos desde genealogía');
            
            // El gallo principal está en ancestros
            if (mounted && ancestros != null) {
              _updateControllersWithCompleteData(Map<String, dynamic>.from(ancestros));
            }
          }
        } else {
          debugPrint('⚠️ No se pudieron obtener datos: ${response.statusCode}');
        }
        
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      } else {
        debugPrint('✅ Datos ya completos, no es necesario cargar más');
      }
    } catch (e) {
      debugPrint('❌ Error cargando datos completos: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
    }
  }
  
  /// 🔥 ACTUALIZAR CONTROLADORES CON DATOS COMPLETOS
  void _updateControllersWithCompleteData(Map<String, dynamic> gallo) {
    // Solo actualizar campos vacíos para no sobrescribir lo que ya tenemos
    if (_pesoController.text.isEmpty && gallo['peso'] != null) {
      _pesoController.text = gallo['peso'].toString();
    }
    
    if (_alturaController.text.isEmpty && gallo['altura'] != null) {
      _alturaController.text = gallo['altura'].toString();
    }
    
    // Manejar raza si está vacía
    if (_raza == null && gallo['raza'] != null) {
      if (gallo['raza'] is Map) {
        _raza = gallo['raza']['nombre']?.toString();
      } else {
        _raza = gallo['raza'].toString();
      }
    } else if (_raza == null && gallo['raza_nombre'] != null) {
      _raza = gallo['raza_nombre'].toString();
    }
    
    if (_colorPatas == null && gallo['color_patas'] != null) {
      _colorPatas = gallo['color_patas'].toString();
    }
    
    if (_colorPlumaje == null && gallo['color_plumaje'] != null) {
      _colorPlumaje = gallo['color_plumaje'].toString();
    } else if (_colorPlumaje == null && gallo['color'] != null) {
      _colorPlumaje = gallo['color'].toString();
    }
    
    if (_criadorController.text.isEmpty && gallo['criador'] != null) {
      _criadorController.text = gallo['criador'].toString();
    }
    
    if (_propietarioController.text.isEmpty && gallo['propietario_actual'] != null) {
      _propietarioController.text = gallo['propietario_actual'].toString();
    }
    
    // Actualizar fecha de nacimiento si no está presente
    if (_fechaNacimiento == null && gallo['fecha_nacimiento'] != null) {
      try {
        _fechaNacimiento = DateTime.parse(gallo['fecha_nacimiento'].toString());
      } catch (e) {
        debugPrint('Error parsing fecha_nacimiento: $e');
      }
    }
    
    // Actualizar nombre y código si están vacíos
    if (_nombreController.text.isEmpty && gallo['nombre'] != null) {
      _nombreController.text = gallo['nombre'].toString();
    }
    
    if (_registroController.text.isEmpty && gallo['codigo_identificacion'] != null) {
      _registroController.text = gallo['codigo_identificacion'].toString();
    }
    
    setState(() {
      _isInitialized = true;
    });
    
    debugPrint('✅ Controladores actualizados con datos completos');
  }

  /// 🔥 PRE-LLENAR FORMULARIO CON DATOS EXISTENTES
  void _preloadFormData() {
    try {
      final gallo = widget.gallo;
      
      // 🔍 DEBUG: Ver qué datos están llegando
      debugPrint('🔥 === DEBUG GALLO DATA ===');
      debugPrint('📊 Campos disponibles: ${gallo.keys.toList()}');
      debugPrint('📝 Tipo de registro: ${gallo['tipo_registro']}');
      debugPrint('📝 Datos completos: $gallo');
      debugPrint('========================');
      
      // FASE 1: Datos principales
      _nombreController.text = gallo['nombre']?.toString() ?? '';
      _registroController.text = gallo['codigo_identificacion']?.toString() ?? '';
      _currentPhotoUrl = gallo['foto_principal_url']?.toString();
      
      if (gallo['fecha_nacimiento'] != null) {
        try {
          _fechaNacimiento = DateTime.parse(gallo['fecha_nacimiento'].toString());
        } catch (e) {
          debugPrint('Error parsing fecha_nacimiento: $e');
        }
      }
      
      _colorPlaca = gallo['color_placa']?.toString();
      _ubicacionPlaca = gallo['ubicacion_placa']?.toString();

      // 🔥 NEW: Load existing additional photos from fotos_adicionales (List or JSON String)
      if (gallo['fotos_adicionales'] != null) {
        try {
          dynamic fotosData;

          // Handle both List (already parsed) and String JSON formats
          if (gallo['fotos_adicionales'] is List) {
            // Already parsed as List (from API response)
            fotosData = gallo['fotos_adicionales'] as List;
            debugPrint('🔍 fotos_adicionales viene como List ya parseada');
          } else if (gallo['fotos_adicionales'] is String) {
            // JSON string that needs parsing
            final fotosAdicionalesJson = gallo['fotos_adicionales'].toString();
            if (fotosAdicionalesJson.isNotEmpty && fotosAdicionalesJson != 'null') {
              fotosData = json.decode(fotosAdicionalesJson);
              debugPrint('🔍 fotos_adicionales parseada desde JSON string');
            }
          }

          if (fotosData is List && fotosData.isNotEmpty) {
            debugPrint('🖼️ Procesando ${fotosData.length} fotos desde BD (nueva estructura)');
            // Clear existing photos and load from database
            _extraImages.clear();

            for (var fotoData in fotosData) {
              if (fotoData is Map && fotoData['url'] != null) {
                // 🔥 NUEVO: Separar foto principal de fotos adicionales
                bool esPrincipal = fotoData['es_principal'] == true;

                if (esPrincipal) {
                  // Esta es la foto principal - actualizar _currentPhotoUrl si no hay foto_principal_url
                  if (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty) {
                    _currentPhotoUrl = fotoData['url'].toString();
                    debugPrint('✅ Foto principal cargada desde fotos_adicionales: $_currentPhotoUrl');
                  }
                } else {
                  // Esta es una foto adicional - agregar a _extraImages
                  _extraImages.add({
                    'type': 'existing_url',
                    'url': fotoData['url'].toString(),
                    'public_id': fotoData['cloudinary_public_id']?.toString(),
                    'cloudinary_public_id': fotoData['cloudinary_public_id']?.toString(),
                    'orden': fotoData['orden'],
                    'es_principal': false,
                  });
                }
              }
            }
            debugPrint('✅ Fotos cargadas: Principal: ${_currentPhotoUrl != null ? "SÍ" : "NO"}, Adicionales: ${_extraImages.length}');
          }
        } catch (e) {
          debugPrint('❌ Error procesando fotos_adicionales: $e');
        }
      }

      // FASE 2: Datos básicos
      // 🔥 FIX: Manejar raza como objeto, string o ID del backend
      if (gallo['raza'] != null) {
        if (gallo['raza'] is Map) {
          // Viene desde genealogía: {nombre: 'Kelso', id: 1}
          _raza = gallo['raza']['nombre']?.toString();
          debugPrint('✅ Raza desde objeto: $_raza');
        } else {
          // Viene desde lista principal: 'Kelso'
          _raza = gallo['raza'].toString();
          debugPrint('✅ Raza desde string: $_raza');
        }
      } else if (gallo['raza_id'] != null) {
        // 🔥 NUEVO: Convertir raza_id del backend al nombre para el dropdown
        _raza = _convertRazaIdToDropdownValue(gallo['raza_id'].toString());
        debugPrint('✅ Raza desde raza_id: ${gallo['raza_id']} → $_raza');
      } else if (gallo['raza_nombre'] != null) {
        // Fallback para formato alternativo
        _raza = gallo['raza_nombre'].toString();
        debugPrint('✅ Raza desde raza_nombre: $_raza');
      }
      
      _colorPatas = gallo['color_patas']?.toString();
      _colorPlumaje = gallo['color_plumaje']?.toString() ?? gallo['color']?.toString();
      _pesoController.text = gallo['peso']?.toString() ?? '';
      _alturaController.text = gallo['altura']?.toString() ?? '';
      _criadorController.text = gallo['criador']?.toString() ?? '';
      _propietarioController.text = gallo['propietario_actual']?.toString() ?? '';
      _observacionesController.text = gallo['observaciones']?.toString() ?? '';

      // FASE 4: Notas finales
      _notasFinalesController.text = gallo['notas']?.toString() ?? '';

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ Formulario pre-llenado exitosamente');
    } catch (e) {
      debugPrint('❌ Error pre-llenando formulario: $e');
      _showSnackBar('Error cargando datos del gallo', isError: true);
    }
  }

  @override
  void dispose() {
    _genealogyTabController.dispose();
    _pageController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _nombreController.dispose();
    _registroController.dispose();
    _pesoController.dispose();
    _alturaController.dispose();
    _criadorController.dispose();
    _propietarioController.dispose();
    _observacionesController.dispose();
    _padreNombreController.dispose();
    _padreRegistroController.dispose();
    _madreNombreController.dispose();
    _madreRegistroController.dispose();
    _notasFinalesController.dispose();
  }

  // ===== NAVEGACIÓN ENTRE FASES =====
  Future<void> _nextStep() async {
    if (await _validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
        await _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),  
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _totalSteps) {
      setState(() => _currentStep = step);
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // ===== VALIDACIONES ROBUSTAS =====
  Future<bool> _validateCurrentStep() async {
    switch (_currentStep) {
      case 0:
        return _validateFase1();
      case 1:
        return _validateFase2();
      case 2:
        return _validateFase3();
      case 3:
        return _validateFase4();
      default:
        return true;
    }
  }

  bool _validateFase1() {
    if (!_formKey1.currentState!.validate()) return false;
    
    if (_nombreController.text.trim().isEmpty) {
      _showValidationError('El nombre del gallo es obligatorio');
      return false;
    }
    
    if (_nombreController.text.trim().length < 2) {
      _showValidationError('El nombre debe tener al menos 2 caracteres');
      return false;
    }
    
    return true;
  }

  bool _validateFase2() {
    if (!_formKey2.currentState!.validate()) return false;
    
    if (_pesoController.text.isNotEmpty) {
      final peso = double.tryParse(_pesoController.text);
      if (peso == null || peso <= 0 || peso > 15) {
        _showValidationError('El peso debe estar entre 0.1 y 15 kg');
        return false;
      }
    }
    
    if (_alturaController.text.isNotEmpty) {
      final altura = int.tryParse(_alturaController.text);
      if (altura == null || altura <= 0 || altura > 150) {
        _showValidationError('La altura debe estar entre 1 y 150 cm');
        return false;
      }
    }
    
    return true;
  }

  bool _validateFase3() {
    if (!_formKey3.currentState!.validate()) return false;
    
    if (_crearPadre && _padreNombreController.text.trim().isEmpty) {
      _showValidationError('Si activas "Crear Padre", el nombre es obligatorio');
      return false;
    }
    
    if (_crearMadre && _madreNombreController.text.trim().isEmpty) {
      _showValidationError('Si activas "Crear Madre", el nombre es obligatorio');
      return false;
    }
    
    // Validar que no se cree padre y madre con el mismo nombre
    if (_crearPadre && _crearMadre) {
      if (_padreNombreController.text.trim().toLowerCase() == 
          _madreNombreController.text.trim().toLowerCase()) {
        _showValidationError('El padre y la madre no pueden tener el mismo nombre');
        return false;
      }
    }
    
    return true;
  }

  bool _validateFase4() {
    return _formKey4.currentState?.validate() ?? true;
  }

  void _showValidationError(String message) {
    _showSnackBar(message, isError: true);
  }

  // ===== GESTIÓN DE IMÁGENES ÉPICA =====
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _loadingMessage = 'Seleccionando imagen...';
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        // Validar tamaño del archivo
        final bytes = await image.readAsBytes();
        final sizeInMB = bytes.length / (1024 * 1024);
        
        if (sizeInMB > 10) {
          _showSnackBar('La imagen es muy grande. Máximo 10MB permitidos.', isError: true);
          return;
        }

        setState(() {
          _selectedImage = kIsWeb ? image : File(image.path);
          _photoChanged = true;
          _loadingMessage = null;
        });
        
        _showSnackBar('Imagen seleccionada correctamente ✅', isError: false);
      } else {
        setState(() {
          _loadingMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _loadingMessage = null;
      });
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
      debugPrint('Error _pickImage: $e');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '📷 Seleccionar Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red, size: 28),
              title: const Text('Cámara', style: TextStyle(fontSize: 16)),
              subtitle: const Text('Tomar foto nueva'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red, size: 28),
              title: const Text('Galería', style: TextStyle(fontSize: 16)),
              subtitle: const Text('Seleccionar desde galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections, color: Colors.purple, size: 28),
              title: const Text('Agregar fotos adicionales', style: TextStyle(fontSize: 16)),
              subtitle: const Text('Seleccionar múltiples (máx 3-4)'),
              onTap: () {
                Navigator.pop(context);
                _pickAdditionalImagesFromGallery();
              },
            ),
            if (_selectedImage != null || _currentPhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                title: const Text('Quitar foto', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Eliminar foto actual'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _photoChanged = true;
                  });
                  _showSnackBar('Foto eliminada', isError: false);
                },
              ),
            if (_extraImages.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.clear_all, color: Colors.orange, size: 28),
                title: const Text('Limpiar fotos adicionales', style: TextStyle(fontSize: 16)),
                subtitle: Text('Actualmente: ${_extraImages.length} seleccionada(s)'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _extraImages.clear());
                  _showSnackBar('Fotos adicionales limpiadas', isError: false);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // NUEVO: Seleccionar múltiples fotos adicionales desde la galería
  Future<void> _pickAdditionalImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isEmpty) return;
      
      // 🔥 CONTAR SOLO FOTOS NUEVAS (no las existing_url)
      int fotosNuevasActuales = _extraImages.where((item) => 
        !(item is Map && item['type'] == 'existing_url')).length;
      
      int fotosAgregadas = 0;
      for (final img in images) {
        // 🔥 LÍMITE: Máximo 3 fotos adicionales NUEVAS (foto_2, foto_3, foto_4)
        if (fotosNuevasActuales + fotosAgregadas >= 3) {
          debugPrint('⚠️ Límite alcanzado: 3 fotos adicionales nuevas');
          break;
        }
        
        if (kIsWeb) {
          _extraImages.add(img);
        } else {
          _extraImages.add(File(img.path));
        }
        fotosAgregadas++;
      }
      
      setState(() {});
      
      if (fotosAgregadas > 0) {
        _showSnackBar('✅ ${fotosAgregadas} foto(s) adicional(es) agregada(s)', isError: false);
      } else {
        _showSnackBar('⚠️ Ya tienes 3 fotos adicionales nuevas. Elimina alguna primero.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error seleccionando adicionales: $e', isError: true);
    }
  }

  // ===== SELECCIONAR MÚLTIPLES FOTOS PARA PADRE =====
  Future<void> _pickPadreFotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isEmpty) return;
      
      setState(() {
        for (final img in images) {
          if (_padreFotos.length >= 5) {
            _showSnackBar('⚠️ Máximo 5 fotos por padre', isError: true);
            break;
          }
          if (kIsWeb) {
            _padreFotos.add(img);
          } else {
            _padreFotos.add(File(img.path));
          }
        }
      });
      
      _showSnackBar('✅ ${images.length} foto(s) agregada(s) para el padre');
    } catch (e) {
      _showSnackBar('Error seleccionando fotos del padre: $e', isError: true);
    }
  }

  // ===== SELECCIONAR MÚLTIPLES FOTOS PARA MADRE =====
  Future<void> _pickMadreFotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isEmpty) return;
      
      setState(() {
        for (final img in images) {
          if (_madreFotos.length >= 5) {
            _showSnackBar('⚠️ Máximo 5 fotos por madre', isError: true);
            break;
          }
          if (kIsWeb) {
            _madreFotos.add(img);
          } else {
            _madreFotos.add(File(img.path));
          }
        }
      });
      
      _showSnackBar('✅ ${images.length} foto(s) agregada(s) para la madre');
    } catch (e) {
      _showSnackBar('Error seleccionando fotos de la madre: $e', isError: true);
    }
  }

  // ===== ELIMINAR FOTO DE PADRE =====
  void _removePadrePhoto(int index) {
    setState(() {
      _padreFotos.removeAt(index);
    });
    _showSnackBar('Foto del padre eliminada');
  }

  // ===== ELIMINAR FOTO DE MADRE =====
  void _removeMadrePhoto(int index) {
    setState(() {
      _madreFotos.removeAt(index);
    });
    _showSnackBar('Foto de la madre eliminada');
  }

  // ===== GUARDAR GALLO ÉPICO =====
  Future<void> _saveGallo() async {
    if (!await _validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Actualizando gallo...';
    });

    try {
      await _updateGalloToBackend();
      
      // Guardar en preferencias para caché
      await _saveToCache();
      
      // 📝 NOTA: _updateGalloToBackend() ya maneja la navegación y el resultado
      // No necesitamos Navigator.pop aquí porque ya se hace en _updateGalloToBackend()
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar: ${e.toString()}', isError: true);
      }
      debugPrint('❌ Error _saveGallo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  /// 🚀 ACTUALIZAR GALLO EN BACKEND CON TÉCNICA RECURSIVA - VERSIÓN CORREGIDA
  Future<void> _updateGalloToBackend() async {
    try {
      print('🔥 === INICIANDO ACTUALIZACIÓN ÉPICA ===');
      
      // Preparar datos para el backend
      final galloData = _prepareGalloDataForBackend();
      
      print('📊 Datos a actualizar: ${galloData.keys}');
      
      // 🗑️ PASO 1: ELIMINAR FOTOS MARCADAS PRIMERO
      if (_photosToDelete.isNotEmpty) {
        _showSnackBar('🗑️ Eliminando ${_photosToDelete.length} foto(s)...', isError: false);
        debugPrint('🔍 Fotos a eliminar: $_photosToDelete');

        bool allDeleted = true;
        for (String publicId in _photosToDelete) {
          try {
            await _deleteFotoFromBackend(widget.gallo['id'], publicId);
            debugPrint('✅ Foto eliminada exitosamente: $publicId');
          } catch (e) {
            debugPrint('❌ Error eliminando foto $publicId: $e');
            allDeleted = false;
          }
        }

        if (allDeleted) {
          _showSnackBar('✅ ${_photosToDelete.length} foto(s) eliminada(s)', isError: false);
        } else {
          _showSnackBar('⚠️ Algunas fotos no se pudieron eliminar', isError: true);
        }
      }

      // 🔥 PASO 2: PREPARAR TODAS LAS FOTOS NUEVAS
      // Foto principal nueva (si cambió)
      dynamic fotoPrincipalNueva = _photoChanged ? _selectedImage : null;
      
      // Fotos adicionales nuevas (solo las que NO son existing_url)
      final fotosAdicionalesNuevas = _extraImages.where((item) =>
        !(item is Map && item['type'] == 'existing_url')).toList();

      debugPrint('📸 Foto principal nueva: ${fotoPrincipalNueva != null ? "SÍ" : "NO"}');
      debugPrint('📸 Fotos adicionales nuevas: ${fotosAdicionalesNuevas.length}');

      // 🔥 PASO 3: SUBIR TODAS LAS FOTOS EN UNA SOLA LLAMADA
      if (fotoPrincipalNueva != null || fotosAdicionalesNuevas.isNotEmpty) {
        _showSnackBar('📸 Subiendo fotos...', isError: false);

        // Preparar array: [foto_principal, foto_adicional_1, foto_adicional_2, foto_adicional_3]
        final List<dynamic> todasLasFotos = [];
        bool tienePrincipal = false;
        
        if (fotoPrincipalNueva != null) {
          todasLasFotos.add(fotoPrincipalNueva); // foto_1
          tienePrincipal = true;
        }
        
        todasLasFotos.addAll(fotosAdicionalesNuevas); // foto_2, foto_3, foto_4 (o foto_2, foto_3, foto_4 si no hay principal)

        debugPrint('📦 Total fotos a subir: ${todasLasFotos.length}');
        debugPrint('📸 Tiene foto principal nueva: $tienePrincipal');

        final fotosResponse = await GalloServiceV2.uploadMultipleFotos(
          galloId: widget.gallo['id'],
          fotos: todasLasFotos,
          tieneFotoPrincipal: tienePrincipal, // ✅ CRUCIAL: Indica si la primera es principal
        );

        if (fotosResponse['success'] == true) {
          _showSnackBar('✅ Fotos actualizadas correctamente', isError: false);
        } else {
          _showSnackBar('⚠️ Error actualizando fotos: ${fotosResponse["message"]}', isError: true);
        }
      }

      // 🔥 PASO 4: ACTUALIZAR DATOS DEL GALLO (SIN FOTOS)
      final response = await GalloServiceV2.updateGalloConExpansionEpico(
        galloId: widget.gallo['id'],
        galloData: galloData,
        foto: null, // NO enviar foto aquí
        fotosAdicionales: null, // NO enviar fotos adicionales aquí
      );

      if (response['success'] == true) {
        print('✅ Actualización exitosa');

        // 🔥 LIMPIAR LISTA DE FOTOS A ELIMINAR
        _photosToDelete.clear();

        // 🔥 PREPARAR RESULTADO ÉPICO PARA LISTA
        final resultadoEpico = {
          'action': 'REFRESH_LIST', // Flag crucial para la lista
          'success': true,
          'gallo_actualizado': {
            'id': widget.gallo['id'],
            'nombre': _nombreController.text.trim(),
            'foto_principal_url': response['data']?['gallo_principal']?['foto_principal_url'] ?? 
                                  response['data']?['gallo_principal']?['url_foto_cloudinary'] ??
                                  widget.gallo['foto_principal_url'], // Fallback a la foto anterior
          },
          'expansion_genealogica': _crearPadre || _crearMadre,
          'registros_nuevos_creados': 0, // Se actualizará si hay expansión
          'message': 'Gallo actualizado correctamente',
        };
        
        // Si hubo expansión genealógica, agregar info adicional
        if (_crearPadre || _crearMadre) {
          int nuevosRegistros = 0;
          if (_crearPadre && _padreNombreController.text.trim().isNotEmpty) nuevosRegistros++;
          if (_crearMadre && _madreNombreController.text.trim().isNotEmpty) nuevosRegistros++;
          
          resultadoEpico['registros_nuevos_creados'] = nuevosRegistros;
          resultadoEpico['mensaje_expansion'] = 'Se crearon $nuevosRegistros nuevos registros genealógicos';
        }
        
        _showSnackBar('¡Gallo actualizado exitosamente! 🔥🐓', isError: false);
        
        // Delay para mostrar mensaje
        await Future.delayed(const Duration(seconds: 1));
        
        // 🎯 RETORNAR RESULTADO ÉPICO A LA LISTA
        if (mounted) {
          Navigator.pop(context, resultadoEpico);
        }
        
      } else {
        throw response['message'] ?? 'Error desconocido del servidor';
      }
      
    } catch (e) {
      print('❌ Error en actualización: $e');
      throw e;
    }
  }

  /// 📤 PREPARAR DATOS PARA BACKEND
  Map<String, dynamic> _prepareGalloDataForBackend() {
    final data = <String, dynamic>{};
    
    // DATOS OBLIGATORIOS
    data['nombre'] = _nombreController.text.trim();
    data['codigo_identificacion'] = _registroController.text.trim().isNotEmpty 
        ? _registroController.text.trim() 
        : widget.gallo['codigo_identificacion'] ?? 'AUTO_${DateTime.now().millisecondsSinceEpoch}';
    
    // 🔍 DEBUG: Ver qué datos se están preparando
    debugPrint('🔥 === DEBUG DATOS PARA BACKEND ===');
    debugPrint('📝 Nombre: ${data['nombre']}');
    debugPrint('🔢 Código: ${data['codigo_identificacion']}');
    debugPrint('📅 Fecha nacimiento: $_fechaNacimiento');
    debugPrint('🎨 Color placa: $_colorPlaca');
    debugPrint('📍 Ubicación placa: $_ubicacionPlaca');
    
    // DATOS OPCIONALES FASE 1
    if (_fechaNacimiento != null) data['fecha_nacimiento'] = _fechaNacimiento!.toIso8601String();
    if (_colorPlaca != null) data['color_placa'] = _colorPlaca;
    if (_ubicacionPlaca != null) data['ubicacion_placa'] = _ubicacionPlaca;
    
    // DATOS OPCIONALES FASE 2
    // 🔥 RAZA_ID CORREGIDO - ENVIAR COMO STRING
    if (_raza != null) {
      data['raza_id'] = _mapRazaToStringId(_raza); // 🔥 NUEVO CAMPO PARA BACKEND
      data['raza'] = _raza; // Mantener el campo original también
      print('🐓 raza_id enviado al backend (EDIT): ${data['raza_id']}'); // DEBUG
    } else {
      print('⚠️ raza_id es null en EDIT - no se enviará'); // DEBUG
    }
    
    if (_colorPatas != null) data['color_patas'] = _colorPatas;
    if (_colorPlumaje != null) data['color_plumaje'] = _colorPlumaje;
    if (_pesoController.text.isNotEmpty) data['peso'] = double.tryParse(_pesoController.text);
    if (_alturaController.text.isNotEmpty) data['altura'] = int.tryParse(_alturaController.text);
    if (_criadorController.text.isNotEmpty) data['criador'] = _criadorController.text.trim();
    // Campo 'propietario_actual' eliminado según requerimiento
    // if (_propietarioController.text.isNotEmpty) data['propietario_actual'] = _propietarioController.text.trim();
    if (_observacionesController.text.isNotEmpty) data['observaciones'] = _observacionesController.text.trim();
    
    // DATOS OPCIONALES FASE 4
    if (_notasFinalesController.text.isNotEmpty) data['notas'] = _notasFinalesController.text.trim();
    
    // EXPANSIÓN GENEALÓGICA
    data['crear_padre'] = _crearPadre;
    data['crear_madre'] = _crearMadre;
    
    if (_crearPadre && _padreNombreController.text.trim().isNotEmpty) {
      data['padre_nombre'] = _padreNombreController.text.trim();
      if (_padreRegistroController.text.isNotEmpty) {
        data['padre_codigo'] = _padreRegistroController.text.trim();
      }
      if (_padreFechaNacimiento != null) {
        data['padre_fecha_nacimiento'] = _padreFechaNacimiento!.toIso8601String();
      }
    }
    
    if (_crearMadre && _madreNombreController.text.trim().isNotEmpty) {
      data['madre_nombre'] = _madreNombreController.text.trim();
      if (_madreRegistroController.text.isNotEmpty) {
        data['madre_codigo'] = _madreRegistroController.text.trim();
      }
      if (_madreFechaNacimiento != null) {
        data['madre_fecha_nacimiento'] = _madreFechaNacimiento!.toIso8601String();
      }
    }
    
    // 🔍 DEBUG: Ver datos finales
    debugPrint('📦 Datos finales para backend: $data');
    debugPrint('===============================');
    
    return data;
  }

  /// 💾 GUARDAR EN CACHÉ LOCAL
  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final galloData = {
        'id': widget.gallo['id'],
        'nombre': _nombreController.text,
        'last_updated': DateTime.now().toIso8601String(),
      };
      await prefs.setString('last_edited_gallo', json.encode(galloData));
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  // ===== SELECCIÓN DE FECHAS =====
  Future<void> _selectDate(BuildContext context, String type) async {
    DateTime? currentDate;
    
    switch (type) {
      case 'gallo':
        currentDate = _fechaNacimiento;
        break;
      case 'padre':
        currentDate = _padreFechaNacimiento;
        break;
      case 'madre':
        currentDate = _madreFechaNacimiento;
        break;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      helpText: 'Seleccionar fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        switch (type) {
          case 'gallo':
            _fechaNacimiento = picked;
            break;
          case 'padre':
            _padreFechaNacimiento = picked;
            break;
          case 'madre':
            _madreFechaNacimiento = picked;
            break;
        }
      });
    }
  }

  // ===== SNACKBAR PERSONALIZADO =====
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] :

        Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: isError ? SnackBarAction(
          label: 'Cerrar',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(height: 16),
              Text('Cargando datos del gallo...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildFase1(), // 📷 Foto y Datos Principales
                _buildFase2(), // 📝 Datos Básicos
                _buildFase3(), // 👨‍👩‍👦 Genealogía
                _buildFase4(), // 📋 Notas Finales
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ===== APP BAR ÉPICA =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.red,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.red,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: _isLoading ? null : () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '✏️ Editar Gallo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Paso ${_currentStep + 1}/$_totalSteps: ${_stepTitles[_currentStep]}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        if (_currentStep == _totalSteps - 1)
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, color: Colors.white),
            onPressed: _isLoading ? null : _saveGallo,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'reset':
                _resetForm();
                break;
              case 'cache':
                _clearCache();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Resetear formulario'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cache',
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Limpiar caché'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===== INDICADOR DE PROGRESO ÉPICO =====
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          final isClickable = index <= _currentStep;
          
          return Expanded(
            child: GestureDetector(
              onTap: isClickable ? () => _goToStep(index) : null,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.red
                          : isCurrent 
                              ? Colors.red
                              : Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: isCurrent ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 4,
                        ),
                      ] : null,
                    ),
                    child: isCompleted 
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Icon(
                            _stepIcons[index],
                            size: 16,
                            color: isCurrent ? Colors.white : Colors.grey[600],
                          ),
                  ),
                  if (index < _totalSteps - 1)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.red : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===== FLOATING ACTION BUTTON =====
  Widget? _buildFloatingActionButton() {
    if (_loadingMessage != null) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.red[300],
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        label: Text(
          _loadingMessage!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }
    return null;
  }

  // ===== FASE 1: 📷 FOTO Y DATOS PRINCIPALES =====
  Widget _buildFase1() {
    return Form(
      key: _formKey1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📷 FOTO Y DATOS PRINCIPALES', 'Información básica del gallo'),
            const SizedBox(height: 20),
            
            // GESTIÓN DE FOTO ÉPICA
            _buildPhotoSection(),
            const SizedBox(height: 24),
            
            // INFORMACIÓN PRINCIPAL
            _buildEpicTextField(
              controller: _nombreController,
              label: 'Nombre del Gallo',
              icon: AppIcons.galloIconData,
              isRequired: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                if (value.trim().length < 2) {
                  return 'Mínimo 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildEpicTextField(
              controller: _registroController,
              label: 'Número de Registro',
              icon: Icons.confirmation_number,
              hint: 'Código único del gallo',
            ),
            const SizedBox(height: 16),
            
            _buildDateField(
              label: 'Fecha de Nacimiento',
              date: _fechaNacimiento,
              onTap: () => _selectDate(context, 'gallo'),
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Color de Placa',
              value: _colorPlaca,
              items: _coloresPlaca,
              onChanged: (value) => setState(() => _colorPlaca = value),
              icon: Icons.palette,
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Ubicación de Placa',
              value: _ubicacionPlaca,
              items: _ubicacionesPlaca,
              onChanged: (value) => setState(() => _ubicacionPlaca = value),
              icon: Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  // ===== SECCIÓN DE FOTO ÉPICA =====
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto del Gallo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: (_selectedImage != null || _currentPhotoUrl != null)
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _selectedImage != null
                        ? (kIsWeb 
                            ? Image.network(
                                (_selectedImage as XFile).path,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(color: Colors.red),
                                  );
                                },
                              )
                            : Image.file(
                                _selectedImage as File,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ))
                        : Image.network(
                            _currentPhotoUrl!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.red),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Error cargando imagen'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _showImagePickerOptions,
                      ),
                    ),
                  ),
                  if (_photoChanged)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NUEVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : InkWell(
                onTap: _showImagePickerOptions,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Toca para agregar foto',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Opcional',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
        const SizedBox(height: 12),
        _buildExtraPhotosGrid(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickAdditionalImagesFromGallery,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_extraImages.isEmpty ? 'Agregar fotos' : 'Agregar más'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_selectedImage != null || _currentPhotoUrl != null || _extraImages.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _openCarouselViewerEdit(0),
                icon: const Icon(Icons.slideshow),
                label: const Text('Ver Carrusel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ===== FASE 2: 📝 DATOS BÁSICOS =====
  Widget _buildFase2() {
    return Form(
      key: _formKey2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📝 CARACTERÍSTICAS FÍSICAS', 'Detalles específicos del gallo'),
            const SizedBox(height: 20),
            
            _buildEpicDropdown(
              label: 'Raza',
              value: _raza,
              items: _razas,
              onChanged: (value) => setState(() => _raza = value),
              icon: AppIcons.galloIconData,
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Color de Patas',
              value: _colorPatas,
              items: _coloresPatas,
              onChanged: (value) => setState(() => _colorPatas = value),
              icon: Icons.colorize,
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Color de Plumaje',
              value: _colorPlumaje,
              items: _coloresPlumaje,
              onChanged: (value) => setState(() => _colorPlumaje = value),
              icon: Icons.brush,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildEpicTextField(
                    controller: _pesoController,
                    label: 'Peso (kg)',
                    icon: Icons.fitness_center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    hint: '0.0',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final peso = double.tryParse(value);
                        if (peso == null) return 'Peso inválido';
                        if (peso <= 0 || peso > 15) return 'Entre 0.1 y 15 kg';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEpicTextField(
                    controller: _alturaController,
                    label: 'Altura (cm)',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                    hint: '0',
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final altura = int.tryParse(value);
                        if (altura == null) return 'Altura inválida';
                        if (altura <= 0 || altura > 150) return 'Entre 1 y 150 cm';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildEpicTextField(
              controller: _criadorController,
              label: 'Criador',
              icon: Icons.person,
              hint: 'Nombre del criador',
            ),
            const SizedBox(height: 16),
            
            _buildEpicTextField(
              controller: _observacionesController,
              label: 'Observaciones',
              icon: Icons.notes,
              maxLines: 3,
              hint: 'Características especiales, comportamiento, etc.',
            ),
          ],
        ),
      ),
    );
  }

  // ===== FASE 3: 👨‍👩‍👦 GENEALOGÍA =====
  Widget _buildFase3() {
    return Form(
      key: _formKey3,
      child: Column(
        children: [
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                Text(
                  '👨‍👩‍👦 EXPANSIÓN GENEALÓGICA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Activa los switches para crear nuevos registros de padre/madre',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _genealogyTabController,
            tabs: [
              Tab(
                icon: Icon(
                  Icons.male,
                  color: _crearPadre ? Colors.blue : Colors.grey,
                ),
                text: 'PADRE',
              ),
              Tab(
                icon: Icon(
                  Icons.female,
                  color: _crearMadre ? Colors.pink : Colors.grey,
                ),
                text: 'MADRE',
              ),
            ],
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            indicatorWeight: 3,
          ),
          Expanded(
            child: TabBarView(
              controller: _genealogyTabController,
              children: [
                _buildPadreTab(),
                _buildMadreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPadreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.male, color: Colors.blue, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Padre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'Activar para agregar información del padre',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _crearPadre,
                    onChanged: (value) => setState(() => _crearPadre = value),
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          
          if (_crearPadre) ...[
            const SizedBox(height: 20),
            _buildEpicTextField(
              controller: _padreNombreController,
              label: 'Nombre del Padre',
              icon: AppIcons.galloIconData,
              isRequired: true,
              validator: (value) {
                if (_crearPadre && (value == null || value.trim().isEmpty)) {
                  return 'Nombre del padre obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildEpicTextField(
              controller: _padreRegistroController,
              label: 'Número de Registro',
              icon: Icons.confirmation_number,
              hint: 'Código del padre',
            ),
            const SizedBox(height: 16),
            
            _buildDateField(
              label: 'Fecha de Nacimiento del Padre',
              date: _padreFechaNacimiento,
              onTap: () => _selectDate(context, 'padre'),
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Color de Placa del Padre',
              value: _padreColorPlaca,
              items: _coloresPlaca,
              onChanged: (value) => setState(() => _padreColorPlaca = value),
              icon: Icons.palette,
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Ubicación de Placa del Padre',
              value: _padreLugarPlaca,
              items: _ubicacionesPlaca,
              onChanged: (value) => setState(() => _padreLugarPlaca = value),
              icon: Icons.location_on,
            ),
            const SizedBox(height: 20),
            
            // ===== FOTOS DEL PADRE =====
            _buildFotosSection(
              titulo: 'Fotos del Padre',
              fotos: _padreFotos,
              onAgregarFotos: _pickPadreFotos,
              onEliminarFoto: _removePadrePhoto,
              icono: Icons.photo_library,
              color: Colors.blue,
            ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Activa el switch para agregar información del padre',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esto creará un nuevo registro de padre vinculado al gallo',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMadreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.female, color: Colors.pink, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Madre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        Text(
                          'Activar para agregar información de la madre',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _crearMadre,
                    onChanged: (value) => setState(() => _crearMadre = value),
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          
          if (_crearMadre) ...[
            const SizedBox(height: 20),
            _buildEpicTextField(
              controller: _madreNombreController,
              label: 'Nombre de la Madre',
              icon: AppIcons.galloIconData,
              isRequired: true,
              validator: (value) {
                if (_crearMadre && (value == null || value.trim().isEmpty)) {
                  return 'Nombre de la madre obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            _buildEpicTextField(
              controller: _madreRegistroController,
              label: 'Número de Registro',
              icon: Icons.confirmation_number,
              hint: 'Código de la madre',
            ),
            const SizedBox(height: 16),
            
            _buildDateField(
              label: 'Fecha de Nacimiento de la Madre',
              date: _madreFechaNacimiento,
              onTap: () => _selectDate(context, 'madre'),
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Color de Placa de la Madre',
              value: _madreColorPlaca,
              items: _coloresPlaca,
              onChanged: (value) => setState(() => _madreColorPlaca = value),
              icon: Icons.palette,
            ),
            const SizedBox(height: 16),
            
            _buildEpicDropdown(
              label: 'Ubicación de Placa de la Madre',
              value: _madreLugarPlaca,
              items: _ubicacionesPlaca,
              onChanged: (value) => setState(() => _madreLugarPlaca = value),
              icon: Icons.location_on,
            ),
            const SizedBox(height: 20),
            
            // ===== FOTOS DE LA MADRE =====
            _buildFotosSection(
              titulo: 'Fotos de la Madre',
              fotos: _madreFotos,
              onAgregarFotos: _pickMadreFotos,
              onEliminarFoto: _removeMadrePhoto,
              icono: Icons.photo_library,
              color: Colors.pink,
            ),
          ] else ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Activa el switch para agregar información de la madre',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esto creará un nuevo registro de madre vinculado al gallo',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

 // ===== FASE 4: 📋 NOTAS FINALES =====
  Widget _buildFase4() {
    return Form(
      key: _formKey4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('📋 NOTAS FINALES', 'Información adicional y resumen'),
            const SizedBox(height: 20),
            
            _buildEpicTextField(
              controller: _notasFinalesController,
              label: 'Notas Adicionales',
              icon: Icons.note_add,
              maxLines: 8,
              hint: 'Agrega cualquier información adicional sobre el gallo:\n'
                     '• Comportamiento especial\n'
                     '• Historial médico\n'
                     '• Características únicas\n'
                     '• Resultados en peleas\n'
                     '• Otros detalles importantes...',
            ),
            
            const SizedBox(height: 24),
            
            // RESUMEN DE CAMBIOS ÉPICO
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[50]!, Colors.red[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Resumen de Cambios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem('Gallo:', _nombreController.text.isNotEmpty ? _nombreController.text : 'Sin cambios'),
                    if (_photoChanged)
                      _buildSummaryItem('Foto:', _selectedImage != null ? 'Nueva foto será subida' : 'Foto eliminada'),
                    if (_crearPadre && _padreNombreController.text.isNotEmpty)
                      _buildSummaryItem('Padre:', 'Se creará: ${_padreNombreController.text}'),
                    if (_crearMadre && _madreNombreController.text.isNotEmpty)
                      _buildSummaryItem('Madre:', 'Se creará: ${_madreNombreController.text}'),
                    if (!_crearPadre && !_crearMadre)
                      _buildSummaryItem('Genealogía:', 'Sin expansión genealógica'),
                    if (_pesoController.text.isNotEmpty)
                      _buildSummaryItem('Peso:', '${_pesoController.text} kg'),
                    if (_alturaController.text.isNotEmpty)
                      _buildSummaryItem('Altura:', '${_alturaController.text} cm'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // INFORMACIÓN TÉCNICA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Técnica Genealógica Recursiva',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Si creas padre/madre, se generarán automáticamente nuevos registros\n'
                    '• Todos los registros mantendrán el mismo ID genealógico\n'
                    '• La genealogía se expande infinitamente sin perder vínculos\n'
                    '• Una consulta obtiene toda la familia completa',
                    style: TextStyle(color: Colors.blue[700], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== WIDGETS AUXILIARES ÉPICOS =====
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpicTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: '$label${isRequired ? ' *' : ''}',
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildEpicDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item),
      )).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.red),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.red),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? Colors.black87 : Colors.grey[500],
                      fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ===== BOTONES DE NAVEGACIÓN ÉPICOS =====
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _previousStep,
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.red, size: 18),
                  label: const Text(
                    'Anterior',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),
            
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: _currentStep == _totalSteps - 1
                  ? ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveGallo,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _isLoading ? 'Actualizando...' : '💾 Actualizar Gallo',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isLoading ? null : _nextStep,
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      label: const Text(
                        'Siguiente',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== FUNCIONES AUXILIARES =====
  void _resetForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resetear Formulario'),
        content: const Text('¿Estás seguro de que quieres resetear todos los campos a sus valores originales?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _preloadFormData();
              setState(() {
                _currentStep = 0;
                _selectedImage = null;
                _photoChanged = false;
                _crearPadre = false;
                _crearMadre = false;
              });
              _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.ease);
              _showSnackBar('Formulario reseteado', isError: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_edited_gallo');
      _showSnackBar('Caché limpiado correctamente', isError: false);
    } catch (e) {
      _showSnackBar('Error limpiando caché', isError: true);
    }
  }

  // ===== HELPER: MAPEAR RAZA A STRING ID (PARA EDICIÓN) =====
  String _mapRazaToStringId(String? raza) {
    if (raza == null) return 'KELSO_AMERICANO';
    
    // 🔥 MAPEAR A IDs STRING COMO ESPERA EL BACKEND
    switch (raza) {
      case 'Kelso': return 'KELSO_AMERICANO';
      case 'Sweater': return 'SWEATER_AMERICANO';
      case 'Hatch': return 'HATCH_AMERICANO';
      case 'Grey': return 'GREY_AMERICANO';
      case 'Roundhead': return 'ROUNDHEAD_AMERICANO';
      case 'Law': return 'LAW_AMERICANO';
      case 'Albany': return 'ALBANY_AMERICANO';
      case 'Butcher': return 'BUTCHER_AMERICANO';
      case 'Claret': return 'CLARET_AMERICANO';
      case 'McLean': return 'MCLEAN_AMERICANO';
      case 'Radio': return 'RADIO_AMERICANO';
      case 'Whitehackle': return 'WHITEHACKLE_AMERICANO';
      case 'Asil': return 'ASIL_PERUANO';
      case 'Shamo': return 'SHAMO_JAPONES';
      case 'Thai': return 'NAVAJERO';
      case 'Peruvian': return 'ASIL_PERUANO';
      default: return 'KELSO_AMERICANO'; // Default
    }
  }

  // ===== FOTOS ADICIONALES: GRID Y CARRUSEL =====
  Widget _buildExtraPhotosGrid() {
    // 🔥 MEJORADO: Grid para fotos ADICIONALES solamente (la principal va por separado)
    const int maxPhotos = 3; // Solo 3 fotos adicionales
    final int totalSlots = 3; // Solo 3 slots para adicionales

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columnas para las 3 fotos adicionales
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0, // Cuadrado para mejor vista en 3 columnas
      ),
      itemCount: totalSlots,
      itemBuilder: (context, index) {
        // 🔥 MEJORADO: Lógica para 3 fotos adicionales en 1 fila
        if (index >= _extraImages.length) {
          // Slot vacío - mostrar botón "agregar"
          if (_extraImages.length < maxPhotos) {
            return InkWell(
              onTap: _pickAdditionalImagesFromGallery,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: Colors.grey[600], size: 32),
                    const SizedBox(height: 4),
                    Text(
                      'Agregar\nfoto',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Slot vacío sin funcionalidad
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }
        }

        // Slot con foto existente
        final item = _extraImages[index];
        Widget image;

        // 🔥 NEW: Handle both existing URLs and new files
        if (item is Map && item['type'] == 'existing_url') {
          // Existing photo from database (URL)
          image = Image.network(
            item['url'],
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
                ),
              );
            },
          );
        } else if (kIsWeb && item is XFile) {
          // New photo on web (XFile)
          image = Image.network(item.path, fit: BoxFit.contain, width: double.infinity, height: double.infinity);
        } else {
          // New photo on mobile (File)
          image = Image.file(item as File, fit: BoxFit.contain, width: double.infinity, height: double.infinity);
        }
        return GestureDetector(
          onTap: () => _openCarouselViewerEdit(index + _primaryOffsetForCarousel()),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black12,
                  child: image
                ),
              ),
              // 🔥 MEJORADO: Botón eliminar más visible y táctil
              Positioned(
                right: 8,
                top: 8,
                child: InkWell(
                  onTap: () {
                    final fotoToDelete = _extraImages[index];

                    // 🔥 NEW: Handle deletion properly for existing vs new photos
                    if (fotoToDelete is Map && fotoToDelete['type'] == 'existing_url') {
                      // Existing photo from database - mark for backend deletion
                      final publicId = fotoToDelete['public_id']?.toString() ?? fotoToDelete['cloudinary_public_id']?.toString();
                      if (publicId != null && publicId.isNotEmpty) {
                        // 🔥 PREVENIR DUPLICADOS
                        if (!_photosToDelete.contains(publicId)) {
                          _photosToDelete.add(publicId);
                          debugPrint('📝 Foto existente marcada para eliminación: $publicId');
                        } else {
                          debugPrint('⚠️ Foto ya marcada para eliminación: $publicId');
                        }
                        debugPrint('📝 Total fotos a eliminar: ${_photosToDelete.length}');
                        debugPrint('📝 Lista completa: $_photosToDelete');
                      } else {
                        debugPrint('❌ No se encontró public_id en la foto: $fotoToDelete');
                      }
                    } else {
                      // New photo (File/XFile) - just remove locally
                      debugPrint('📝 Nueva foto removida localmente');
                    }

                    setState(() {
                      _extraImages.removeAt(index);
                    });

                    _showSnackBar(
                      '🗑️ Foto eliminada (se aplicará al guardar)',
                      isError: false
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _primaryOffsetForCarousel() {
    return (_selectedImage != null || _currentPhotoUrl != null) ? 1 : 0;
  }

  void _openCarouselViewerEdit(int initialIndex) {
    final List<dynamic> items = [];
    if (_selectedImage != null) {
      items.add(_selectedImage);
    } else if (_currentPhotoUrl != null) {
      items.add(_currentPhotoUrl);
    }
    items.addAll(_extraImages);
    if (items.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final controller = PageController(initialPage: initialIndex.clamp(0, items.length - 1));
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  // 🔥 NEW: Handle existing URL objects from database
                  if (item is Map && item['type'] == 'existing_url') {
                    return InteractiveViewer(
                      child: Image.network(
                        item['url'],
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                          );
                        },
                      )
                    );
                  }

                  // Handle String URLs (foto principal)
                  if (item is String) {
                    return InteractiveViewer(child: Image.network(item, fit: BoxFit.contain));
                  }

                  // Handle XFile (web)
                  if (kIsWeb && item is XFile) {
                    return InteractiveViewer(child: Image.network(item.path, fit: BoxFit.contain));
                  }

                  // Handle File (mobile)
                  if (item is File) {
                    return InteractiveViewer(child: Image.file(item, fit: BoxFit.contain));
                  }

                  return const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🗑️ ELIMINAR FOTO DEL BACKEND Y CLOUDINARY
  Future<void> _deleteFotoFromBackend(int galloId, String publicId) async {
    try {
      debugPrint('🔍 Iniciando eliminación: gallo=$galloId, publicId=$publicId');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      // URL encode the public_id to handle special characters like "/"
      final encodedPublicId = Uri.encodeComponent(publicId);
      final url = 'https://gallerappback-production.up.railway.app/api/v1/gallos/$galloId/fotos/$encodedPublicId';
      debugPrint('🌐 URL de eliminación: $url');
      debugPrint('🔧 PublicId original: $publicId');
      debugPrint('🔧 PublicId encoded: $encodedPublicId');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('✅ Foto eliminada correctamente del backend: $publicId');
      } else {
        debugPrint('❌ Error eliminando foto del backend: ${response.statusCode} - ${response.body}');
        throw Exception('Error eliminando foto: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error en _deleteFotoFromBackend: $e');
      throw e;
    }
  }

  // ===== WIDGET DE SECCIÓN DE FOTOS =====
  Widget _buildFotosSection({
    required String titulo,
    required List<dynamic> fotos,
    required VoidCallback onAgregarFotos,
    required Function(int) onEliminarFoto,
    required IconData icono,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${fotos.length}/5',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Botón para agregar fotos
            ElevatedButton.icon(
              onPressed: fotos.length < 5 ? onAgregarFotos : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(fotos.isEmpty ? 'Agregar Fotos' : 'Agregar Más'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            // Grid de fotos seleccionadas
            if (fotos.isNotEmpty) ...[
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: fotos.length,
                itemBuilder: (context, index) {
                  final foto = fotos[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                (foto as XFile).path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              )
                            : Image.file(
                                foto as File,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => onEliminarFoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            
            // Mensaje informativo
            if (fotos.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Puedes agregar hasta 5 fotos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
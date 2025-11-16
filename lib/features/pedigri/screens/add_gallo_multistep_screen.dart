import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../../services/gallo_service.dart';
import '../../../services/gallo_service_v2.dart';
import '../../../services/suscripcion_service.dart'; // ✅ AGREGADO
import '../../../shared/widgets/limite_interceptor.dart'; // ✅ AGREGADO
import '../../../models/suscripcion_models.dart'; // ✅ AGREGADO
import '../../../shared/constants/app_icons.dart';

class AddGalloMultistepScreen extends StatefulWidget {
  const AddGalloMultistepScreen({Key? key}) : super(key: key);

  @override
  State<AddGalloMultistepScreen> createState() => _AddGalloMultistepScreenState();
}

class _AddGalloMultistepScreenState extends State<AddGalloMultistepScreen> with TickerProviderStateMixin {
  // ===== CONTROL DE FASES =====
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  // ===== CONTROLADORES FASE 1: 📷 Foto y Datos Principales =====
  final _nombreController = TextEditingController();
  final _registroController = TextEditingController();
  DateTime? _fechaNacimiento;
  String? _colorPlaca;
  String? _ubicacionPlaca;
  // Migración: múltiples fotos (máx 4). Mantenemos compatibilidad con File/XFile
  final List<dynamic> _selectedImages = []; // cada item: File (móvil) o XFile (web)
  
  // ===== CONTROLADORES FASE 2: 📝 Datos Básicos =====
  String? _raza;
  String? _colorPatas;
  String? _colorPlumaje;
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _criadorController = TextEditingController();
  final _propietarioController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  // ===== CONTROLADORES FASE 3: 👨‍👩‍👦 Genealogía =====
  late TabController _genealogyTabController;
  
  // TAB PADRE
  final _padreNombreController = TextEditingController();
  DateTime? _padreFechaNacimiento;
  final _padreRegistroController = TextEditingController();
  String? _padreColorPlaca;
  String? _padreLugarPlaca;
  
  // TAB MADRE
  final _madreNombreController = TextEditingController();
  DateTime? _madreFechaNacimiento;
  final _madreRegistroController = TextEditingController();
  String? _madreColorPlaca;
  String? _madreLugarPlaca;
  
  // ===== CONTROLADORES FASE 4: 📋 Notas Finales =====
  final _notasFinalesController = TextEditingController();
  
  // ===== ESTADOS =====
  bool _isLoading = false;
  
  // ===== SERVICIOS =====
  final ImagePicker _imagePicker = ImagePicker();
  
  // ===== DATOS DROPDOWN =====
  final List<String> _coloresPlaca = ['Rojo', 'Azul', 'Verde', 'Amarillo', 'Blanco', 'Negro', 'Plateado', 'Dorado'];
  final List<String> _ubicacionesPlaca = ['Ala Derecha', 'Ala Izquierda','Ambas Alas'];
  final List<String> _razas = ['Kelso', 'Hatch', 'Albany', 'Sweater', 'Radio', 'Claret'];
  final List<String> _coloresPatas = ['Amarillo', 'Blanco', 'Verde', 'Negro', 'Gris'];
  final List<String> _coloresPlumaje = ['Colorado', 'Giro', 'Cenizo', 'Blanco', 'Negro', 'Combinado'];

  @override
  void initState() {
    super.initState();
    _genealogyTabController = TabController(length: 2, vsync: this);
    
    // Valores por defecto
    _pesoController.text = '2.5';
    _alturaController.text = '45';
  }

  @override
  void dispose() {
    // Dispose controladores
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
    
    _pageController.dispose();
    _genealogyTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildEpicAppBar(),
      body: WillPopScope(
        onWillPop: _handleBackPressed,
        child: Column(
          children: [
            // Progress indicator épico
            _buildEpicProgressIndicator(),
            
            // Contenido de fases
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Solo navegación por botones
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildFase1(), // 📷 Foto y Datos Principales
                  _buildFase2(), // 📝 Datos Básicos
                  _buildFase3(), // 👨‍👩‍👦 Genealogía
                  _buildFase4(), // 📋 Notas Finales
                ],
              ),
            ),
            
            // Botones de navegación épicos
            _buildEpicNavigationButtons(),
          ],
        ),
      ),
    );
  }

  // ===== APPBAR ÉPICO =====
  PreferredSizeWidget _buildEpicAppBar() {
    final List<String> stepTitles = [
      '📷 Foto y Datos',
      '📝 Características', 
      '👨‍👩‍👦 Genealogía',
      '📋 Finalizar'
    ];
    
    return AppBar(
      backgroundColor: Colors.red, // ✅ ROJO PURO
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          const Text(
            '➕ Nuevo Gallo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Paso ${_currentStep + 1}/4: ${stepTitles[_currentStep]}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        if (_currentStep == 3)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _guardarGalloCompleto,
          ),
      ],
    );
  }

  // ===== PROGRESS INDICATOR ÉPICO =====
  Widget _buildEpicProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent 
                            ? Colors.red  // ✅ TEMA ROJO
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (index < 3)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isCompleted 
                            ? Colors.red  // ✅ TEMA ROJO
                            : isCurrent 
                                ? Colors.red  // ✅ TEMA ROJO
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: isCompleted 
                          ? const Icon(Icons.check, size: 8, color: Colors.white)
                          : null,
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===== FASE 1: 📷 FOTO Y DATOS PRINCIPALES =====
  Widget _buildFase1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header informativo
          _buildPhaseHeader(
            icon: Icons.photo_camera,
            title: 'FASE 1: Foto y Datos Principales',
            subtitle: 'Información básica del gallo',
          ),
          const SizedBox(height: 24),

          // Sección de foto
          _buildPhotoSection(),
          const SizedBox(height: 24),
          
          // 1. Nombre del Gallo * (obligatorio)
          _buildEpicTextField(
            controller: _nombreController,
            label: 'Nombre del Gallo',
            hint: 'Ej: El Campeón, Relámpago...',
            icon: AppIcons.galloIconData,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          // 2. Fecha de Nacimiento
          _buildDatePicker(
            label: 'Fecha de Nacimiento',
            selectedDate: _fechaNacimiento,
            onDateSelected: (date) => setState(() => _fechaNacimiento = date),
          ),
          const SizedBox(height: 16),
          
          // 3. Número de Registro
          _buildEpicTextField(
            controller: _registroController,
            label: 'Número de Registro',
            hint: 'Ej: CAM001, REL002...',
            icon: Icons.confirmation_number,
          ),
          const SizedBox(height: 16),
          
          // 4. Color de Placa
          _buildEpicDropdown(
            label: 'Color de Placa',
            value: _colorPlaca,
            items: _coloresPlaca,
            onChanged: (value) => setState(() => _colorPlaca = value),
            icon: Icons.palette,
          ),
          const SizedBox(height: 16),
          
          // 5. Ubicación de Placa
          _buildEpicDropdown(
            label: 'Ubicación de Placa',
            value: _ubicacionPlaca,
            items: _ubicacionesPlaca,
            onChanged: (value) => setState(() => _ubicacionPlaca = value),
            icon: Icons.place,
          ),
        ],
      ),
    );
  }

  // ===== FASE 2: 📝 DATOS BÁSICOS =====
  Widget _buildFase2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header informativo
          _buildPhaseHeader(
            icon: Icons.description,
            title: 'FASE 2: Características Físicas',
            subtitle: 'Detalles físicos y procedencia',
          ),
          const SizedBox(height: 24),
          
          // 1. Raza
          _buildEpicDropdown(
            label: 'Raza',
            value: _raza,
            items: _razas,
            onChanged: (value) => setState(() => _raza = value),
            icon: AppIcons.galloIconData,
          ),
          const SizedBox(height: 16),
          
          // 2. Color de Patas
          _buildEpicDropdown(
            label: 'Color de Patas',
            value: _colorPatas,
            items: _coloresPatas,
            onChanged: (value) => setState(() => _colorPatas = value),
            icon: Icons.colorize,
          ),
          const SizedBox(height: 16),
          
          // 3. Color de Plumaje
          _buildEpicDropdown(
            label: 'Color de Plumaje',
            value: _colorPlumaje,
            items: _coloresPlumaje,
            onChanged: (value) => setState(() => _colorPlumaje = value),
            icon: Icons.brush,
          ),
          const SizedBox(height: 16),
          
          // 4 y 5. Peso y Altura (en fila)
          Row(
            children: [
              Expanded(
                child: _buildEpicTextField(
                  controller: _pesoController,
                  label: 'Peso (kg)',
                  hint: '2.5',
                  icon: Icons.fitness_center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEpicTextField(
                  controller: _alturaController,
                  label: 'Altura (cm)',
                  hint: '45',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 6. Criador
          _buildEpicTextField(
            controller: _criadorController,
            label: 'Criador',
            hint: 'Nombre del criador',
            icon: Icons.person,
          ),
          const SizedBox(height: 16),
          
          // 7. Propietario Actual
          _buildEpicTextField(
            controller: _propietarioController,
            label: 'Propietario Actual',
            hint: 'Nombre del propietario',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          
          // 8. Observaciones
          _buildEpicTextField(
            controller: _observacionesController,
            label: 'Observaciones',
            hint: 'Características especiales, temperamento...',
            icon: Icons.note,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ===== FASE 3: 👨‍👩‍👦 GENEALOGÍA =====
  Widget _buildFase3() {
    return Column(
      children: [
        // Header informativo
        Container(
          padding: const EdgeInsets.all(20),
          child: _buildPhaseHeader(
            icon: Icons.family_restroom,
            title: 'FASE 3: Genealogía',
            subtitle: 'Información de los padres (opcional)',
          ),
        ),
        
        // Tabs de genealogía
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _genealogyTabController,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            tabs: const [
              Tab(
                icon: Icon(Icons.male),
                text: 'PADRE 👨',
              ),
              Tab(
                icon: Icon(Icons.female),
                text: 'MADRE 👩',
              ),
            ],
          ),
        ),
        
        // Contenido de tabs
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
    );
  }

  Widget _buildPadreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '👨 Información del Padre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildEpicTextField(
            controller: _padreNombreController,
            label: 'Nombre del Padre',
            hint: 'Ej: Tornado, El Jefe...',
            icon: Icons.male,
          ),
          const SizedBox(height: 16),
          
          _buildDatePicker(
            label: 'Fecha de Nacimiento del Padre',
            selectedDate: _padreFechaNacimiento,
            onDateSelected: (date) => setState(() => _padreFechaNacimiento = date),
          ),
          const SizedBox(height: 16),
          
          _buildEpicTextField(
            controller: _padreRegistroController,
            label: 'Número de Registro del Padre',
            hint: 'Ej: TOR001...',
            icon: Icons.confirmation_number,
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
            label: 'Lugar de Placa del Padre',
            value: _padreLugarPlaca,
            items: _ubicacionesPlaca,
            onChanged: (value) => setState(() => _padreLugarPlaca = value),
            icon: Icons.place,
          ),
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
          const Text(
            '👩 Información de la Madre',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildEpicTextField(
            controller: _madreNombreController,
            label: 'Nombre de la Madre',
            hint: 'Ej: Reina, La Jefa...',
            icon: Icons.female,
          ),
          const SizedBox(height: 16),
          
          _buildDatePicker(
            label: 'Fecha de Nacimiento de la Madre',
            selectedDate: _madreFechaNacimiento,
            onDateSelected: (date) => setState(() => _madreFechaNacimiento = date),
          ),
          const SizedBox(height: 16),
          
          _buildEpicTextField(
            controller: _madreRegistroController,
            label: 'Número de Registro de la Madre',
            hint: 'Ej: REI001...',
            icon: Icons.confirmation_number,
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
            label: 'Lugar de Placa de la Madre',
            value: _madreLugarPlaca,
            items: _ubicacionesPlaca,
            onChanged: (value) => setState(() => _madreLugarPlaca = value),
            icon: Icons.place,
          ),
        ],
      ),
    );
  }

  // ===== FASE 4: 📋 NOTAS FINALES =====
  Widget _buildFase4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header informativo
          _buildPhaseHeader(
            icon: Icons.note_add,
            title: 'FASE 4: Finalización',
            subtitle: 'Notas adicionales y guardado',
          ),
          const SizedBox(height: 24),
          
          // Resumen de datos ingresados
          _buildDataSummary(),
          const SizedBox(height: 24),
          
          // Notas finales (expandible)
          _buildEpicTextField(
            controller: _notasFinalesController,
            label: 'Notas Finales',
            hint: 'Información adicional, historial médico, logros, etc...',
            icon: Icons.notes,
            maxLines: 6,
          ),
          const SizedBox(height: 32),
          
          // Botón guardar épico
          _buildEpicSaveButton(),
        ],
      ),
    );
  }

  // ===== COMPONENTES UI ÉPICOS =====
  
  Widget _buildPhaseHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEpicTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.red) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEpicDropdown({
    required String label,
    String? value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.red) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () => _selectDate(onDateSelected),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.red),
            const SizedBox(width: 12),
            Text(
              selectedDate != null
                  ? '$label: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'
                  : label,
              style: TextStyle(
                fontSize: 16,
                color: selectedDate != null ? Colors.black : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📸 Fotos del Gallo (hasta 4)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 12),

        // 🔥 NUEVO: Estructura igual al edit screen
        if (_selectedImages.isEmpty)
          // Estado vacío - mostrar botón grande para agregar primera foto
          InkWell(
            onTap: _pickMultipleFromGallery,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 42, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Agregar foto principal', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('Toca para seleccionar hasta 4 fotos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          )
        else
          // Mostrar fotos seleccionadas
          Column(
            children: [
              // 📸 FOTO PRINCIPAL (primera imagen)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[100], // Fondo para ver el ajuste
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: _buildImageForDisplay(_selectedImages[0], BoxFit.contain),
                      ),
                    ),
                    // Badge "Principal"
                    Positioned(
                      top: 8,
                      left: 8,
{{ ... }
                    ),
                    itemCount: 3, // Máximo 3 fotos adicionales
                    itemBuilder: (context, index) {
                      final photoIndex = index + 1; // Índices 1, 2, 3 (saltamos la principal que es índice 0)

                      if (photoIndex < _selectedImages.length) {
                        // Mostrar foto adicional existente
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[100], // Fondo
                                child: _buildImageForDisplay(_selectedImages[photoIndex], BoxFit.contain),
                              ),
                            ),
                            // Botón eliminar mini
                            Positioned(
                              top: 2,
                              right: 2,
{{ ... }
        ),
      );
    }
  }

  // 🖼️ HELPER: Construir widget de imagen según tipo (File o XFile)
  // BoxFit.contain = La imagen se ajusta dentro del contenedor sin cortarse
  // BoxFit.cover = La imagen llena todo el contenedor (puede cortarse)
  Widget _buildImageForDisplay(dynamic image, BoxFit fit) {
    if (image is XFile) {
      return Image.network(
        image.path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          );
        },
      );
    } else {
      return Image.file(
        image as File,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
          );
        },
      );
    }
  }
}
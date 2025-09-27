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
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildImageForDisplay(_selectedImages[0], BoxFit.cover),
                    ),
                    // Badge "Principal"
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Principal', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    // Botón eliminar
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(0);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 📸 FOTOS ADICIONALES (2, 3, 4) en una fila
              if (_selectedImages.length > 1 || _selectedImages.length < 4)
                Container(
                  height: 80,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, // 3 columnas para fotos adicionales
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0, // Cuadrado
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
                              child: _buildImageForDisplay(_selectedImages[photoIndex], BoxFit.cover),
                            ),
                            // Botón eliminar mini
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(photoIndex);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else if (_selectedImages.length < 4) {
                        // Mostrar botón "agregar más" solo si no hemos llegado al máximo
                        return InkWell(
                          onTap: _pickMultipleFromGallery,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, color: Colors.grey[600], size: 16),
                                Text('Agregar', style: TextStyle(color: Colors.grey[600], fontSize: 8)),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Slot vacío (ya tenemos 4 fotos)
                        return Container();
                      }
                    },
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickMultipleFromGallery,
                icon: const Icon(Icons.add_a_photo),
                label: Text(_selectedImages.isEmpty ? 'Agregar Fotos' : 'Agregar más'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openCarouselViewer(0),
                icon: const Icon(Icons.slideshow),
                label: const Text('Ver Carrusel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAddPhotoTile() {
    return InkWell(
      onTap: _showPhotoOptions,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Icon(Icons.add_photo_alternate, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    final item = _selectedImages[index];
    Widget image;
    if (kIsWeb && item is XFile) {
      image = Image.network(item.path, fit: BoxFit.cover);
    } else {
      image = Image.file(item as File, fit: BoxFit.cover);
    }
    return GestureDetector(
      onTap: () => _openCarouselViewer(index),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(color: Colors.black12, child: image),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedImages.removeAt(index);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCarouselViewer(int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final controller = PageController(initialPage: initialIndex);
        return Dialog(
          insetPadding: const EdgeInsets.all(12),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: controller,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final item = _selectedImages[index];
                  if (kIsWeb && item is XFile) {
                    return InteractiveViewer(
                      child: Image.network(item.path, fit: BoxFit.contain),
                    );
                  } else {
                    return InteractiveViewer(
                      child: Image.file(item as File, fit: BoxFit.contain),
                    );
                  }
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

  Widget _buildDataSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text(
                'Resumen de Datos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text('📷 Fotos: ${_selectedImages.isNotEmpty ? "✅ ${_selectedImages.length} agregada(s)" : "❌ Sin fotos"}'),
          Text('🐓 Nombre: ${_nombreController.text.isNotEmpty ? _nombreController.text : "❌ Requerido"}'),
          Text('📝 Registro: ${_registroController.text.isNotEmpty ? _registroController.text : "Auto-generado"}'),
          Text('🏋️ Peso: ${_pesoController.text.isNotEmpty ? "${_pesoController.text} kg" : "No especificado"}'),
          Text('📏 Altura: ${_alturaController.text.isNotEmpty ? "${_alturaController.text} cm" : "No especificado"}'),
          Text('👨 Padre: ${_padreNombreController.text.isNotEmpty ? _padreNombreController.text : "Sin información"}'),
          Text('👩 Madre: ${_madreNombreController.text.isNotEmpty ? _madreNombreController.text : "Sin información"}'),
        ],
      ),
    );
  }

  Widget _buildEpicSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _guardarGalloCompleto,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: _isLoading 
        ? const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Guardando Gallo...'),
            ],
          )
        : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save, size: 24),
              SizedBox(width: 12),
              Text(
                'Guardar Gallo Completo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
    );
  }

  // ===== BOTONES DE NAVEGACIÓN ÉPICOS =====
  Widget _buildEpicNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón Anterior
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ),
          
          if (_currentStep > 0) const SizedBox(width: 16),
          
          // Botón Siguiente/Guardar
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _currentStep == 3 ? _guardarGalloCompleto : _nextStep,
              icon: Icon(_currentStep == 3 ? Icons.save : Icons.arrow_forward),
              label: Text(_currentStep == 3 ? 'Guardar' : 'Siguiente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== LÓGICA DE NAVEGACIÓN =====
  
  void _nextStep() {
    try {
      // Validar fase actual antes de avanzar
      switch (_currentStep) {
        case 0:
          _validateFase1();
          break;
        case 1:
          _validateFase2();
          break;
        case 2:
          _validateFase3();
          break;
      }
      
      if (_currentStep < 3) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      _showEpicSnackbar(e.toString(), Colors.red);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _handleBackPressed() async {
    if (_currentStep > 0) {
      _previousStep();
      return false;
    } else {
      return await _showExitDialog();
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Salir del formulario'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres salir?\n\nSe perderán todos los datos ingresados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ===== VALIDACIONES ÉPICAS =====
  
  void _validateFase1() {
    if (_nombreController.text.trim().isEmpty) {
      throw 'El nombre del gallo es obligatorio';
    }
    if (_nombreController.text.trim().length < 2) {
      throw 'El nombre debe tener al menos 2 caracteres';
    }
  }

  void _validateFase2() {
    if (_pesoController.text.isNotEmpty) {
      final peso = double.tryParse(_pesoController.text);
      if (peso == null || peso <= 0 || peso > 10) {
        throw 'Peso debe ser entre 0.1 y 10 kg';
      }
    }
    
    if (_alturaController.text.isNotEmpty) {
      final altura = int.tryParse(_alturaController.text);
      if (altura == null || altura <= 0 || altura > 100) {
        throw 'Altura debe ser entre 1 y 100 cm';
      }
    }
  }

  void _validateFase3() {
    // Genealogía es opcional, pero si se llena debe ser válida
    if (_padreNombreController.text.trim().isNotEmpty) {
      if (_padreNombreController.text.trim().length < 2) {
        throw 'Nombre del padre debe tener al menos 2 caracteres';
      }
    }
    
    if (_madreNombreController.text.trim().isNotEmpty) {
      if (_madreNombreController.text.trim().length < 2) {
        throw 'Nombre de la madre debe tener al menos 2 caracteres';
      }
    }
  }

  // ===== FUNCIONES DE FOTO =====
  
  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.blue),
              title: const Text('Cámara'),
              subtitle: const Text('Tomar foto nueva'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Galería'),
              subtitle: const Text('Seleccionar imagen existente'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (_selectedImages.length < 4) ...[
              ListTile(
                leading: const Icon(Icons.collections, color: Colors.purple),
                title: const Text('Galería (múltiples)'),
                subtitle: const Text('Seleccionar hasta completar 4'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleFromGallery();
                },
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        if (_selectedImages.length >= 4) {
          _showEpicSnackbar('⚠️ Límite de 4 fotos alcanzado', Colors.orange);
          return;
        }
        setState(() {
          if (kIsWeb) {
            _selectedImages.add(image); // XFile para web
          } else {
            _selectedImages.add(File(image.path)); // File para móvil
          }
        });
        _showEpicSnackbar('📷 Foto agregada', Colors.green);
      }
    } catch (e) {
      _showEpicSnackbar('❌ Error accediendo a la cámara: $e', Colors.red);
    }
  }
  
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        if (_selectedImages.length >= 4) {
          _showEpicSnackbar('⚠️ Ya tienes 4 fotos seleccionadas', Colors.orange);
          return;
        }
        setState(() {
          if (kIsWeb) {
            _selectedImages.add(image); // XFile para web
          } else {
            _selectedImages.add(File(image.path)); // File para móvil
          }
        });
        _showEpicSnackbar('📁 Imagen agregada', Colors.green);
      }
    } catch (e) {
      _showEpicSnackbar('❌ Error accediendo a la galería: $e', Colors.red);
    }
  }

  Future<void> _pickMultipleFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (images.isEmpty) return;
      for (final img in images) {
        if (_selectedImages.length >= 4) break;
        if (kIsWeb) {
          _selectedImages.add(img);
        } else {
          _selectedImages.add(File(img.path));
        }
      }
      setState(() {});
      _showEpicSnackbar('📁 ${images.length} imagen(es) seleccionada(s)', Colors.green);
    } catch (e) {
      _showEpicSnackbar('❌ Error seleccionando múltiples: $e', Colors.red);
    }
  }

  Future<void> _selectDate(Function(DateTime) onDateSelected) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.red,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      onDateSelected(date);
    }
  }

  // ===== GUARDAR GALLO COMPLETO ÉPICO =====
  
  // ===== MÉTODO ÉPICO DE GUARDADO - INTEGRACIÓN TOTAL =====
  Future<void> _guardarGalloCompleto() async {
    try {
      print('🔥 === INICIANDO GUARDADO ÉPICO ===');
      
      // 🚨 VALIDAR LÍMITES DE SUSCRIPCIÓN PRIMERO (DIRECTO)
      try {
        print('🔍 [AddGallo] Validando límites de gallos...');
        
        final validacion = await SuscripcionService.validarLimite(
          recursoTipo: RecursoTipo.gallos.value,
          galloId: null,
        );
        
        print('🔍 [AddGallo] Resultado: puedeCrear=${validacion.puedeCrear}');
        
        if (!validacion.puedeCrear) {
          print('❌ [AddGallo] Límite alcanzado - Mostrando popup directo');
          
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.white,
                title: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text('Límite Alcanzado', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                titlePadding: EdgeInsets.zero,
                content: Text(
                  '${validacion.mensajeError ?? "Has alcanzado el límite de gallos"}\n\n'
                  '¿Deseas actualizar tu plan para crear más gallos?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/planes');
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Actualizar Plan', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          
          return; // Salir sin crear el gallo
        }
        
        print('✅ [AddGallo] Límite OK - Continuando con creación...');
      } catch (e) {
        print('❌ [AddGallo] Error en validación de límites: $e');
        _showEpicSnackbar('⚠️ Error validando límites. Continuando...', Colors.orange);
        // Continuar sin validación en caso de error del servidor
      }
      
      // 🔄 AHORA SÍ ACTIVAR LOADING PARA EL GUARDADO REAL
      setState(() => _isLoading = true);
      
      // 1. 🔍 VALIDACIONES RÁPIDAS
      if (_nombreController.text.trim().isEmpty) {
        throw 'El nombre del gallo es obligatorio';
      }
      if (_nombreController.text.trim().length < 2) {
        throw 'El nombre debe tener al menos 2 caracteres';
      }
      
      _showEpicSnackbar('🔍 Validando datos...', Colors.blue);
      await Future.delayed(Duration(milliseconds: 800));
      
      // 2. 📤 PREPARAR DATOS PARA BACKEND
      _showEpicSnackbar('📤 Preparando datos...', Colors.blue);
      
      final galloData = _prepareGalloDataForBackend();
      print('📊 Datos preparados: ${galloData.keys.length} campos');
      
      await Future.delayed(Duration(milliseconds: 800));
      
      // 3. 🚀 ENVIAR AL BACKEND - UNA SOLA LLAMADA CON TODAS LAS FOTOS
      if (_selectedImages.isNotEmpty) {
        _showEpicSnackbar('🚀 Creando gallo con ${_selectedImages.length} fotos...', Colors.orange);
      } else {
        _showEpicSnackbar('🚀 Creando gallo...', Colors.orange);
      }

      final response = await GalloServiceV2.createGalloConGenealogiaEpico(
        galloData: galloData,
        foto: _selectedImages.isNotEmpty ? _selectedImages.first : null,
        fotosAdicionales: _selectedImages.length > 1 ? _selectedImages.sublist(1) : [],
      );

      // 4. 🎯 PROCESAR RESPUESTA ÉPICA
      if (response['success'] == true) {
        _showEpicSnackbar('✅ Gallo creado exitosamente', Colors.green);
        await _handleSuccessResponse(response);
      } else {
        throw response['message'] ?? 'Error desconocido del servidor';
      }
      
    } catch (e) {
      print('❌ Error en guardado épico: $e');
      _showEpicSnackbar('❌ Error: $e', Colors.red);
      await Future.delayed(Duration(milliseconds: 2000)); // Esperar para que el usuario lea el error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===== HELPER: PREPARAR DATOS PARA BACKEND =====
  Map<String, dynamic> _prepareGalloDataForBackend() {
    final data = <String, dynamic>{};
    
    // DATOS OBLIGATORIOS
    data['nombre'] = _nombreController.text.trim();
    data['codigo_identificacion'] = _registroController.text.trim().isNotEmpty 
        ? _registroController.text.trim() 
        : 'AUTO_${DateTime.now().millisecondsSinceEpoch}';
    
    // DATOS OPCIONALES FASE 1
    if (_fechaNacimiento != null) data['fecha_nacimiento'] = _fechaNacimiento;
    if (_colorPlaca != null) data['color_placa'] = _colorPlaca;
    if (_ubicacionPlaca != null) data['ubicacion_placa'] = _ubicacionPlaca;
    
    // DATOS OPCIONALES FASE 2
    if (_pesoController.text.isNotEmpty) data['peso'] = double.tryParse(_pesoController.text) ?? 2.5;
    if (_alturaController.text.isNotEmpty) data['altura'] = int.tryParse(_alturaController.text) ?? 45;
    
    // 🔥 RAZA_ID CORREGIDO - ENVIAR COMO STRING, NO COMO ENTERO
    if (_raza != null) {
      data['raza_id'] = _mapRazaToStringId(_raza); // 🔥 NUEVO MÉTODO
      print('🐓 raza_id enviado al backend: ${data['raza_id']}'); // DEBUG
    } else {
      print('⚠️ raza_id es null - no se enviará'); // DEBUG
    }
    
    if (_colorPatas != null) data['color_patas'] = _colorPatas;
    if (_colorPlumaje != null) data['color'] = _colorPlumaje;
    if (_criadorController.text.isNotEmpty) data['criador'] = _criadorController.text.trim();
    if (_propietarioController.text.isNotEmpty) data['propietario_actual'] = _propietarioController.text.trim();
    if (_observacionesController.text.isNotEmpty) data['observaciones'] = _observacionesController.text.trim();
    
    // DATOS FASE 4
    if (_notasFinalesController.text.isNotEmpty) data['notas'] = _notasFinalesController.text.trim();
    
    // GENEALOGÍA ÉPICA
    final crearPadre = _padreNombreController.text.trim().isNotEmpty;
    final crearMadre = _madreNombreController.text.trim().isNotEmpty;
    
    data['crear_padre'] = crearPadre;
    data['crear_madre'] = crearMadre;
    
    if (crearPadre) {
      data['padre_nombre'] = _padreNombreController.text.trim();
      if (_padreRegistroController.text.isNotEmpty) {
        data['padre_codigo'] = _padreRegistroController.text.trim();
      }
      if (_padreFechaNacimiento != null) {
        data['padre_fecha_nacimiento'] = _padreFechaNacimiento;
      }
    }
    
    if (crearMadre) {
      data['madre_nombre'] = _madreNombreController.text.trim();
      if (_madreRegistroController.text.isNotEmpty) {
        data['madre_codigo'] = _madreRegistroController.text.trim();
      }
      if (_madreFechaNacimiento != null) {
        data['madre_fecha_nacimiento'] = _madreFechaNacimiento;
      }
    }
    
    // 🔍 DEBUG: MOSTRAR TODOS LOS DATOS FINALES
    print('📊 === DATOS FINALES PARA BACKEND ===');
    data.forEach((key, value) {
      print('🔑 $key: $value (${value.runtimeType})');
    });
    print('=========================================');
    
    return data;
  }

  // ===== HELPER: PROCESAR RESPUESTA EXITOSA =====
  Future<void> _handleSuccessResponse(Map<String, dynamic> response) async {
    final data = response['data'];
    final galloPrincipal = data['data']?['gallo_principal'] ?? data['gallo_principal'] ?? data;
    
    // Calcular registros creados
    final totalRegistros = 1 + 
        (_padreNombreController.text.trim().isNotEmpty ? 1 : 0) + 
        (_madreNombreController.text.trim().isNotEmpty ? 1 : 0);
    
    // LIMPIAR SNACKBARS ANTERIORES
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // PASO 1: MOSTRAR QUE SE COMPLETÓ
    _showEpicSnackbar('✅ ¡Gallo creado exitosamente!', Colors.green);
    await Future.delayed(Duration(milliseconds: 1500));
    
    // PASO 2: MOSTRAR RESUMEN DETALLADO
    ScaffoldMessenger.of(context).clearSnackBars();
    _showEpicSnackbar(
      '🎉 RESUMEN FINAL:\n'
      '• Gallo principal: ${galloPrincipal?['nombre'] ?? _nombreController.text}\n'
      '• Total registros creados: $totalRegistros\n'
      '• Padre: ${_padreNombreController.text.isNotEmpty ? "✅ ${_padreNombreController.text}" : "❌ Sin datos"}\n'
      '• Madre: ${_madreNombreController.text.isNotEmpty ? "✅ ${_madreNombreController.text}" : "❌ Sin datos"}\n'
      '• Fotos: ${_selectedImages.isNotEmpty ? "✅ ${_selectedImages.length} subida(s)" : "❌ Sin foto"}',
      Colors.green,
    );
    
    // PASO 3: ESPERAR QUE EL USUARIO LEA TODO
    await Future.delayed(Duration(milliseconds: 3500));
    
    // PASO 4: MOSTRAR QUE VA A REGRESAR Y REFRESCAR
    ScaffoldMessenger.of(context).clearSnackBars();
    _showEpicSnackbar('🔄 Actualizando lista de gallos...', Colors.blue);
    await Future.delayed(Duration(milliseconds: 1500));
    
    // PASO 5: LIMPIAR TODO Y REGRESAR CON DATOS PARA REFRESCAR
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Retornar resultado ÉPICO para refrescar la lista
    final galloCompleto = {
      'success': true,
      'action': 'REFRESH_LIST', // 🔥 FLAG ÉPICO PARA REFRESCAR
      'total_registros_creados': totalRegistros,
      'gallo_principal': {
        'id': galloPrincipal?['id'],
        'nombre': galloPrincipal?['nombre'] ?? _nombreController.text,
        'codigo_identificacion': galloPrincipal?['codigo_identificacion'],
      },
      'genealogia_creada': {
        'padre': _padreNombreController.text.isNotEmpty ? _padreNombreController.text : null,
        'madre': _madreNombreController.text.isNotEmpty ? _madreNombreController.text : null,
      },
      'foto_subida': _selectedImages.isNotEmpty,
      'mensaje_exito': '🎉 Se crearon $totalRegistros gallos con genealogía!',
      'fecha_creacion': DateTime.now().toIso8601String(),
    };
    
    Navigator.pop(context, galloCompleto);
  }

  // ===== HELPER: MAPEAR RAZA A STRING ID (CORREGIDO) =====
  String _mapRazaToStringId(String? raza) {
    if (raza == null) return 'KELSO_AMERICANO';
    
    // 🔥 MAPEAR A IDs STRING COMO ESPERA EL BACKEND
    switch (raza) {
      case 'Kelso': return 'KELSO_AMERICANO';
      case 'Hatch': return 'HATCH_AMERICANO';
      case 'Albany': return 'ALBANY_AMERICANO';
      case 'Sweater': return 'SWEATER_AMERICANO';
      case 'Radio': return 'RADIO_AMERICANO';
      case 'Claret': return 'CLARET_AMERICANO';
      default: return 'KELSO_AMERICANO'; // Default
    }
  }

  // ===== HELPER: MAPEAR RAZA A ID (MANTENER PARA COMPATIBILIDAD) =====
  int _mapRazaToId(String? raza) {
    if (raza == null) return 1;
    
    switch (raza) {
      case 'Kelso': return 1;
      case 'Hatch': return 2;
      case 'Albany': return 3;
      case 'Sweater': return 4;
      case 'Radio': return 5;
      case 'Claret': return 6;
      default: return 1;
    }
  }

  // ===== DIÁLOGO ERROR FOTO =====
  Future<bool> _showFotoErrorDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Error subiendo foto'),
          ],
        ),
        content: const Text(
          'No se pudo subir la foto del gallo.\n\n¿Qué deseas hacer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuar sin foto', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  // ===== SNACKBAR ÉPICO =====
  void _showEpicSnackbar(String message, Color backgroundColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  // 🖼️ HELPER: Construir widget de imagen según tipo (File o XFile)
  Widget _buildImageForDisplay(dynamic image, BoxFit fit) {
    if (image is XFile) {
      return Image.network(
        image.path,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      return Image.file(
        image as File,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
      );
    }
  }
}
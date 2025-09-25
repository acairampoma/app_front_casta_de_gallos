// 📁 lib/features/admin/screens/formulario_coliseo_screen.dart
// 🏟️ Formulario para crear/editar coliseos

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../shared/theme/app_colors.dart';

class FormularioColiseoScreen extends StatefulWidget {
  final Map<String, dynamic>? coliseo;

  const FormularioColiseoScreen({
    Key? key,
    this.coliseo,
  }) : super(key: key);

  @override
  State<FormularioColiseoScreen> createState() => _FormularioColiseoScreenState();
}

class _FormularioColiseoScreenState extends State<FormularioColiseoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _nombreController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _direccionController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _aforoMaximoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  // Estado
  String tipoColiseoSeleccionado = 'local';
  bool activoEstado = true;
  bool isLoading = false;

  final List<Map<String, String>> tiposColiseo = [
    {'codigo': 'local', 'nombre': '🏠 Local'},
    {'codigo': 'grande', 'nombre': '🏟️ Grande'},
    {'codigo': 'especial', 'nombre': '👑 Especial'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    _departamentoController.dispose();
    _aforoMaximoController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initializeFormData() {
    if (widget.coliseo != null) {
      final coliseo = widget.coliseo!;

      _nombreController.text = coliseo['nombre'] ?? '';
      _ciudadController.text = coliseo['ciudad'] ?? '';
      _direccionController.text = coliseo['direccion'] ?? '';
      _departamentoController.text = coliseo['departamento'] ?? '';
      _aforoMaximoController.text = coliseo['aforo_maximo']?.toString() ?? '';
      _descripcionController.text = coliseo['descripcion'] ?? '';
      _telefonoController.text = coliseo['telefono'] ?? '';
      _emailController.text = coliseo['email'] ?? '';

      tipoColiseoSeleccionado = coliseo['tipo_coliseo'] ?? 'local';
      activoEstado = coliseo['activo'] ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.coliseo != null ? 'Editar Coliseo' : 'Nuevo Coliseo',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInformacionBasicaSection(),
                const SizedBox(height: 20),
                _buildConfiguracionSection(),
                const SizedBox(height: 20),
                _buildContactoSection(),
                const SizedBox(height: 32),
                _buildSaveButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🏟️ SECCIÓN 1: INFORMACIÓN BÁSICA
  Widget _buildInformacionBasicaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏟️ INFORMACIÓN BÁSICA',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 16),

          // Nombre del coliseo
          TextFormField(
            controller: _nombreController,
            decoration: InputDecoration(
              labelText: 'Nombre del Coliseo *',
              hintText: 'Ej: Coliseo Los Gallos de Oro',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Ciudad y Departamento
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ciudadController,
                  decoration: InputDecoration(
                    labelText: 'Ciudad *',
                    hintText: 'Ej: Lima',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La ciudad es obligatoria';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _departamentoController,
                  decoration: InputDecoration(
                    labelText: 'Departamento *',
                    hintText: 'Ej: Lima',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El departamento es obligatorio';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dirección
          TextFormField(
            controller: _direccionController,
            decoration: InputDecoration(
              labelText: 'Dirección',
              hintText: 'Av. Principal 123, Distrito',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Descripción
          TextFormField(
            controller: _descripcionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Descripción',
              hintText: 'Descripción del coliseo, características especiales...',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ SECCIÓN 2: CONFIGURACIÓN
  Widget _buildConfiguracionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ CONFIGURACIÓN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),

          // Tipo de coliseo
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tipo de Coliseo *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: tipoColiseoSeleccionado,
                    isExpanded: true,
                    onChanged: (String? value) {
                      setState(() {
                        tipoColiseoSeleccionado = value!;
                      });
                    },
                    items: tiposColiseo.map((tipo) {
                      return DropdownMenuItem(
                        value: tipo['codigo'],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            tipo['nombre']!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Aforo máximo
          TextFormField(
            controller: _aforoMaximoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Aforo Máximo *',
              hintText: 'Ej: 500',
              suffixText: 'personas',
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El aforo es obligatorio';
              }
              final aforo = int.tryParse(value.trim());
              if (aforo == null || aforo <= 0) {
                return 'Ingrese un número válido mayor a 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Estado activo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activoEstado ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activoEstado ? Colors.green[300]! : Colors.red[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  activoEstado ? Icons.check_circle : Icons.cancel,
                  color: activoEstado ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estado del Coliseo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: activoEstado ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
                Switch(
                  value: activoEstado,
                  onChanged: (value) {
                    setState(() {
                      activoEstado = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📞 SECCIÓN 3: INFORMACIÓN DE CONTACTO
  Widget _buildContactoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📞 INFORMACIÓN DE CONTACTO',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),

          // Teléfono
          TextFormField(
            controller: _telefonoController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono',
              hintText: 'Ej: +51 999 123 456',
              prefixIcon: const Icon(Icons.phone),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'contacto@coliseo.com',
              prefixIcon: const Icon(Icons.email),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingrese un email válido';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _guardarColiseo,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                widget.coliseo != null ? 'Actualizar Coliseo' : 'Crear Coliseo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _guardarColiseo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('Token de autenticación no encontrado');
      }

      final Map<String, dynamic> coliseoData = {
        'nombre': _nombreController.text.trim(),
        'ciudad': _ciudadController.text.trim(),
        'departamento': _departamentoController.text.trim(),
        'tipo_coliseo': tipoColiseoSeleccionado,
        'aforo_maximo': int.parse(_aforoMaximoController.text.trim()),
        'activo': activoEstado,
      };

      // Agregar campos opcionales solo si no están vacíos
      if (_direccionController.text.trim().isNotEmpty) {
        coliseoData['direccion'] = _direccionController.text.trim();
      }
      if (_descripcionController.text.trim().isNotEmpty) {
        coliseoData['descripcion'] = _descripcionController.text.trim();
      }
      if (_telefonoController.text.trim().isNotEmpty) {
        coliseoData['telefono'] = _telefonoController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty) {
        coliseoData['email'] = _emailController.text.trim();
      }

      final response = widget.coliseo != null
        ? await http.put(
            Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/coliseos/${widget.coliseo!['id']}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(coliseoData),
          )
        : await http.post(
            Uri.parse('https://gallerappback-production.up.railway.app/api/v1/transmisiones/admin/coliseos'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(coliseoData),
          );

      print('🔍 Response status: ${response.statusCode}');
      print('🔍 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.coliseo != null
                ? 'Coliseo actualizado exitosamente'
                : 'Coliseo creado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Error del servidor');
      }
    } catch (e) {
      print('Error guardando coliseo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando coliseo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
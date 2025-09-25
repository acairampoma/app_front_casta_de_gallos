import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../shared/widgets/base_screen.dart';
import '../../../shared/widgets/adaptive_layout_builder.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/admin_notification_service.dart';
import '../../../utils/password_validator.dart';
import '../../auth/screens/login_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({Key? key}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isLoading = true;
  UserModel? _user;
  ProfileModel? _profile;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔐 CAMBIAR CONTRASEÑA
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool _obscureCurrentPassword = true;
    bool _obscureNewPassword = true;
    bool _obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: _obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña Actual',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPassword = !_obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    border: const OutlineInputBorder(),
                    helperText: 'Debe tener: letra + número, mín. 6 caracteres',
                    helperMaxLines: 2,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 🔐 VALIDACIONES ROBUSTAS CON PasswordValidator
                
                // Validar contraseña actual
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Ingresa tu contraseña actual'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Validar nueva contraseña con validador robusto
                final passwordError = PasswordValidator.validatePassword(newPasswordController.text);
                if (passwordError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $passwordError'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  return;
                }
                
                // Validar confirmación
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Las contraseñas no coinciden'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Cambiar contraseña
                Navigator.pop(context);
                
                // Mostrar loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('🔐 Cambiando contraseña...'),
                      ],
                    ),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 10),
                  ),
                );
                
                try {
                  final success = await AuthService.instance.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Contraseña cambiada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Error: Contraseña actual incorrecta'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } on ApiException catch (e) {
                  if (mounted) {
                    String errorMessage;
                    if (e.message.contains('Not Found') || e.message.contains('404')) {
                      errorMessage = '❌ Endpoint no disponible. Haz deploy del backend actualizado.';
                    } else if (e.message.contains('actual incorrecta')) {
                      errorMessage = '❌ Contraseña actual incorrecta';
                    } else if (e.message.contains('6 caracteres') || e.message.contains('letra') || e.message.contains('número')) {
                      errorMessage = '❌ Nueva contraseña: ${e.message}';
                    } else {
                      errorMessage = '❌ Error: ${e.message}';
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error de conexión: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  // 📱 CONTACTAR WHATSAPP
  void _contactWhatsApp() async {
    const phoneNumber = '51993592328'; // Número con código de país
    const message = '¡Hola! Necesito ayuda con la app Casta de Gallos 🐓';
    
    // URLs para diferentes plataformas
    final whatsappAppUrl = 'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}';
    final whatsappWebUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    
    try {
      // Intentar abrir la APP de WhatsApp primero
      final appUri = Uri.parse(whatsappAppUrl);
      bool launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        // Si no se puede abrir la app, intentar WhatsApp Web
        final webUri = Uri.parse(whatsappWebUrl);
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
      
      if (!launched) {
        throw Exception('No se pudo abrir WhatsApp');
      }
    } catch (e) {
      // Si falla, mostrar información de contacto
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📱 No se pudo abrir WhatsApp'),
                const Text('Contacta manualmente:'),
                Text('Teléfono: +$phoneNumber'),
                Text('Mensaje: $message'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      await AuthService.instance.loadCurrentUser();
      setState(() {
        _user = AuthService.instance.currentUser;
        _profile = AuthService.instance.currentProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return BaseScreen(
      title: 'Mi Perfil',
      subtitle: 'Información de usuario',
      currentIndex: 4, // Perfil section
      child: AdaptiveLayoutBuilder(
        mobile: _buildMobileProfile(),
        tablet: _buildTabletProfile(),
      ),
    );
  }
  
  Widget _buildMobileProfile() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildMenuOptions(context),
            const SizedBox(height: 24),
            _buildAdminButton(context),
            const SizedBox(height: 16),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabletProfile() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: ResponsiveRowColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo: Información del perfil
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildTabletProfileHeader(),
                  const SizedBox(height: 32),
                  _buildTabletProfileStats(),
                ],
              ),
            ),
            const SizedBox(width: 32),
            
            // Panel derecho: Opciones y configuraciones
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildTabletMenuOptions(context),
                  const SizedBox(height: 32),
                  _buildTabletAdminSection(context),
                  const SizedBox(height: 24),
                  _buildTabletLogoutButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 📷 TOMAR FOTO CON CÁMARA
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compresión para optimizar subida
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      print('💥 Error tomando foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accediendo a la cámara: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 🇬 ELEGIR DE GALERÍA
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compresión para optimizar subida
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      print('💥 Error seleccionando imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accediendo a la galería: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // ⬆️ SUBIR AVATAR
  Future<void> _uploadAvatar(File imageFile) async {
    setState(() {
      _isUploadingAvatar = true;
    });
    
    try {
      // Mostrar mensaje de subida
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('📷 Subiendo imagen...'),
            ],
          ),
          duration: Duration(seconds: 10),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Subir avatar usando AuthService
      final success = await AuthService.instance.uploadAvatar(imageFile);
      
      setState(() {
        _isUploadingAvatar = false;
      });
      
      if (success && mounted) {
        // Actualizar perfil en UI
        setState(() {
          _profile = AuthService.instance.currentProfile;
        });
        
        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('✅ Avatar actualizado exitosamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Error subiendo avatar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingAvatar = false;
      });
      
      print('💥 Error subiendo avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 🗑️ ELIMINAR AVATAR
  Future<void> _removeAvatar() async {
    try {
      // Mostrar diálogo de confirmación
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Avatar'),
          content: const Text('¿Estás seguro que deseas eliminar tu avatar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        // Mostrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('🗑️ Eliminando avatar...'),
              ],
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
        
        final success = await AuthService.instance.removeAvatar();
        
        if (success && mounted) {
          // Actualizar perfil en UI
          setState(() {
            _profile = AuthService.instance.currentProfile;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Avatar eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error eliminando avatar'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Error eliminando avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Avatar con botón para cambiar
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showAvatarOptions(),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                    child: _profile?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              _profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primary,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _user?.isPremium == true ? Colors.amber : Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _user?.isPremium == true ? Icons.star : Icons.verified,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                // Botón de cámara
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: () => _showAvatarOptions(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nombre
            Text(
              _profile?.nombreCompleto ?? 'Usuario',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Email
            Text(
              _user?.email ?? 'email@ejemplo.com',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // Galpón
            if (_profile?.nombreGalpon != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🏠 ${_profile!.nombreGalpon}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Stats básicos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('ID Usuario', '${_user?.id ?? 0}'),
                _buildStatItem('Ciudad', _profile?.ciudad ?? 'Lima'),
                _buildStatItem('Estado', _user?.isActive == true ? 'Activo' : 'Inactivo'),
              ],
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    final menuOptions = [
      _MenuOption(
        icon: Icons.edit,
        title: 'Editar Perfil',
        subtitle: 'Actualizar información personal',
        color: Colors.blue,
        onTap: () => _showEditProfileDialog(),
      ),
      ..._getMenuOptions(),
      _MenuOption(
        icon: Icons.delete_forever,
        title: 'Eliminar Cuenta',
        subtitle: 'Eliminación permanente (Apple requerido)',
        color: Colors.red,
        onTap: () => _showDeleteAccountDialog(),
      ),
      _MenuOption(
        icon: Icons.info,
        title: 'Acerca de',
        subtitle: 'Información de la aplicación',
        color: Colors.grey,
        onTap: () => _showAboutDialog(context),
      ),
    ];

    return Column(
      children: menuOptions.map((option) => _buildMenuOptionCard(option)).toList(),
    );
  }

  Widget _buildMenuOptionCard(_MenuOption option) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: option.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            option.icon,
            color: option.color,
            size: 24,
          ),
        ),
        title: Text(
          option.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          option.subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: option.onTap,
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context) {
    // 👑 MEJORADO: Usar campo es_admin de la BD
    if (!AuthService.instance.isAdmin) {
      return const SizedBox.shrink();
    }
    
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AdminNotificationService.obtenerPagosPendientes(),
      builder: (context, snapshot) {
        final pagosPendientes = snapshot.data?.length ?? 0;
        
        return Container(
          width: double.infinity,
          child: Stack(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    print('[Perfil] Admin navegando a Panel Admin...');
                    await _navegarAPanelAdmin(context);
                    print('[Perfil] Admin regresó del Panel Admin');
                  } catch (e) {
                    print('[Perfil] Error al abrir Panel Admin: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo abrir el Panel Admin. Intenta nuevamente.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('👑 Panel Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Badge de notificaciones pendientes
              if (pagosPendientes > 0)
                Positioned(
                  right: 12,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    child: Text(
                      '$pagosPendientes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nombreController = TextEditingController(text: _profile?.nombreCompleto);
    final telefonoController = TextEditingController(text: _profile?.telefono);
    final galponController = TextEditingController(text: _profile?.nombreGalpon);
    final biografiaController = TextEditingController(text: _profile?.biografia);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: galponController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Galpón',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: biografiaController,
                decoration: const InputDecoration(
                  labelText: 'Biografía',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await AuthService.instance.updateProfile(
                nombreCompleto: nombreController.text.trim().isNotEmpty 
                    ? nombreController.text.trim() 
                    : null,
                telefono: telefonoController.text.trim().isNotEmpty 
                    ? telefonoController.text.trim() 
                    : null,
                nombreGalpon: galponController.text.trim().isNotEmpty 
                    ? galponController.text.trim() 
                    : null,
                biografia: biografiaController.text.trim().isNotEmpty 
                    ? biografiaController.text.trim() 
                    : null,
              );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Perfil actualizado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadUserData();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Error actualizando perfil'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAvatarOptions() {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cambiar Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Tomar Foto'),
              subtitle: const Text('Usar cámara del dispositivo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Elegir de Galería'),
              subtitle: const Text('Seleccionar imagen existente'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if (_profile?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Casta de Gallos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión: 1.0.0'),
            SizedBox(height: 16),
            Text('Aplicación profesional para gestión integral de gallos de pelea.'),
            SizedBox(height: 16),
            Text('Características:'),
            Text('• Registro de gallos y pedigrí'),
            Text('• Control de vacunas y salud'),
            Text('• Gestión de entrenamientos'),
            Text('• Seguimiento de peleas'),
            Text('• Reportes y estadísticas'),
            SizedBox(height: 16),
            Text('© 2025 - Todos los derechos reservados'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🗑️ ELIMINAR CUENTA - DIÁLOGO COMPLETO CON VALIDACIONES
  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    bool _obscurePassword = true;
    bool _isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // No permitir cerrar tocando fuera
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Eliminar Cuenta',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ ADVERTENCIA IMPORTANTE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Esta acción es IRREVERSIBLE\n'
                        '• Se eliminarán TODOS tus datos\n'
                        '• Perfil, gallos, peleas, etc.\n'
                        '• No hay forma de recuperar la información',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Para confirmar, ingresa:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // Contraseña
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isDeleting,
                  decoration: InputDecoration(
                    labelText: 'Tu contraseña actual',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Texto de confirmación
                TextField(
                  controller: confirmationController,
                  enabled: !_isDeleting,
                  decoration: const InputDecoration(
                    labelText: 'Escribe: ELIMINAR MI CUENTA',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                    helperText: 'Debes escribir exactamente: ELIMINAR MI CUENTA',
                    helperMaxLines: 2,
                  ),
                ),
                
                if (_isDeleting)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Eliminando cuenta...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isDeleting ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isDeleting ? null : () async {
                // Validaciones
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Ingresa tu contraseña'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (confirmationController.text != 'ELIMINAR MI CUENTA') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ Debes escribir exactamente: ELIMINAR MI CUENTA'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Ejecutar eliminación
                setState(() {
                  _isDeleting = true;
                });
                
                try {
                  final response = await AuthService.instance.deleteAccount(
                    password: passwordController.text,
                    confirmationText: confirmationController.text,
                  );
                  
                  setState(() {
                    _isDeleting = false;
                  });
                  
                  Navigator.pop(context); // Cerrar diálogo
                  
                  if (response['success'] == true) {
                    // Mostrar mensaje de despedida
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'Cuenta eliminada exitosamente'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                    
                    // Navegar al login después de un delay
                    await Future.delayed(const Duration(seconds: 2));
                    
                    if (mounted) {
                      final navigator = Navigator.of(context, rootNavigator: true);
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } else {
                    // Error del servidor
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ ${response['message'] ?? 'Error eliminando cuenta'}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() {
                    _isDeleting = false;
                  });
                  
                  print('💥 Error eliminando cuenta: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error de conexión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ELIMINAR PERMANENTEMENTE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro que deseas cerrar sesión?\n\nEsto te desconectará del backend.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Cerrar diálogo
                Navigator.of(context).pop();
                
                // SOLUCIÓN DEFINITIVA: Guardar Navigator antes del logout
                final navigator = Navigator.of(context, rootNavigator: true);
                
                try {
                  // Ejecutar logout
                  await AuthService.instance.logout();
                  
                  // Limpiar SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  
                } catch (e) {
                  print('💥 Error en logout: $e');
                }
                
                // NAVEGAR SIEMPRE (con o sin error) usando el Navigator guardado
                // Esto evita el error "deactivated widget"
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  // ========================================
  // MÉTODOS ADMIN
  // ========================================

  Future<bool> _esUsuarioAdmin() async {
    // 👑 MEJORADO: Usar directamente AuthService que ya maneja es_admin
    return AuthService.instance.isAdmin;
  }

  Future<void> _navegarAPanelAdmin(BuildContext context) async {
    try {
      print('🚀 NAVEGANDO AL PANEL ADMIN...');
      print('👑 Admin verificado: ${AuthService.instance.isAdmin}');
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AdminDashboardScreen(),
        ),
      );
    } catch (e) {
      print('❌ ERROR NAVEGANDO AL PANEL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accediendo al panel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // ==========================================
  // 📟 MÉTODOS PARA TABLET
  // ==========================================
  
  Widget _buildTabletProfileHeader() {
    return ResponsiveCard(
      child: Column(
        children: [
          // Avatar más grande para tablet
          Stack(
            children: [
              GestureDetector(
                onTap: () => _showAvatarOptions(),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  ),
                  child: _profile?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _profile!.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 80,
                                color: AppColors.primary,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 80,
                          color: AppColors.primary,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: _user?.isPremium == true ? Colors.amber : Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _user?.isPremium == true ? Icons.star : Icons.verified,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: GestureDetector(
                  onTap: () => _showAvatarOptions(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Nombre más grande para tablet
          ResponsiveText(
            _profile?.nombreCompleto ?? 'Usuario',
            baseFontSize: 28,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Email
          ResponsiveText(
            _user?.email ?? 'email@ejemplo.com',
            baseFontSize: 16,
            color: Colors.grey.shade600,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Galpón
          if (_profile?.nombreGalpon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  ResponsiveText(
                    _profile!.nombreGalpon!,
                    baseFontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabletProfileStats() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Información del Perfil',
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          
          _buildTabletInfoRow('ID Usuario', '${_user?.id ?? 0}', Icons.person),
          const SizedBox(height: 16),
          _buildTabletInfoRow('Ciudad', _profile?.ciudad ?? 'Lima', Icons.location_on),
          const SizedBox(height: 16),
          _buildTabletInfoRow('Estado', _user?.isActive == true ? 'Activo' : 'Inactivo', Icons.check_circle),
          const SizedBox(height: 16),
          _buildTabletInfoRow('Teléfono', _profile?.telefono ?? 'No registrado', Icons.phone),
          const SizedBox(height: 16),
          _buildTabletInfoRow('Membresía', _user?.isPremium == true ? 'Premium' : 'Básica', Icons.star),
        ],
      ),
    );
  }
  
  Widget _buildTabletInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                label,
                baseFontSize: 12,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 4),
              ResponsiveText(
                value,
                baseFontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabletMenuOptions(BuildContext context) {
    final menuOptions = _getMenuOptions();
    
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Configuración de Cuenta',
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          
          ...menuOptions.map((option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTabletMenuOptionCard(option),
          )),
        ],
      ),
    );
  }
  
  Widget _buildTabletMenuOptionCard(_MenuOption option) {
    return InkWell(
      onTap: option.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: option.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    option.title,
                    baseFontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  ResponsiveText(
                    option.subtitle,
                    baseFontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabletAdminSection(BuildContext context) {
    return FutureBuilder<bool>(
      future: _esUsuarioAdmin(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return ResponsiveCard(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      ResponsiveText(
                        'Panel de Administrador',
                        baseFontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ResponsiveText(
                        'Gestiona usuarios, notificaciones y configuraciones del sistema',
                        baseFontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _navegarAPanelAdmin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.orange.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ResponsiveText(
                            'Acceder al Panel',
                            baseFontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildTabletLogoutButton(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        children: [
          ResponsiveText(
            'Sesión y Cuenta',
            baseFontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          
          // Botón de eliminar cuenta
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showDeleteAccountDialog(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_forever, size: 20),
                  const SizedBox(width: 8),
                  ResponsiveText(
                    'Eliminar Cuenta',
                    baseFontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Botón de cerrar sesión
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, size: 20),
                  const SizedBox(width: 8),
                  ResponsiveText(
                    'Cerrar Sesión',
                    baseFontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<_MenuOption> _getMenuOptions() {
    return [
      _MenuOption(
        icon: Icons.lock,
        title: 'Cambiar Contraseña',
        subtitle: 'Actualiza tu contraseña de acceso',
        color: Colors.blue,
        onTap: () => _showChangePasswordDialog(),
      ),
      _MenuOption(
        icon: Icons.support_agent,
        title: 'Contactar Soporte',
        subtitle: 'Envía un mensaje por WhatsApp',
        color: Colors.green,
        onTap: () => _contactWhatsApp(),
      ),
      _MenuOption(
        icon: Icons.info_outline,
        title: 'Información de la App',
        subtitle: 'Versión y detalles técnicos',
        color: Colors.purple,
        onTap: () => _showAppInfo(),
      ),
      _MenuOption(
        icon: Icons.feedback,
        title: 'Enviar Feedback',
        subtitle: 'Ayúdanos a mejorar la app',
        color: Colors.orange,
        onTap: () => _showFeedbackDialog(),
      ),
    ];
  }
  
  // Método para mostrar información de la app
  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de la App'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 Casta de Gallos'),
            Text('Versión: 1.0.0'),
            SizedBox(height: 16),
            Text('Gestión profesional de gallos de pelea con funcionalidades completas.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  
  // Método para mostrar diálogo de feedback
  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ayúdanos a mejorar la app con tu feedback:'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Escribe tu comentario, sugerencia o reporte de error...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (feedbackController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Gracias por tu feedback. Lo revisaremos pronto.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

class _MenuOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  _MenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

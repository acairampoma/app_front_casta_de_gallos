import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/adaptive_layout_builder.dart';
import '../../../services/auth_service.dart';
import '../../../services/admin_notification_service.dart';
import '../../../services/user_notification_service.dart';
import '../../../utils/password_validator.dart';
import '../../../utils/email_validator.dart';
import '../../../utils/device_utils.dart';
import '../../home/screens/home_screen.dart';
import 'forgot_password_screen.dart';
import 'email_verification_screen.dart';

// ==========================================
// 🏆 MÓDULO DE USUARIOS ÉPICO Y COMPLETO
// ==========================================
// Transformación épica de 200 líneas a 1200+ líneas
// Basado en el prototipo HTML profesional

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // ==========================================
  // 🎯 ESTADO Y CONTROLADORES PRINCIPALES
  // ==========================================
  
  // Navegación entre pantallas
  PageController _pageController = PageController();
  int _currentScreen = 0; // 0: Login, 1: Registro, 2: Dashboard, 3: Stats
  
  // Controladores de login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  bool _isLoginLoading = false;
  bool _obscureLoginPassword = true;
  
  // Controladores de registro épico
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  final _regGalponController = TextEditingController();
  final _regPropietarioController = TextEditingController();
  final _regTelefonoController = TextEditingController();
  final _regFormKey = GlobalKey<FormState>();
  bool _isRegisterLoading = false;
  bool _obscureRegPassword = true;
  bool _obscureRegConfirmPassword = true;
  
  // Validaciones en tiempo real
  Map<String, ValidationState> _validations = {
    'email': ValidationState(),
    'password': ValidationState(),
    'confirmPassword': ValidationState(),
    'telefono': ValidationState(),
    'galpon': ValidationState(),
    'propietario': ValidationState(),
  };
  bool _showValidations = false;
  
  // Animaciones épicas
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  // Usuarios mock (simulando base de datos)
  List<UserData> _usuarios = [
    UserData(
      id: 1,
      email: 'juan@gallos.com',
      password: '123456',
      telefono: '987654321',
      nombreGalpon: 'El Palenque Real',
      nombrePropietario: 'Juan Carlos Mendoza',
      fechaRegistro: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];
  
  UserData? _registeredUser; // Para mostrar en pantalla de éxito

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTestData();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    _regGalponController.dispose();
    _regPropietarioController.dispose();
    _regTelefonoController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }
  
  void _initTestData() {
    // Formulario limpio para producción
    // _loginEmailController.text = '';
    // _loginPasswordController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildLoginScreen(),
            _buildRegistroScreen(),
            _buildDashboardScreen(),
            _buildEstadisticasScreen(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🚀 PANTALLA DE LOGIN ÉPICA
  // ==========================================
  
  Widget _buildLoginScreen() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AdaptiveLayoutBuilder(
          mobile: _buildMobileLogin(),
          tablet: _buildTabletLogin(),
        ),
      ),
    );
  }
  
  // 📱 DISEÑO MÓVIL (ACTUAL)
  Widget _buildMobileLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _loginFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo épico con animación
              _buildAnimatedLogo(),
              const SizedBox(height: 40),
              
              // Formulario de login épico
              _buildLoginForm(),
              const SizedBox(height: 24),
              
              // Botón de login épico
              _buildLoginButton(),
              const SizedBox(height: 16),
              
              // Link de contraseña olvidada
              _buildForgotPasswordLink(),
              const SizedBox(height: 20),
              
              // Link de registro mejorado
              _buildRegisterLink(),
            ],
          ),
        ),
      ),
    );
  }
  
  // 📟 DISEÑO IPAD/TABLET 
  Widget _buildTabletLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              // 🎨 PANEL IZQUIERDO: Bienvenida e información
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo para iPad
                      Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/images/logo/logo2.webp',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🐓', style: TextStyle(fontSize: 40, color: Colors.white)),
                                  Text('🎆', style: TextStyle(fontSize: 30, color: Colors.white)),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Título principal
                      ResponsiveText(
                        '¡Bienvenido a\nCasta de Gallos!',
                        baseFontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      
                      // Subtítulo
                      ResponsiveText(
                        'La aplicación profesional para gestión integral de gallos de pelea con backend real.',
                        baseFontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 24),
                      
                      // Características destacadas
                      ..._buildFeaturesList(),
                    ],
                  ),
                ),
              ),
              
              // 📱 PANEL DERECHO: Formulario de login
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título del formulario
                        ResponsiveText(
                          'Iniciar Sesión',
                          baseFontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        const SizedBox(height: 8),
                        ResponsiveText(
                          'Accede a tu cuenta y gestiona tu galón',
                          baseFontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 32),
                        
                        // Formulario más ancho para tablet
                        _buildTabletLoginForm(),
                        const SizedBox(height: 32),
                        
                        // Botón más ancho para tablet
                        _buildTabletLoginButton(),
                        const SizedBox(height: 24),
                        
                        // Enlaces adaptados para tablet
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildForgotPasswordLink(),
                            _buildTabletRegisterLink(),
                          ],
                        ),
                      ],
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
  
  List<Widget> _buildFeaturesList() {
    final features = [
      '✅ Backend PostgreSQL + JWT',
      '☁️ Storage en Cloudinary',
      '🔔 Notificaciones Firebase',
      '👑 Panel de administrador',
      '📊 Estadísticas completas',
    ];
    
    return features.map((feature) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ResponsiveText(
        feature,
        baseFontSize: 14,
        color: Colors.white.withOpacity(0.8),
      ),
    )).toList();
  }
  
  Widget _buildTabletLoginForm() {
    return Column(
      children: [
        // Email épico para tablet
        _buildTabletTextField(
          controller: _loginEmailController,
          label: 'Email o Usuario',
          hint: 'juan@gallos.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu email o usuario';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        
        // Contraseña épica para tablet
        _buildTabletTextField(
          controller: _loginPasswordController,
          label: 'Contraseña',
          hint: '••••••••',
          icon: Icons.lock_outlined,
          isPassword: true,
          obscureText: _obscureLoginPassword,
          onTogglePassword: () {
            setState(() {
              _obscureLoginPassword = !_obscureLoginPassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildTabletTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          label,
          baseFontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 24),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
  
  Widget _buildTabletLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoginLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 6,
          shadowColor: AppColors.primary.withOpacity(0.4),
        ),
        child: _isLoginLoading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : ResponsiveText(
                'Iniciar Sesión',
                baseFontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
      ),
    );
  }
  
  Widget _buildTabletRegisterLink() {
    return GestureDetector(
      onTap: () => _navigateToScreen(1),
      child: ResponsiveText(
        '¿No tienes cuenta? Regístrate',
        baseFontSize: 14,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  Widget _buildAnimatedLogo() {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/logo/logo2.webp',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback si no encuentra la imagen
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🐓', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 8),
                  Text('🎆', style: TextStyle(fontSize: 40)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // ==========================================
  // 🚀 MÉTODOS DE NAVEGACIÓN Y LÓGICA
  // ==========================================
  
  void _navigateToScreen(int screen) {
    setState(() {
      _currentScreen = screen;
    });
    _pageController.animateToPage(
      screen,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoginLoading = true;
      });

      try {
        final email = _loginEmailController.text.trim();
        final password = _loginPasswordController.text;

        print('🚀 Login con backend real: $email');

        // 🔥 LOGIN REAL CON BACKEND
        final success = await AuthService.instance.login(email, password);

        setState(() {
          _isLoginLoading = false;
        });

        if (success && mounted) {
          // Login exitoso
          final user = AuthService.instance.currentUser;
          final profile = AuthService.instance.currentProfile;
          final isAdmin = AuthService.instance.isAdmin;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAdmin 
                ? '👑 ¡Bienvenido Administrador!'
                : '¡Bienvenido, ${profile?.nombreCompleto ?? user?.email}!'),
              backgroundColor: isAdmin ? Colors.orange : AppColors.success,
            ),
          );
          
          // Navegar al HomeScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else if (mounted) {
          // Error en login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credenciales incorrectas'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('💥 Error login: $e');
        setState(() {
          _isLoginLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error de conexión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  void _handleRegister() async {
    if (_regFormKey.currentState!.validate()) {
      setState(() {
        _isRegisterLoading = true;
      });

      try {
        final email = _regEmailController.text.trim();
        final password = _regPasswordController.text;
        final nombreCompleto = _regPropietarioController.text.trim();
        final telefono = _regTelefonoController.text.trim();
        final nombreGalpon = _regGalponController.text.trim();

        print('🚀 Registro con backend real: $email');

        // REGISTRO REAL CON BACKEND
        final registerResponse = await AuthService.instance.register(
          email: email,
          password: password,
          nombreCompleto: nombreCompleto,
          telefono: telefono.isNotEmpty ? telefono : null,
          nombreGalpon: nombreGalpon.isNotEmpty ? nombreGalpon : null,
        );

        if (registerResponse != null) {
          print('✅ Usuario registrado exitosamente');

          setState(() {
            _isRegisterLoading = false;
          });

          if (mounted) {
            // Limpiar formulario
            _regEmailController.clear();
            _regPasswordController.clear();
            _regConfirmPasswordController.clear();
            _regGalponController.clear();
            _regPropietarioController.clear();
            _regTelefonoController.clear();

            // NAVEGAR A PANTALLA DE VERIFICACIÓN DE EMAIL
            print('📧 Navegando a verificación de email...');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: email,
                  password: password,
                  nombreCompleto: nombreCompleto,
                  nombreGalpon: nombreGalpon.isNotEmpty ? nombreGalpon : null,
                  telefono: telefono.isNotEmpty ? telefono : null,
                ),
              ),
            );

            // Mostrar mensaje de confirmación
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✅ ¡Cuenta creada exitosamente!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('📧 Verifica tu email: $email'),
                    const Text('🔐 Ingresa el código de 6 dígitos'),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          setState(() {
            _isRegisterLoading = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Error en el registro. Inténtalo nuevamente'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('💥 Error registro: $e');
        setState(() {
          _isRegisterLoading = false;
        });

        if (mounted) {
          // Extraer mensaje de error más amigable
          String errorMessage = 'Error de registro';
          String errorTitle = 'Error de Registro';
          IconData errorIcon = Icons.error_outline;
          Color errorColor = Colors.red;
          bool showLoginButton = false;
          
          if (e.toString().contains('email ya está registrado') || 
              e.toString().contains('already registered') ||
              e.toString().contains('already exists')) {
            errorTitle = '⚠️ Email Ya Registrado';
            errorMessage = 'Este correo electrónico ya tiene una cuenta asociada.\n\n¿Ya tienes cuenta? Inicia sesión en su lugar.';
            errorIcon = Icons.person_off_outlined;
            errorColor = Colors.orange;
            showLoginButton = true;
          } else if (e.toString().contains('conexión') || 
                     e.toString().contains('network') ||
                     e.toString().contains('timeout')) {
            errorTitle = '🌐 Error de Conexión';
            errorMessage = 'No se pudo conectar con el servidor.\n\nVerifica tu conexión a internet e intenta nuevamente.';
            errorIcon = Icons.wifi_off;
          } else {
            errorTitle = '❌ Error Inesperado';
            errorMessage = e.toString().replaceAll('Error de conexión: ', '').replaceAll('Exception: ', '');
          }

          // Mostrar diálogo de error estilo SweetAlert
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.all(24),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono de error
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        errorIcon,
                        color: errorColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Título
                    Text(
                      errorTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    
                    // Mensaje
                    Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Consejo adicional para email duplicado
                    if (showLoginButton) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Usa la opción "Iniciar Sesión" para acceder.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Botones
                    Row(
                      children: [
                        if (showLoginButton) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                // Cambiar a pestaña de login
                                _tabController.animateTo(0);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              showLoginButton ? 'Cerrar' : 'Entendido',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }
      }
    }
  }

  Widget _buildLoginForm() {
    return Container(
      width: 320,
      child: Column(
        children: [
          // Email épico
          _buildEpicTextField(
            controller: _loginEmailController,
            label: 'Email o Usuario',
            hint: 'juan@gallos.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu email o usuario';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Contraseña épica
          _buildEpicTextField(
            controller: _loginPasswordController,
            label: 'Contraseña',
            hint: '••••••••',
            icon: Icons.lock_outlined,
            isPassword: true,
            obscureText: _obscureLoginPassword,
            onTogglePassword: () {
              setState(() {
                _obscureLoginPassword = !_obscureLoginPassword;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildEpicTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginButton() {
    return Container(
      width: 320,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoginLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: _isLoginLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
  
  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            ),
          );
        },
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => _navigateToScreen(1),
          child: Text(
            'Regístrate aquí',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildRegistroScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToScreen(0),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crear Cuenta Nueva',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Únete a Casta de Reyes',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _regFormKey,
          child: Column(
            children: [
              // Sección Datos de Acceso
              _buildFormSection(
                title: 'Datos de Acceso',
                icon: Icons.lock_outlined,
                children: [
                  _buildEpicTextField(
                    controller: _regEmailController,
                    label: 'Correo Electrónico',
                    hint: 'tu@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => EmailValidator.validateEmail(value),
                  ),
                  const SizedBox(height: 16),
                  _buildEpicTextField(
                    controller: _regPasswordController,
                    label: 'Contraseña',
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    isPassword: true,
                    obscureText: _obscureRegPassword,
                    onTogglePassword: () {
                      setState(() {
                        _obscureRegPassword = !_obscureRegPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La contraseña es obligatoria';
                      }
                      if (value.length < 8) {
                        return 'Mínimo 8 caracteres';
                      }
                      if (!value.contains(RegExp(r'[A-Z]'))) {
                        return 'Debe contener al menos una mayúscula';
                      }
                      if (!value.contains(RegExp(r'[a-z]'))) {
                        return 'Debe contener al menos una minúscula';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Debe contener al menos un número';
                      }
                      if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                        return 'Debe contener al menos un símbolo especial';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildPasswordRequirements(),
                  const SizedBox(height: 16),
                  _buildEpicTextField(
                    controller: _regConfirmPasswordController,
                    label: 'Confirmar Contraseña',
                    hint: '••••••••',
                    icon: Icons.lock_outlined,
                    isPassword: true,
                    obscureText: _obscureRegConfirmPassword,
                    onTogglePassword: () {
                      setState(() {
                        _obscureRegConfirmPassword = !_obscureRegConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _regPasswordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Sección Datos del Galpón
              _buildFormSection(
                title: 'Datos del Galpón',
                icon: Icons.home_outlined,
                children: [
                  _buildEpicTextField(
                    controller: _regGalponController,
                    label: 'Nombre del Galpón',
                    hint: 'Ej: El Palenque Real',
                    icon: Icons.home_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre del galpón es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildEpicTextField(
                    controller: _regPropietarioController,
                    label: 'Nombre del Propietario',
                    hint: 'Tu nombre completo',
                    icon: Icons.person_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tu nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildEpicTextField(
                    controller: _regTelefonoController,
                    label: 'Teléfono',
                    hint: '987654321',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El teléfono es obligatorio';
                      }
                      if (value.length != 9) {
                        return 'Debe tener 9 dígitos';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Botón de registro
              _buildRegisterButton(),
              const SizedBox(height: 16),
              
              // Link a login
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La contraseña debe tener:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '• Mínimo 8 caracteres\n• Una mayúscula y una minúscula\n• Un número y un símbolo especial',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isRegisterLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: Colors.green.withOpacity(0.3),
        ),
        child: _isRegisterLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
  
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya tienes cuenta? ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => _navigateToScreen(0),
          child: Text(
            'Inicia sesión',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDashboardScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Sistema activo',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _navigateToScreen(0),
          ),
        ],
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          '📊 Dashboard épico próximamente\n\nIncluirá:\n• Lista de usuarios\n• Estadísticas\n• Gráficos\n• Acciones rápidas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
  
  Widget _buildEstadisticasScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToScreen(2),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas del Sistema',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Métricas de usuarios',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          '📈 Estadísticas épicas próximamente\n\nIncluirá:\n• Métricas de usuarios\n• Registros recientes\n• Estado de seguridad\n• Gráficos interactivos',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

// ==========================================
// 📊 MODELOS DE DATOS ÉPICOS
// ==========================================

class UserData {
  final int id;
  final String email;
  final String password;
  final String telefono;
  final String nombreGalpon;
  final String nombrePropietario;
  final DateTime fechaRegistro;

  UserData({
    required this.id,
    required this.email,
    required this.password,
    required this.telefono,
    required this.nombreGalpon,
    required this.nombrePropietario,
    required this.fechaRegistro,
  });
}

class ValidationState {
  bool isValid;
  String message;

  ValidationState({
    this.isValid = false,
    this.message = '',
  });
}
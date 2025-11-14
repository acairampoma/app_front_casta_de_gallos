import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../home/screens/home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String nombreCompleto;
  final String? nombreGalpon;
  final String? telefono;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.nombreCompleto,
    this.nombreGalpon,
    this.telefono,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  // Controladores para los 6 dígitos
  late List<TextEditingController> _codeControllers;
  late List<FocusNode> _focusNodes;
  
  // Estado
  bool _isVerifying = false;
  bool _isResending = false;
  int _remainingSeconds = 120; // 2 minutos
  late AnimationController _timerController;
  String? _errorMessage;
  
  // Animaciones
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _startTimer();
    _initAnimations();
  }

  void _initializeControllers() {
    _codeControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  void _initAnimations() {
    _timerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<Offset>(
      begin: const Offset(-10, 0),
      end: const Offset(10, 0),
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));
  }

  void _startTimer() {
    _timerController = AnimationController(
      duration: const Duration(seconds: 120),
      vsync: this,
    );

    _timerController.addListener(() {
      setState(() {
        _remainingSeconds = (120 * (1 - _timerController.value)).toInt();
      });
    });

    _timerController.forward();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _getCode() {
    return _codeControllers.map((c) => c.text).join();
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Solo permitir números
      if (!RegExp(r'^\d$').hasMatch(value)) {
        _codeControllers[index].clear();
        return;
      }

      // Mover al siguiente campo
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Último dígito, ocultar teclado
        _focusNodes[index].unfocus();
      }
    }
  }

  void _onBackspace(int index, String value) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    final code = _getCode();

    if (code.length != 6) {
      _showError('Por favor ingresa los 6 dígitos');
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Verificando código: $code para ${widget.email}');

      final response = await AuthService.instance.verifyEmail(widget.email, code);

      if (!mounted) return;

      if (response['success'] == true) {
        print('✅ Email verificado exitosamente');

        // Auto-login después de verificación
        final loginSuccess = await AuthService.instance.login(
          widget.email,
          widget.password,
        );

        if (!mounted) return;

        if (loginSuccess) {
          // Navegar al home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎉 ¡Email verificado exitosamente!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Bienvenido, ${widget.nombreCompleto}'),
                ],
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          _showError('Error en auto-login. Por favor inicia sesión manualmente');
        }
      } else {
        _showError(response['message'] ?? 'Código inválido');
        _shakeController.forward().then((_) {
          _shakeController.reverse();
        });
      }
    } catch (e) {
      print('💥 Error verificando: $e');
      _showError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      print('📧 Reenviando código a ${widget.email}');

      final response = await AuthService.instance.resendVerificationCode(widget.email);

      if (!mounted) return;

      if (response['success'] == true) {
        print('✅ Código reenviado exitosamente');

        // Limpiar campos
        for (var controller in _codeControllers) {
          controller.clear();
        }

        // Reiniciar timer
        _timerController.reset();
        _startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Código reenviado a tu email'),
            backgroundColor: AppColors.success,
          ),
        );

        // Enfocar primer campo
        _focusNodes[0].requestFocus();
      } else {
        _showError(response['message'] ?? 'Error reenviando código');
      }
    } catch (e) {
      print('💥 Error reenviando: $e');
      _showError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Verificar Email'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icono de verificación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.mail_outline,
                size: 60,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Título
            Text(
              'Verifica tu Email',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtítulo
            Text(
              'Hemos enviado un código de 6 dígitos a:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Email
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Campos de código
            SlideTransition(
              position: _shakeAnimation,
              child: _buildCodeInputs(),
            ),

            const SizedBox(height: 24),

            // Mensaje de error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Botón verificar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Verificar Código',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Timer y botón reenviar
            Column(
              children: [
                if (_remainingSeconds > 0)
                  Text(
                    '⏱️ Reenviar código en ${_remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _isResending ? null : _handleResend,
                    child: Text(
                      _isResending ? '📧 Reenviando...' : '📧 ¿No recibiste el código? Reenviar',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isResending ? Colors.grey.shade400 : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Consejos:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Revisa tu carpeta de spam si no ves el email\n'
                    '• El código expira en 15 minutos\n'
                    '• Puedes reenviar el código después de 2 minutos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInputs() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          6,
          (index) => Container(
            width: 55,
            height: 70,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: TextFormField(
              controller: _codeControllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              autofocus: index == 0,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                if (value.isEmpty) {
                  _onBackspace(index, value);
                } else {
                  _onCodeChanged(index, value);
                }
              },
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

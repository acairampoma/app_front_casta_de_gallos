// 💳 Pantalla de Proceso de Pago - QR Yape Integration
// Compatible con: https://gallerappback-production.up.railway.app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../models/suscripcion_models.dart';
import '../../../models/pago_models.dart';
import '../../../services/pago_service.dart';
import '../../../services/mercadopago_service.dart';
import '../../../services/firebase_notification_service.dart';
import '../../../services/auth_service.dart';
import '../../planes/screens/planes_screen.dart';
import 'checkout_webview_screen.dart';

class ProcesoPagoScreen extends StatefulWidget {
  final PlanCatalogo plan;
  final UpgradeResponse upgradeResponse;

  const ProcesoPagoScreen({
    Key? key,
    required this.plan,
    required this.upgradeResponse,
  }) : super(key: key);

  @override
  State<ProcesoPagoScreen> createState() => _ProcesoPagoScreenState();
}

class _ProcesoPagoScreenState extends State<ProcesoPagoScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _qrAnimationController;
  late Animation<double> _qrScaleAnimation;
  late Animation<double> _qrRotationAnimation;

  QRYapeResponse? _qrResponse;
  XFile? _comprobanteImagen;
  StreamSubscription<PagoPendiente>? _pollingSubscription;

  bool _isLoadingQR = false;  // No cargar QR automáticamente
  bool _isConfirmandoPago = false;
  bool _isSubiendoComprobante = false;
  bool _comprobanteSubido = false;
  String? _comprobanteUrl;
  String? _error;
  PagoPendiente? _estadoPago;

  // 💳 NUEVOS: Campos para Mercado Pago
  final TextEditingController _numeroYapeController = TextEditingController();
  final TextEditingController _codigoConfirmacionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    // NO generar QR automáticamente - solo cuando se use Mercado Pago
  }

  void _setupControllers() {
    _tabController = TabController(length: 3, vsync: this);
    _qrAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  void _setupAnimations() {
    _qrScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _qrAnimationController,
      curve: Curves.elasticOut,
    ));

    _qrRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _qrAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _generarQR() async {
    try {
      setState(() {
        _isLoadingQR = true;
        _error = null;
      });

      final qrResponse = await PagoService.generarQRYape(widget.plan.codigo);
      
      setState(() {
        _qrResponse = qrResponse;
        _isLoadingQR = false;
      });

      // Iniciar animación del QR
      _qrAnimationController.forward();

      // Iniciar polling del estado de pago
      _iniciarPolling();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingQR = false;
      });
    }
  }

  void _iniciarPolling() {
    if (_qrResponse == null) return;

    _pollingSubscription = PagoService.monitearPago(_qrResponse!.pagoId)
        .listen((pago) {
      setState(() {
        _estadoPago = pago;
      });

      if (pago.estaAprobado) {
        _mostrarExito();
      } else if (pago.estaRechazado) {
        _mostrarRechazo();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _qrAnimationController.dispose();
    _referenciaController.dispose();
    _pollingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: _isLoadingQR 
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildMainContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Pagar ${widget.plan.nombre}'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        onPressed: () => _mostrarConfirmacionSalir(),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        if (_estadoPago != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: _getEstadoColor(),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getEstadoTexto(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 16),
          Text(
            'Generando QR de pago...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'Error al generar el pago',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generarQR,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildResumenPlan(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: TabBarView(
              key: ValueKey(_tabController.index),
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Deshabilitar swipe
              children: [
                _buildPasoQR(),
                _buildPasoComprobante(),
                _buildPasoConfirmacion(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenPlan() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getPlanIcon(),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Upgrade de suscripción',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/. ${widget.plan.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                '/mes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasoQR() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStepIndicator(0),
          const SizedBox(height: 24),
          
          // 💰 MONTO A PAGAR - LO MÁS IMPORTANTE
          Card(
            elevation: 8,
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.green.shade300, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '💰 Monto a Pagar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'S/. ${widget.plan.precio.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Plan ${widget.plan.nombre}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 💳 INSTRUCCIONES MERCADO PAGO
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.payment,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '💳 Pago Seguro con Mercado Pago',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Al hacer clic en el botón de abajo, serás redirigido a Mercado Pago para completar tu pago de forma segura.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Puedes pagar con Yape, tarjeta de débito o crédito',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCode() {
    if (_qrResponse?.qrUrl == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _qrAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _qrScaleAnimation.value,
          child: Transform.rotate(
            angle: _qrRotationAnimation.value,
            child: Container(
              width: 250,
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  _qrResponse!.qrUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.qr_code,
                      size: 100,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ TU IMAGEN YAPE - REEMPLAZA EL QR DE GUÍA
  Widget _buildYapeGuideImage() {
    return Container(
      width: 250,
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/yape/yape.jpg', // ✅ TU IMAGEN GRANDE Y CENTRADA
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Imagen Yape', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQRInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monto a pagar:'),
              Text(
                'S/. ${_qrResponse?.montoFormateado ?? widget.plan.precio.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Número de Yape:'),
              Text(
                _qrResponse?.numeroYape ?? '993-592-328',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (_qrResponse?.tiempoExpiracion != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expira en:'),
                Text(
                  _formatearTiempoExpiracion(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasoComprobante() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStepIndicator(1),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💳 Paso 2: Datos del Pago',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ingresa los datos de tu pago con Yape',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // 📱 Número de Yape
                  _buildNumeroYapeInput(),
                  const SizedBox(height: 20),
                  
                  // 🔢 Código de Confirmación
                  _buildCodigoConfirmacionInput(),
                  const SizedBox(height: 20),
                  
                  // 📝 Referencia (opcional)
                  _buildReferenciaInput(),
                  
                  const SizedBox(height: 16),
                  
                  // ℹ️ Info adicional
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El código de confirmación aparece después de realizar el pago en Yape',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteSelector() {
    return GestureDetector(
      onTap: _seleccionarComprobante,
      child: Container(
        width: double.infinity,
        height: 140, // 👆 Reducido de 200 a 140
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: _comprobanteImagen != null
            ? _buildComprobantePreview()
            : _buildComprobanteePlaceholder(),
      ),
    );
  }

  Widget _buildComprobantePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          // 📏 Imagen centrada y compacta
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.file(
              File(_comprobanteImagen!.path),
              fit: BoxFit.contain, // 👆 Cambiado de cover a contain
              alignment: Alignment.center,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _comprobanteImagen = null),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
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
      ),
    );
  }

  Widget _buildComprobanteePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 48, // 👆 Reducido de 64 a 48
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 8), // 👆 Reducido de 12 a 8
        Text(
          'Toca para seleccionar\ncomprobante de pago',
          style: TextStyle(
            fontSize: 14, // 👆 Reducido de 16 a 14
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4), // 👆 Reducido de 8 a 4
        Text(
          'JPG, PNG (máx. 10MB)',
          style: TextStyle(
            fontSize: 11, // 👆 Reducido de 12 a 11
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // 📱 Número de Yape del usuario
  Widget _buildNumeroYapeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Número de Yape',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _numeroYapeController,
          decoration: InputDecoration(
            hintText: 'Ej: 999 888 777',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.phone_android, color: Colors.purple),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
        ),
      ],
    );
  }

  // 🔢 Código de Confirmación de Yape
  Widget _buildCodigoConfirmacionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Código de Confirmación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codigoConfirmacionController,
          decoration: InputDecoration(
            hintText: 'Ej: ABC123XYZ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.verified, color: Colors.green),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
          ],
        ),
      ],
    );
  }

  // 📝 Referencia opcional
  Widget _buildReferenciaInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Número de operación (opcional):',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _referenciaController,
          decoration: InputDecoration(
            hintText: 'Ej: 123456789',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.receipt, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
        ),
      ],
    );
  }

  Widget _buildPasoConfirmacion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStepIndicator(2),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    '✅ Paso 3: Confirmación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirma que has realizado el pago',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildResumenConfirmacion(),
                  const SizedBox(height: 24),
                  // BOTÓN ELIMINADO - Usar solo el de navegación
                ],
              ),
            ),
          ),
          if (_estadoPago != null) ...[
            const SizedBox(height: 20),
            _buildEstadoPago(),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenConfirmacion() {
    final numeroCompleto = _numeroYapeController.text.isNotEmpty;
    final codigoCompleto = _codigoConfirmacionController.text.isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          _buildResumenRow('Plan:', widget.plan.nombre),
          _buildResumenRow('Monto:', 'S/. ${widget.plan.precio.toStringAsFixed(2)}'),
          _buildResumenRow(
            'Número Yape:',
            numeroCompleto 
              ? _numeroYapeController.text
              : '❌ REQUERIDO'
          ),
          _buildResumenRow(
            'Código:',
            codigoCompleto 
              ? _codigoConfirmacionController.text
              : '❌ REQUERIDO'
          ),
          if (_referenciaController.text.isNotEmpty)
            _buildResumenRow('Referencia:', _referenciaController.text),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // BOTÓN CONFIRMACIÓN ELIMINADO - Se usa solo el de navegación

  Widget _buildEstadoPago() {
    if (_estadoPago == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getEstadoIcon(),
                  color: _getEstadoColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado del Pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        _getEstadoDescripcion(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getEstadoTexto(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        final isCompleted = index < currentStep;
        
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive 
                    ? AppColors.primary 
                    : Colors.grey.shade300,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (index < 2) Container(
              width: 40,
              height: 2,
              color: index < currentStep 
                  ? AppColors.primary 
                  : Colors.grey.shade300,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_tabController.index > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _tabController.animateTo(_tabController.index - 1),
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _getNextButtonAction(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getNextButtonAction() != null ? AppColors.primary : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isConfirmandoPago 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Procesando...'),
                        ],
                      )
                    : Text(_getNextButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // MÉTODOS PRIVADOS
  // ========================================

  Future<void> _seleccionarComprobante() async {
    try {
      final imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,  // 👆 Reducido de 1024 a 800
        maxHeight: 800, // 👆 Reducido de 1024 a 800
        imageQuality: 75, // 👆 Reducido de 80 a 75 para menor peso
      );

      if (imagen != null) {
        setState(() {
          _comprobanteImagen = imagen;
          _comprobanteSubido = false; // Reset estado subida
          _comprobanteUrl = null;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  /// 📸 FLUJO ROBUSTO: Subir comprobante en paso 2
  Future<void> _subirComprobanteYContinuar() async {
    if (_qrResponse == null || _comprobanteImagen == null) return;

    try {
      setState(() => _isSubiendoComprobante = true);

      print('📸 [ProcesoPago] === SUBIENDO COMPROBANTE EN PASO 2 ===');
      print('📸 [ProcesoPago] Pago ID: ${_qrResponse!.pagoId}');

      // Subir comprobante usando el endpoint existente
      final comprobanteUrl = await PagoService.subirComprobante(
        _qrResponse!.pagoId,
        _comprobanteImagen!
      );

      setState(() {
        _comprobanteSubido = true;
        _comprobanteUrl = comprobanteUrl;
      });

      print('✅ [ProcesoPago] Comprobante subido exitosamente: $comprobanteUrl');

      // Feedback de éxito
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Comprobante subido exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Pequeño delay para que el usuario vea el éxito
      await Future.delayed(const Duration(milliseconds: 500));

      // Continuar al paso 3
      _tabController.animateTo(2);

    } catch (e) {
      print('❌ [ProcesoPago] Error subiendo comprobante: $e');
      _mostrarError('Error subiendo comprobante: $e\n\nPor favor, verifica tu conexión e inténtalo de nuevo.');
    } finally {
      setState(() => _isSubiendoComprobante = false);
    }
  }

  /// Abrir checkout de Mercado Pago con Yape
  Future<void> _confirmarPago() async {
    try {
      setState(() => _isConfirmandoPago = true);

      print('💳 [ProcesoPago] === ABRIENDO CHECKOUT DE MERCADO PAGO ===');
      print('💳 [ProcesoPago] Plan: ${widget.plan.codigo}');
      print('💳 [ProcesoPago] Monto: S/. ${widget.plan.precio}');

      // Crear preferencia de pago con Yape
      final resultado = await MercadoPagoService.crearPreferenciaYape(
        planCodigo: widget.plan.codigo,
      );

      print('💳 [ProcesoPago] Preferencia creada: ${resultado['preference_id']}');

      final initPoint = resultado['init_point'];
      
      if (initPoint == null || initPoint.isEmpty) {
        throw Exception('No se pudo obtener el link de pago');
      }

      HapticFeedback.mediumImpact();

      if (!mounted) return;

      // MÓVIL: Abrir WebView embebido
      if (!kIsWeb) {
        print('📱 [ProcesoPago] Abriendo WebView embebido en móvil');
        
        final result = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (context) => CheckoutWebViewScreen(
              checkoutUrl: initPoint,
              planNombre: widget.plan.nombre,
            ),
          ),
        );

        if (result != null && mounted) {
          final success = result['success'] == true;
          final status = result['status'] as String?;

          if (success && status == 'approved') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ ¡Pago aprobado! Tu suscripción se activará en breve'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (status == 'pending') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Pago pendiente. Te notificaremos cuando se apruebe'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (status == 'rejected') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Pago rechazado. Intenta con otro método de pago'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Navegar a Mi Suscripción
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PlanesScreen(abrirMiSuscripcion: true),
              ),
            );
          }
        }
      } 
      // WEB: Abrir en nueva pestaña
      else {
        print('🌐 [ProcesoPago] Abriendo en navegador (Web)');
        
        final Uri url = Uri.parse(initPoint);
        
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🌐 Abriendo checkout de Mercado Pago...\n\nCompleta el pago y regresa a la app'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 5),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const PlanesScreen(abrirMiSuscripcion: true),
              ),
            );
          }
        } else {
          throw Exception('No se pudo abrir el link de pago');
        }
      }

    } catch (e) {
      _mostrarError('Error abriendo checkout: $e');
    } finally {
      if (mounted) {
        setState(() => _isConfirmandoPago = false);
      }
    }
  }

  void _mostrarConfirmacionSalir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar proceso?'),
        content: const Text(
          'Si sales ahora, perderás el progreso actual. '
          '¿Estás seguro que deseas cancelar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar dialog
              Navigator.of(context).pop(); // Cerrar pantalla
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('¡Pago Aprobado!'),
          ],
        ),
        content: const Text(
          'Tu pago ha sido verificado y aprobado. '
          'Tu suscripción se ha actualizado correctamente.'
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar dialog
              Navigator.of(context).pop(); // Volver a planes
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _mostrarRechazo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Pago Rechazado'),
          ],
        ),
        content: Text(
          'Tu pago ha sido rechazado. '
          'Motivo: ${_estadoPago?.observaciones ?? 'No especificado'}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generarQR(); // Reintentar
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  VoidCallback? _getNextButtonAction() {
    // Si está confirmando pago, deshabilitar botón
    if (_isConfirmandoPago) {
      return null;
    }
    
    switch (_tabController.index) {
      case 0:
        // Paso 1: Abrir checkout de Mercado Pago directamente
        return _confirmarPago;
        
      case 1:
        // Paso 2: Validar comprobante subido
        return _comprobanteSubido
          ? () async {
              HapticFeedback.lightImpact();
              _tabController.animateTo(2);
            }
          : _comprobanteImagen != null
              ? _subirComprobanteYContinuar
              : null;
          
      case 2:
        // Paso 3: Confirmar pago manual (si es necesario)
        return _comprobanteSubido
          ? () async {
              // Navegar a Mi Suscripción
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const PlanesScreen(abrirMiSuscripcion: true),
                ),
              );
            }
          : null;
          
      default:
        return null;
    }
  }

  String _getNextButtonText() {
    if (_isConfirmandoPago) {
      return 'Abriendo checkout...';
    }
    
    if (_isSubiendoComprobante) {
      return 'Subiendo comprobante...';
    }
    
    switch (_tabController.index) {
      case 0:
        return '💳 Pagar con Yape';
      case 1:
        if (_comprobanteSubido) {
          return 'Continuar';
        }
        return _comprobanteImagen != null
            ? 'Subir Comprobante'
            : 'Selecciona comprobante';
      case 2:
        return 'Ver Mi Suscripción';
      default:
        return 'Siguiente';
    }
  }

  String _getPlanIcon() {
    switch (widget.plan.codigo.toLowerCase()) {
      case 'basico': return '⭐';
      case 'premium': return '💎';
      case 'profesional': return '👑';
      default: return '📋';
    }
  }

  String _formatearTiempoExpiracion() {
    if (_qrResponse?.tiempoExpiracion == null) return 'N/A';
    
    final diferencia = _qrResponse!.tiempoExpiracion!.difference(DateTime.now());
    final minutes = diferencia.inMinutes;
    
    if (minutes <= 0) return 'Expirado';
    if (minutes < 60) return '${minutes}m';
    
    final hours = diferencia.inHours;
    return '${hours}h ${minutes % 60}m';
  }

  Color _getEstadoColor() {
    if (_estadoPago == null) return Colors.grey;
    
    switch (_estadoPago!.estado.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'verificando': return Colors.blue;
      case 'aprobado': return Colors.green;
      case 'rechazado': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getEstadoTexto() {
    if (_estadoPago == null) return 'Pendiente';
    return _estadoPago!.estado;
  }

  IconData _getEstadoIcon() {
    if (_estadoPago == null) return Icons.schedule;
    
    switch (_estadoPago!.estado.toLowerCase()) {
      case 'pendiente': return Icons.schedule;
      case 'verificando': return Icons.hourglass_empty;
      case 'aprobado': return Icons.check_circle;
      case 'rechazado': return Icons.error;
      default: return Icons.help;
    }
  }

  String _getEstadoDescripcion() {
    if (_estadoPago == null) return 'Esperando confirmación';
    
    switch (_estadoPago!.estado.toLowerCase()) {
      case 'pendiente':
        return 'Tu pago está siendo procesado';
      case 'verificando':
        return 'Verificando comprobante con administrador';
      case 'aprobado':
        return '¡Tu suscripción se ha actualizado!';
      case 'rechazado':
        return 'El pago no pudo ser verificado';
      default:
        return 'Estado desconocido';
    }
  }
}
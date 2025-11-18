// 💳 Pantalla de WebView para Checkout de Mercado Pago
// Muestra el checkout embebido dentro de la app

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../shared/theme/app_colors.dart';

class CheckoutWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String planNombre;

  const CheckoutWebViewScreen({
    Key? key,
    required this.checkoutUrl,
    required this.planNombre,
  }) : super(key: key);

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
            print('🌐 [Checkout] Navegando a: $url');
            _checkForRedirect(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            print('✅ [Checkout] Página cargada: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ [Checkout] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _checkForRedirect(String url) {
    // Detectar redirecciones de Mercado Pago
    if (url.contains('/pago-exitoso')) {
      print('✅ [Checkout] Pago exitoso detectado');
      _handlePaymentSuccess();
    } else if (url.contains('/pago-fallido')) {
      print('❌ [Checkout] Pago fallido detectado');
      _handlePaymentFailure();
    } else if (url.contains('/pago-pendiente')) {
      print('⏳ [Checkout] Pago pendiente detectado');
      _handlePaymentPending();
    }
  }

  void _handlePaymentSuccess() {
    Navigator.of(context).pop({'success': true, 'status': 'approved'});
  }

  void _handlePaymentFailure() {
    Navigator.of(context).pop({'success': false, 'status': 'rejected'});
  }

  void _handlePaymentPending() {
    Navigator.of(context).pop({'success': false, 'status': 'pending'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Pagar ${widget.planNombre}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando checkout...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar pago?'),
        content: const Text(
          '¿Estás seguro que deseas cancelar el proceso de pago?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar pagando'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar dialog
              Navigator.of(context).pop({'success': false, 'status': 'cancelled'}); // Cerrar WebView
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// 📺 lib/features/transmisiones/screens/transmision_en_vivo_screen.dart
// 🔴 Pantalla para ver transmisiones en vivo con WebView

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../shared/theme/app_colors.dart';

class TransmisionEnVivoScreen extends StatefulWidget {
  final Map<String, dynamic> evento;

  const TransmisionEnVivoScreen({
    Key? key,
    required this.evento,
  }) : super(key: key);

  @override
  State<TransmisionEnVivoScreen> createState() => _TransmisionEnVivoScreenState();
}

class _TransmisionEnVivoScreenState extends State<TransmisionEnVivoScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final String url = widget.evento['url_transmision'] ?? '';

    if (url.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'URL de transmisión no disponible';
        _isLoading = false;
      });
      return;
    }

    print('📺 [TRANSMISION-VIVO] Iniciando WebView para: $url');

    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              print('📺 [TRANSMISION-VIVO] Progreso de carga: $progress%');
            },
            onPageStarted: (String url) {
              print('📺 [TRANSMISION-VIVO] Página iniciada: $url');
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
            onPageFinished: (String url) {
              print('📺 [TRANSMISION-VIVO] Página cargada: $url');
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {
              print('📺 [TRANSMISION-VIVO] Error de WebView: ${error.description}');
              setState(() {
                _hasError = true;
                _errorMessage = 'Error cargando transmisión: ${error.description}';
                _isLoading = false;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              print('📺 [TRANSMISION-VIVO] Navegación a: ${request.url}');
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(url));
    } catch (e) {
      print('📺 [TRANSMISION-VIVO] Error inicializando WebView: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Error inicializando reproductor: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen ? null : _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingButtons(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.evento['titulo'] ?? 'Transmisión en Vivo',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🔴 EN VIVO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.evento['coliseo'] != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.evento['coliseo']['nombre'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _toggleFullscreen,
          icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          tooltip: _isFullscreen ? 'Salir de pantalla completa' : 'Pantalla completa',
        ),
        IconButton(
          onPressed: _reloadTransmission,
          icon: const Icon(Icons.refresh),
          tooltip: 'Recargar transmisión',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        // WebView
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _hasError
            ? _buildErrorView()
            : WebViewWidget(controller: _webViewController),
        ),

        // Indicador de carga
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando transmisión...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Overlay de información (solo visible al iniciar)
        if (!_hasError && !_isLoading)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Error de Transmisión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'No se pudo cargar la transmisión',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _reloadTransmission,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    if (_hasError || _isFullscreen) return Container();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón de información
        FloatingActionButton(
          onPressed: _showEventInfo,
          backgroundColor: Colors.black54,
          foregroundColor: Colors.white,
          mini: true,
          heroTag: 'info',
          child: const Icon(Icons.info_outline),
        ),
        const SizedBox(height: 8),

        // Botón de pantalla completa
        FloatingActionButton(
          onPressed: _toggleFullscreen,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          mini: true,
          heroTag: 'fullscreen',
          child: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
        ),
      ],
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      // Ocultar barras del sistema
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      // Orientación landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Mostrar barras del sistema
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Volver a orientación normal
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _reloadTransmission() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    _webViewController.reload();
  }

  void _showEventInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Título del evento
            Text(
              widget.evento['titulo'] ?? 'Transmisión en Vivo',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Información del evento
            if (widget.evento['descripcion'] != null) ...[
              _buildInfoRow(Icons.description, 'Descripción', widget.evento['descripcion']),
              const SizedBox(height: 12),
            ],

            if (widget.evento['coliseo'] != null) ...[
              _buildInfoRow(
                Icons.home_work,
                'Coliseo',
                '${widget.evento['coliseo']['nombre']} - ${widget.evento['coliseo']['ciudad']}',
              ),
              const SizedBox(height: 12),
            ],

            _buildInfoRow(Icons.live_tv, 'Estado', '🔴 EN VIVO'),

            if (widget.evento['precio_entrada'] != null && widget.evento['precio_entrada'] > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow(Icons.monetization_on, 'Precio', 'S/ ${widget.evento['precio_entrada']}'),
            ],

            const SizedBox(height: 20),

            // Botón cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cerrar'),
              ),
            ),

            // Padding adicional para el safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Restaurar orientación normal al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Restaurar barras del sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }
}
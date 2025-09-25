import 'package:flutter/material.dart';
import '../../../shared/widgets/base_screen.dart';
import '../../../shared/widgets/adaptive_layout_builder.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/suscripcion_service.dart';
import '../../../models/suscripcion_models.dart';
import '../../../features/planes/screens/planes_screen.dart';
import '../../../config/adaptive_ui_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _notificationsInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeNotifications();
  }

  Future<void> _loadUserData() async {
    try {
      // Cargar datos del usuario desde el backend
      await AuthService.instance.loadCurrentUser();
      if (mounted) {
        setState(() {}); // Actualizar UI
      }
    } catch (e) {
      print('💥 Error cargando datos usuario: $e');
    }
  }

  /// 📺 Verificar acceso a transmisiones antes de navegar
  Future<void> _verificarAccesoTransmisiones(BuildContext context) async {
    try {
      print('📺 [HomeScreen] Verificando acceso a transmisiones...');

      // Obtener suscripción activa del usuario
      Suscripcion? suscripcionActiva;
      try {
        suscripcionActiva = await SuscripcionService.obtenerSuscripcionActual();
      } catch (e) {
        print('🚫 [HomeScreen] Error obteniendo suscripción: $e');
        // Si hay error, asumir que no hay suscripción
        suscripcionActiva = null;
      }

      if (suscripcionActiva == null) {
        print('🚫 [HomeScreen] Sin suscripción activa');
        _mostrarDialogoSinSuscripcion(context);
        return;
      }

      // Verificar si la suscripción incluye streaming
      final planCodigo = suscripcionActiva.planType.toLowerCase();
      if (planCodigo == 'gratuito') {
        print('🚫 [HomeScreen] Plan gratuito no incluye streaming');
        _mostrarDialogoPlanGratuito(context);
        return;
      }

      // Verificar si el acceso aún está vigente
      final fechaActivacion = suscripcionActiva.fechaInicio;
      if (fechaActivacion == null) {
        print('🚫 [HomeScreen] Suscripción no activada');
        _mostrarDialogoSuscripcionNoActivada(context);
        return;
      }

      // Calcular fecha de expiración del streaming
      final fechaExpiracionStreaming = _calcularFechaExpiracionStreaming(fechaActivacion, planCodigo);
      final ahora = DateTime.now();

      if (ahora.isAfter(fechaExpiracionStreaming)) {
        print('🚫 [HomeScreen] Acceso a streaming expirado');
        print('📅 [HomeScreen] Expiró: ${fechaExpiracionStreaming.toIso8601String()}');
        _mostrarDialogoStreamingExpirado(context, fechaExpiracionStreaming);
        return;
      }

      // ✅ Todo bien, permitir acceso
      print('✅ [HomeScreen] Acceso a streaming autorizado');
      print('📅 [HomeScreen] Válido hasta: ${fechaExpiracionStreaming.toIso8601String()}');
      Navigator.pushNamed(context, '/transmisiones');

    } catch (e) {
      print('❌ [HomeScreen] Error verificando acceso: $e');
      _mostrarDialogoError(context, e.toString());
    }
  }

  /// 📅 Calcular fecha de expiración del streaming según el plan
  DateTime _calcularFechaExpiracionStreaming(DateTime fechaActivacion, String planCodigo) {
    switch (planCodigo) {
      case 'basico':
        return fechaActivacion.add(const Duration(days: 7)); // 1 semana
      case 'premium':
        return fechaActivacion.add(const Duration(days: 14)); // 2 semanas
      case 'profesional':
        return fechaActivacion.add(const Duration(days: 30)); // 1 mes
      default:
        return fechaActivacion; // Plan gratuito, ya expirado
    }
  }

  /// 🚫 Diálogo: Sin suscripción activa
  void _mostrarDialogoSinSuscripcion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tv_off, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Sin Acceso a Streaming'),
          ],
        ),
        content: const Text(
          'No tienes una suscripción activa para acceder a las transmisiones en vivo.\n\n'
          '¿Te gustaría suscribirte ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlanesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ver Planes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 🆓 Diálogo: Plan gratuito
  void _mostrarDialogoPlanGratuito(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.upgrade, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Actualiza tu Plan'),
          ],
        ),
        content: const Text(
          'Tu plan gratuito no incluye acceso a transmisiones en vivo.\n\n'
          'Actualiza a un plan premium para disfrutar de:\n'
          '• Básico: 1 semana de streaming\n'
          '• Premium: 2 semanas de streaming\n'
          '• Profesional: 1 mes de streaming',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlanesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Actualizar Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ⏱️ Diálogo: Suscripción no activada
  void _mostrarDialogoSuscripcionNoActivada(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending_actions, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Suscripción Pendiente'),
          ],
        ),
        content: const Text(
          'Tu suscripción está pendiente de activación por nuestro equipo.\n\n'
          'Una vez aprobada, tendrás acceso completo a las transmisiones en vivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlanesScreen(abrirMiSuscripcion: true),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Ver Estado', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 📅 Diálogo: Streaming expirado
  void _mostrarDialogoStreamingExpirado(BuildContext context, DateTime fechaExpiracion) {
    final diasExpirado = DateTime.now().difference(fechaExpiracion).inDays;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time_filled, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Acceso Expirado'),
          ],
        ),
        content: Text(
          'Tu acceso a streaming expiró hace $diasExpirado día${diasExpirado != 1 ? 's' : ''}.\n\n'
          'Renueva tu suscripción para seguir disfrutando de las transmisiones en vivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlanesScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Renovar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ❌ Diálogo: Error general
  void _mostrarDialogoError(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(
          'Error verificando el acceso a transmisiones:\n\n$error',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    
    print('🚀 [HomeScreen] Inicializando notificaciones...');
    
    // Esperar un poco a que el HomeScreen se cargue completamente
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) {
      print('⚠️ [HomeScreen] Widget no montado - cancelando notificaciones');
      return;
    }
    
    try {
      final isAdmin = AuthService.instance.isAdmin;
      print('🚀 [HomeScreen] Usuario admin: $isAdmin');
      
      // 🔔 FIREBASE NOTIFICACIONES YA INICIALIZADAS EN LOGIN
      print('🔥 [HomeScreen] Usando Firebase para notificaciones - polling deshabilitado');
      
      // Ya no necesitamos polling - Firebase maneja todo automáticamente
      
      _notificationsInitialized = true;
      print('✅ [HomeScreen] Notificaciones inicializadas exitosamente');
      
    } catch (e) {
      print('❌ [HomeScreen] Error inicializando notificaciones: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Casta de Gallos',
      subtitle: 'Gestión Profesional de Gallos de Pelea',
      currentIndex: 0,
      showQuickNav: true,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return AdaptiveLayoutBuilder(
      mobile: _buildMobileContent(context),
      tablet: _buildTabletContent(context),
    );
  }
  
  Widget _buildMobileContent(BuildContext context) {
    return FutureBuilder<AdaptiveUIConfig>(
      future: AdaptiveUIManager.getOptimalConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? AdaptiveUIConfig.standard();
        
        return SingleChildScrollView(
          padding: config.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: config.gridSpacing * 0.5),
              _buildWelcomeCard(),
              SizedBox(height: config.gridSpacing * 1.5),
              _buildMenuGrid(context),
              SizedBox(height: config.gridSpacing * 1.5),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTabletContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // 🎨 Layout horizontal para tablet
          ResponsiveRowColumn(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panel izquierdo: Bienvenida y perfil
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildTabletWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildTabletStatsCard(),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              
              // Panel derecho: Menú principal
              Expanded(
                flex: 2,
                child: _buildTabletMenuGrid(context),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserName() {
    final user = AuthService.instance.currentUser;
    final profile = AuthService.instance.currentProfile;
    
    return Text(
      profile?.nombreCompleto ?? user?.email ?? 'Usuario',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildWelcomeCard() {
    final user = AuthService.instance.currentUser;
    final profile = AuthService.instance.currentProfile;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
        children: [
          // 📷 AVATAR CON FOTO DE PERFIL (igual que ProfileScreen)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: profile?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(
                      profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 35,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 35,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                _buildUserName(),
                // 🏠 MOSTRAR GALPÓN SI EXISTE
                if (profile?.nombreGalpon != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Galpon ${profile!.nombreGalpon!}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // 👑 BADGE DE ESTADO (Premium/Verificado)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: user?.isPremium == true ? Colors.amber : Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              user?.isPremium == true ? Icons.star : Icons.verified,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabletWelcomeCard() {
    final user = AuthService.instance.currentUser;
    final profile = AuthService.instance.currentProfile;
    
    return ResponsiveCard(
      child: Column(
        children: [
          // Avatar más grande para tablet
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            child: profile?.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      profile!.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: 20),
          
          // Información del usuario
          ResponsiveText(
            'Bienvenido',
            baseFontSize: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          
          ResponsiveText(
            profile?.nombreCompleto ?? user?.email ?? 'Usuario',
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          
          if (profile?.nombreGalpon != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  ResponsiveText(
                    profile!.nombreGalpon!,
                    baseFontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Badge de estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: user?.isPremium == true ? Colors.amber : Colors.green,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: (user?.isPremium == true ? Colors.amber : Colors.green).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user?.isPremium == true ? Icons.star : Icons.verified,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                ResponsiveText(
                  user?.isPremium == true ? 'Premium' : 'Verificado',
                  baseFontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabletStatsCard() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Estadísticas Rápidas',
            baseFontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          
          _buildStatItem(
            icon: Icons.pets,
            label: 'Gallos',
            value: '12',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            icon: Icons.medical_services,
            label: 'Vacunas',
            value: '8',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            icon: Icons.sports_martial_arts,
            label: 'Peleas',
            value: '5',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'Victorias',
            value: '3',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                label,
                baseFontSize: 12,
                color: Colors.grey.shade600,
              ),
              ResponsiveText(
                value,
                baseFontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabletMenuGrid(BuildContext context) {
    final menuItems = _getMenuItems(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Módulos del Sistema',
          baseFontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(height: 24),
        
        ResponsiveGrid(
          children: menuItems.map((item) => _buildTabletMenuItemCard(item)).toList(),
          spacing: 24.0,
          runSpacing: 24.0,
          forceColumns: 3,
        ),
      ],
    );
  }
  
  Widget _buildTabletMenuItemCard(_MenuItem item) {
    return ResponsiveCard(
      elevation: 4.0,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Imagen o icono más grande para tablet
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: item.icon != null
                    ? Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          item.icon!,
                          size: 40,
                          color: item.color,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          item.imagePath!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: item.color,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              
              // Título más grande para tablet
              ResponsiveText(
                item.title,
                baseFontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  List<_MenuItem> _getMenuItems(BuildContext context) {
    return [
      // 🥇 PRIMERA POSICIÓN: Transmisiones
      _MenuItem(
        title: 'Transmisiones',
        icon: Icons.live_tv,
        color: Colors.red,
        onTap: () => _verificarAccesoTransmisiones(context),
      ),
      // 🥈 SEGUNDA POSICIÓN: Marketplace (nuevo módulo)
      _MenuItem(
        title: 'Marketplace',
        imagePath: 'assets/images/modulos/markeplace.webp',
        color: Colors.indigo,
        onTap: () {
          // Navegación segura: intenta ir a /marketplace y si no existe la ruta, muestra aviso
          try {
            Navigator.pushNamed(context, '/marketplace');
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Marketplace aún no está disponible'),
                backgroundColor: Colors.indigo,
              ),
            );
          }
        },
      ),
      // 🥉 RESTO DE MÓDULOS EN ORDEN ESTABLECIDO
      _MenuItem(
        title: 'Pedigrí',
        imagePath: 'assets/images/modulos/PEDIGRI.webp',
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/pedigri'),
      ),
      _MenuItem(
        title: 'Vacunas',
        imagePath: 'assets/images/modulos/VACUNAS.webp',
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/vacunas'),
      ),
      _MenuItem(
        title: 'Topes',
        imagePath: 'assets/images/modulos/TOPES.webp',
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/topes'),
      ),
      _MenuItem(
        title: 'Peleas',
        imagePath: 'assets/images/modulos/PELEA.webp',
        color: Colors.red,
        onTap: () => Navigator.pushNamed(context, '/peleas'),
      ),
      _MenuItem(
        title: 'Reportes',
        imagePath: 'assets/images/modulos/REPORTES.webp',
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/reportes'),
      ),
      _MenuItem(
        title: 'Inversiones',
        imagePath: 'assets/images/modulos/INVERSION.webp',
        color: Colors.teal,
        onTap: () => Navigator.pushNamed(context, '/inversiones'),
      ),
      _MenuItem(
        title: 'Suscripciones',
        imagePath: 'assets/images/modulos/SUSCRIPCION.webp',
        color: Colors.amber,
        onTap: () async {
          try {
            print('[Home] Navegando a SuscripcionScreen...');
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlanesScreen(),
              ),
            );
            print('[Home] Regresó de PlanesScreen (API Railway)');
          } catch (e) {
            print('[Home] Error al navegar a SuscripcionScreen: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo abrir Suscripciones. Intenta nuevamente.'),
                ),
              );
            }
          }
        },
      ),
    ];
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menuItems = _getMenuItems(context);

    return FutureBuilder<AdaptiveUIConfig>(
      future: AdaptiveUIManager.getOptimalConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? AdaptiveUIConfig.standard();
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: config.gridSpacing,
            mainAxisSpacing: config.gridSpacing,
            childAspectRatio: 1.2,
          ),
          itemCount: menuItems.length,
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildMenuItemCard(_MenuItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 📐 RESPONSIVE: Calcular tamaños basados en espacio disponible
        final screenWidth = MediaQuery.of(context).size.width;
        final cardWidth = constraints.maxWidth;
        
        // 🎯 TAMAÑOS ADAPTATIVOS BASADOS EN ANCHO DE PANTALLA
        double imageSize;
        double titleFontSize;
        double spacing;
        
        if (screenWidth < 360) {
          // 📱 Pantallas muy pequeñas (iPhone SE, Android compactos)
          imageSize = cardWidth * 0.4;  // Reducido de 0.5
          titleFontSize = 11.0;  // Reducido de 12
          spacing = 6.0;  // Reducido de 8
        } else if (screenWidth < 400) {
          // 📱 Pantallas pequeñas estándar
          imageSize = cardWidth * 0.45;  // Reducido de 0.55
          titleFontSize = 12.0;  // Reducido de 13
          spacing = 8.0;  // Reducido de 10
        } else if (screenWidth < 600) {
          // 📱 Pantallas normales (mayoría Android/iPhone)
          imageSize = cardWidth * 0.48;  // Reducido de 0.6
          titleFontSize = 13.0;  // Reducido de 14
          spacing = 10.0;  // Reducido de 12
        } else {
          // 📱 Pantallas grandes (tablets)
          imageSize = cardWidth * 0.38;  // Reducido de 0.45
          titleFontSize = 14.0;  // Reducido de 15
          spacing = 12.0;  // Reducido de 14
        }
        
        return Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(spacing),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🖼️ IMAGEN O ICONO MÁS PEQUEÑO PARA DAR ESPACIO AL TÍTULO
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: item.icon != null
                        ? Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon!,
                              size: imageSize * 0.5,
                              color: item.color,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              item.imagePath!,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: imageSize,
                                  height: imageSize,
                                  decoration: BoxDecoration(
                                    color: item.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: imageSize * 0.4,
                                    color: item.color,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  SizedBox(height: spacing * 0.6),
                  
                  // 📝 TÍTULO CON PADDING HORIZONTAL PARA EVITAR DESBORDE
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final String title;
  final String? imagePath; // 🖼️ Path para imagen de asset
  final IconData? icon; // 🎯 Icono Material Design
  final Color color;
  final VoidCallback onTap;

  _MenuItem({
    required this.title,
    this.imagePath, // 🖼️ OPCIONAL para mantener compatibilidad
    this.icon, // 🎯 OPCIONAL para usar iconos
    required this.color,
    required this.onTap,
  });
}

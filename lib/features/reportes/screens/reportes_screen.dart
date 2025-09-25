// 📊🐓 PANTALLA ÉPICA DE REPORTES - LA MEJOR DEL MUNDO GALLÍSTICO
import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/error_widget.dart' as custom_error;
import '../../../shared/widgets/base_screen.dart';
import '../services/reportes_service.dart';
import '../models/dashboard_model.dart';
import '../widgets/filtros_simple_widget.dart';
import '../widgets/dashboard_tab.dart';
import '../widgets/rankings_tab.dart';
import '../widgets/documentos_tab.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> 
    with TickerProviderStateMixin {
  
  // 🎯 CONTROLADORES Y ESTADO
  late TabController _tabController;
  final ReportesService _reportesService = ReportesService();
  
  // 📊 DATOS DEL DASHBOARD
  DashboardModel? _dashboardData;
  bool _isLoading = true;
  String? _error;
  
  // 🗓️ FILTROS DINÁMICOS
  int? _anoSeleccionado;
  int? _mesSeleccionado;
  List<int> _anosDisponibles = [];
  
  // 🎨 ANIMACIONES
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    // Cargar datos iniciales
    _initializeData();
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  // 🚀 INICIALIZAR DATOS ÉPICOS
  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Generar años disponibles simples (2020-2025)
      _anosDisponibles = List.generate(6, (index) => 2020 + index).reversed.toList();
      
      // Si no hay filtros, usar período actual
      if (_anoSeleccionado == null && _mesSeleccionado == null) {
        // Usar valores por defecto
        _anoSeleccionado = 2025;
        _mesSeleccionado = 8;
        // final current = periodosResponse['periodo_actual'];
        // if (current != null) {
        //   _anoSeleccionado = current['ano'];
        //   _mesSeleccionado = current['mes'];
        // }
      }
      
      // Cargar dashboard con filtros
      await _loadDashboard();
      
    } catch (e) {
      setState(() {
        _error = 'Error cargando reportes: $e';
        _isLoading = false;
      });
      
      // Mostrar error en snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _initializeData,
            ),
          ),
        );
      }
    }
  }
  
  // 📊 CARGAR DASHBOARD CON FILTROS
  Future<void> _loadDashboard() async {
    try {
      print('🚀 === INICIANDO CARGA DE DASHBOARD ===');
      print('🚀 Filtros: año=$_anoSeleccionado, mes=$_mesSeleccionado');
      
      final data = await _reportesService.getDashboard(
        ano: _anoSeleccionado,
        mes: _mesSeleccionado,
      );
      
      print('🚀 === DATOS RECIBIDOS DEL SERVICIO ===');
      print('🚀 Data es null: ${data == null}');
      print('🚀 Data es Map: ${data is Map<String, dynamic>}');
      
      if (data != null) {
        print('🚀 Keys del JSON: ${data.keys.toList()}');
        print('🚀 JSON completo: $data');
      }
      
      // Validar que tenemos datos antes de parsear
      if (data != null && data is Map<String, dynamic>) {
        setState(() {
          try {
            print('🚀 === INICIANDO PARSEO DEL MODELO ===');
            _dashboardData = DashboardModel.fromJson(data);
            print('🚀 === MODELO PARSEADO EXITOSAMENTE ===');
            _error = null;
          } catch (parseError) {
            print('❌ Error parseando dashboard: $parseError');
            print('❌ Stack trace: ${StackTrace.current}');
            _error = 'Error procesando datos del dashboard: $parseError';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No se recibieron datos del servidor';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Error general cargando dashboard: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      setState(() {
        _error = 'Error conectando con el servidor: $e';
        _isLoading = false;
      });
    }
  }
  
  // 🔄 REFRESH DATOS
  Future<void> _refreshData() async {
    await _loadDashboard();
  }
  
  // 🗓️ CAMBIAR FILTROS
  void _onFiltrosChanged({int? ano, int? mes}) {
    if (ano != _anoSeleccionado || mes != _mesSeleccionado) {
      setState(() {
        _anoSeleccionado = ano;
        _mesSeleccionado = mes;
        _isLoading = true;
      });
      _loadDashboard();
    }
  }

  // 🎨 BUILD PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Reportes',
      subtitle: 'Dashboard gallístico avanzado',
      currentIndex: 2,
      showAppBar: false,
      child: Container(
        color: Colors.grey[50],
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 🎯 APP BAR ÉPICO
                SliverAppBar(
                  expandedHeight: 160,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Título épico - más compacto
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.analytics,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '🐓 Reportes Épicos',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Dashboard gallístico avanzado',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 🗓️ FILTROS WIDGET ÉPICOS
                              FiltrosSimpleWidget(
                                anoSeleccionado: _anoSeleccionado,
                                mesSeleccionado: _mesSeleccionado,
                                anosDisponibles: _anosDisponibles,
                                onFiltrosChanged: _onFiltrosChanged,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // 🎯 TABS ÉPICOS
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.dashboard),
                          text: 'Dashboard',
                        ),
                        Tab(
                          icon: Icon(Icons.leaderboard),
                          text: 'Rankings',
                        ),
                        Tab(
                          icon: Icon(Icons.description),
                          text: 'Documentos',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            
            // 📱 BODY CON TABS
            body: _buildBody(),
          ),
        ),
      ),
    );
  }
  
  // 📱 BUILD BODY SEGÚN ESTADO
  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Cargando reportes épicos...');
    }
    
    if (_error != null) {
      return custom_error.ErrorWidget(
        message: _error!,
        onRetry: _refreshData,
      );
    }
    
    if (_dashboardData == null) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    return TabBarView(
      controller: _tabController,
      children: [
        // 📊 DASHBOARD TAB
        DashboardTab(
          dashboardData: _dashboardData!,
          onRefresh: _refreshData,
        ),
        
        // 🏆 RANKINGS TAB ÉPICO
        RankingsTab(
          anoSeleccionado: _anoSeleccionado,
          mesSeleccionado: _mesSeleccionado,
        ),
        
        // 📄 DOCUMENTOS TAB ÉPICO
        const DocumentosTab(),
      ],
    );
  }
}

// 🎯 DELEGATE PARA STICKY TAB BAR
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
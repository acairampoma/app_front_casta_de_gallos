// 📋 Widget de Tarjeta de Plan - Diseño Premium
// Compatible con planes desde Railway API

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../models/suscripcion_models.dart';

class PlanCard extends StatefulWidget {
  final PlanCatalogo plan;
  final bool esRecomendado;
  final bool esPlanActual;
  final VoidCallback onSeleccionado;

  const PlanCard({
    Key? key,
    required this.plan,
    required this.onSeleccionado,
    this.esRecomendado = false,
    this.esPlanActual = false,
  }) : super(key: key);

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              _animationController.forward();
              HapticFeedback.lightImpact();
            },
            onTapUp: (_) {
              _animationController.reverse();
              widget.onSeleccionado();
            },
            onTapCancel: () => _animationController.reverse(),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getPlanColor().withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildMainCard(),
                  if (widget.esRecomendado) _buildRecomendadoBadge(),
                  if (widget.esPlanActual) _buildPlanActualBadge(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _getPlanColor().withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: widget.esPlanActual
              ? Colors.green
              : widget.esRecomendado
                  ? _getPlanColor()
                  : Colors.grey.shade200,
          width: widget.esPlanActual || widget.esRecomendado ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildPrecio(),
          const SizedBox(height: 20),
          _buildCaracteristicas(),
          const SizedBox(height: 20),
          _buildBotonSeleccionar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getPlanColor(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getPlanIcon(),
              style: const TextStyle(fontSize: 24),
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _getPlanColor(),
                ),
              ),
              Text(
                widget.plan.descripcion ?? 'Plan de suscripción',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrecio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.plan.precio > 0) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.plan.precio.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _getPlanColor(),
                ),
              ),
              Text(
                '/mes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            'GRATIS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _getPlanColor(),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Facturación mensual',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildCaracteristicas() {
    final caracteristicas = [
      // 1️⃣ STREAMING
      _CaracteristicaPlan(
        icono: '📺',
        titulo: 'Streaming',
        valor: _getAccesoStreaming(),
        esDestacado: true,
      ),

      // 2️⃣ MARKETPLACE
      _CaracteristicaPlan(
        icono: '🏪',
        titulo: 'Marketplace',
        valor: widget.plan.marketplacePublicacionesMax == null || widget.plan.marketplacePublicacionesMax! <= 0
            ? 'Sin acceso'
            : '${widget.plan.marketplacePublicacionesMax} publicaciones',
        esDestacado: widget.plan.marketplacePublicacionesMax != null && widget.plan.marketplacePublicacionesMax! > 0,
      ),

      // 3️⃣ GALLOS
      _CaracteristicaPlan(
        icono: '🐓',
        titulo: 'Gallos',
        valor: widget.plan.gallosMaximo == -1
            ? 'Ilimitados'
            : '${widget.plan.gallosMaximo}',
      ),

      // 4️⃣ PELEAS
      _CaracteristicaPlan(
        icono: '🥊',
        titulo: 'Peleas',
        valor: widget.plan.peleasPorGallo == -1
            ? 'Ilimitadas'
            : '${widget.plan.peleasPorGallo} por gallo',
      ),

      // 5️⃣ TOPES (ENTRENAMIENTOS)
      _CaracteristicaPlan(
        icono: '🏋️',
        titulo: 'Topes',
        valor: widget.plan.topesPorGallo == -1
            ? 'Ilimitados'
            : '${widget.plan.topesPorGallo} por gallo',
      ),

      // 6️⃣ VACUNAS
      _CaracteristicaPlan(
        icono: '💉',
        titulo: 'Vacunas',
        valor: widget.plan.vacunasPorGallo == -1
            ? 'Ilimitadas'
            : '${widget.plan.vacunasPorGallo} por gallo',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Características incluidas:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        ...caracteristicas.map((caracteristica) => 
          _buildCaracteristicaItem(caracteristica)
        ),
      ],
    );
  }

  Widget _buildCaracteristicaItem(_CaracteristicaPlan caracteristica) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: caracteristica.esDestacado
          ? BoxDecoration(
              color: _getPlanColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getPlanColor().withOpacity(0.3),
                width: 1,
              ),
            )
          : null,
      child: Row(
        children: [
          Text(
            caracteristica.icono,
            style: TextStyle(
              fontSize: caracteristica.esDestacado ? 22 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  caracteristica.titulo,
                  style: TextStyle(
                    fontSize: caracteristica.esDestacado ? 17 : 16,
                    fontWeight: caracteristica.esDestacado
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: caracteristica.esDestacado
                        ? _getPlanColor()
                        : Colors.black87,
                  ),
                ),
                Container(
                  padding: caracteristica.esDestacado
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
                      : EdgeInsets.zero,
                  decoration: caracteristica.esDestacado
                      ? BoxDecoration(
                          color: _getPlanColor(),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Text(
                    caracteristica.valor,
                    style: TextStyle(
                      fontSize: caracteristica.esDestacado ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: caracteristica.esDestacado
                          ? Colors.white
                          : _getPlanColor(),
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

  Widget _buildBotonSeleccionar() {
    String textoBoton;
    Color colorBoton;
    Color colorTexto;

    if (widget.esPlanActual) {
      textoBoton = 'Plan Actual';
      colorBoton = Colors.green;
      colorTexto = Colors.white;
    } else if (widget.plan.codigo == 'gratuito') {
      textoBoton = 'Plan Gratuito';
      colorBoton = Colors.grey.shade300;
      colorTexto = Colors.grey.shade600;
    } else {
      textoBoton = 'Seleccionar Plan';
      colorBoton = _getPlanColor();
      colorTexto = Colors.white;
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: widget.esPlanActual ? null : widget.onSeleccionado,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorBoton,
          foregroundColor: colorTexto,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: widget.esPlanActual ? 0 : 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.esPlanActual) ...[
              const Icon(Icons.check_circle, size: 20),
              const SizedBox(width: 8),
            ] else if (!widget.esPlanActual && widget.plan.codigo != 'gratuito') ...[
              const Icon(Icons.rocket_launch, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              textoBoton,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecomendadoBadge() {
    return Positioned(
      top: -5,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.red.shade400],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Recomendado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanActualBadge() {
    return Positioned(
      top: -5,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Activo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPlanColor() {
    switch (widget.plan.codigo.toLowerCase()) {
      case 'gratuito':
        return Colors.grey.shade600;
      case 'basico':
        return Colors.blue.shade600;
      case 'premium':
        return Colors.red.shade600;
      case 'profesional':
        return Colors.amber.shade600;
      default:
        return AppColors.primary;
    }
  }

  String _getPlanIcon() {
    switch (widget.plan.codigo.toLowerCase()) {
      case 'gratuito':
        return '🆓';
      case 'basico':
        return '⭐';
      case 'premium':
        return '💎';
      case 'profesional':
        return '👑';
      default:
        return '📋';
    }
  }

  /// 📺 Obtener período de acceso a streaming desde datos de BD
  String _getAccesoStreaming() {
    // ✅ Usar duracionSemanas del modelo que lee desde BD
    if (widget.plan.duracionSemanas == null || widget.plan.duracionSemanas! <= 0) {
      return 'Sin acceso';
    }
    return '${widget.plan.duracionSemanas} semanas';
  }
}

// ========================================
// MODELOS HELPER
// ========================================

class _CaracteristicaPlan {
  final String icono;
  final String titulo;
  final String valor;
  final bool esDestacado;

  _CaracteristicaPlan({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.esDestacado = false,
  });
}
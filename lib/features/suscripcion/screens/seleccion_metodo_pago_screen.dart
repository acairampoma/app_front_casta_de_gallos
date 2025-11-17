// 💳 Pantalla de Selección de Método de Pago
// Permite elegir entre Yape y Mercado Pago (Visa/Mastercard)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../models/suscripcion_models.dart';
import 'proceso_pago_screen.dart';
import 'proceso_pago_mercadopago_screen.dart';

class SeleccionMetodoPagoScreen extends StatefulWidget {
  final PlanCatalogo plan;
  final UpgradeResponse upgradeResponse;

  const SeleccionMetodoPagoScreen({
    Key? key,
    required this.plan,
    required this.upgradeResponse,
  }) : super(key: key);

  @override
  State<SeleccionMetodoPagoScreen> createState() => _SeleccionMetodoPagoScreenState();
}

class _SeleccionMetodoPagoScreenState extends State<SeleccionMetodoPagoScreen> {
  String? _metodoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Método de Pago',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const SizedBox(height: 16),
                    const Text(
                      'Elige cómo pagar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selecciona tu método de pago preferido',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Resumen del plan
                    _buildResumenPlan(),
                    const SizedBox(height: 32),

                    // Métodos de pago
                    const Text(
                      'Métodos disponibles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // YAPE
                    _buildMetodoPagoCard(
                      metodo: 'yape',
                      titulo: 'Yape',
                      subtitulo: 'Pago rápido con Yape',
                      icono: '💜',
                      color: Colors.purple,
                      descripcion: 'Escanea el QR, ingresa tu número y código de confirmación',
                    ),
                    const SizedBox(height: 16),

                    // MERCADO PAGO
                    _buildMetodoPagoCard(
                      metodo: 'mercadopago',
                      titulo: 'Tarjeta de Crédito/Débito',
                      subtitulo: 'Visa, Mastercard, American Express',
                      icono: '💳',
                      color: Colors.blue,
                      descripcion: 'Pago seguro con Mercado Pago',
                      popular: true,
                    ),
                  ],
                ),
              ),
            ),

            // Botón continuar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenPlan() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan seleccionado',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.plan.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${widget.plan.duracionDias} días',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoPagoCard({
    required String metodo,
    required String titulo,
    required String subtitulo,
    required String icono,
    required Color color,
    required String descripcion,
    bool popular = false,
  }) {
    final isSelected = _metodoSeleccionado == metodo;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _metodoSeleccionado = metodo;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      icono,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Título y subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (popular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Radio button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? color : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descripcion,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _metodoSeleccionado != null ? _continuar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _metodoSeleccionado != null
                  ? AppColors.primary
                  : Colors.grey,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _metodoSeleccionado == null
                  ? 'Selecciona un método de pago'
                  : 'Continuar con ${_metodoSeleccionado == "yape" ? "Yape" : "Tarjeta"}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _continuar() {
    HapticFeedback.mediumImpact();

    if (_metodoSeleccionado == 'yape') {
      // Navegar a proceso de pago Yape
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProcesoPagoScreen(
            plan: widget.plan,
            upgradeResponse: widget.upgradeResponse,
          ),
        ),
      );
    } else if (_metodoSeleccionado == 'mercadopago') {
      // Navegar a proceso de pago Mercado Pago
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ProcesoPagoMercadoPagoScreen(
            plan: widget.plan,
            upgradeResponse: widget.upgradeResponse,
          ),
        ),
      );
    }
  }
}

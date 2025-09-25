import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickNavFAB extends StatelessWidget {
  const QuickNavFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _openWhatsAppSupport,
      backgroundColor: const Color(0xFF25D366), // Verde WhatsApp
      heroTag: "quick_nav",
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/icono/wassapt.webp',
          fit: BoxFit.contain,
          width: 28,
          height: 28,
        ),
      ),
    );
  }

  // 🟢 Abrir soporte por WhatsApp con mensaje predefinido
  Future<void> _openWhatsAppSupport() async {
    const phone = '51993592328';
    const message = 'Hola, necesito soporte técnico en GalloApp';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
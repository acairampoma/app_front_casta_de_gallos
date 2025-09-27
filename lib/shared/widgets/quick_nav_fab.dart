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

  // 🟢 Abrir soporte por WhatsApp con mensaje predefinido (igual que en perfil)
  Future<void> _openWhatsAppSupport() async {
    const phoneNumber = '51993592328'; // Número con código de país
    const message = 'Hola, necesito soporte técnico en GalloApp';

    // URLs para diferentes plataformas
    final whatsappAppUrl = 'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}';
    final whatsappWebUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    try {
      // Intentar abrir la APP de WhatsApp primero
      final appUri = Uri.parse(whatsappAppUrl);
      bool launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);

      if (!launched) {
        // Si no se puede abrir la app, intentar WhatsApp Web
        final webUri = Uri.parse(whatsappWebUrl);
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        throw Exception('No se pudo abrir WhatsApp');
      }
    } catch (e) {
      print('❌ Error abriendo WhatsApp: $e');
      // Fallback silencioso - intenta WhatsApp Web una vez más
      try {
        final webUri = Uri.parse(whatsappWebUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        print('❌ Error final: $e2');
      }
    }
  }
}
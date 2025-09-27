import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> openChat({required String phone, String? message}) async {
    print('🔥 WhatsApp Service - Teléfono original: $phone');

    // Limpiar y normalizar el número (igual que en perfil)
    String normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Si no tiene código de país, agregar 51 (Perú) - SIN EL +
    if (!normalized.startsWith('51') && !normalized.startsWith('+')) {
      if (normalized.startsWith('9') && normalized.length == 9) {
        normalized = '51$normalized'; // 987654321 -> 51987654321
      } else if (normalized.length == 9) {
        normalized = '51$normalized';
      }
    }

    // Remover + si lo tiene (para consistencia con perfil)
    normalized = normalized.replaceAll('+', '');

    print('🔥 WhatsApp Service - Teléfono normalizado: $normalized');

    final text = Uri.encodeComponent(message ?? 'Hola, estoy interesado');

    // URLs exactamente como en perfil
    final whatsappAppUrl = 'whatsapp://send?phone=$normalized&text=$text';
    final whatsappWebUrl = 'https://wa.me/$normalized?text=$text';

    try {
      print('🔥 Intentando app: $whatsappAppUrl');

      // Intentar abrir la APP de WhatsApp primero (igual que perfil)
      final appUri = Uri.parse(whatsappAppUrl);
      bool launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);

      if (!launched) {
        print('🔥 App falló, intentando web: $whatsappWebUrl');
        // Si no se puede abrir la app, intentar WhatsApp Web
        final webUri = Uri.parse(whatsappWebUrl);
        launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        throw Exception('No se pudo abrir WhatsApp');
      }

      print('✅ WhatsApp abierto exitosamente');

    } catch (e) {
      print('❌ Error abriendo WhatsApp: $e');
      throw 'No se pudo abrir WhatsApp: $e';
    }
  }
}

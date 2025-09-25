import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> openChat({required String phone, String? message}) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final text = Uri.encodeComponent(message ?? 'Hola, estoy interesado');
    final uri = Uri.parse('https://wa.me/$normalized?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir WhatsApp';
    }
  }
}

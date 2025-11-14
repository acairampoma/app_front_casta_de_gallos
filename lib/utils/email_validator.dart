class EmailValidator {
  // Patrón regex robusto para validar emails (RFC 5322 simplificado)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Valida la sintaxis del email
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El email es obligatorio';
    }

    email = email.trim();

    // Longitud mínima
    if (email.length < 5) {
      return 'El email es muy corto';
    }

    // Longitud máxima
    if (email.length > 254) {
      return 'El email es muy largo';
    }

    // Validar formato
    if (!_emailRegex.hasMatch(email)) {
      return 'Ingresa un email válido (ej: usuario@ejemplo.com)';
    }

    // Validar que no tenga espacios
    if (email.contains(' ')) {
      return 'El email no puede contener espacios';
    }

    // Validar que no tenga caracteres especiales inválidos
    if (email.contains('..')) {
      return 'El email no puede tener puntos consecutivos';
    }

    return null; // null significa que es válido
  }

  /// Verifica si el email es válido (sin mensajes de error)
  static bool isEmailValid(String? email) {
    return validateEmail(email) == null;
  }

  /// Normaliza el email (trim y lowercase)
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Extrae el dominio del email
  static String? getDomain(String email) {
    final parts = email.split('@');
    return parts.length == 2 ? parts[1] : null;
  }

  /// Verifica si es un email corporativo (no es gmail, hotmail, etc)
  static bool isCorporateEmail(String email) {
    final domain = getDomain(email)?.toLowerCase() ?? '';
    final freeProviders = [
      'gmail.com',
      'hotmail.com',
      'outlook.com',
      'yahoo.com',
      'aol.com',
      'mail.com',
      'protonmail.com',
    ];
    return !freeProviders.contains(domain);
  }
}

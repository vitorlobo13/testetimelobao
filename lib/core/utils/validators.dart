/// Classe com validadores de formulários
class Validators {
  /// Valida email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }

    return null;
  }

  /// Valida senha
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }

    return null;
  }

  /// Valida senha forte
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }

    if (value.length < 8) {
      return 'Senha deve ter no mínimo 8 caracteres';
    }

    // Verifica se tem letra maiúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Senha deve conter letra maiúscula';
    }

    // Verifica se tem letra minúscula
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Senha deve conter letra minúscula';
    }

    // Verifica se tem número
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Senha deve conter número';
    }

    return null;
  }

/// Valida confirmação de senha (com trim para segurança)
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirmação de senha é obrigatória';
      }

      // Compara os valores sem espaços laterais
      if (value.trim() != password.trim()) {
        return 'Senhas não conferem';
      }

      return null;
    };
  }

  /// Valida nome
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }

    if (value.length < 3) {
      return 'Nome deve ter no mínimo 3 caracteres';
    }

    if (!value.contains(' ')) {
      return 'Digite nome completo';
    }

    return null;
  }

  /// Valida telefone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }

    // Remove caracteres não numéricos
    final numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length < 10 || numbersOnly.length > 11) {
      return 'Telefone inválido';
    }

    return null;
  }

  /// Valida campo obrigatório
  static String? required(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  /// Valida CPF
  static String? cpf(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }

    // Remove caracteres não numéricos
    final numbersOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (numbersOnly.length != 11) {
      return 'CPF inválido';
    }

    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(numbersOnly)) {
      return 'CPF inválido';
    }

    // Validação dos dígitos verificadores
    final digits = numbersOnly.split('').map(int.parse).toList();
    
    // Calcula primeiro dígito verificador
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    var remainder = sum % 11;
    var digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (digits[9] != digit1) {
      return 'CPF inválido';
    }

    // Calcula segundo dígito verificador
    sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    remainder = sum % 11;
    var digit2 = remainder < 2 ? 0 : 11 - remainder;

    if (digits[10] != digit2) {
      return 'CPF inválido';
    }

    return null;
  }
}
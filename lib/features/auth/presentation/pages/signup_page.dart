import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/application/app_state_repository.dart';
import '../../../../core/services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ranchoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  String? _selectedRole;
  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _ranchoController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // 1) Validar formulario
    if (!_formKey.currentState!.validate()) return;

    // 2) Validar términos
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
        ),
      );
      return;
    }

    // 3) Validar contraseñas
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener al menos 8 caracteres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 4) Validar email
    final email = _correoController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El correo electrónico es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 5) Llamar al backend
    setState(() => _isLoading = true);

    try {
      print('🚀 Iniciando registro...');
      print('👤 Nombre: ${_nombreController.text.trim()}');
      print('📧 Email: $email');
      print('📱 Teléfono: ${_telefonoController.text.trim()}');
      print('🏠 Rancho: ${_ranchoController.text.trim()}');

      // Registrar en el backend (CON TELÉFONO)
      final authResponse = await _authService.register(
        email: email,
        password: _passwordController.text,
        fullName: _nombreController.text.trim(),
        phone: _telefonoController.text.trim().isNotEmpty
            ? _telefonoController.text.trim()
            : null,
      );

      print('✅ Registro exitoso: $authResponse');

      if (!mounted) return;

      // 6) Guardar en AppStateRepository (estado local)
      final appState = context.read<AppStateRepository>();

      appState.updateProfile(
        name: _nombreController.text.trim(),
        role: _selectedRole,
        ranch: _ranchoController.text.trim(),
        phone: _telefonoController.text.trim(),
        email: email,
      );

      appState.setLoggedIn(true, email: email);

      // 7) Mostrar éxito y navegar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a cattle-list
      context.go('/cattle-list');

    } catch (e) {
      print('❌ Error en registro: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Logo circular
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Tarjeta principal
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con logo y título
                    Row(
                      children: [
                        Icon(Icons.eco, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Bovara',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Crear cuenta en Bovara',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Organiza los datos de tu rancho y deja de depender de libretas y WhatsApp.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF616161),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Formulario
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'Nombre completo',
                            controller: _nombreController,
                            hint: 'Ej: Juan Pérez García',
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField(
                            label: 'Rol principal en el rancho',
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Nombre del rancho',
                            controller: _ranchoController,
                            hint: 'Ej: Rancho El Mezquite',
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Teléfono de contacto',
                            controller: _telefonoController,
                            hint: 'Ej: 3331234567',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Correo electrónico',
                            controller: _correoController,
                            hint: 'Ej: juan@correo.com',
                            keyboardType: TextInputType.emailAddress,
                            optional: false,
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            hint: 'Mínimo 8 caracteres',
                            obscure: _obscurePassword,
                            onToggle: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            label: 'Confirmar contraseña',
                            controller: _confirmPasswordController,
                            hint: 'Repite tu contraseña',
                            obscure: _obscureConfirmPassword,
                            onToggle: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Términos y condiciones
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  side: const BorderSide(
                                    color: Color(0xFF000000),
                                    width: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Acepto los términos y condiciones de uso de Bovara',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF222222),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Botón crear cuenta
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Crear cuenta',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Link iniciar sesión
                          Center(
                            child: TextButton(
                              onPressed: () {
                                context.go('/login');
                              },
                              child: const Text(
                                'Ya tengo cuenta, iniciar sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF8D6E63),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 4),
              const Text(
                '(Opcional)',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFADAEBC),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              hint: const Text(
                'Selecciona tu rol',
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontSize: 16,
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF222222),
              ),
              items: ['Dueño', 'Administrador', 'Vaquero', 'Otro']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFADAEBC),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF616161),
                  size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

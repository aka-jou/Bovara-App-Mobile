// lib/features/auth/presentation/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/application/app_state_repository.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late ConnectivityService _connectivityService;
  bool _isConnected = true;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _connectivityService = ConnectivityService();
    _isConnected = _connectivityService.isConnected;

    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _connectivityService.dispose();
    super.dispose();
  }

  // ✅ MÉTODO CORREGIDO
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay conexión a internet. No se puede iniciar sesión.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        email: _userController.text.trim(),
        password: _passwordController.text,
      );

      print('✅ Login exitoso: ${response.user.email}');
      print('👤 Nombre: ${response.user.fullName}');
      print('📧 Email: ${response.user.email}');
      print('📱 Phone: ${response.user.phone}');
      print('🏠 Ranch: ${response.user.ranch}');
      print('👔 Role: ${response.user.role}');

      if (mounted) {
        final appState = context.read<AppStateRepository>();

        // ✅ GUARDAR DATOS (sin ?? porque updateProfile maneja nulls)
        appState.updateProfile(
          name: response.user.fullName,
          email: response.user.email,
          phone: response.user.phone,
          ranch: response.user.ranch,
          role: response.user.role,
        );

        appState.setLoggedIn(
          true,
          email: response.user.email,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Bienvenido ${response.user.fullName ?? "Usuario"}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        context.go('/home');
      }
    } catch (e) {
      print('❌ Error en login: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', '').replaceAll('Error de conexión: ', ''),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Bovara',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.cow,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Bienvenido',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF222222),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Center(
                            child: Text(
                              'Inicia sesión para continuar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF616161),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Formulario
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email
                                TextFormField(
                                  controller: _userController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    hintText: 'Email o teléfono',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    prefixIcon: const Icon(Icons.person),
                                    suffixIcon: const Icon(
                                      Icons.alternate_email_outlined,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDDDDDD),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu email o teléfono';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Ingresa un email válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Contraseña
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enabled: !_isLoading,
                                  decoration: InputDecoration(
                                    hintText: 'Contraseña',
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFDDDDDD),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa tu contraseña';
                                    }
                                    if (value.length < 6) {
                                      return 'Usa al menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Botón Iniciar sesión
                                SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _onLoginPressed,
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text(
                                      'Iniciar sesión',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Botón Crear cuenta
                                SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFCCCCCC),
                                      ),
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                      context.go('/signup');
                                    },
                                    child: const Text(
                                      'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Cifrado activo
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: Color(0xFF2E7D32),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Cifrado activo',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Banner fijo en la parte inferior
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                color: _isConnected
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isConnected ? Icons.wifi : Icons.sync_problem_outlined,
                      color: _isConnected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFF57C00),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _isConnected
                            ? 'Conectado - Sincronización disponible'
                            : 'Sin conexión - Modo offline activo',
                        style: TextStyle(
                          fontSize: 14,
                          color: _isConnected
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFF57C00),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

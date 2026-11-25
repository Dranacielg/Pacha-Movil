import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _bgColor = Color(0xFFF2F4FC);
  static const Color _headerBlue = Color(0xFF2357B8);
  static const Color _headerDarkBlue = Color(0xFF173B82);
  static const Color _primaryPurple = Color(0xFF6B35D9);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // Lógica de Redirección por Rol
        if (email == 'admin@pacha.com') {
          Navigator.pushReplacementNamed(context, '/mapa');
        } else {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Correo o contraseña incorrectos';
      if (e.code == 'user-not-found') mensaje = 'No existe un usuario con ese correo';
      if (e.code == 'wrong-password') mensaje = 'Contraseña incorrecta';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje, style: const TextStyle(color: Colors.red))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _recuperarPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Primero escribí tu email arriba. Después tocá de nuevo.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '📧 Te enviamos un correo a $email con instrucciones. Revisá tu bandeja (y el spam).'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No pudimos enviar el correo';
      if (e.code == 'user-not-found') {
        mensaje = 'No existe una cuenta con ese email';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El email no es válido';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _headerBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Iniciar sesión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        // AutofillGroup ayuda al celular a sugerir correos y contraseñas guardadas
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner superior
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/banner_login.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_headerBlue, _headerDarkBlue],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.landscape,
                            color: Colors.white54,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                    // Gradiente difuminado para fundir con el color de fondo de la app
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _headerDarkBlue.withValues(alpha: 0.15),
                            _bgColor.withValues(alpha: 0.35),
                            _bgColor,
                          ],
                        ),
                      ),
                    ),
                    // Textos superpuestos en el banner
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 14.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: _headerBlue,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'PURMAMARCA - JUJUY, ARGENTINA',
                                  style: TextStyle(
                                    color: _headerDarkBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Formulario principal de Login
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volvé a encontrarte.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _headerDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresá y descubrí la ciudad, sus encuentros y esos lugares que son nuestros.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo Email
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: _headerDarkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: _headerDarkBlue),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        hintText: 'Tu email',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: _headerBlue,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primaryPurple,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Campo Contraseña
                    const Text(
                      'Contraseña',
                      style: TextStyle(
                        color: _headerDarkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: _headerDarkBlue),
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'Tu contraseña',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: _headerBlue,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black45,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primaryPurple,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ¿Olvidaste tu contraseña?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _recuperarPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: _headerBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón Iniciar sesión
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Pie de página (Registrate)
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Todavía no tenés cuenta? ',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                child: const Text(
                                  'Registrate',
                                  style: TextStyle(
                                    color: _primaryPurple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Lo dejamos listo para el futuro
                          GestureDetector(
                            onTap: () {},
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Seguir explorando sin cuenta',
                                  style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_outward,
                                  color: Colors.black45,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
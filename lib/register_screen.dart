import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _bgColor = Color(0xFFF2F4FC);
  static const Color _headerBlue = Color(0xFF2357B8);
  static const Color _headerDarkBlue = Color(0xFF173B82);
  static const Color _primaryPurple = Color(0xFF6B35D9);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _cargando = false; // <-- Para mostrar el circulito de carga

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validaciones visuales
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completá todos los campos')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      // LÓGICA DE FIREBASE
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardamos el nombre en el perfil de Firebase
      await userCredential.user?.updateDisplayName(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('¡Cuenta creada con éxito! Ya podés iniciar sesión.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar';
      if (e.code == 'weak-password') mensaje = 'La contraseña es muy débil';
      if (e.code == 'email-already-in-use') {
        mensaje = 'Ese correo ya está registrado';
      }
      if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo no es válido';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Registro',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _headerBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        // AutofillGroup para que el celular sugiera correos y contraseñas
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
                      'assets/bannercerros.png',
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
                            Icons.image,
                            color: Colors.white54,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                    // Gradiente difuminado
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
                    // Textos superpuestos
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
                                  'CERROS 7 COLORES - JUJUY, ARGENTINA',
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

              // Formulario principal
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jujuy se vive mejor\njuntos.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _headerDarkBlue,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Creá tu cuenta, guardá tus lugares favoritos y no te pierdas ningún encuentro.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Campo Nombre
                    const Text(
                      'Nombre y apellido',
                      style: TextStyle(
                        color: _headerDarkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: _headerDarkBlue),
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        hintText: '¿Cómo te llamás?',
                        hintStyle: const TextStyle(
                          color: Colors.black38,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline,
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
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

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
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        hintText: 'Creá una contraseña',
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
                    const SizedBox(height: 4),
                    const Text(
                      'Usá al menos 6 caracteres.',
                      style: TextStyle(color: Colors.black45, fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    // Campo Confirmar Contraseña
                    const Text(
                      'Confirmar contraseña',
                      style: TextStyle(
                        color: _headerDarkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: _headerDarkBlue),
                      decoration: InputDecoration(
                        hintText: 'Repetí tu contraseña',
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
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black45,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
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
                    const SizedBox(height: 16),

                    // Términos y condiciones
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: _primaryPurple,
                          checkColor: Colors.white,
                          side: const BorderSide(color: _headerBlue),
                          onChanged: (val) =>
                              setState(() => _termsAccepted = val ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            'Acepto los Términos y condiciones y la Política de privacidad.',
                            style:
                                TextStyle(color: Colors.black87, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón Crear cuenta
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _registrarse,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _cargando
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
                                    'Crear mi cuenta',
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
                    const SizedBox(height: 20),

                    // Pie de página (Ir a Iniciar sesión)
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tenés cuenta? ',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Iniciá sesión',
                              style: TextStyle(
                                color: _primaryPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
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
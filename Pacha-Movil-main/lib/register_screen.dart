import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

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

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cuenta creada! Ahora podés iniciar sesión')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131622),
      appBar: AppBar(
        title: const Text('Registro', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner superior: Acá podés cambiar fácilmente la imagen de fondo 
            // (Usá Image.asset('tu/ruta/imagen.png') si preferís tus assets locales)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Imagen de fondo (Modificala por Image.asset si querés usar tus propios archivos)
                  Image.asset(
                    'assets/bannercerros.png',
                  ),
                  
                  // Gradiente difuminado para fundir con el color de fondo de la app
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF131622).withOpacity(0.5),
                          const Color(0xFF131622),
                        ],
                      ),
                    ),
                  ),

                  // Textos y ubicación superpuestos en el banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const Text(
                          '',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'CERROS 7 COLORES - JUJUY, ARGENTINA',
                              style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Formulario principal de Registro
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jujuy se vive mejor\njuntos.',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Creá tu cuenta, guardá tus lugares favoritos y no te pierdas ningún encuentro.',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),

                  // Campo Nombre y apellido
                  const Text('Nombre y apellido', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '¿Cómo te llamás?',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E2336),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Email
                  const Text('Email', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tu email',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.mail_outline, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1E2336),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Campo Contraseña
                  const Text('Contraseña', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Creá una contraseña',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E2336),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Usá al menos 8 caracteres, una letra y un número.', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 16),

                  // Campo Confirmar Contraseña
                  const Text('Confirmar contraseña', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Repetí tu contraseña',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E2336),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Términos y condiciones
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        activeColor: const Color(0xFFFF7F6C),
                        checkColor: const Color(0xFF131622),
                        onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Acepto los Términos y condiciones y la Política de privacidad.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      onPressed: _registrarse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F6C),
                        foregroundColor: const Color(0xFF131622),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Crear mi cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                        const Text('¿Ya tenés cuenta? ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Iniciá sesión',
                            style: TextStyle(color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold, fontSize: 13),
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
    );
  }
}
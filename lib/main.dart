import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Importante para la lógica
import 'firebase_options.dart';
import 'menuprincipal.dart';
import 'colectivosyrutas.dart';
import 'eventos.dart';
import 'lugaresconocer.dart';
import 'map_screen.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QuePaChaJujuyApp());
}

class QuePaChaJujuyApp extends StatelessWidget {
  const QuePaChaJujuyApp({super.key});

  static const Color _bgColor = Color(0xFFF2F4FC);
  static const Color _headerBlue = Color(0xFF2357B8);
  static const Color _primaryPurple = Color(0xFF6B35D9);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qué Pa Cha en Jujuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bgColor,
        primaryColor: _primaryPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _headerBlue,
          primary: _primaryPurple,
          secondary: _headerBlue,
          surface: _bgColor,
        ),
        fontFamily: 'sans-serif',
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _primaryPurple, width: 1.5),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PantallaBienvenida(),
        '/login': (context) => const LoginScreen(),
        '/menu': (context) => const MenuPrincipal(),
        '/colectivos': (context) => const ColectivosY_Rutas(),
        '/eventos': (context) => const EventosScreen(),
        '/lugares': (context) => const LugaresConocerScreen(),
        '/mapa': (context) => MapScreen(),
      },
    );
  }
}

// --- SPLASH SCREEN CON LÓGICA DE FIREBASE Y DISEÑO NUEVO ---
class PantallaBienvenida extends StatefulWidget {
  const PantallaBienvenida({super.key});

  @override
  State<PantallaBienvenida> createState() => _PantallaBienvenidaState();
}

class _PantallaBienvenidaState extends State<PantallaBienvenida> {
  static const Color _bgColor = Color(0xFFF2F4FC);
  static const Color _headerBlue = Color(0xFF2357B8);
  static const Color _headerDarkBlue = Color(0xFF173B82);
  static const Color _primaryPurple = Color(0xFF6B35D9);

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    // Esperamos 2 segundos para que el usuario vea el logo
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Si ya está logueado, salta el login
      if (user.email == 'admin@pacha.com') {
        Navigator.pushReplacementNamed(context, '/mapa');
      } else {
        Navigator.pushReplacementNamed(context, '/menu');
      }
    } else {
      // Si no hay sesión, va al login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_headerBlue, _headerDarkBlue],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'San Salvador de Jujuy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                children: [
                  Image.asset(
                    'assets/icono_nuevo_menu.png', // <-- Mantenemos la imagen nueva de ellos
                    height: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.landscape,
                      size: 100,
                      color: _headerBlue,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Qué Pa Cha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: _headerDarkBlue,
                    ),
                  ),
                  const Text(
                    'en JUJUY?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: _primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'La ciudad, sus encuentros y esos\nlugares que son nuestros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _primaryPurple,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Cargando...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _headerDarkBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Hecha para quienes viven y visitan Jujuy.',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
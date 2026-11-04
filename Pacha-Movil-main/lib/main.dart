import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qué Pa Cha en Jujuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF131622),
        primaryColor: const Color(0xFFFF7F6C),
        fontFamily: 'sans-serif',
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF7F6C))),
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
        '/mapa': (context) => MapScreen(), // <-- Sin el 'const' para evitar problemas
      },
    );
  }
}

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const []),
              Column(
                children: [
                  Image.asset(
                    'assets/icono_nuevo_menu.png',
                    height: 240,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.landscape, size: 100, color: Color(0xFFFF7F6C)),
                  ),
                  const SizedBox(height: 30),
                  const Text('Qué Pa Cha', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, color: Colors.white)),
                  const Text('en JUJUY?', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1, color: Color(0xFFFF7F6C))),
                  const SizedBox(height: 16),
                  const Text('La ciudad, sus encuentros y esos\nlugares que son nuestros.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.4)),
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F6C),
                        foregroundColor: const Color(0xFF131622),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Salí a descubrir Jujuy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hecha para quienes viven y visitan Jujuy.', style: TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
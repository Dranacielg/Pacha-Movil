import 'package:flutter/material.dart';
import 'menuprincipal.dart';
import 'colectivosyrutas.dart';
import 'eventos.dart';
import 'lugaresconocer.dart';

void main() {
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
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PantallaBienvenida(),
        '/menu': (context) => const MenuPrincipal(),
        '/colectivos': (context) => const ColectivosY_Rutas(),
        '/eventos': (context) => const EventosScreen(),
        '/lugares': (context) => const LugaresConocerScreen(),
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
              // Barra superior simulada (Hora y estado)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('9:41', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Icon(Icons.wifi, size: 16),
                ],
              ),
              
              // Contenido central (Logo y textos)
              Column(
                children: [
                  // Placeholder para el Logo / Ilustración principal
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2235),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo_principal.png',
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.landscape,
                          size: 80,
                          color: Color(0xFFFF7F6C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    '¿Qué Pa Cha\nen Jujuy?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'La ciudad, sus encuentros y esos\nlugares que son nuestros.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Botón inferior y pie
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/menu');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7F6C),
                        foregroundColor: const Color(0xFF131622),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Salí a descubrir Jujuy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hecha para quienes viven y visitan Jujuy.',
                    style: TextStyle(fontSize: 11, color: Colors.white38),
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
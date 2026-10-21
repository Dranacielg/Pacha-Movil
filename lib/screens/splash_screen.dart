import 'package:flutter/material.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Temporizador de 3 segundos para ir a la pantalla principal
    Future.delayed(const Duration(seconds: 3), () {
      _goToMain();
    });
  }

  void _goToMain() {
    if (mounted) {
      // pushReplacement elimina el splash del historial para que el botón "atrás" no vuelva aquí
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF6E5),
      body: Center(
        child: GestureDetector(
          onTap: _goToMain,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Aquí irá tu imagen real. Por ahora un placeholder.
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('AQUÍ VA EL LOGO\n(Imagen)'),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'TOCÁ EL LOGO PARA ENTRAR',
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 12,
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
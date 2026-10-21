import 'package:flutter/material.dart';
import 'colectivos_screen.dart';
import 'eventos_screen.dart';
import 'lugares_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF6E5), // Fondo crema de tu diseño
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Título superior
              Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Que Pa Cha en Jujuy?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Botón 1: Colectivos
              _MenuButton(
                title: 'Colectivos y rutas',
                subtitle: 'Líneas, horarios y recorridos',
                color: Colors.amber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ColectivosScreen())),
              ),
              const SizedBox(height: 15),

              // Botón 2: Eventos
              _MenuButton(
                title: 'Eventos en la Ciudad',
                subtitle: 'Fiestas, ferias y recitales',
                color: Colors.redAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventosScreen())),
              ),
              const SizedBox(height: 15),

              // Botón 3: Lugares
              _MenuButton(
                title: 'Lugares típicos para ir',
                subtitle: 'Cerros, quebradas y miradores',
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LugaresScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget personalizado para no repetir código en los botones
class _MenuButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 20,
              top: 40,
              child: Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
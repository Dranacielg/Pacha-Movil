import 'package:flutter/material.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos en la Ciudad')),
      body: const Center(child: Text('Pantalla de Eventos (Próximamente)')),
    );
  }
}
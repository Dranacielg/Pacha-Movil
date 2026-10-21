import 'package:flutter/material.dart';

class ColectivosScreen extends StatelessWidget {
  const ColectivosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colectivos y rutas')),
      body: const Center(child: Text('Pantalla de Colectivos (Próximamente)')),
    );
  }
}
import 'package:flutter/material.dart';

class EventosScreen extends StatelessWidget {
  const EventosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Eventos en la Ciudad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.tune, size: 20, color: Colors.white70),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa resumido superior
          Container(
            height: 150,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(Icons.map_outlined, size: 50, color: Colors.white24),
                ),
                const Positioned(
                  bottom: 10,
                  left: 12,
                  child: Text('San Salvador de Jujuy', style: TextStyle(fontSize: 11, color: Colors.white60)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Título de sección y filtro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('EVENTOS DE LA SEMANA', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                Text('Octubre', style: TextStyle(fontSize: 12, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de eventos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildEventItem(
                  dia: '17',
                  mes: 'OCT',
                  etiqueta: '• EN CURSO - HASTA 23:00',
                  titulo: 'Peña Folclórica en el Centro Cultural',
                  lugarHora: 'Centro Cultural Héctor Tizón • 20:00 hs',
                ),
                _buildEventItem(
                  dia: '18',
                  mes: 'OCT',
                  etiqueta: '• MAÑANA - 10:00 HS',
                  titulo: 'Feria de Artesanos en Plaza Belgrano',
                  lugarHora: 'Plaza Belgrano • Entrada libre',
                ),
                _buildEventItem(
                  dia: '20',
                  mes: 'OCT',
                  etiqueta: '• EN 3 DÍAS - 21:00 HS',
                  titulo: 'Concierto en el Anfiteatro',
                  lugarHora: 'Anfiteatro Las Lavanderas • Entradas en puerta',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildEventItem({required String dia, required String mes, required String etiqueta, required String titulo, required String lugarHora}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Cuadro de fecha (ej: 17 OCT)
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2E334D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text(mes, style: const TextStyle(fontSize: 10, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Detalles del evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(fontSize: 9, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(lugarHora, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161925),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF7F6C),
        unselectedItemColor: Colors.white54,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/menu');
          if (index == 1) Navigator.pushReplacementNamed(context, '/colectivos');
          if (index == 3) Navigator.pushReplacementNamed(context, '/lugares');
        },
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus_outlined), label: 'Colectivos'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.place_outlined), label: 'Lugares'),
        ],
      ),
    );
  }
}
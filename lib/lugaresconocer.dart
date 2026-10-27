import 'package:flutter/material.dart';

class LugaresConocerScreen extends StatefulWidget {
  const LugaresConocerScreen({super.key});

  @override
  State<LugaresConocerScreen> createState() => _LugaresConocerScreenState();
}

class _LugaresConocerScreenState extends State<LugaresConocerScreen> {
  String filtroSeleccionado = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lugares Para Conocer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            height: 140,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              children: [
                Center(child: Icon(Icons.map_outlined, size: 45, color: Colors.white24)),
                const Positioned(
                  bottom: 10,
                  left: 12,
                  child: Text('San Salvador de Jujuy', style: TextStyle(fontSize: 11, color: Colors.white60)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filtros horizontales (Todos, Gastronomía, Cultura, Paseo)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Todos'),
                _buildFilterChip('Gastronomía'),
                _buildFilterChip('Cultura'),
                _buildFilterChip('Paseo'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de lugares
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildLugarItem(
                  tipo: 'RESTAURANTE',
                  nombre: 'Viracocha',
                  detalle: 'Independencia 989\nAbierto hasta 01:00',
                  icono: Icons.restaurant,
                ),
                _buildLugarItem(
                  tipo: 'TEATRO',
                  nombre: 'Teatro Mitre',
                  detalle: 'Sarmiento 350\nFunción 21:00 hs',
                  icono: Icons.theater_comedy,
                ),
                _buildLugarItem(
                  tipo: 'PASEO',
                  nombre: 'Parque Lineal',
                  detalle: 'Ribera del Río\nAbierto todo el día',
                  icono: Icons.park,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildFilterChip(String label) {
    bool activo = filtroSeleccionado == label;
    return GestureDetector(
      onTap: () => setState(() => filtroSeleccionado = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFFF7F6C) : const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? Colors.transparent : Colors.white10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: activo ? const Color(0xFF131622) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildLugarItem({required String tipo, required String nombre, required String detalle, required IconData icono}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2E334D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 20, color: const Color(0xFFFF7F6C)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tipo, style: const TextStyle(fontSize: 9, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 2),
                Text(detalle, style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.3)),
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
          if (index == 2) Navigator.pushReplacementNamed(context, '/eventos');
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
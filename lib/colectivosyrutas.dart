import 'package:flutter/material.dart';

class ColectivosY_Rutas extends StatefulWidget {
  const ColectivosY_Rutas({super.key});

  @override
  State<ColectivosY_Rutas> createState() => _ColectivosY_RutasState();
}

class _ColectivosY_RutasState extends State<ColectivosY_Rutas> {
  String lineaSeleccionada = 'Urbano';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Colectivos y rutas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.tune, size: 20, color: Colors.white70),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mapa simulado superior
          Container(
            height: 190,
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
                  child: Icon(Icons.map_outlined, size: 60, color: Colors.white24),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Tocá el mapa para elegir un punto', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ),
                ),
                const Positioned(
                  bottom: 12,
                  right: 12,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFFF7F6C),
                    child: Icon(Icons.my_location, size: 16, color: Color(0xFF131622)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Selector de pestaña (Urbano / Santa Ana)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text('ELEGÍ EL Nº DE LINEA', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.more_horiz, size: 14, color: Colors.white38),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2235),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => lineaSeleccionada = 'Urbano'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: lineaSeleccionada == 'Urbano' ? const Color(0xFFFF7F6C) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Urbano',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lineaSeleccionada == 'Urbano' ? const Color(0xFF131622) : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => lineaSeleccionada = 'Santa Ana'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: lineaSeleccionada == 'Santa Ana' ? const Color(0xFFFF7F6C) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Santa Ana',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lineaSeleccionada == 'Santa Ana' ? const Color(0xFF131622) : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Lista de líneas de colectivos
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildBusItem(numero: '1', ruta: 'Centro ↔ Alto Comedero', tipo: 'Urbano - Línea 1'),
                _buildBusItem(numero: '2', ruta: 'Terminal ↔ Los Perales', tipo: 'Urbano - Línea 2'),
                _buildBusItem(numero: '3', ruta: 'Ciudad de Nieva ↔ Palpalá', tipo: 'Urbano - Línea 3'),
              ],
            ),
          ),

          // Pie de texto
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Elegí una línea para ver su recorrido y horarios.', style: TextStyle(fontSize: 11, color: Colors.white38)),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildBusItem({required String numero, required String ruta, required String tipo}) {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2E334D),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(numero, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ruta, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 2),
                Text(tipo, style: const TextStyle(fontSize: 11, color: Colors.white54)),
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
          if (index == 2) Navigator.pushReplacementNamed(context, '/eventos');
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
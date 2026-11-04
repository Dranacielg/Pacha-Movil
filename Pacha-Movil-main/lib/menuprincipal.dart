import 'package:flutter/material.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) Navigator.pushNamed(context, '/colectivos');
    if (index == 2) Navigator.pushNamed(context, '/eventos');
    if (index == 3) Navigator.pushNamed(context, '/lugares');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de ubicación superior
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, size: 14, color: Color(0xFFFF7F6C)),
                      SizedBox(width: 4),
                      Text(
                        'JUJUY, ARGENTINA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                  const Icon(Icons.tune, size: 20, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'QUE PA CHA EN JUJUY?',
                style: TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                '¿Qué pinta hacer hoy?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Tarjeta 1: Colectivos y rutas
              _buildCategoryCard(
                context,
                title: 'Colectivos y rutas',
                subtitle: 'Líneas, y recorridos',
                imagePath: 'assets/colesyrutas.jpeg',
                route: '/colectivos',
              ),
              const SizedBox(height: 16),

              // Tarjeta 2: Eventos en la Ciudad
              _buildCategoryCard(
                context,
                title: 'Eventos en la Ciudad',
                subtitle: 'Fiestas, Ferias y Recitales.',
                imagePath: 'assets/eventos.jpeg',
                route: '/eventos',
              ),
              const SizedBox(height: 16),

              // Tarjeta 3: Lugares Para Conocer
              _buildCategoryCard(
                context,
                title: 'Lugares Para Conocer',
                subtitle: 'Cerros, quebradas y miradores',
                imagePath: 'assets/lugaresconocer.jpeg',
                route: '/lugares',
              ),
              const SizedBox(height: 20),

              // Ubicación inferior detallada
              Row(
                children: const [
                  Icon(Icons.location_on, size: 14, color: Color(0xFFFF7F6C)),
                  SizedBox(width: 6),
                  Text(
                    'San Salvador de Jujuy',
                    style: TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoryCard(BuildContext context, {required String title, required String subtitle, required String imagePath, required String route}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen superior de la tarjeta (Placeholder / Asset)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  color: Color(0xFF282D45),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.image, color: Colors.white24, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            // Contenido inferior de la tarjeta
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E334D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_outward, size: 16, color: Color(0xFFFF7F6C)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
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
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
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
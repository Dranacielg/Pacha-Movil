import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';

class LugaresConocerScreen extends StatefulWidget {
  const LugaresConocerScreen({super.key});

  @override
  State<LugaresConocerScreen> createState() => _LugaresConocerScreenState();
}

class _LugaresConocerScreenState extends State<LugaresConocerScreen> {
  final MapStorage _storage = MapStorage();
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();

  // Variables de estado
  List<PuntoInteres> _todosLosPuntos = [];
  List<PuntoInteres> _soloLugares = [];
  StreamSubscription? _subPuntos;

  @override
  void initState() {
    super.initState();
    // Escuchamos la nube en tiempo real
    _subPuntos = _storage.streamPuntos().listen((data) {
      if (mounted) {
        setState(() {
          _todosLosPuntos = data;
          // Filtramos solo lo que es de categoría 'lugar'
          _soloLugares = data.where((p) => p.categoria == 'lugar').toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _subPuntos?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lugares para Conocer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.tune, size: 20, color: Colors.white70),
          ),
        ],
      ),
      body: Column(
        children: [
          // MAPA REAL (Solo muestra lugares)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  RutaMap(
                    key: _mapKey,
                    mostrarRutas: false,       // No mostramos líneas
                    mostrarColectivos: false,  // No mostramos paradas
                    mostrarEventos: false,     // No mostramos eventos
                    mostrarLugares: true,      // SOLO mostramos lugares
                    puntos: _soloLugares,      // Le pasamos solo la lista de lugares
                    rutas: const [],           // Sin rutas
                    modoAgregarPunto: false,   // No se puede agregar desde aquí
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _mapKey.currentState?.centrarEnMiUbicacion(),
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFFF7F6C),
                        child: Icon(Icons.my_location, size: 16, color: Color(0xFF131622)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Título de sección
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LUGARES DISPONIBLES', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                Text('${_soloLugares.length} encontrados', style: const TextStyle(fontSize: 12, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Lista de lugares dinámica
          Expanded(
            child: _soloLugares.isEmpty
                ? const Center(child: Text('No hay lugares creados aún', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _soloLugares.length,
                    itemBuilder: (context, index) {
                      final lugar = _soloLugares[index];
                      return _buildLugarItem(lugar);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildLugarItem(PuntoInteres lugar) {
    return GestureDetector(
      onTap: () {
        // Al tocar el lugar, movemos el mapa hacia él
        _mapKey.currentState?.moverCamara(lugar.punto, 16);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            // Cuadro representativo (ícono del lugar)
            Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2E334D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(lugar.icono, color: lugar.color, size: 24),
            ),
            const SizedBox(width: 14),
            // Detalles del lugar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LUGAR', style: TextStyle(fontSize: 9, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(lugar.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    '${lugar.lat.toStringAsFixed(4)}, ${lugar.lng.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
          ],
        ),
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
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- NUEVO: Para el portapapeles
import 'package:latlong2/latlong.dart';
import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final MapStorage _storage = MapStorage();
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();

  List<PuntoInteres> _todosLosPuntos = [];
  List<PuntoInteres> _soloEventos = [];
  StreamSubscription? _subPuntos;

  PuntoInteres? _eventoSeleccionado;

  @override
  void initState() {
    super.initState();
    _subPuntos = _storage.streamPuntos().listen((data) {
      if (mounted) {
        setState(() {
          _todosLosPuntos = data;
          _soloEventos = data.where((p) => p.categoria == 'evento').toList();
          if (_eventoSeleccionado != null && !_soloEventos.any((e) => e.id == _eventoSeleccionado!.id)) {
            _eventoSeleccionado = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subPuntos?.cancel();
    super.dispose();
  }

  // Función para copiar al portapapeles
  void _copiarCoordenadas(PuntoInteres evento) {
    Clipboard.setData(ClipboardData(text: '${evento.lat}, ${evento.lng}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Coordenadas copiadas. Pegalas en Colectivos o en Uber.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Eventos en la Ciudad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_eventoSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _eventoSeleccionado = null),
            )
        ],
      ),
      body: Column(
        children: [
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
                    mostrarRutas: false,
                    mostrarColectivos: false,
                    mostrarLugares: false,
                    mostrarEventos: true,
                    puntos: _eventoSeleccionado != null ? [_eventoSeleccionado!] : [],
                    rutas: const [],
                    modoAgregarPunto: false,
                  ),
                  
                  if (_eventoSeleccionado == null)
                    const Positioned(
                      top: 10, left: 0, right: 0,
                      child: Center(
                        child: Text('Tocá un evento de la lista para verlo', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EVENTOS DISPONIBLES', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                Text('${_soloEventos.length} encontrados', style: const TextStyle(fontSize: 12, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _soloEventos.isEmpty
                ? const Center(child: Text('No hay eventos creados aún', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _soloEventos.length,
                    itemBuilder: (context, index) {
                      final evento = _soloEventos[index];
                      return _buildEventItem(evento);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildEventItem(PuntoInteres evento) {
    bool isSelected = _eventoSeleccionado?.id == evento.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _mapKey.currentState?.moverCamara(evento.punto, 16);
          } else {
            _eventoSeleccionado = evento;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E334D) : const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFFFF7F6C) : Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2E334D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(evento.icono, color: evento.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelected ? 'TOCÁ DE NUEVO PARA IR' : 'EVENTO', 
                    style: TextStyle(fontSize: 9, color: isSelected ? Colors.greenAccent : const Color(0xFFFF7F6C), fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 2),
                  Text(evento.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    '${evento.lat.toStringAsFixed(4)}, ${evento.lng.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
            
            // BOTÓN DE COPIAR (Solo aparece si el evento está seleccionado)
            if (isSelected)
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.blueAccent),
                tooltip: 'Copiar coordenadas',
                onPressed: () => _copiarCoordenadas(evento),
              ),

            Icon(
              isSelected ? Icons.my_location : Icons.touch_app, 
              size: 18, 
              color: isSelected ? Colors.greenAccent : Colors.white38
            ),
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
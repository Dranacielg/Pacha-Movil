import 'dart:async';
import 'widgets/resena_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';
import 'utils/map_launcher.dart'; // <-- Para el botón de Cómo llegar

class LugaresConocerScreen extends StatefulWidget {
  const LugaresConocerScreen({super.key});

  @override
  State<LugaresConocerScreen> createState() => _LugaresConocerScreenState();
}

class _LugaresConocerScreenState extends State<LugaresConocerScreen> {
  final MapStorage _storage = MapStorage();
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();

  List<PuntoInteres> _todosLosPuntos = [];
  List<PuntoInteres> _lugaresFiltrados = [];
  StreamSubscription? _subPuntos;

  PuntoInteres? _lugarSeleccionado;
  
  String _categoriaSeleccionada = 'gastronomia';

  final List<Map<String, dynamic>> _categorias = [
    {'id': 'gastronomia', 'nombre': 'Gastronomía', 'icono': Icons.restaurant},
    {'id': 'recreacion', 'nombre': 'Recreación', 'icono': Icons.park},
    {'id': 'deportes', 'nombre': 'Deportes', 'icono': Icons.pool},
    {'id': 'cultura', 'nombre': 'Cultura', 'icono': Icons.theaters},
    {'id': 'compras', 'nombre': 'Compras', 'icono': Icons.shopping_bag},
  ];

  bool _permiteResenas(String subCategoria) {
    return ['gastronomia', 'cultura', 'compras'].contains(subCategoria);
  }

  @override
  void initState() {
    super.initState();
    _subPuntos = _storage.streamPuntos().listen((data) {
      if (mounted) {
        setState(() {
          _todosLosPuntos = data;
          _actualizarListaFiltrada();
        });
      }
    });
  }

  @override
  void dispose() {
    _subPuntos?.cancel();
    super.dispose();
  }

  void _actualizarListaFiltrada() {
    _lugaresFiltrados = _todosLosPuntos.where((p) => 
      p.categoria == 'lugar' && p.categoriaLugar == _categoriaSeleccionada
    ).toList();

    if (_lugarSeleccionado != null && !_lugaresFiltrados.any((e) => e.id == _lugarSeleccionado!.id)) {
      _lugarSeleccionado = null;
    }
  }

  bool _estaAbierto(PuntoInteres lugar) {
    if (lugar.horarios.isEmpty) return true; 
    
    final now = DateTime.now();
    final dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final diaHoy = dias[now.weekday - 1];
    final ahoraMinutos = now.hour * 60 + now.minute;

    final horariosHoy = lugar.horarios.where((h) => h.dia == diaHoy).toList();
    if (horariosHoy.isEmpty) return false;

    for (var h in horariosHoy) {
      try {
        int parseTime(String timeStr) {
           String clean = timeStr.toLowerCase().replaceAll('a. m.', 'am').replaceAll('p. m.', 'pm');
           bool isPM = clean.contains('pm');
           clean = clean.replaceAll('am', '').replaceAll('pm', '').trim();
           var parts = clean.split(':');
           int hr = int.parse(parts[0]);
           int min = parts.length > 1 ? int.parse(parts[1]) : 0;
           if (isPM && hr < 12) hr += 12;
           if (!isPM && hr == 12) hr = 0;
           return hr * 60 + min;
        }

        int start = parseTime(h.apertura);
        int end = parseTime(h.cierre);

        if (start == end) return true; 

        if (end < start) {
          if (ahoraMinutos >= start || ahoraMinutos <= end) return true;
        } else {
          if (ahoraMinutos >= start && ahoraMinutos <= end) return true;
        }
      } catch (e) {
        // Error de formato de hora
      }
    }
    return false; 
  }

  void _copiarCoordenadas(PuntoInteres lugar) {
    Clipboard.setData(ClipboardData(text: '${lugar.lat}, ${lugar.lng}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Coordenadas copiadas para usar en otras apps.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Lugares para Conocer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // MANTENEMOS EL ÍCONO DE AJUSTES DE TU EQUIPO
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: Icon(Icons.tune, size: 20, color: Colors.white70),
          ),
          // BOTÓN PARA CERRAR LA SELECCIÓN DEL MAPA
          if (_lugarSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _lugarSeleccionado = null),
            )
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  RutaMap(
                    key: _mapKey,
                    mostrarRutas: false,
                    mostrarColectivos: false,
                    mostrarEventos: false,
                    mostrarLugares: true,
                    puntos: _lugarSeleccionado != null ? [_lugarSeleccionado!] : [],
                    rutas: const [],
                    modoAgregarPunto: false,
                  ),
                  if (_lugarSeleccionado == null)
                    const Positioned(
                      top: 10, left: 0, right: 0,
                      child: Center(
                        child: Text('Tocá un lugar de la lista para verlo', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    bottom: 12, right: 12,
                    child: GestureDetector(
                      onTap: () => _mapKey.currentState?.centrarEnMiUbicacion(),
                      child: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFF7F6C), child: Icon(Icons.my_location, size: 16, color: Color(0xFF131622))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // FILTROS POR CATEGORÍA
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                bool isSelected = _categoriaSeleccionada == cat['id'];
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat['nombre']),
                    avatar: Icon(cat['icono'], size: 16, color: isSelected ? Colors.black : Colors.white70),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF7F6C),
                    backgroundColor: const Color(0xFF1E2235),
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12),
                    onSelected: (val) {
                      setState(() {
                        _categoriaSeleccionada = cat['id'];
                        _lugarSeleccionado = null; 
                        _actualizarListaFiltrada();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // TÍTULO Y LISTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LUGARES DISPONIBLES', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                Text('${_lugaresFiltrados.length} encontrados', style: const TextStyle(fontSize: 12, color: Color(0xFFFF7F6C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _lugaresFiltrados.isEmpty
                ? const Center(child: Text('No hay lugares en esta categoría', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _lugaresFiltrados.length,
                    itemBuilder: (context, index) {
                      final lugar = _lugaresFiltrados[index];
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
    bool isSelected = _lugarSeleccionado?.id == lugar.id;
    bool abierto = _estaAbierto(lugar);
    bool tieneResenas = _permiteResenas(lugar.categoriaLugar);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _mapKey.currentState?.moverCamara(lugar.punto, 16);
          } else {
            _lugarSeleccionado = lugar;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 52,
                  decoration: BoxDecoration(color: const Color(0xFF2E334D), borderRadius: BorderRadius.circular(10)),
                  child: Icon(lugar.icono, color: lugar.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: abierto ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: abierto ? Colors.green : Colors.red, width: 0.5)
                            ),
                            child: Text(
                              abierto ? 'ABIERTO' : 'CERRADO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: abierto ? Colors.greenAccent : Colors.redAccent),
                            ),
                          ),
                          const Spacer(),
                          if (tieneResenas && lugar.resenas.isNotEmpty) ...[
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(lugar.puntuacionPromedio.toStringAsFixed(1), style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(lugar.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            
            if (lugar.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lugar.descripcion,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (lugar.horarios.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: lugar.horarios.map((h) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.white38),
                      const SizedBox(width: 4),
                      Text('${h.dia.substring(0,3)}: ${h.apertura} - ${h.cierre}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    ],
                  );
                }).toList(),
              )
            ],

            const Divider(color: Colors.white12, height: 20),
            
            // BOTONES DE ACCIÓN
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _copiarCoordenadas(lugar),
                  icon: const Icon(Icons.copy, size: 16, color: Colors.blueAccent),
                  label: const Text('Copiar', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () {
                    MapLauncher.showAppChooser(
                      context: context,
                      lat: lugar.lat,
                      lng: lugar.lng,
                      nombreLugar: lugar.nombre,
                    );
                  },
                  icon: const Icon(Icons.directions, size: 16, color: Colors.greenAccent),
                  label: const Text('Cómo llegar', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ),
                if (tieneResenas)
                  TextButton.icon(
                    onPressed: () async {
                      final nuevaResena = await showModalBottomSheet<Resena>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: const Color(0xFF161925),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (context) => ResenaModal(lugar: lugar),
                      );

                      if (nuevaResena != null) {
                        List<Resena> resenasActualizadas = List.from(lugar.resenas)..add(nuevaResena);
                        PuntoInteres lugarActualizado = PuntoInteres(
                          id: lugar.id,
                          nombre: lugar.nombre,
                          descripcion: lugar.descripcion,
                          lat: lugar.lat,
                          lng: lugar.lng,
                          iconoCode: lugar.iconoCode,
                          colorValue: lugar.colorValue,
                          categoria: lugar.categoria,
                          categoriaLugar: lugar.categoriaLugar,
                          horarios: lugar.horarios,
                          resenas: resenasActualizadas,
                        );

                        await _storage.actualizarPunto(lugarActualizado);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Gracias por tu reseña!')));
                      }
                    },
                    icon: const Icon(Icons.rate_review, size: 16, color: Color(0xFFFF7F6C)),
                    label: const Text('Dejar Reseña', style: TextStyle(color: Color(0xFFFF7F6C), fontSize: 12)),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF161925), border: Border(top: BorderSide(color: Colors.white10, width: 0.5))),
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
        selectedFontSize: 11, unselectedFontSize: 11, elevation: 0,
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

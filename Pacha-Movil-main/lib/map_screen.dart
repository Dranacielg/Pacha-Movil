import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();
  final MapStorage _storage = MapStorage();

  // Variables de estado para los datos
  List<PuntoInteres> _puntos = [];
  List<RutaColectivo> _rutas = [];
  StreamSubscription? _subPuntos;
  StreamSubscription? _subRutas;

  bool _mostrarRutas = true; 
  bool _mostrarLugares = true; 
  bool _mostrarEventos = true; 
  bool _mostrarColectivos = true; 

  bool _modoAgregarPunto = false;
  bool _modoAgregarRuta = false;
  
  List<LatLng> _rutaEnProgreso = [];
  List<LatLng> _paradasEnProgreso = []; 
  bool _modoEsParada = true; 

  @override
  void initState() {
    super.initState();
    // Escuchamos los cambios de la nube y actualizamos el estado
    _subPuntos = _storage.streamPuntos().listen((data) {
      if (mounted) setState(() => _puntos = data);
    });
    _subRutas = _storage.streamRutas().listen((data) {
      if (mounted) setState(() => _rutas = data);
    });
  }

  @override
  void dispose() {
    _subPuntos?.cancel();
    _subRutas?.cancel();
    super.dispose();
  }

  void _alTocarMapa(LatLng punto) async {
    if (_modoAgregarPunto) {
      setState(() => _modoAgregarPunto = false);
      
      final TextEditingController controller = TextEditingController();
      String categoriaSeleccionada = 'lugar'; 

      final resultado = await showDialog<String>(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Nuevo Punto'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre del lugar'), autofocus: true),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: categoriaSeleccionada,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: const [
                        DropdownMenuItem(value: 'lugar', child: Text('Lugar (Restaurante, Cine...)')),
                        DropdownMenuItem(value: 'evento', child: Text('Evento (Fiesta, Recital...)')),
                        DropdownMenuItem(value: 'colectivo', child: Text('Parada de Colectivo')),
                      ],
                      onChanged: (val) {
                        setDialogState(() { categoriaSeleccionada = val!; });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
                ],
              );
            }
          );
        },
      );

      if (resultado != null && resultado.isNotEmpty) {
        IconData iconoFinal;
        Color colorFinal;

        if (categoriaSeleccionada == 'evento') {
          iconoFinal = Icons.event;
          colorFinal = Colors.pinkAccent;
        } else if (categoriaSeleccionada == 'colectivo') {
          iconoFinal = Icons.directions_bus;
          colorFinal = Colors.greenAccent;
        } else {
          iconoFinal = Icons.place;
          colorFinal = Colors.blueAccent;
        }

        final nuevoPunto = PuntoInteres(
          id: '', 
          nombre: resultado, 
          lat: punto.latitude, 
          lng: punto.longitude,
          iconoCode: iconoFinal.codePoint, 
          colorValue: colorFinal.value,
          categoria: categoriaSeleccionada, 
        );
        
        await _storage.guardarPunto(nuevoPunto); 
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Punto guardado en la nube')));
      }
    }
    else if (_modoAgregarRuta) {
      setState(() { 
        _rutaEnProgreso.add(punto); 
        if (_modoEsParada) {
          _paradasEnProgreso.add(punto);
        }
      });
    }
  }

  void _guardarRutaEnProgreso() async {
    if (_rutaEnProgreso.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregá al menos 2 puntos para hacer una ruta')));
      return;
    }

    final TextEditingController controller = TextEditingController();
    String categoriaSeleccionada = 'urbano';

    final resultado = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Guardar Ruta'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre de la línea (ej. Línea 1)'), autofocus: true),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: categoriaSeleccionada,
                    decoration: const InputDecoration(labelText: 'Tipo de línea'),
                    items: const [
                      DropdownMenuItem(value: 'urbano', child: Text('Urbano')),
                      DropdownMenuItem(value: 'santa_ana', child: Text('Santa Ana')),
                    ],
                    onChanged: (val) => setDialogState(() => categoriaSeleccionada = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar Ruta')),
              ],
            );
          }
        );
      },
    );

    if (resultado != null && resultado.isNotEmpty) {
      final nuevaRuta = RutaColectivo(
        id: '', 
        nombre: resultado,
        puntosTrazo: List.from(_rutaEnProgreso),
        paradas: List.from(_paradasEnProgreso),
        colorValue: Colors.deepPurpleAccent.value,
        categoriaRuta: categoriaSeleccionada,
      );

      setState(() {
        _rutaEnProgreso.clear(); 
        _paradasEnProgreso.clear(); 
        _modoAgregarRuta = false;
      });

      await _storage.guardarRuta(nuevaRuta);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ruta "$resultado" guardada en la nube')));
    }
  }

  void _cancelarRuta() {
    setState(() {
      _rutaEnProgreso.clear();
      _paradasEnProgreso.clear();
      _modoAgregarRuta = false;
    });
  }

  void _abrirGestionGuardados() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161925),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 10),
                    const TabBar(
                      labelColor: Color(0xFFFF7F6C), unselectedLabelColor: Colors.white54, indicatorColor: Color(0xFFFF7F6C),
                      tabs: [Tab(text: 'Puntos'), Tab(text: 'Rutas')],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _puntos.isEmpty
                              ? const Center(child: Text('No hay puntos guardados', style: TextStyle(color: Colors.white54)))
                              : ListView.builder(
                                  itemCount: _puntos.length,
                                  itemBuilder: (context, index) {
                                    final p = _puntos[index];
                                    return ListTile(
                                      leading: Icon(p.icono, color: p.color),
                                      title: Text(p.nombre, style: const TextStyle(color: Colors.white)),
                                      subtitle: Text(p.categoria.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () async {
                                          await _storage.eliminarPunto(p.id); 
                                          setModalState(() {}); 
                                        },
                                      ),
                                    );
                                  },
                                ),
                          _rutas.isEmpty
                              ? const Center(child: Text('No hay rutas guardadas', style: TextStyle(color: Colors.white54)))
                              : ListView.builder(
                                  itemCount: _rutas.length,
                                  itemBuilder: (context, index) {
                                    final r = _rutas[index];
                                    return ListTile(
                                      leading: Icon(Icons.alt_route, color: r.color),
                                      title: Text(r.nombre, style: const TextStyle(color: Colors.white)),
                                      subtitle: Text('${r.puntosTrazo.length} puntos, ${r.paradas.length} paradas', style: const TextStyle(color: Colors.white38)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () async {
                                          await _storage.eliminarRuta(r.id); 
                                          setModalState(() {}); 
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio de Mapas'), backgroundColor: const Color(0xFF161925), foregroundColor: Colors.white),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: RutaMap(
              key: _mapKey,
              mostrarRutas: _mostrarRutas,
              mostrarLugares: _mostrarLugares,
              mostrarEventos: _mostrarEventos,
              mostrarColectivos: _mostrarColectivos,
              puntos: _puntos,
              rutas: _rutas,
              modoAgregarPunto: _modoAgregarPunto,
              modoAgregarRuta: _modoAgregarRuta,
              rutaEnProgreso: _rutaEnProgreso,
              onMapTap: _alTocarMapa,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF131622),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildSwitchChip('Rutas', _mostrarRutas, (v) => setState(() => _mostrarRutas = v)),
                        _buildSwitchChip('Lugares', _mostrarLugares, (v) => setState(() => _mostrarLugares = v)),
                        _buildSwitchChip('Eventos', _mostrarEventos, (v) => setState(() => _mostrarEventos = v)),
                        _buildSwitchChip('Colectivos', _mostrarColectivos, (v) => setState(() => _mostrarColectivos = v)),
                      ],
                    ),
                    const Divider(color: Colors.white24),

                    ElevatedButton.icon(
                      onPressed: _abrirGestionGuardados,
                      icon: const Icon(Icons.list),
                      label: const Text('Gestionar Guardados (Borrar/Ver)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                    ),
                    const SizedBox(height: 10),

                    if (_modoAgregarRuta) ...[
                      Text('Puntos en la ruta: ${_rutaEnProgreso.length}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      SwitchListTile(
                        title: const Text('El próximo toque es una PARADA', style: TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: const Text('Apagalo si es solo una curva del camino', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        activeColor: Colors.greenAccent,
                        value: _modoEsParada,
                        onChanged: (val) => setState(() => _modoEsParada = val),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(onPressed: _guardarRutaEnProgreso, icon: const Icon(Icons.save), label: const Text('Guardar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton.icon(onPressed: _cancelarRuta, icon: const Icon(Icons.cancel), label: const Text('Cancelar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white))),
                        ],
                      ),
                    ] 
                    else ...[
                      ElevatedButton.icon(
                        onPressed: () => setState(() { _modoAgregarPunto = !_modoAgregarPunto; _modoAgregarRuta = false; }),
                        icon: Icon(_modoAgregarPunto ? Icons.map : Icons.add_location),
                        label: Text(_modoAgregarPunto ? 'Tocá el mapa para el Punto...' : 'Agregar Punto al Mapa'),
                        style: ElevatedButton.styleFrom(backgroundColor: _modoAgregarPunto ? Colors.orange : Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => setState(() { _modoAgregarRuta = !_modoAgregarRuta; _modoAgregarPunto = false; _rutaEnProgreso.clear(); _paradasEnProgreso.clear(); }),
                        icon: const Icon(Icons.alt_route),
                        label: const Text('Trazar Ruta de Colectivo'),
                        style: ElevatedButton.styleFrom(backgroundColor: _modoAgregarRuta ? Colors.orange : Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _mapKey.currentState?.centrarEnMiUbicacion(),
                      icon: const Icon(Icons.my_location),
                      label: const Text('Centrar en mi ubicación'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7F6C), foregroundColor: const Color(0xFF131622), minimumSize: const Size(double.infinity, 50)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: value ? Colors.black : Colors.white70, fontSize: 12)),
      selected: value,
      selectedColor: const Color(0xFFFF7F6C),
      backgroundColor: const Color(0xFF161925),
      checkmarkColor: Colors.black,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
    );
  }
}
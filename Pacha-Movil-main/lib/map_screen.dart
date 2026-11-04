import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  List<PuntoInteres> _puntos = [];
  List<RutaColectivo> _rutas = [];
  StreamSubscription? _subPuntos;
  StreamSubscription? _subRutas;

  bool _mostrarRutas = true; 
  bool _mostrarLugares = true; 
  bool _mostrarEventos = true; 

  bool _modoAgregarPunto = false;
  bool _modoAgregarRuta = false;
  
  List<LatLng> _rutaEnProgreso = [];
  List<LatLng> _paradasEnProgreso = []; 
  bool _modoEsParada = true; 

  @override
  void initState() {
    super.initState();
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
      _mostrarFormularioCreacion(punto);
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

  // --- FORMULARIO AVANZADO ---
  void _mostrarFormularioCreacion(LatLng punto) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    String categoriaPrincipal = 'lugar'; 
    String subcategoriaLugar = 'gastronomia';
    List<HorarioAtencion> horariosTemporales = [];
    
    DateTime? fechaInicioEvento;
    DateTime? fechaFinEvento;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nuevo Punto en el Mapa', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción breve'), maxLines: 2, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: categoriaPrincipal,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Categoría Principal'),
                      items: const [
                        DropdownMenuItem(value: 'lugar', child: Text('Lugar')),
                        DropdownMenuItem(value: 'evento', child: Text('Evento')),
                      ],
                      onChanged: (val) => setModalState(() => categoriaPrincipal = val!),
                    ),
                    
                    // SECCIÓN DE LUGAR
                    if (categoriaPrincipal == 'lugar') ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: subcategoriaLugar,
                        dropdownColor: const Color(0xFF1E2235),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Tipo de Lugar'),
                        items: const [
                          DropdownMenuItem(value: 'gastronomia', child: Text('Gastronomía (Comida/Bebida)')),
                          DropdownMenuItem(value: 'recreacion', child: Text('Recreación (Plazas/Parques)')),
                          DropdownMenuItem(value: 'deportes', child: Text('Deportes (Piscinas/Canchas)')),
                          DropdownMenuItem(value: 'cultura', child: Text('Cultura (Cines/Teatros)')),
                          DropdownMenuItem(value: 'compras', child: Text('Compras (Shoppings/Ferias)')),
                        ],
                        onChanged: (val) => setModalState(() => subcategoriaLugar = val!),
                      ),
                      
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Horarios de Atención', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: () async {
                              final nuevoHorario = await _agregarHorario(context);
                              if (nuevoHorario != null) setModalState(() => horariosTemporales.add(nuevoHorario));
                            },
                            icon: const Icon(Icons.add, color: Color(0xFFFF7F6C), size: 18),
                            label: const Text('Agregar', style: TextStyle(color: Color(0xFFFF7F6C))),
                          )
                        ],
                      ),
                      
                      if (horariosTemporales.isEmpty)
                        const Text('No hay horarios cargados.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ...horariosTemporales.map((h) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time, color: Colors.white54, size: 20),
                          title: Text('${h.dia}: ${h.apertura} a ${h.cierre}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                            onPressed: () => setModalState(() => horariosTemporales.remove(h)),
                          ),
                        );
                      }).toList(),
                    ],

                    // SECCIÓN DE EVENTO (FECHAS)
                    if (categoriaPrincipal == 'evento') ...[
                      const SizedBox(height: 20),
                      const Text('Fecha y Hora del Evento', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (date != null) {
                                  if (!context.mounted) return;
                                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (time != null) {
                                    setModalState(() => fechaInicioEvento = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                  }
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(fechaInicioEvento == null ? 'Inicio' : '${fechaInicioEvento!.day}/${fechaInicioEvento!.month} ${fechaInicioEvento!.hour}:${fechaInicioEvento!.minute.toString().padLeft(2,'0')}'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E334D)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                                if (date != null) {
                                  if (!context.mounted) return;
                                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                  if (time != null) {
                                    setModalState(() => fechaFinEvento = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                                  }
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(fechaFinEvento == null ? 'Fin' : '${fechaFinEvento!.day}/${fechaFinEvento!.month} ${fechaFinEvento!.hour}:${fechaFinEvento!.minute.toString().padLeft(2,'0')}'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E334D)),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 25),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nombreCtrl.text.isEmpty) return;
                          Navigator.pop(context);
                          
                          IconData iconoFinal;
                          Color colorFinal;
                          if (categoriaPrincipal == 'evento') {
                            iconoFinal = Icons.event; colorFinal = Colors.pinkAccent;
                          } else {
                            iconoFinal = Icons.place; colorFinal = Colors.blueAccent;
                          }

                          final nuevoPunto = PuntoInteres(
                            id: '', 
                            nombre: nombreCtrl.text, 
                            descripcion: descCtrl.text,
                            lat: punto.latitude, 
                            lng: punto.longitude,
                            iconoCode: iconoFinal.codePoint, 
                            colorValue: colorFinal.value,
                            categoria: categoriaPrincipal, 
                            categoriaLugar: categoriaPrincipal == 'lugar' ? subcategoriaLugar : '',
                            horarios: horariosTemporales,
                            fechaInicio: fechaInicioEvento?.millisecondsSinceEpoch,
                            fechaFin: fechaFinEvento?.millisecondsSinceEpoch,
                          );
                          
                          await _storage.guardarPunto(nuevoPunto); 
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en la nube')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7F6C), 
                          foregroundColor: const Color(0xFF131622),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        child: const Text('GUARDAR EN EL MAPA', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  // --- VENTANA PARA ELEGIR UN HORARIO ---
  Future<HorarioAtencion?> _agregarHorario(BuildContext context) async {
    String diaSeleccionado = 'Lunes';
    TimeOfDay? horaApertura;
    TimeOfDay? horaCierre;

    return showDialog<HorarioAtencion>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2235),
              title: const Text('Nuevo Horario', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: diaSeleccionado,
                    dropdownColor: const Color(0xFF161925),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Día'),
                    items: ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'].map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => diaSeleccionado = val!),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
                            if (time != null) setDialogState(() => horaApertura = time);
                          },
                          child: Text(horaApertura == null ? 'Apertura' : 'Abre: ${horaApertura!.format(context)}', style: const TextStyle(color: Colors.greenAccent)),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
                            if (time != null) setDialogState(() => horaCierre = time);
                          },
                          child: Text(horaCierre == null ? 'Cierre' : 'Cierra: ${horaCierre!.format(context)}', style: const TextStyle(color: Colors.redAccent)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (horaApertura != null && horaCierre != null) {
                      Navigator.pop(context, HorarioAtencion(
                        dia: diaSeleccionado,
                        apertura: horaApertura!.format(context),
                        cierre: horaCierre!.format(context),
                      ));
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          }
        );
      }
    );
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

  // --- DISEÑO MAPA PROTAGONISTA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Mapa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. MAPA A PANTALLA COMPLETA
          Positioned.fill(
            child: RutaMap(
              key: _mapKey,
              mostrarRutas: _mostrarRutas,
              mostrarLugares: _mostrarLugares,
              mostrarEventos: _mostrarEventos,
              mostrarColectivos: false, 
              puntos: _puntos,
              rutas: _rutas,
              modoAgregarPunto: _modoAgregarPunto,
              modoAgregarRuta: _modoAgregarRuta,
              rutaEnProgreso: _rutaEnProgreso,
              onMapTap: _alTocarMapa,
            ),
          ),

          // 2. FILTROS FLOTANTES
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFloatingChip('Rutas', _mostrarRutas, (v) => setState(() => _mostrarRutas = v)),
                  const SizedBox(width: 8),
                  _buildFloatingChip('Lugares', _mostrarLugares, (v) => setState(() => _mostrarLugares = v)),
                  const SizedBox(width: 8),
                  _buildFloatingChip('Eventos', _mostrarEventos, (v) => setState(() => _mostrarEventos = v)),
                ],
              ),
            ),
          ),

          // 3. BOTONES FLOTANTES
          Positioned(
            right: 16,
            bottom: _modoAgregarRuta ? 180 : 30, 
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.list,
                  tooltip: 'Gestionar Guardados',
                  color: Colors.grey[800]!,
                  onPressed: _abrirGestionGuardados,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.alt_route,
                  tooltip: 'Trazar Ruta',
                  color: _modoAgregarRuta ? Colors.orange : Colors.teal,
                  onPressed: () {
                    setState(() {
                      _modoAgregarRuta = !_modoAgregarRuta;
                      _modoAgregarPunto = false;
                      _rutaEnProgreso.clear();
                      _paradasEnProgreso.clear();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.add_location,
                  tooltip: 'Agregar Punto',
                  color: _modoAgregarPunto ? Colors.orange : Colors.blueAccent,
                  onPressed: () {
                    setState(() {
                      _modoAgregarPunto = !_modoAgregarPunto;
                      _modoAgregarRuta = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Icons.my_location,
                  tooltip: 'Mi Ubicación',
                  color: const Color(0xFF161925),
                  iconColor: const Color(0xFFFF7F6C),
                  onPressed: () => _mapKey.currentState?.centrarEnMiUbicacion(),
                ),
              ],
            ),
          ),

          // 4. AVISO AL AGREGAR PUNTO
          if (_modoAgregarPunto)
            Positioned(
              bottom: 30,
              left: 20,
              right: 80, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
                ),
                child: const Text(
                  'Tocá el mapa para ubicar el punto',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // 5. PANEL INFERIOR AL TRAZAR RUTA
          if (_modoAgregarRuta)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF161925),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Puntos en la ruta: ${_rutaEnProgreso.length}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    SwitchListTile(
                      title: const Text('El próximo toque es una PARADA', style: TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: const Text('Apagalo si es solo una curva del camino', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      activeColor: Colors.greenAccent,
                      value: _modoEsParada,
                      onChanged: (val) => setState(() => _modoEsParada = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton.icon(onPressed: _guardarRutaEnProgreso, icon: const Icon(Icons.save), label: const Text('Guardar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(0, 45)))),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton.icon(onPressed: _cancelarRuta, icon: const Icon(Icons.cancel), label: const Text('Cancelar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(0, 45)))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingChip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label, style: TextStyle(color: value ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      selected: value,
      selectedColor: const Color(0xFFFF7F6C),
      backgroundColor: const Color(0xFF161925).withOpacity(0.9),
      checkmarkColor: Colors.black,
      onSelected: onChanged,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white24)),
    );
  }

  Widget _buildActionButton({required IconData icon, required String tooltip, required Color color, Color iconColor = Colors.white, required VoidCallback onPressed}) {
    return Tooltip(
      message: tooltip,
      child: FloatingActionButton(
        heroTag: tooltip,
        backgroundColor: color,
        foregroundColor: iconColor,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}

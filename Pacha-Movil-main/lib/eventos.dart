import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/editor_punto.dart';
import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';
import 'widgets/editor_punto.dart';
import 'utils/map_launcher.dart';
import 'colectivosyrutas.dart';

class EventosScreen extends StatefulWidget {
  const EventosScreen({super.key});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final MapStorage _storage = MapStorage();
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();
  final TextEditingController _busquedaCtrl = TextEditingController();

  List<PuntoInteres> _todosLosPuntos = [];
  List<PuntoInteres> _eventosFiltrados = [];
  StreamSubscription? _subPuntos;
  Timer? _tickerEstado;

  PuntoInteres? _eventoSeleccionado;
  String _filtroFecha = 'todos';
  LatLng? _miUbicacion;

  // ✅ AHORA SÍ, dentro del State
  bool get _esAdmin =>
      FirebaseAuth.instance.currentUser?.email == 'admin@pacha.com';

  static const _filtros = <Map<String, String>>[
    {'id': 'todos', 'label': 'Todos'},
    {'id': 'hoy', 'label': 'Hoy'},
    {'id': 'semana', 'label': 'Esta semana'},
    {'id': 'mes', 'label': 'Este mes'},
  ];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
    _subPuntos = _storage.streamPuntos().listen((data) {
      if (mounted) {
        setState(() {
          _todosLosPuntos = data;
          _actualizarLista();
          // 🔍 Diagnóstico: mirá la consola cuando crees un evento
          debugPrint('🔍 Puntos totales: ${data.length} · '
              'Eventos (categoría): ${data.where((p) => p.categoria == 'evento').length} · '
              'Eventos visibles: ${_eventosFiltrados.length}');
        });
      }
    });
    _tickerEstado = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subPuntos?.cancel();
    _tickerEstado?.cancel();
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() => _miUbicacion = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}
  }

  void _actualizarLista() {
    final ahora = DateTime.now();
    final inicioHoy =
        DateTime(ahora.year, ahora.month, ahora.day).millisecondsSinceEpoch;
    final finHoy = inicioHoy + const Duration(days: 1).inMilliseconds;
    final finSemana = inicioHoy + const Duration(days: 7).inMilliseconds;
    final finMes = inicioHoy + const Duration(days: 30).inMilliseconds;
    final query = _busquedaCtrl.text.trim().toLowerCase();

    _eventosFiltrados = _todosLosPuntos.where((p) {
      if (p.categoria != 'evento') return false;

      if (p.fechaFin != null && p.fechaFin! < ahora.millisecondsSinceEpoch) {
        return false;
      }

      if (_filtroFecha != 'todos') {
        final inicio = p.fechaInicio;
        if (inicio == null) return false;
        final fin =
            p.fechaFin ?? (inicio + const Duration(hours: 3).inMilliseconds);

        if (_filtroFecha == 'hoy') {
          if (fin < inicioHoy || inicio >= finHoy) return false;
        } else if (_filtroFecha == 'semana') {
          if (fin < inicioHoy || inicio >= finSemana) return false;
        } else if (_filtroFecha == 'mes') {
          if (fin < inicioHoy || inicio >= finMes) return false;
        }
      }

      if (query.isNotEmpty && !p.nombre.toLowerCase().contains(query)) {
        return false;
      }

      return true;
    }).toList();

    _eventosFiltrados.sort((a, b) {
      final aLive = _estaEnVivo(a);
      final bLive = _estaEnVivo(b);
      if (aLive != bLive) return aLive ? -1 : 1;
      if (a.fechaInicio == null) return 1;
      if (b.fechaInicio == null) return -1;
      return a.fechaInicio!.compareTo(b.fechaInicio!);
    });

    if (_eventoSeleccionado != null &&
        !_eventosFiltrados.any((e) => e.id == _eventoSeleccionado!.id)) {
      _eventoSeleccionado = null;
    }
  }

  bool _estaEnVivo(PuntoInteres evento) {
    if (evento.fechaInicio == null) return false;
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final inicio = evento.fechaInicio!;
    final fin =
        evento.fechaFin ?? (inicio + const Duration(hours: 3).inMilliseconds);
    return ahora >= inicio && ahora <= fin;
  }

  String _formatearFecha(int? timestamp) {
    if (timestamp == null) return 'Fecha a confirmar';
    final fecha = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final ahora = DateTime.now();
    final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
    final soloHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diffDias = soloFecha.difference(soloHoy).inDays;

    String diaStr;
    if (diffDias == 0) {
      diaStr = 'Hoy';
    } else if (diffDias == 1) {
      diaStr = 'Mañana';
    } else if (diffDias == -1) {
      diaStr = 'Ayer';
    } else if (diffDias > 1 && diffDias <= 7) {
      diaStr = 'En $diffDias días';
    } else {
      diaStr = '${fecha.day}/${fecha.month}';
    }

    final hora =
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    return '$diaStr · $hora hs';
  }

  String _formatearRango(PuntoInteres evento) {
    if (evento.fechaInicio == null) return 'Fecha a confirmar';
    if (evento.fechaFin == null) return _formatearFecha(evento.fechaInicio);

    final inicio = DateTime.fromMillisecondsSinceEpoch(evento.fechaInicio!);
    final fin = DateTime.fromMillisecondsSinceEpoch(evento.fechaFin!);
    final mismoDia = inicio.year == fin.year &&
        inicio.month == fin.month &&
        inicio.day == fin.day;

    if (mismoDia) {
      final horaInicio =
          '${inicio.hour.toString().padLeft(2, '0')}:${inicio.minute.toString().padLeft(2, '0')}';
      final horaFin =
          '${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}';
      final diaBase = _formatearFecha(evento.fechaInicio).split(' · ').first;
      return '$diaBase · $horaInicio a $horaFin hs';
    }

    return 'Del ${inicio.day}/${inicio.month} al ${fin.day}/${fin.month}';
  }

  String? _distanciaString(PuntoInteres evento) {
    if (_miUbicacion == null) return null;
    const Distance dist = Distance();
    final m = dist.as(LengthUnit.Meter, _miUbicacion!, evento.punto);
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

    void _irAColectivos(PuntoInteres evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColectivosY_Rutas(
          destinoInicial: evento.punto,
          nombreDestino: evento.nombre,
        ),
      ),
    );
  }

  Future<void> _compartirEvento(PuntoInteres evento) async {
    final texto = '🎉 ${evento.nombre}\n'
        '📅 ${_formatearRango(evento)}\n'
        '📍 https://www.google.com/maps/search/?api=1&query=${evento.lat},${evento.lng}\n\n'
        '¡Vamos a juntarnos! (vía Qué Pa Cha en Jujuy)';
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Texto copiado. Pegalo en WhatsApp o donde quieras.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // ✅ Editar evento (solo admin)
  Future<void> _editarEvento(PuntoInteres evento) async {
    final editado = await EditorPunto.editarEvento(context, evento);
    if (editado == null) return;
    await _storage.actualizarPunto(editado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Evento actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Eventos en la Ciudad',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_eventoSeleccionado != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _eventoSeleccionado = null),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildMiniMapa(),
          const SizedBox(height: 10),
          _buildBuscador(),
          const SizedBox(height: 8),
          _buildFiltros(),
          const SizedBox(height: 10),
          _buildEncabezadoLista(),
          const SizedBox(height: 8),
          Expanded(
            child: _eventosFiltrados.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 48, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text(
                            _todosLosPuntos.any((p) => p.categoria == 'evento')
                                ? 'No hay eventos que coincidan con el filtro'
                                : 'No hay eventos cargados todavía',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _eventosFiltrados.length,
                    itemBuilder: (context, index) =>
                        _buildEventItem(_eventosFiltrados[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 2),
    );
  }

  Widget _buildMiniMapa() {
    return Container(
      height: 250,
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
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tocá un evento de la lista para verlo',
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
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
                  child:
                      Icon(Icons.my_location, size: 16, color: Color(0xFF131622)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _busquedaCtrl,
        onChanged: (_) => setState(_actualizarLista),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar evento...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
          suffixIcon: _busquedaCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    setState(_actualizarLista);
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          fillColor: const Color(0xFF1E2235),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFFF7F6C)),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtros.length,
        itemBuilder: (context, index) {
          final f = _filtros[index];
          final isSel = _filtroFecha == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label']!, style: const TextStyle(fontSize: 12)),
              selected: isSel,
              selectedColor: const Color(0xFFFF7F6C),
              backgroundColor: const Color(0xFF1E2235),
              labelStyle: TextStyle(
                color: isSel ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (_) {
                setState(() {
                  _filtroFecha = f['id']!;
                  _actualizarLista();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEncabezadoLista() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PRÓXIMOS EVENTOS',
            style: TextStyle(
                fontSize: 10,
                color: Colors.white38,
                fontWeight: FontWeight.bold),
          ),
          Text(
            '${_eventosFiltrados.length} programados',
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF7F6C),
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeEstado(PuntoInteres evento) {
    if (evento.fechaInicio == null) {
      return _chip('A CONFIRMAR', Colors.grey);
    }
    if (_estaEnVivo(evento)) {
      return _chip('EN VIVO', Colors.redAccent, icon: Icons.fiber_manual_record);
    }
    final inicio = DateTime.fromMillisecondsSinceEpoch(evento.fechaInicio!);
    final soloFecha = DateTime(inicio.year, inicio.month, inicio.day);
    final ahora = DateTime.now();
    final soloHoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diff = soloFecha.difference(soloHoy).inDays;

    if (diff == 0) return _chip('HOY', Colors.greenAccent);
    if (diff == 1) return _chip('MAÑANA', Colors.amber);
    if (diff > 1 && diff <= 7) return _chip('EN $diff DÍAS', Colors.blueAccent);
    return _chip('${inicio.day}/${inicio.month}', Colors.white70);
  }

  Widget _chip(String txt, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 8, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            txt,
            style:
                TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(PuntoInteres evento) {
    final isSelected = _eventoSeleccionado?.id == evento.id;
    final vivo = _estaEnVivo(evento);
    final distancia = _distanciaString(evento);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _mapKey.currentState?.moverCamara(evento.punto, 16);
          } else {
            _eventoSeleccionado = evento;
            _mapKey.currentState?.moverCamara(evento.punto, 15);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E334D) : const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7F6C) : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 52,
                  decoration: BoxDecoration(
                    color: vivo
                        ? Colors.redAccent.withOpacity(0.2)
                        : const Color(0xFF2E334D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(evento.icono,
                      color: vivo ? Colors.redAccent : evento.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge + distancia + ✏️ editar
                      Row(
                        children: [
                          _buildBadgeEstado(evento),
                          const Spacer(),
                          if (distancia != null) ...[
                            const Icon(Icons.near_me,
                                size: 11, color: Colors.white38),
                            const SizedBox(width: 3),
                            Text(
                              distancia,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white54),
                            ),
                          ],
                          // ✅ Botón editar (solo admin)
                          if (_esAdmin) ...[
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Colors.amberAccent),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Editar evento',
                              onPressed: () => _editarEvento(evento),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        evento.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatearRango(evento),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (evento.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                evento.descripcion,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Divider(color: Colors.white12, height: 20),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                                TextButton.icon(
                  onPressed: () => _irAColectivos(evento),
                  icon: const Icon(Icons.directions_bus,
                      size: 15, color: Colors.teal),
                  label: const Text('Colectivo',
                      style: TextStyle(color: Colors.teal, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    MapLauncher.showAppChooser(
                      context: context,
                      lat: evento.lat,
                      lng: evento.lng,
                      nombreLugar: evento.nombre,
                    );
                  },
                  icon: const Icon(Icons.directions,
                      size: 15, color: Colors.greenAccent),
                  label: const Text('Cómo llegar',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _compartirEvento(evento),
                  icon: const Icon(Icons.share,
                      size: 15, color: Colors.purpleAccent),
                  label: const Text('Compartir',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_outlined), label: 'Colectivos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.place_outlined), label: 'Lugares'),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';
import 'widgets/editor_punto.dart';

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

  // Modos
  bool _modoAgregarPunto = false;
  bool _modoAgregarRuta = false;
  String? _categoriaForzada; // 'evento' | 'lugar' | null

  // Panel
  bool _panelAbierto = true;
  bool _panelExpandido = false;
  int _tabActual = 0; // 0=Eventos, 1=Lugares, 2=Rutas

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

  // ─── Tocar mapa (para colocar nuevo punto) ───
  void _alTocarMapa(LatLng punto) async {
  if (_modoAgregarPunto) {
    _confirmarUbicacionPunto(punto);
  }
}

void _confirmarUbicacionPunto(LatLng punto) {
  final cat = _categoriaForzada ?? 'lugar';
  setState(() {
    _modoAgregarPunto = false;
    _categoriaForzada = null;
    _panelAbierto = true;
  });
  _mostrarFormularioCreacion(punto, categoriaInicial: cat);
}

  // ─── Mover cámara + cerrar panel ───
  void _irAlPunto(LatLng punto) {
  // Solo centra el mapa, el panel queda como está
  _mapKey.currentState?.moverCamara(punto, 16);
}

  // ─── Agregar evento / lugar ───
  void _empezarAgregar(String categoria) {
    setState(() {
      _modoAgregarPunto = true;
      _modoAgregarRuta = false;
      _categoriaForzada = categoria;
      _panelAbierto = true;
    });
  }

  // ─── Agregar ruta (menú de opciones) ───
  void _empezarAgregarRuta() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Crear nueva ruta',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: Colors.teal),
              title: const Text('Trazar ruta manual (mira)',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Apuntá al centro del mapa y agregá puntos',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _modoAgregarRuta = true;
                  _modoAgregarPunto = false;
                  _panelAbierto = true;
                  _rutaEnProgreso.clear();
                  _paradasEnProgreso.clear();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: Colors.deepPurpleAccent),
              title: const Text('Pegar coordenadas',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Pegá las coordenadas una por línea',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _mostrarImportarRuta();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // EDITAR PUNTO
  // ══════════════════════════════════════════
  Future<void> _editarPunto(PuntoInteres p) async {
    PuntoInteres? editado;
    if (p.categoria == 'evento') {
      editado = await EditorPunto.editarEvento(context, p);
    } else {
      editado = await EditorPunto.editarLugar(context, p);
    }
    if (editado == null) return;
    await _storage.actualizarPunto(editado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Punto actualizado')));
    }
  }

  Future<void> _eliminarPunto(PuntoInteres p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('¿Eliminar?', style: TextStyle(color: Colors.white)),
        content: Text('Se va a eliminar "${p.nombre}".',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _storage.eliminarPunto(p.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Punto eliminado')));
    }
  }

  // ══════════════════════════════════════════
  // EDITAR / ELIMINAR RUTA
  // ══════════════════════════════════════════
  Future<void> _editarRuta(RutaColectivo r) async {
    final editada = await _mostrarEditarRuta(r);
    if (editada == null) return;
    await _storage.actualizarRuta(editada);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ruta actualizada')));
    }
  }

  Future<void> _eliminarRuta(RutaColectivo r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text('¿Eliminar ruta?',
            style: TextStyle(color: Colors.white)),
        content: Text('Se va a eliminar "${r.nombre}".',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _storage.eliminarRuta(r.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑️ Ruta eliminada')));
    }
  }

  // ─── Editar Ruta (diálogo existente, se reusa) ───
  Future<RutaColectivo?> _mostrarEditarRuta(RutaColectivo ruta) async {
    final nombreCtrl = TextEditingController(text: ruta.nombre);
    final empresaCtrl = TextEditingController(text: ruta.empresa);
    String categoria = ruta.categoriaRuta;
    int colorValue = ruta.colorValue;

    final colores = <int>[
      0xFFC51414, 0xFFF0F343, 0xFF00C853, 0xFF2979FF,
      0xFF9C27B0, 0xFFFF7F6C, 0xFFFFFFFF,
    ];

    return showDialog<RutaColectivo>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Editar ruta',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la línea'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: empresaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Empresa (opcional)',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: categoria,
                  dropdownColor: const Color(0xFF161925),
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(labelText: 'Pestaña (categoría)'),
                  items: const [
                    DropdownMenuItem(value: 'urbano', child: Text('Urbano')),
                    DropdownMenuItem(
                        value: 'santa_ana', child: Text('Santa Ana')),
                  ],
                  onChanged: (v) => setS(() => categoria = v!),
                ),
                const SizedBox(height: 16),
                const Text('Color del trazo',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colores.map((c) {
                    final sel = c == colorValue;
                    return GestureDetector(
                      onTap: () => setS(() => colorValue = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Trazo: ${ruta.puntosTrazo.length} pts · Paradas: ${ruta.paradas.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final n = nombreCtrl.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(
                  ctx,
                  ruta.copyWith(
                    nombre: n,
                    empresa: empresaCtrl.text.trim(),
                    categoriaRuta: categoria,
                    colorValue: colorValue,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // FORMULARIO DE CREACIÓN
  // ══════════════════════════════════════════
  void _mostrarFormularioCreacion(LatLng punto,
      {String categoriaInicial = 'lugar'}) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String categoriaPrincipal = categoriaInicial;
    String subcategoriaLugar = 'gastronomia';
    List<HorarioAtencion> horariosTemporales = [];
    DateTime? fechaInicioEvento;
    DateTime? fechaFinEvento;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      categoriaPrincipal == 'evento'
                          ? 'Nuevo Evento'
                          : 'Nuevo Lugar',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(labelText: 'Descripción breve'),
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: categoriaPrincipal,
                  dropdownColor: const Color(0xFF1E2235),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'lugar', child: Text('Lugar')),
                    DropdownMenuItem(value: 'evento', child: Text('Evento')),
                  ],
                  onChanged: (v) =>
                      setModalState(() => categoriaPrincipal = v!),
                ),
                if (categoriaPrincipal == 'lugar') ...[
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: subcategoriaLugar,
                    dropdownColor: const Color(0xFF1E2235),
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'Categoría de lugar'),
                    items: const [
                      DropdownMenuItem(
                          value: 'gastronomia', child: Text('Gastronomía')),
                      DropdownMenuItem(
                          value: 'recreacion', child: Text('Recreación')),
                      DropdownMenuItem(
                          value: 'deportes', child: Text('Deportes')),
                      DropdownMenuItem(value: 'cultura', child: Text('Cultura')),
                      DropdownMenuItem(value: 'compras', child: Text('Compras')),
                    ],
                    onChanged: (v) =>
                        setModalState(() => subcategoriaLugar = v!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Horarios',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () async {
                          final h = await _agregarHorario(context);
                          if (h != null) setModalState(() => horariosTemporales.add(h));
                        },
                        icon: const Icon(Icons.add,
                            color: Color(0xFFFF7F6C), size: 18),
                        label: const Text('Agregar',
                            style: TextStyle(color: Color(0xFFFF7F6C))),
                      ),
                    ],
                  ),
                  if (horariosTemporales.isEmpty)
                    const Text('Sin horarios cargados.',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 12)),
                  ...horariosTemporales.map((h) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.access_time,
                            color: Colors.white54, size: 18),
                        title: Text('${h.dia}: ${h.apertura} - ${h.cierre}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent, size: 18),
                          onPressed: () =>
                              setModalState(() => horariosTemporales.remove(h)),
                        ),
                      )),
                ],
                if (categoriaPrincipal == 'evento') ...[
                  const SizedBox(height: 20),
                  const Text('Fechas',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (date == null) return;
                            if (!context.mounted) return;
                            final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now());
                            if (time == null) return;
                            setModalState(() => fechaInicioEvento = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute));
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            fechaInicioEvento == null
                                ? 'Inicio'
                                : '${fechaInicioEvento!.day}/${fechaInicioEvento!.month} '
                                    '${fechaInicioEvento!.hour}:${fechaInicioEvento!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E334D)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 365)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (date == null) return;
                            if (!context.mounted) return;
                            final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now());
                            if (time == null) return;
                            setModalState(() => fechaFinEvento = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute));
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            fechaFinEvento == null
                                ? 'Fin'
                                : '${fechaFinEvento!.day}/${fechaFinEvento!.month} '
                                    '${fechaFinEvento!.hour}:${fechaFinEvento!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E334D)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
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
                        iconoFinal = Icons.event;
                        colorFinal = Colors.pinkAccent;
                      } else {
                        iconoFinal = Icons.place;
                        colorFinal = Colors.blueAccent;
                      }
                      final nuevoPunto = PuntoInteres(
                        id: '',
                        nombre: nombreCtrl.text.trim(),
                        descripcion: descCtrl.text.trim(),
                        lat: punto.latitude,
                        lng: punto.longitude,
                        iconoCode: iconoFinal.codePoint,
                        colorValue: colorFinal.value,
                        categoria: categoriaPrincipal,
                        categoriaLugar:
                            categoriaPrincipal == 'lugar' ? subcategoriaLugar : '',
                        horarios: horariosTemporales,
                        fechaInicio: fechaInicioEvento?.millisecondsSinceEpoch,
                        fechaFin: fechaFinEvento?.millisecondsSinceEpoch,
                      );
                      await _storage.guardarPunto(nuevoPunto);
                      if (!mounted) return;
                      setState(() {
                        _tabActual = categoriaPrincipal == 'evento' ? 0 : 1;
                        _panelAbierto = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Guardado en la nube')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F6C),
                      foregroundColor: const Color(0xFF131622),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('GUARDAR',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<HorarioAtencion?> _agregarHorario(BuildContext context) async {
    String diaSeleccionado = 'Lunes';
    TimeOfDay? horaApertura, horaCierre;
    return showDialog<HorarioAtencion>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Nuevo Horario',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: diaSeleccionado,
                dropdownColor: const Color(0xFF161925),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Día'),
                items: ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setS(() => diaSeleccionado = v!),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0));
                        if (t != null) setS(() => horaApertura = t);
                      },
                      child: Text(
                        horaApertura == null
                            ? 'Apertura'
                            : 'Abre: ${horaApertura!.format(context)}',
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 20, minute: 0));
                        if (t != null) setS(() => horaCierre = t);
                      },
                      child: Text(
                        horaCierre == null
                            ? 'Cierre'
                            : 'Cierra: ${horaCierre!.format(context)}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (horaApertura != null && horaCierre != null) {
                  Navigator.pop(
                      context,
                      HorarioAtencion(
                        dia: diaSeleccionado,
                        apertura: horaApertura!.format(context),
                        cierre: horaCierre!.format(context),
                      ));
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Importar ruta desde texto (existente) ───
  void _mostrarImportarRuta() {
    final textoCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    String categoriaRuta = 'urbano';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Importar ruta desde texto',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Coordenadas (una por línea: lat, lng)',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                TextField(
                  controller: textoCtrl,
                  maxLines: 5,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: '-24.1858, -65.2995\n...',
                    hintStyle: TextStyle(color: Colors.white24),
                    border: OutlineInputBorder(),
                    fillColor: Color(0xFF1E2235),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la línea'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: categoriaRuta,
                  dropdownColor: const Color(0xFF1E2235),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Empresa'),
                  items: const [
                    DropdownMenuItem(value: 'urbano', child: Text('Urbano')),
                    DropdownMenuItem(
                        value: 'santa_ana', child: Text('Santa Ana')),
                  ],
                  onChanged: (v) => setS(() => categoriaRuta = v!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (textoCtrl.text.isEmpty || nombreCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Completá nombre y coordenadas')));
                        return;
                      }
                      Navigator.pop(ctx);
                      _procesarTextoCoordenadas(
                          textoCtrl.text, nombreCtrl.text, categoriaRuta);
                    },
                    icon: const Icon(Icons.settings_ethernet),
                    label: const Text('PROCESAR',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F6C),
                      foregroundColor: const Color(0xFF131622),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _procesarTextoCoordenadas(
      String texto, String nombreRuta, String categoria) {
    final puntos = <LatLng>[];
    for (var linea in texto.split('\n')) {
      if (!linea.contains(',')) continue;
      final partes = linea.split(',');
      if (partes.length < 2) continue;
      try {
        puntos.add(LatLng(
            double.parse(partes[0].trim()), double.parse(partes[1].trim())));
      } catch (_) {}
    }
    if (puntos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay coordenadas válidas')));
      return;
    }
    _mostrarConfiguracionPuntosExtraidos(puntos, nombreRuta, categoria);
  }

  void _mostrarConfiguracionPuntosExtraidos(
      List<LatLng> puntos, String nombreRuta, String categoria) {
    List<bool> esParadaList = List.generate(puntos.length, (i) => false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Marca las paradas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const Text('Activá el switch solo en las paradas reales',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: puntos.length,
                  itemBuilder: (_, i) => SwitchListTile(
                    title: Text('Punto ${i + 1}',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                        '${puntos[i].latitude}, ${puntos[i].longitude}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                    activeColor: Colors.greenAccent,
                    value: esParadaList[i],
                    onChanged: (v) => setS(() => esParadaList[i] = v),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final paradas = <LatLng>[];
                      for (int i = 0; i < puntos.length; i++) {
                        if (esParadaList[i]) paradas.add(puntos[i]);
                      }
                      final nuevaRuta = RutaColectivo(
                        id: '',
                        nombre: nombreRuta,
                        puntosTrazo: puntos,
                        paradas: paradas,
                        colorValue: Colors.deepPurpleAccent.value,
                        categoriaRuta: categoria,
                      );
                      await _storage.guardarRuta(nuevaRuta);
                      if (!mounted) return;
                      setState(() {
                        _tabActual = 2;
                        _panelAbierto = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Ruta guardada')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Text('GUARDAR RUTA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Modo ruta manual ───
  void _agregarPuntoConMira() {
    final centro = _mapKey.currentState?.getCentroActual();
    if (centro == null) return;
    setState(() {
      _rutaEnProgreso.add(centro);
      if (_modoEsParada) _paradasEnProgreso.add(centro);
    });
  }

  void _deshacerUltimoPunto() {
    if (_rutaEnProgreso.isEmpty) return;
    setState(() {
      final u = _rutaEnProgreso.removeLast();
      _paradasEnProgreso.remove(u);
    });
  }

  void _guardarRutaEnProgreso() async {
    if (_rutaEnProgreso.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agregá al menos 2 puntos')));
      return;
    }
    final ctrl = TextEditingController();
    String cat = 'urbano';
    final nombre = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Guardar Ruta',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration:
                    const InputDecoration(labelText: 'Nombre de la línea'),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: cat,
                dropdownColor: const Color(0xFF161925),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Empresa'),
                items: const [
                  DropdownMenuItem(value: 'urbano', child: Text('Urbano')),
                  DropdownMenuItem(value: 'santa_ana', child: Text('Santa Ana')),
                ],
                onChanged: (v) => setS(() => cat = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (nombre == null || nombre.isEmpty) return;
    final nueva = RutaColectivo(
      id: '',
      nombre: nombre,
      puntosTrazo: List.from(_rutaEnProgreso),
      paradas: List.from(_paradasEnProgreso),
      colorValue: Colors.deepPurpleAccent.value,
      categoriaRuta: cat,
    );
    await _storage.guardarRuta(nueva);
    if (!mounted) return;
    setState(() {
      _rutaEnProgreso.clear();
      _paradasEnProgreso.clear();
      _modoAgregarRuta = false;
      _tabActual = 2;
      _panelAbierto = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Ruta "$nombre" guardada')));
  }

  void _cancelarRuta() {
    setState(() {
      _rutaEnProgreso.clear();
      _paradasEnProgreso.clear();
      _modoAgregarRuta = false;
      _panelAbierto = true;
    });
  }

  // ══════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
final h = MediaQuery.of(context).size.height;
final double panelHeight;
if (_modoAgregarRuta) {
  panelHeight = h * 0.38;
} else if (_modoAgregarPunto) {
  panelHeight = h * 0.32;
} else if (!_panelAbierto) {
  panelHeight = 0;
} else {
  panelHeight = h * 0.45; // siempre 45%, sin expansión
}

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Mapa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ═══ MAPA ═══
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
              modoAgregarRuta: false,
              rutaEnProgreso: _rutaEnProgreso,
              onMapTap: _alTocarMapa,
            ),
          ),

          // ═══ CHIPS ARRIBA ═══
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _chip('Rutas', _mostrarRutas,
                      (v) => setState(() => _mostrarRutas = v)),
                  const SizedBox(width: 8),
                  _chip('Lugares', _mostrarLugares,
                      (v) => setState(() => _mostrarLugares = v)),
                  const SizedBox(width: 8),
                  _chip('Eventos', _mostrarEventos,
                      (v) => setState(() => _mostrarEventos = v)),
                ],
              ),
            ),
          ),

          // ═══ CROSSHAIR (mira) — para agregar punto O trazar ruta ═══
if (_modoAgregarRuta || _modoAgregarPunto)
  Positioned.fill(
    child: IgnorePointer(
      child: Stack(
        children: [
          // El + está EXACTAMENTE en el centro del mapa
          const Center(
            child: Icon(
              Icons.add,
              size: 44,
              color: Colors.blueAccent,
              shadows: [
                Shadow(color: Colors.black45, blurRadius: 6),
                Shadow(color: Colors.white, blurRadius: 2),
              ],
            ),
          ),
          // El texto va DEBAJO del +, no lo empuja
          Align(
            alignment: const Alignment(0, 0.15),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _modoAgregarRuta
                    ? 'Apunta y confirma'
                    : 'Ubicá el ${_categoriaForzada ?? "punto"}',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  ),

          // ═══ FAB Mi Ubicación ═══
Positioned(
  right: 16,
  bottom: _panelAbierto ? panelHeight + 16 : 70,
  child: FloatingActionButton(
    heroTag: 'mi_ubicacion',
    backgroundColor: const Color(0xFF161925),
    foregroundColor: const Color(0xFFFF7F6C),
    onPressed: () => _mapKey.currentState?.centrarEnMiUbicacion(),
    child: const Icon(Icons.my_location),
  ),
),

          // ═══ MINI-BARRA para reabrir el panel ═══
if (!_panelAbierto && !_modoAgregarRuta && !_modoAgregarPunto)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: GestureDetector(
      onTap: () => setState(() => _panelAbierto = true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF161925),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up,
                    color: Colors.white54, size: 18),
                SizedBox(width: 4),
                Text('Abrir panel',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ),
  ),

          // ═══ PANEL INFERIOR ═══
          if (panelHeight > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: panelHeight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: const BoxDecoration(
                  color: Color(0xFF161925),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 12)
                  ],
                ),
                child: _modoAgregarRuta
    ? _buildPanelTrazarRuta()
    : _modoAgregarPunto
        ? _buildPanelAgregarPunto()
        : _buildPanelTabs(),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PANEL CON TABS
  // ══════════════════════════════════════════
  Widget _buildPanelTabs() {
    return DefaultTabController(
  length: 3,
  initialIndex: _tabActual,
      child: Column(
        children: [
         // Header — tap para OCULTAR el panel
GestureDetector(
  onTap: () => setState(() => _panelAbierto = false),
  behavior: HitTestBehavior.opaque,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 4),
        const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.white38,
          size: 20,
        ),
      ],
    ),
  ),
),
          // Tabs
          TabBar(
            onTap: (i) => setState(() => _tabActual = i),
            labelColor: const Color(0xFFFF7F6C),
            unselectedLabelColor: Colors.white54,
            indicatorColor: const Color(0xFFFF7F6C),
            tabs: const [
              Tab(text: 'Eventos'),
              Tab(text: 'Lugares'),
              Tab(text: 'Rutas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTabEventos(),
                _buildTabLugares(),
                _buildTabRutas(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab Eventos ───
  Widget _buildTabEventos() {
    final eventos = _puntos.where((p) => p.categoria == 'evento').toList();
    return _tabLayout(
      ayuda:
          '📍 Estos son los eventos del mapa. Tocá uno para verlo centrado, ✏️ para editar o 🗑️ para eliminar.',
      items: eventos,
      empty: 'Todavía no hay eventos creados',
      itemBuilder: (p) => _itemPunto(p),
      textoBoton: 'Crear nuevo evento',
      colorBoton: Colors.pinkAccent,
      onCrear: () => _empezarAgregar('evento'),
    );
  }

  // ─── Tab Lugares ───
  Widget _buildTabLugares() {
    final lugares = _puntos.where((p) => p.categoria == 'lugar').toList();
    return _tabLayout(
      ayuda:
          '📍 Estos son los lugares del mapa. Tocá uno para verlo centrado, ✏️ para editar o 🗑️ para eliminar.',
      items: lugares,
      empty: 'Todavía no hay lugares creados',
      itemBuilder: (p) => _itemPunto(p),
      textoBoton: 'Crear nuevo lugar',
      colorBoton: Colors.blueAccent,
      onCrear: () => _empezarAgregar('lugar'),
    );
  }

  // ─── Tab Rutas ───
  Widget _buildTabRutas() {
    return _tabLayout(
      ayuda:
          '🚌 Estas son las líneas del mapa. Tocá una para verla centrada, ✏️ para editar o 🗑️ para eliminar.',
      items: _rutas,
      empty: 'Todavía no hay rutas creadas',
      itemBuilder: (r) => _itemRuta(r),
      textoBoton: 'Crear nueva ruta',
      colorBoton: Colors.teal,
      onCrear: _empezarAgregarRuta,
    );
  }

  // ─── Layout genérico de tab ───
  Widget _tabLayout<T>({
    required String ayuda,
    required List<T> items,
    required String empty,
    required Widget Function(T) itemBuilder,
    required String textoBoton,
    required Color colorBoton,
    required VoidCallback onCrear,
  }) {
    return Column(
      children: [
        // Texto de ayuda
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFFF7F6C), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ayuda,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.3)),
                ),
              ],
            ),
          ),
        ),
        // Lista
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox,
                            size: 40, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(empty,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 13),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (_, i) => itemBuilder(items[i]),
                ),
        ),
        // Botón crear
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add, size: 20),
              label: Text(textoBoton,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorBoton,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Item de punto (evento o lugar) ───
  Widget _itemPunto(PuntoInteres p) {
    final subtitulo = p.categoria == 'evento'
        ? (p.fechaInicio != null
            ? _formatearFecha(p.fechaInicio!)
            : 'Sin fecha')
        : p.categoriaLugar;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E334D),
          child: Icon(p.icono, color: p.color, size: 20),
        ),
        title: Text(p.nombre,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        subtitle: Text(subtitulo,
            style:
                const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit,
                  color: Colors.amberAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _editarPunto(p),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete,
                  color: Colors.redAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _eliminarPunto(p),
            ),
          ],
        ),
        onTap: () => _irAlPunto(p.punto),
      ),
    );
  }

  // ─── Item de ruta ───
  Widget _itemRuta(RutaColectivo r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E334D),
          child: Icon(Icons.alt_route, color: r.color, size: 20),
        ),
        title: Text(r.nombre,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${r.empresa.isNotEmpty ? "${r.empresa} · " : ""}${r.categoriaRuta == 'santa_ana' ? "Santa Ana" : "Urbano"}',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit,
                  color: Colors.amberAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _editarRuta(r),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete,
                  color: Colors.redAccent, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _eliminarRuta(r),
            ),
          ],
        ),
        onTap: () {
          if (r.puntosTrazo.isNotEmpty) _irAlPunto(r.puntosTrazo.first);
        },
      ),
    );
  }

  String _formatearFecha(int ts) {
    final fecha = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${fecha.day}/${fecha.month}/${fecha.year} · '
        '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════
// PANEL CUANDO ESTÁ UBICANDO PUNTO (evento/lugar)
// ══════════════════════════════════════════
Widget _buildPanelAgregarPunto() {
  final cat = _categoriaForzada ?? 'lugar';
  final esEvento = cat == 'evento';
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              esEvento ? Icons.event : Icons.place,
              color: esEvento ? Colors.pinkAccent : Colors.blueAccent,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Ubicando nuevo ${esEvento ? "evento" : "lugar"}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Movés el mapa hasta que el + quede sobre el lugar exacto, y tocás Confirmar.',
          style: TextStyle(
              color: Colors.white54, fontSize: 12, height: 1.3),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              final centro = _mapKey.currentState?.getCentroActual();
              if (centro == null) return;
              _confirmarUbicacionPunto(centro);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('CONFIRMAR UBICACIÓN',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  esEvento ? Colors.pinkAccent : Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: () => setState(() {
              _modoAgregarPunto = false;
              _categoriaForzada = null;
              _panelAbierto = true;
            }),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Cancelar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ══════════════════════════════════════════
  // PANEL CUANDO ESTÁ TRAZANDO RUTA
  // ══════════════════════════════════════════
  Widget _buildPanelTrazarRuta() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              const Text('Trazando ruta',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_rutaEnProgreso.length} pts',
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.white),
                tooltip: 'Deshacer',
                onPressed: _deshacerUltimoPunto,
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Próximo punto es PARADA',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: const Text('Apagalo si es solo una curva',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            activeColor: Colors.greenAccent,
            value: _modoEsParada,
            onChanged: (v) => setState(() => _modoEsParada = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _agregarPuntoConMira,
              icon: const Icon(Icons.gps_fixed),
              label: const Text('AGREGAR PUNTO EN LA MIRA',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _guardarRutaEnProgreso,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _cancelarRuta,
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancelar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Chip arriba ───
  Widget _chip(String label, bool value, Function(bool) onChanged) {
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              color: value ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      selected: value,
      selectedColor: const Color(0xFFFF7F6C),
      backgroundColor: const Color(0xFF161925).withOpacity(0.9),
      checkmarkColor: Colors.black,
      onSelected: onChanged,
      elevation: 3,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24)),
    );
  }
}
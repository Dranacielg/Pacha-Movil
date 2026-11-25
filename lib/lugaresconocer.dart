import 'dart:async';
import 'widgets/resena_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';
import 'utils/map_launcher.dart';
import 'colectivosyrutas.dart';


class LugaresConocerScreen extends StatefulWidget {
  const LugaresConocerScreen({super.key});

  @override
  State<LugaresConocerScreen> createState() => _LugaresConocerScreenState();
}

class _LugaresConocerScreenState extends State<LugaresConocerScreen> {
  static const Color _bgColor = Color(0xFFF2F4FC);
  static const Color _headerBlue = Color(0xFF2357B8);
  static const Color _headerDarkBlue = Color(0xFF173B82);
  static const Color _primaryPurple = Color(0xFF6B35D9);

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

  bool get _esAdmin =>
      FirebaseAuth.instance.currentUser?.email == 'admin@pacha.com';

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
        p.categoria == 'lugar' &&
        p.categoriaLugar == _categoriaSeleccionada).toList();

    if (_lugarSeleccionado != null &&
        !_lugaresFiltrados.any((e) => e.id == _lugarSeleccionado!.id)) {
      _lugarSeleccionado = null;
    }
  }

  bool _estaAbierto(PuntoInteres lugar) {
    if (lugar.horarios.isEmpty) return true;
    final now = DateTime.now();
    final dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    final diaHoy = dias[now.weekday - 1];
    final ahoraMin = now.hour * 60 + now.minute;

    for (var h in lugar.horarios.where((h) => h.dia == diaHoy)) {
      try {
        int parseTime(String s) {
          String clean = s.toLowerCase();
          bool isPM = clean.contains('pm') || clean.contains('p. m.');
          clean = clean
              .replaceAll('a. m.', '')
              .replaceAll('p. m.', '')
              .replaceAll('am', '')
              .replaceAll('pm', '')
              .trim();
          final parts = clean.split(':');
          int hr = int.parse(parts[0]);
          int mn = parts.length > 1 ? int.parse(parts[1]) : 0;
          if (isPM && hr < 12) hr += 12;
          if (!isPM && hr == 12) hr = 0;
          return hr * 60 + mn;
        }

        final ini = parseTime(h.apertura);
        final fin = parseTime(h.cierre);
        if (ini == fin) return true;
        if (fin < ini) {
          if (ahoraMin >= ini || ahoraMin <= fin) return true;
        } else {
          if (ahoraMin >= ini && ahoraMin <= fin) return true;
        }
      } catch (_) {}
    }
    return false;
  }

  List<Resena> _resenasOrdenadas(List<Resena> resenas) {
    final copia = List<Resena>.from(resenas);
    copia.sort((a, b) {
      final fa = a.fecha ?? 0;
      final fb = b.fecha ?? 0;
      return fb.compareTo(fa);
    });
    return copia;
  }

  void _irAColectivos(PuntoInteres lugar) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColectivosY_Rutas(
          destinoInicial: lugar.punto,
          nombreDestino: lugar.nombre,
        ),
      ),
    );
  }

  Future<Resena?> _crearResena(PuntoInteres lugar,
      {Resena? existente}) async {
    final nueva = await showModalBottomSheet<Resena>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ResenaModal(lugar: lugar, existente: existente),
    );
    if (nueva == null) return null;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? user?.email ?? '';
    return Resena(
      usuario: nueva.usuario,
      usuarioId: userId,
      comentario: nueva.comentario,
      estetica: nueva.estetica,
      atencion: nueva.atencion,
      servicios: nueva.servicios,
      fecha: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<PuntoInteres> _guardarResena(
      PuntoInteres lugar, Resena resena, StateSetter setSheetState) async {
    final actualizadas = List<Resena>.from(lugar.resenas);

    final index = actualizadas.indexWhere(
      (r) => r.usuarioId.isNotEmpty && r.usuarioId == resena.usuarioId,
    );
    final esEdicion = index >= 0;
    if (esEdicion) {
      actualizadas[index] = resena;
    } else {
      actualizadas.add(resena);
    }

    final lugarActualizado = _clonarLugar(lugar, resenas: actualizadas);
    await _storage.actualizarPunto(lugarActualizado);
    setSheetState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(esEdicion
              ? '✏️ Tu reseña fue actualizada'
              : '¡Gracias por tu reseña!'),
        ),
      );
    }
    return lugarActualizado;
  }

  Future<PuntoInteres?> _eliminarResena(
      PuntoInteres lugar, Resena resena, StateSetter setSheetState) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('¿Eliminar reseña?',
            style: TextStyle(color: _headerDarkBlue)),
        content: Text(
          'La reseña de "${resena.usuario}" se va a borrar.\n'
          'Esto no se puede deshacer.',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return null;

    final actualizadas = lugar.resenas.where((r) => r != resena).toList();
    final lugarActualizado = _clonarLugar(lugar, resenas: actualizadas);
    await _storage.actualizarPunto(lugarActualizado);
    setSheetState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Reseña eliminada')),
      );
    }
    return lugarActualizado;
  }

  PuntoInteres _clonarLugar(PuntoInteres l, {List<Resena>? resenas}) {
    return PuntoInteres(
      id: l.id,
      nombre: l.nombre,
      descripcion: l.descripcion,
      lat: l.lat,
      lng: l.lng,
      iconoCode: l.iconoCode,
      colorValue: l.colorValue,
      categoria: l.categoria,
      categoriaLugar: l.categoriaLugar,
      horarios: l.horarios,
      resenas: resenas ?? l.resenas,
      fechaInicio: l.fechaInicio,
      fechaFin: l.fechaFin,
    );
  }

  bool _puedeEliminarResena(Resena r) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    if (user.email == 'admin@pacha.com') return true;
    return r.usuarioId.isNotEmpty && r.usuarioId == user.uid;
  }

  void _mostrarDetalleLugar(PuntoInteres lugar) {
    setState(() => _lugarSeleccionado = lugar);
    _mapKey.currentState?.moverCamara(lugar.punto, 16);

    PuntoInteres lugarLocal = lugar;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _buildDetalleLugar(
              lugarLocal,
              scrollCtrl,
              setSheetState,
              onLugarActualizado: (nuevo) {
                lugarLocal = nuevo;
                setSheetState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleLugar(
    PuntoInteres lugar,
    ScrollController scrollCtrl,
    StateSetter setSheetState, {
    ValueChanged<PuntoInteres>? onLugarActualizado,
  }) {
    final abierto = _estaAbierto(lugar);
    final resenasOrd = _resenasOrdenadas(lugar.resenas);
    final puedeResenar = _permiteResenas(lugar.categoriaLugar);

    return ListView(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_up, size: 12, color: Colors.black45),
              SizedBox(width: 4),
              Text(
                'Deslizá arriba para ampliar · abajo para achicar',
                style: TextStyle(color: Colors.black45, fontSize: 10),
              ),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 12, color: Colors.black45),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(lugar.icono, color: lugar.color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: abierto
                              ? Colors.green.withValues(alpha: 0.14)
                              : Colors.red.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: abierto ? Colors.green : Colors.red,
                              width: 0.7),
                        ),
                        child: Text(
                          abierto ? 'ABIERTO' : 'CERRADO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: abierto
                                  ? Colors.green.shade800
                                  : Colors.red.shade700),
                        ),
                      ),
                      const Spacer(),
                      if (lugar.categoriaLugar.isNotEmpty)
                        Text(
                          lugar.categoriaLugar.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.black45,
                              fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lugar.nombre,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _headerDarkBlue),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (lugar.resenas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                lugar.puntuacionPromedio.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${lugar.resenas.length} reseña${lugar.resenas.length == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],

        if (lugar.descripcion.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            lugar.descripcion,
            style: const TextStyle(
                color: Colors.black87, fontSize: 14, height: 1.4),
          ),
        ],

        if (lugar.horarios.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('HORARIOS',
              style: TextStyle(
                  fontSize: 11,
                  color: _headerDarkBlue,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lugar.horarios.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: _headerBlue),
                    const SizedBox(width: 8),
                    Text(
                      h.dia,
                      style: const TextStyle(
                          color: _headerDarkBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text('${h.apertura} - ${h.cierre}',
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 13)),
                  ],
                ),
              )),
        ],

        const SizedBox(height: 20),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _irAColectivos(lugar),
              icon: const Icon(Icons.directions_bus,
                  size: 16, color: _headerBlue),
              label: const Text('Colectivo',
                  style: TextStyle(color: _headerBlue, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _headerBlue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => MapLauncher.showAppChooser(
                context: context,
                lat: lugar.lat,
                lng: lugar.lng,
                nombreLugar: lugar.nombre,
              ),
              icon: const Icon(Icons.directions,
                  size: 16, color: Colors.green),
              label: const Text('Cómo llegar',
                  style: TextStyle(color: Colors.green, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            if (puedeResenar)
              Builder(builder: (_) {
                final user = FirebaseAuth.instance.currentUser;
                final userId = user?.uid ?? user?.email ?? '';
                Resena? miResena;
                for (final r in lugar.resenas) {
                  if (r.usuarioId.isNotEmpty && r.usuarioId == userId) {
                    miResena = r;
                    break;
                  }
                }

                final esEdicion = miResena != null;
                return OutlinedButton.icon(
                  onPressed: () async {
                    final nueva =
                        await _crearResena(lugar, existente: miResena);
                    if (nueva == null) return;
                    final actualizado =
                        await _guardarResena(lugar, nueva, setSheetState);
                    onLugarActualizado?.call(actualizado);
                  },
                  icon: Icon(
                    esEdicion ? Icons.edit : Icons.rate_review,
                    size: 16,
                    color: _primaryPurple,
                  ),
                  label: Text(
                    esEdicion ? 'Editar mi reseña' : 'Dejar reseña',
                    style: const TextStyle(
                        color: _primaryPurple, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryPurple),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                );
              }),
          ],
        ),

        const SizedBox(height: 20),

        if (puedeResenar) ...[
          const Divider(color: Colors.black12),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('RESEÑAS',
                  style: TextStyle(
                      fontSize: 11,
                      color: _headerDarkBlue,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('(${lugar.resenas.length})',
                  style: const TextStyle(
                      fontSize: 11,
                      color: _headerDarkBlue,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (lugar.resenas.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      color: Colors.black38, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Todavía no hay reseñas. ¡Sé el primero!',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            ...resenasOrd.map((r) => _buildResenaCard(
                  r, lugar, setSheetState,
                  onLugarActualizado: onLugarActualizado,
                )),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildResenaCard(
      Resena r, PuntoInteres lugar, StateSetter setSheetState,
      {ValueChanged<PuntoInteres>? onLugarActualizado}) {
    final puedeBorrar = _puedeEliminarResena(r);
    final fechaStr = r.fecha != null ? _formatearFechaResena(r.fecha!) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Text(
                  r.usuario.isNotEmpty ? r.usuario[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: _primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.usuario,
                      style: const TextStyle(
                          color: _headerDarkBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          r.promedio.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                        if (fechaStr.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(fechaStr,
                              style: const TextStyle(
                                  color: Colors.black45, fontSize: 10)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (puedeBorrar)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.black45, size: 18),
                  padding: EdgeInsets.zero,
                  onSelected: (v) async {
                    if (v == 'del') {
                      final actualizado =
                          await _eliminarResena(lugar, r, setSheetState);
                      if (actualizado != null) {
                        onLugarActualizado?.call(actualizado);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'del',
                      child: Row(
                        children: [
                          Icon(Icons.delete,
                              color: Colors.redAccent, size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar',
                              style: TextStyle(
                                  color: Colors.redAccent, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (r.comentario.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              r.comentario,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 13, height: 1.4),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _miniPuntaje('Estética', r.estetica),
              _miniPuntaje('Atención', r.atencion),
              _miniPuntaje('Servicios', r.servicios),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniPuntaje(String label, double valor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style: const TextStyle(color: Colors.black54, fontSize: 10)),
        const Icon(Icons.star, color: Colors.amber, size: 10),
        const SizedBox(width: 1),
        Text(valor.toStringAsFixed(1),
            style: const TextStyle(color: Colors.amber, fontSize: 10)),
      ],
    );
  }

  String _formatearFechaResena(int ts) {
    final fecha = DateTime.fromMillisecondsSinceEpoch(ts);
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          _buildPanelSuperior(context),
          const SizedBox(height: 10),
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
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
                    puntos:
                        _lugarSeleccionado != null ? [_lugarSeleccionado!] : [],
                    rutas: const [],
                    modoAgregarPunto: false,
                  ),
                  if (_lugarSeleccionado == null)
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Tocá un lugar para verlo en el mapa',
                            style: TextStyle(
                                color: _headerDarkBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () =>
                          _mapKey.currentState?.centrarEnMiUbicacion(),
                      child: const CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.my_location,
                            size: 17, color: _headerBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final cat = _categorias[index];
                final isSel = _categoriaSeleccionada == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat['nombre']),
                    avatar: Icon(cat['icono'],
                        size: 16,
                        color: isSel ? Colors.white : _headerBlue),
                    selected: isSel,
                    selectedColor: _primaryPurple,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSel ? _primaryPurple : Colors.black12,
                      ),
                    ),
                    labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    onSelected: (_) {
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('LUGARES DISPONIBLES',
                    style: TextStyle(
                        fontSize: 11,
                        color: _headerDarkBlue,
                        fontWeight: FontWeight.bold)),
                Text('${_lugaresFiltrados.length} encontrados',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _primaryPurple,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _lugaresFiltrados.isEmpty
                ? const Center(
                    child: Text('No hay lugares en esta categoría',
                        style: TextStyle(color: Colors.black45)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _lugaresFiltrados.length,
                    itemBuilder: (context, index) =>
                        _buildLugarCard(_lugaresFiltrados[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 3),
    );
  }

  Widget _buildPanelSuperior(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_headerBlue, _headerDarkBlue],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26173B82),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                ),
              ),
              const Spacer(),
              if (_lugarSeleccionado != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _lugarSeleccionado = null),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qué Pa Cha en Jujuy',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lugares para Conocer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLugarCard(PuntoInteres lugar) {
    final abierto = _estaAbierto(lugar);
    final tieneResenas = _permiteResenas(lugar.categoriaLugar);

    return GestureDetector(
      onTap: () => _mostrarDetalleLugar(lugar),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _lugarSeleccionado?.id == lugar.id
                  ? _primaryPurple
                  : Colors.black12,
              width: _lugarSeleccionado?.id == lugar.id ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 52,
                  decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(10)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: abierto
                                  ? Colors.green.withValues(alpha: 0.14)
                                  : Colors.red.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: abierto ? Colors.green : Colors.red,
                                  width: 0.7),
                            ),
                            child: Text(
                              abierto ? 'ABIERTO' : 'CERRADO',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: abierto
                                      ? Colors.green.shade800
                                      : Colors.red.shade700),
                            ),
                          ),
                          const Spacer(),
                          if (tieneResenas && lugar.resenas.isNotEmpty) ...[
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${lugar.puntuacionPromedio.toStringAsFixed(1)} (${lugar.resenas.length})',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(lugar.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _headerDarkBlue)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.black38),
              ],
            ),
            if (lugar.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                lugar.descripcion,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 0.8)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryPurple,
        unselectedItemColor: Colors.black54,
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/menu');
          if (index == 1)
            Navigator.pushReplacementNamed(context, '/colectivos');
          if (index == 2) Navigator.pushReplacementNamed(context, '/eventos');
        },
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_outlined),
              label: 'Colectivos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined), label: 'Eventos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.place_outlined), label: 'Lugares'),
        ],
      ),
    );
  }
}
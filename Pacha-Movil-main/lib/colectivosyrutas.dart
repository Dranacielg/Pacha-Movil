import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';

class ColectivosY_Rutas extends StatefulWidget {
  final LatLng? destinoInicial;
  final String? nombreDestino;

  const ColectivosY_Rutas({
    super.key,
    this.destinoInicial,
    this.nombreDestino,
  });

  @override
  State<ColectivosY_Rutas> createState() => _ColectivosY_RutasState();
}

class _ColectivosY_RutasState extends State<ColectivosY_Rutas> {
  String lineaSeleccionada = 'Urbano';

  final MapStorage _storage = MapStorage();
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();

  List<PuntoInteres> _puntos = [];
  List<RutaColectivo> _rutas = [];
  StreamSubscription? _subPuntos;
  StreamSubscription? _subRutas;

  RutaColectivo? _rutaSeleccionada;

  LatLng? _destinoTocado;
  LatLng? _miUbicacion;
  List<LatLng> _paradasCercanasAlDestino = [];
  LatLng? _paradaSubida;
  LatLng? _paradaBajada;
  bool _calculandoRuta = false;
  bool _modoMira = false;

    @override
  void initState() {
    super.initState();
    if (widget.destinoInicial != null) {
      _destinoTocado = widget.destinoInicial;
      _calculandoRuta = true;
    }
    _inicializar();
    _subPuntos = _storage.streamPuntos().listen((data) {
      if (mounted) setState(() => _puntos = data);
    });
    _subRutas = _storage.streamRutas().listen((data) {
      if (mounted) setState(() => _rutas = data);
    });
  }

  Future<void> _inicializar() async {
    await _obtenerUbicacionActual();
    if (!mounted) return;
    if (widget.destinoInicial == null) return;

    if (_miUbicacion == null) {
      setState(() => _calculandoRuta = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Necesitamos tu ubicación GPS para calcular los colectivos'),
        ),
      );
      return;
    }

    if (widget.nombreDestino != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🚌 Buscando colectivos para ${widget.nombreDestino}...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // Pequeño delay para que la UI se renderice antes del modal
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _analizarDestino(widget.destinoInicial!);
  }

  @override
  void dispose() {
    _subPuntos?.cancel();
    _subRutas?.cancel();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) return;
            final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;
      setState(() => _miUbicacion = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      debugPrint("Error GPS: $e");
    }
  }

void _analizarDestino(LatLng destino) async {
  if (_miUbicacion == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Necesitamos tu ubicación GPS para calcular')));
    return;
  }
  setState(() {
    _destinoTocado = destino;
    _calculandoRuta = true;
    _rutaSeleccionada = null;
    _paradaSubida = null;
    _paradaBajada = null;
    _paradasCercanasAlDestino.clear();
    _modoMira = false;
  });

  const Distance dist = Distance();
  List<Map<String, dynamic>> resultados = [];

  // Parámetros
  const double maxCaminataSubida = 700; // cuánto aceptamos caminar hasta la parada
  const double maxCaminataBajada = 500; // cuánto aceptamos caminar desde la parada
  const double pesoPorParada = 15; // 15 "metros virtuales" por parada de recorrido

  for (var ruta in _rutas) {
    final paradas = ruta.paradas;
    if (paradas.length < 2) continue;

    // 1. Precalcular distancia al origen y al destino para cada parada
    final distOrigen = List<double>.filled(paradas.length, double.infinity);
    final distDestino = List<double>.filled(paradas.length, double.infinity);

    for (int i = 0; i < paradas.length; i++) {
      distOrigen[i] = dist.as(LengthUnit.Meter, paradas[i], _miUbicacion!);
      distDestino[i] = dist.as(LengthUnit.Meter, paradas[i], destino);
    }

    // 2. Buscar el mejor par (subida < bajada) por costo total
    double mejorCosto = double.infinity;
    int mejorSubida = -1;
    int mejorBajada = -1;

    for (int i = 0; i < paradas.length; i++) {
      if (distOrigen[i] > maxCaminataSubida) continue;

      // Pequeña optimización: si la subida ya supera el mejor costo, saltamos
      if (distOrigen[i] >= mejorCosto) continue;

      for (int j = i + 1; j < paradas.length; j++) {
        if (distDestino[j] > maxCaminataBajada) continue;

        // Costo: caminar a la subida + caminar desde la bajada
        // + penalización por la cantidad de paradas de recorrido entre i y j
        final costo = distOrigen[i] +
            distDestino[j] +
            (j - i) * pesoPorParada;

        if (costo < mejorCosto) {
          mejorCosto = costo;
          mejorSubida = i;
          mejorBajada = j;
        }
      }
    }

    // 3. Si encontramos un par válido, lo agregamos a los resultados
    if (mejorSubida != -1 && mejorBajada != -1) {
      final paradaSubida = paradas[mejorSubida];
      final paradaBajada = paradas[mejorBajada];

      resultados.add({
        'ruta': ruta,
        'paradaSubida': paradaSubida,
        'distanciaSubida': distOrigen[mejorSubida],
        'paradaBajada': paradaBajada,
        'distanciaBajada': distDestino[mejorBajada],
        'paradasRecorrido': mejorBajada - mejorSubida,
        'sentido': mejorBajada > paradas.length ~/ 2
            ? 'Hacia el final de la línea'
            : 'Hacia el inicio de la línea',
      });

      if (!_paradasCercanasAlDestino.contains(paradaBajada)) {
        _paradasCercanasAlDestino.add(paradaBajada);
      }

      // 🔍 DEBUG: descomentar para ver los detalles en consola
      // debugPrint(
      //   '[${ruta.nombre}] subida=${mejorSubida}, bajada=${mejorBajada}, '
      //   'paradas=${mejorBajada - mejorSubida}, '
      //   'distSub=${distOrigen[mejorSubida].toStringAsFixed(0)}m, '
      //   'distBaj=${distDestino[mejorBajada].toStringAsFixed(0)}m, '
      //   'costo=${mejorCosto.toStringAsFixed(0)}',
      // );
    }
  }

  // 4. Ordenar por costo total (no solo por distancia de subida)
  resultados.sort((a, b) {
    final costA = (a['distanciaSubida'] as double) +
        (a['distanciaBajada'] as double) +
        (a['paradasRecorrido'] as int) * pesoPorParada;
    final costB = (b['distanciaSubida'] as double) +
        (b['distanciaBajada'] as double) +
        (b['paradasRecorrido'] as int) * pesoPorParada;
    return costA.compareTo(costB);
  });

  setState(() => _calculandoRuta = false);

  if (resultados.isNotEmpty) {
    _mostrarPanelResultados(resultados);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('No hay colectivos que te sirvan para ese viaje')),
    );
  }
}

 void _mostrarPanelResultados(List<Map<String, dynamic>> rutasCercanas) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // ← permite que el sheet crezca más del 50%
    backgroundColor: const Color(0xFF1E2235),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle visual (la rayita para arrastrar)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                rutasCercanas.length == 1
                    ? '1 línea te sirve'
                    : '${rutasCercanas.length} líneas te sirven',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tocá una línea para ver el recorrido completo',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),

            // ← clave: Flexible + ListView.builder con shrinkWrap
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: rutasCercanas.length,
                itemBuilder: (context, index) {
                  final item = rutasCercanas[index];
                  final ruta = item['ruta'] as RutaColectivo;
                  final distSubida = item['distanciaSubida'] as double;
                  final distBajada = item['distanciaBajada'] as double;
                  final sentido = item['sentido'] as String;

                  return ListTile(
                    leading: Icon(Icons.directions_bus, color: ruta.color),
                    title: Text(
                      ruta.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ruta.empresa.isNotEmpty)
                          Text(
                            ruta.empresa,
                            style: const TextStyle(
                              color: Color(0xFFFF7F6C),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          'Sube a ${distSubida.toStringAsFixed(0)}m de ti',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Baja a ${distBajada.toStringAsFixed(0)}m del destino',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          sentido,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.white38,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _rutaSeleccionada = ruta;
                        _paradaSubida = item['paradaSubida'];
                        _paradaBajada = item['paradaBajada'];
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  void _limpiarSeleccion() {
    setState(() {
      _destinoTocado = null;
      _paradaSubida = null;
      _paradaBajada = null;
      _rutaSeleccionada = null;
      _paradasCercanasAlDestino.clear();
      _modoMira = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String filtro = lineaSeleccionada == 'Urbano' ? 'urbano' : 'santa_ana';
    final rutasDeLaPestana = _rutas.where((r) => r.categoriaRuta == filtro).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Colectivos y rutas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          if (_destinoTocado != null || _rutaSeleccionada != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _limpiarSeleccion,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 250,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  RutaMap(
                    key: _mapKey,
                    mostrarRutas: true,
                    mostrarColectivos: false,
                    mostrarEventos: false,
                    mostrarLugares: false,
                    puntos: _puntos,
                    rutas: _rutaSeleccionada == null ? [] : [_rutaSeleccionada!],
                    destinoSeleccionado: _destinoTocado,
                    paradasCercanas: _paradasCercanasAlDestino,
                    paradaSubida: _paradaSubida,
                    paradaBajada: _paradaBajada,
                    modoAgregarPunto: false,
                  ),
                  if (_calculandoRuta)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFFF7F6C))),
                  if (_modoMira)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 40, color: Colors.blueAccent, shadows: [Shadow(color: Colors.white, blurRadius: 4)]),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Elegí tu destino', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (!_modoMira && _destinoTocado == null && !_calculandoRuta)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _modoMira = true),
                          icon: const Icon(Icons.gps_fixed, size: 18),
                          label: const Text('¿A dónde querés ir?'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7F6C),
                            foregroundColor: const Color(0xFF131622),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                  if (_modoMira)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => setState(() => _modoMira = false),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              final centro = _mapKey.currentState?.getCentroActual();
                              if (centro != null) _analizarDestino(centro);
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  if (!_modoMira)
                    Positioned(
                      bottom: 12, right: 12,
                      child: GestureDetector(
                        onTap: () { _obtenerUbicacionActual(); _mapKey.currentState?.centrarEnMiUbicacion(); },
                        child: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFF7F6C), child: Icon(Icons.my_location, size: 16, color: Color(0xFF131622))),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFF1E2235), borderRadius: BorderRadius.circular(30)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () { setState(() { lineaSeleccionada = 'Urbano'; }); _limpiarSeleccion(); },
                      child: Container(
                        decoration: BoxDecoration(color: lineaSeleccionada == 'Urbano' ? const Color.fromARGB(255, 197, 20, 20) : Colors.transparent, borderRadius: BorderRadius.circular(30)),
                        alignment: Alignment.center,
                        child: Text('Urbano', style: TextStyle(fontWeight: FontWeight.bold, color: lineaSeleccionada == 'Urbano' ? Colors.white : Colors.white70)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { setState(() { lineaSeleccionada = 'Santa Ana'; }); _limpiarSeleccion(); },
                      child: Container(
                        decoration: BoxDecoration(color: lineaSeleccionada == 'Santa Ana' ? const Color.fromARGB(255, 240, 243, 67) : Colors.transparent, borderRadius: BorderRadius.circular(30)),
                        alignment: Alignment.center,
                        child: Text('Santa Ana', style: TextStyle(fontWeight: FontWeight.bold, color: lineaSeleccionada == 'Santa Ana' ? const Color(0xFF131622) : Colors.white70)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: rutasDeLaPestana.isEmpty
                ? const Center(child: Text('No hay líneas guardadas', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: rutasDeLaPestana.length,
                    itemBuilder: (context, index) {
                      final ruta = rutasDeLaPestana[index];
                      bool isSelected = _rutaSeleccionada?.id == ruta.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _limpiarSeleccion();
                            } else {
                              _rutaSeleccionada = ruta;
                              _destinoTocado = null;
                              _paradaSubida = null;
                              _paradaBajada = null;
                              _modoMira = false;
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2E334D) : const Color(0xFF1E2235),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isSelected ? const Color(0xFFFF7F6C) : Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                ruta.categoriaRuta == 'urbano'
                                    ? 'assets/urbanologo.png'
                                    : 'assets/santa_logo.png',
                                width: 40,
                                height: 40,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_bus, color: ruta.color, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                    if (ruta.empresa.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(ruta.empresa, style: const TextStyle(fontSize: 11, color: Color(0xFFFF7F6C))),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFFF7F6C), size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, 1),
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
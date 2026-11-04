import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'map_data.dart';
import 'map_storage.dart';
import 'widgets/ruta_map.dart';

class ColectivosY_Rutas extends StatefulWidget {
  const ColectivosY_Rutas({super.key});

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

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    
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

  Future<void> _obtenerUbicacionActual() async {
    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _miUbicacion = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      print("Error GPS: $e");
    }
  }

  Future<void> _pegarYBuscar() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    
    if (data == null || data.text == null || data.text!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay coordenadas en el portapapeles')));
      return;
    }

    try {
      final partes = data.text!.split(',');
      if (partes.length == 2) {
        final lat = double.parse(partes[0].trim());
        final lng = double.parse(partes[1].trim());
        _analizarDestino(LatLng(lat, lng));
      } else {
        throw FormatException();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El texto copiado no tiene el formato correcto (Lat, Lng)')),
        );
      }
    }
  }

  void _analizarDestino(LatLng destino) async {
    if (_miUbicacion == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Necesitamos tu ubicación GPS para calcular')));
      return;
    }

    setState(() {
      _destinoTocado = destino;
      _calculandoRuta = true;
      _rutaSeleccionada = null;
      _paradaSubida = null;
      _paradaBajada = null;
      _paradasCercanasAlDestino.clear();
    });

    const Distance dist = Distance();
    List<Map<String, dynamic>> resultados = [];

    for (var ruta in _rutas) {
      LatLng? mejorBajada;
      double minDistDestino = double.infinity;

      LatLng? mejorSubida;
      double minDistOrigen = double.infinity;

      for (var parada in ruta.paradas) {
        double dDestino = dist.as(LengthUnit.Meter, parada, destino);
        if (dDestino < minDistDestino) {
          minDistDestino = dDestino;
          mejorBajada = parada;
        }

        double dOrigen = dist.as(LengthUnit.Meter, parada, _miUbicacion!);
        if (dOrigen < minDistOrigen) {
          minDistOrigen = dOrigen;
          mejorSubida = parada;
        }
      }

      if (mejorBajada != null && minDistDestino <= 500) {
        resultados.add({
          'ruta': ruta,
          'paradaSubida': mejorSubida,
          'distanciaSubida': minDistOrigen,
          'paradaBajada': mejorBajada,
          'distanciaBajada': minDistDestino,
        });
        
        if (!_paradasCercanasAlDestino.contains(mejorBajada)) {
          _paradasCercanasAlDestino.add(mejorBajada);
        }
      }
    }

    resultados.sort((a, b) => (a['distanciaSubida'] as double).compareTo(b['distanciaSubida'] as double));

    setState(() {
      _calculandoRuta = false;
    });

    if (resultados.isNotEmpty) {
      _mostrarPanelResultados(resultados);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay colectivos pasando a 500m de este punto')));
    }
  }

  void _mostrarPanelResultados(List<Map<String, dynamic>> rutasCercanas) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Colectivos para este viaje', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text('Tocá una línea para ver el recorrido completo', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const Divider(color: Colors.white24),
              ...rutasCercanas.map((item) {
                final ruta = item['ruta'] as RutaColectivo;
                final paradaSubida = item['paradaSubida'] as LatLng;
                final distSubida = item['distanciaSubida'] as double;
                final paradaBajada = item['paradaBajada'] as LatLng;
                final distBajada = item['distanciaBajada'] as double;

                return ListTile(
                  leading: Icon(Icons.directions_bus, color: ruta.color),
                  title: Text(ruta.nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sube a ${distSubida.toStringAsFixed(0)}m de ti', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                      Text('Baja a ${distBajada.toStringAsFixed(0)}m del destino', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _rutaSeleccionada = ruta;
                      _paradaSubida = paradaSubida;
                      _paradaBajada = paradaBajada;
                    });
                  },
                );
              }).toList(),
            ],
          ),
        );
      }
    );
  }

  void _limpiarSeleccion() {
    setState(() {
      _destinoTocado = null;
      _paradaSubida = null; 
      _paradaBajada = null; 
      _rutaSeleccionada = null;
      _paradasCercanasAlDestino.clear();
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
          IconButton(
            icon: const Icon(Icons.content_paste, color: Color(0xFFFF7F6C)),
            tooltip: 'Pegar coordenadas de destino',
            onPressed: _pegarYBuscar,
          ),
          if (_destinoTocado != null || _rutaSeleccionada != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _limpiarSeleccion,
            )
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
                    modoAgregarPunto: true, 
                    onMapTap: (punto) => _analizarDestino(punto),
                  ),
                  
                  if (_calculandoRuta)
                    const Center(child: CircularProgressIndicator(color: Color(0xFFFF7F6C))),

                  if (_destinoTocado == null && !_calculandoRuta)
                    const Positioned(
                      top: 10, left: 0, right: 0,
                      child: Center(
                        child: Text('Tocá el mapa o pegá coordenadas para buscar', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),

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
              // DISEÑO NUEVO DE LA RAMA MAIN (BorderRadius 30)
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
                              // NUEVOS LOGOS DE LA RAMA MAIN
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
                                child: Text(ruta.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
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

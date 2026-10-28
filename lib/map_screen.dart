import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Widget de mapa reutilizable con ubicación del usuario.
class RutaMap extends StatefulWidget {
  const RutaMap({super.key});

  @override
  State<RutaMap> createState() => RutaMapState();
}

class RutaMapState extends State<RutaMap> {
  static const LatLng _initialCenter = LatLng(-24.1858, -65.2995);
  final MapController _mapController = MapController();

  /// Pide permiso y mueve el mapa a la ubicación actual del usuario.
  Future<void> centrarEnMiUbicacion() async {
    // 1. Verificar si el servicio de ubicación está activo
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      // Opcional: podrías mostrar un SnackBar avisando
      return;
    }

    // 2. Verificar / pedir permiso
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return;
    }

    // 3. Obtener posición y mover cámara
    final posicion = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _mapController.move(LatLng(posicion.latitude, posicion.longitude), 16);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 13,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.example.definitiva',
          maxNativeZoom: 16,
        ),

        // ── Capa que dibuja el puntito azul de ubicación ──
        CurrentLocationLayer(),

        // ─── Acá agregaremos después PolylineLayer para rutas ───
      ],
    );
  }
}

/// Pantalla contenedora: mapa arriba (50%), panel de controles abajo (50%).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<RutaMapState> _mapKey = GlobalKey<RutaMapState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Mitad superior: el mapa ──
          Expanded(
            flex: 1,
            child: RutaMap(key: _mapKey),
          ),

          // ── Mitad inferior: panel de controles ──
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF161925),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Panel de rutas y ubicación',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _mapKey.currentState?.centrarEnMiUbicacion(),
                        icon: const Icon(Icons.my_location),
                        label: const Text('Centrar en mi ubicación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7F6C),
                          foregroundColor: const Color(0xFF131622),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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
}
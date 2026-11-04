import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../map_data.dart';

class RutaMap extends StatefulWidget {
  final bool mostrarRutas;
  final bool mostrarLugares;
  final bool mostrarEventos;
  final bool mostrarColectivos;
  final List<PuntoInteres> puntos;
  final List<RutaColectivo> rutas;
  
  final bool modoAgregarPunto;
  final bool modoAgregarRuta;
  final List<LatLng> rutaEnProgreso; 
  final Function(LatLng)? onMapTap; 

  final LatLng? destinoSeleccionado;
  final List<LatLng>? paradasCercanas;
  final LatLng? paradaRecomendada;
  final LatLng? paradaSubida;
  final LatLng? paradaBajada;

  const RutaMap({
    super.key,
    required this.mostrarRutas,
    required this.mostrarLugares,
    required this.mostrarEventos,
    required this.mostrarColectivos,
    required this.puntos,
    required this.rutas,
    this.modoAgregarPunto = false,
    this.modoAgregarRuta = false,
    this.rutaEnProgreso = const [],
    this.onMapTap,
    this.destinoSeleccionado,
    this.paradasCercanas,
    this.paradaRecomendada,
    this.paradaSubida,
    this.paradaBajada,
  });

  @override
  State<RutaMap> createState() => RutaMapState();
}

class RutaMapState extends State<RutaMap> {
  static const LatLng _initialCenter = LatLng(-24.1858, -65.2995);
  final MapController _mapController = MapController();
  CacheStore? _cacheStore;
  double _currentZoom = 13.0;

  final String _stadiaUrl = 'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png?api_key=fd585fe6-8299-4dba-b57b-cf34b30288ae';

  @override
  void initState() {
    super.initState();
    _initCacheStore();
  }

  Future<void> _initCacheStore() async {
    final dir = await getApplicationSupportDirectory();
    final storePath = '${dir.path}${Platform.pathSeparator}MapTiles';
    if (mounted) {
      setState(() {
        _cacheStore = FileCacheStore(storePath);
      });
    }
  }

  Future<void> centrarEnMiUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) return;

    final posicion = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _mapController.move(LatLng(posicion.latitude, posicion.longitude), 16);
  }

  // Método para mover la cámara del mapa a una coordenada específica
  void moverCamara(LatLng punto, double zoom) {
    _mapController.move(punto, zoom);
  }

  @override
  Widget build(BuildContext context) {
    if (_cacheStore == null) return const Center(child: CircularProgressIndicator());

    final puntosFiltrados = widget.puntos.where((p) {
      if (p.categoria == 'lugar' && widget.mostrarLugares) return true;
      if (p.categoria == 'evento' && widget.mostrarEventos) return true;
      if (p.categoria == 'colectivo' && widget.mostrarColectivos) return true;
      return false;
    }).toList();

    // Variables de tamaño dinámico para los brillos de subida/bajada
    double sizeBrillo = _currentZoom >= 15 ? 46 : (_currentZoom >= 12 ? 32 : 18);
    double sizeIcono = _currentZoom >= 15 ? 24 : (_currentZoom >= 12 ? 16 : 10);
    double blurBrillo = _currentZoom >= 15 ? 12 : (_currentZoom >= 12 ? 6 : 3);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _initialCenter,
        initialZoom: 13,
        minZoom: 3,
        maxZoom: 20,
        onPositionChanged: (camera, hasGesture) {
          setState(() { _currentZoom = camera.zoom; });
        },
        onTap: (widget.modoAgregarPunto || widget.modoAgregarRuta) && widget.onMapTap != null
            ? (tapPosition, point) => widget.onMapTap!(point) 
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: _stadiaUrl,
          userAgentPackageName: 'com.example.definitiva',
          maxNativeZoom: 20,
          tileProvider: CachedTileProvider(store: _cacheStore!, maxStale: const Duration(days: 30)),
        ),
        
        if (widget.mostrarRutas)
          PolylineLayer(
            polylines: widget.rutas.map((ruta) => Polyline(
              points: ruta.puntosTrazo, 
              color: ruta.color, 
              strokeWidth: 4.0
            )).toList(),
          ),

        if (widget.mostrarRutas)
          MarkerLayer(
            markers: widget.rutas.expand((ruta) => ruta.paradas).map((parada) {
              return Marker(
                point: parada,
                width: 12, height: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    shape: BoxShape.circle, 
                    border: Border.all(color: Colors.black54, width: 2)
                  ),
                ),
              );
            }).toList(),
          ),

        if (widget.rutaEnProgreso.isNotEmpty)
          PolylineLayer(
            polylines: [Polyline(points: widget.rutaEnProgreso, color: Colors.orangeAccent, strokeWidth: 5.0)],
          ),

        if (widget.rutaEnProgreso.isNotEmpty)
          MarkerLayer(
            markers: widget.rutaEnProgreso.map((punto) {
              return Marker(
                point: punto, width: 20, height: 20,
                child: Container(decoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
              );
            }).toList(),
          ),
          
        if (puntosFiltrados.isNotEmpty)
          MarkerLayer(
            markers: puntosFiltrados.map((punto) {
              // Tamaño y resplandor dinámico según el zoom
              double sizeBase = _currentZoom >= 15 ? 22 : (_currentZoom >= 12 ? 14 : 8);
              double blurGlow = _currentZoom >= 15 ? 16 : (_currentZoom >= 12 ? 8 : 4);
              
              // Color según la categoría
              Color colorPunto = punto.categoria == 'evento' 
                  ? const Color(0xFFFF4081) // Rosa vibrante para eventos
                  : const Color(0xFF00E5FF); // Cian brillante para lugares

              return Marker(
                point: punto.punto, 
                width: sizeBase * 3, // Damos margen para que no se corte el resplandor
                height: sizeBase * 3,
                child: Center(
                  child: Container(
                    width: sizeBase,
                    height: sizeBase,
                    decoration: BoxDecoration(
                      color: colorPunto,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: _currentZoom >= 12 ? 2 : 1),
                      boxShadow: [
                        BoxShadow(
                          color: colorPunto.withOpacity(0.8),
                          blurRadius: blurGlow,
                          spreadRadius: blurGlow / 3,
                        )
                      ]
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
        if (widget.destinoSeleccionado != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.destinoSeleccionado!,
                width: 40, height: 40,
                child: const Icon(Icons.location_on, color: Colors.blueAccent, size: 40, shadows: [Shadow(color: Colors.black, blurRadius: 5)]),
              )
            ],
          ),

        if (widget.paradasCercanas != null && widget.paradasCercanas!.isNotEmpty)
          MarkerLayer(
            markers: widget.paradasCercanas!.map((parada) {
              return Marker(
                point: parada,
                width: 16, height: 16,
                child: Container(
                  decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle, border: Border.all(color: Colors.black45, width: 1.5)),
                ),
              );
            }).toList(),
          ),

        // PARADA DE SUBIDA (Brillo dinámico)
        if (widget.paradaSubida != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.paradaSubida!,
                width: sizeBrillo, height: sizeBrillo,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: blurBrillo, spreadRadius: blurBrillo/2)],
                  ),
                  child: Icon(Icons.directions_walk, color: Colors.white, size: sizeIcono),
                ),
              )
            ],
          ),

        // PARADA DE BAJADA (Brillo dinámico)
        if (widget.paradaBajada != null)
          MarkerLayer(
            markers: [
              Marker(
                point: widget.paradaBajada!,
                width: sizeBrillo, height: sizeBrillo,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.6),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.orangeAccent, blurRadius: blurBrillo, spreadRadius: blurBrillo/2)],
                  ),
                  child: Icon(Icons.flag, color: Colors.white, size: sizeIcono),
                ),
              )
            ],
          ),

        CurrentLocationLayer(),
      ],
    );
  }
}

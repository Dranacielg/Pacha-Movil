import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class PuntoInteres {
  final String id;
  final String nombre;
  final double lat;
  final double lng;
  final int iconoCode;
  final int colorValue;
  final String categoria; // <-- NUEVO: 'evento', 'lugar', 'colectivo'

  PuntoInteres({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.iconoCode,
    required this.colorValue,
    required this.categoria,
  });

  LatLng get punto => LatLng(lat, lng);
  IconData get icono => IconData(iconoCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'lat': lat,
        'lng': lng,
        'iconoCode': iconoCode,
        'colorValue': colorValue,
        'categoria': categoria,
      };

  factory PuntoInteres.fromJson(Map<String, dynamic> json) => PuntoInteres(
        id: json['id'],
        nombre: json['nombre'],
        lat: json['lat'],
        lng: json['lng'],
        iconoCode: json['iconoCode'],
        colorValue: json['colorValue'],
        // Si un punto viejo no tiene categoría, le ponemos 'lugar' por defecto
        categoria: json['categoria'] ?? 'lugar', 
      );
}

class RutaColectivo {
  final String id;
  final String nombre;
  final List<LatLng> puntosTrazo; // Toda la línea (curvas, etc)
  final List<LatLng> paradas;     // Solo donde se sube/baja
  final int colorValue;
  final String categoriaRuta;

  RutaColectivo({
    required this.id,
    required this.nombre,
    required this.puntosTrazo,
    required this.paradas,
    required this.colorValue,
    required this.categoriaRuta,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'colorValue': colorValue,
        'categoriaRuta': categoriaRuta,
        'puntosTrazo': puntosTrazo.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'paradas': paradas.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      };

  factory RutaColectivo.fromJson(Map<String, dynamic> json) => RutaColectivo(
        id: json['id'],
        nombre: json['nombre'],
        colorValue: json['colorValue'],
        categoriaRuta: json['categoriaRuta'] ?? 'urbano',
        puntosTrazo: (json['puntosTrazo'] as List)
            .map((p) => LatLng(p['lat'], p['lng']))
            .toList(),
        paradas: (json['paradas'] as List)
            .map((p) => LatLng(p['lat'], p['lng']))
            .toList(),
      );
}
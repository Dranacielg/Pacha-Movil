import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ─── CLASE HORARIO ───
class HorarioAtencion {
  final String dia; // 'Lunes', 'Martes', etc.
  final String apertura; // '08:00'
  final String cierre; // '20:00'

  HorarioAtencion({
    required this.dia,
    required this.apertura,
    required this.cierre,
  });

  Map<String, dynamic> toJson() => {
        'dia': dia,
        'apertura': apertura,
        'cierre': cierre,
      };

  factory HorarioAtencion.fromJson(Map<String, dynamic> json) => HorarioAtencion(
        dia: json['dia'],
        apertura: json['apertura'],
        cierre: json['cierre'],
      );
}

// ─── CLASE RESEÑA ───
class Resena {
  final String usuario;
  final String comentario;
  final double estetica; // 1 a 5
  final double atencion; // 1 a 5
  final double servicios; // 1 a 5

  Resena({
    required this.usuario,
    required this.comentario,
    required this.estetica,
    required this.atencion,
    required this.servicios,
  });

  double get promedio => (estetica + atencion + servicios) / 3;

  Map<String, dynamic> toJson() => {
        'usuario': usuario,
        'comentario': comentario,
        'estetica': estetica,
        'atencion': atencion,
        'servicios': servicios,
      };

  factory Resena.fromJson(Map<String, dynamic> json) => Resena(
        usuario: json['usuario'],
        comentario: json['comentario'],
        estetica: (json['estetica'] as num).toDouble(),
        atencion: (json['atencion'] as num).toDouble(),
        servicios: (json['servicios'] as num).toDouble(),
      );
}

// ─── CLASE PUNTO INTERES ───
class PuntoInteres {
  final String id;
  final String nombre;
  final String descripcion;
  final double lat;
  final double lng;
  final int iconoCode;
  final int colorValue;
  final String categoria; 
  
  final String categoriaLugar; 
  final List<HorarioAtencion> horarios;
  final List<Resena> resenas;

  // CAMPOS PARA EVENTOS (Milisegundos para Firestore)
  final int? fechaInicio;
  final int? fechaFin;

  PuntoInteres({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.lat,
    required this.lng,
    required this.iconoCode,
    required this.colorValue,
    required this.categoria,
    this.categoriaLugar = '',
    this.horarios = const [],
    this.resenas = const [],
    this.fechaInicio,
    this.fechaFin,
  });

  LatLng get punto => LatLng(lat, lng);
  IconData get icono => IconData(iconoCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  double get puntuacionPromedio {
    if (resenas.isEmpty) return 0.0;
    double suma = resenas.fold(0, (prev, resena) => prev + resena.promedio);
    return suma / resenas.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'lat': lat,
        'lng': lng,
        'iconoCode': iconoCode,
        'colorValue': colorValue,
        'categoria': categoria,
        'categoriaLugar': categoriaLugar,
        'horarios': horarios.map((h) => h.toJson()).toList(),
        'resenas': resenas.map((r) => r.toJson()).toList(),
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
      };

  factory PuntoInteres.fromJson(Map<String, dynamic> json) => PuntoInteres(
        id: json['id'],
        nombre: json['nombre'],
        descripcion: json['descripcion'] ?? '',
        lat: json['lat'],
        lng: json['lng'],
        iconoCode: json['iconoCode'],
        colorValue: json['colorValue'],
        categoria: json['categoria'] ?? 'lugar',
        categoriaLugar: json['categoriaLugar'] ?? '',
        horarios: json['horarios'] != null 
            ? (json['horarios'] as List).map((h) => HorarioAtencion.fromJson(h)).toList() 
            : [],
        resenas: json['resenas'] != null 
            ? (json['resenas'] as List).map((r) => Resena.fromJson(r)).toList() 
            : [],
        fechaInicio: json['fechaInicio'],
        fechaFin: json['fechaFin'],
      );
}

// ─── CLASE RUTA COLECTIVO ───
class RutaColectivo {
  final String id;
  final String nombre;
  final List<LatLng> puntosTrazo;
  final List<LatLng> paradas;
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
        puntosTrazo: (json['puntosTrazo'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList(),
        paradas: (json['paradas'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList(),
      );
}

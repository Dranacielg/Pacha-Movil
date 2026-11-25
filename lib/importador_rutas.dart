import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'map_data.dart';
import 'map_storage.dart';

class ImportResultado {
  final int importadas;
  final int reemplazadas;
  final int errores;
  ImportResultado({
    required this.importadas,
    required this.reemplazadas,
    required this.errores,
  });

  @override
  String toString() =>
      '✅ $importadas líneas importadas · ♻️ $reemplazadas anteriores reemplazadas · ⚠️ $errores errores';
}

class ImportadorRutas {
  /// Importa el JSON agrupando por `linea` (ida + vuelta en una sola ruta).
  /// Corrige trazados invertidos y encadena MultiLineStrings.
  static Future<ImportResultado> importarDesdeAsset(
    MapStorage storage, {
    String assetPath = 'assets/rutas_colectivos_jujuy.json',
    double espaciadoParadasMetros = 400,
    bool reemplazar = true,
  }) async {
    final jsonStr = await rootBundle.loadString(assetPath);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final rutasJson = data['rutas'] as List;

    // 1. Recolectar líneas presentes en el JSON
    final lineasEnJson = <String>{};
    for (var r in rutasJson) {
      final linea = (r['linea'] as String? ?? '').trim();
      if (linea.isNotEmpty) lineasEnJson.add(linea);
    }

    // 2. Borrar rutas existentes con ese número de línea
    int eliminadas = 0;
    if (reemplazar) {
      try {
        final existentes = await storage.streamRutas().first;
        for (var existente in existentes) {
          if (_nombreCoincideConLinea(existente.nombre, lineasEnJson)) {
            await storage.eliminarRuta(existente.id);
            eliminadas++;
          }
        }
      } catch (e) {
        debugPrint('Error al borrar rutas previas: $e');
      }
    }

    // 3. Construir rutas mergeadas con correcciones
    int importadas = 0, errores = 0;
    final aSubir = <RutaColectivo>[];
    const Distance dist = Distance();

    for (var rutaJson in rutasJson) {
      try {
        final linea = (rutaJson['linea'] as String? ?? '').trim();
        if (linea.isEmpty) {
          errores++;
          continue;
        }

        final empresa = (rutaJson['empresa'] as String? ?? '').trim();
        final colorHex = rutaJson['color'] as String?;
        final trazados = rutaJson['trazados'] as List? ?? [];
        if (trazados.isEmpty) {
          errores++;
          continue;
        }

        final puntosTrazo = <LatLng>[];
        final paradas = <LatLng>[];
        String? origen;
        String? destino;

        for (var t in trazados) {
          final tipoGeom = t['tipo_geometria'] as String? ?? 'LineString';
          final coords = t['coordenadas'] as List;
          var puntos = _extraerPuntos(coords, tipoGeom);
          if (puntos.length < 2) continue;

          // FIX 1: Detectar y corregir trazado invertido
          // Si el ÚLTIMO punto del trazado actual está más cerca del ÚLTIMO
          // punto acumulado que del PRIMERO, hay que invertir el trazado.
          if (puntosTrazo.isNotEmpty) {
            final finAnterior = puntosTrazo.last;
            final dInicio = dist.as(LengthUnit.Meter, finAnterior, puntos.first);
            final dFinal = dist.as(LengthUnit.Meter, finAnterior, puntos.last);
            if (dFinal < dInicio) {
              puntos = puntos.reversed.toList();
              debugPrint('Línea $linea: trazado invertido corregido');
            }
          }

          puntosTrazo.addAll(puntos);
          paradas.addAll(_samplearParadas(puntos, espaciadoMetros: espaciadoParadasMetros));

          origen ??= t['origen'] as String?;
          destino ??= t['destino'] as String?;
        }

        if (puntosTrazo.isEmpty) {
          errores++;
          continue;
        }

        final categoriaRuta =
            empresa.toLowerCase().contains('santa ana') ? 'santa_ana' : 'urbano';
        final colorValue = _parseHexColor(colorHex) ?? _colorPorCategoria(categoriaRuta);
        final nombre = (origen != null &&
                destino != null &&
                origen.isNotEmpty &&
                destino.isNotEmpty)
            ? 'Línea $linea: $origen ↔ $destino'
            : 'Línea $linea';

        aSubir.add(RutaColectivo(
          id: '',
          nombre: nombre,
          puntosTrazo: puntosTrazo,
          paradas: paradas,
          colorValue: colorValue,
          categoriaRuta: categoriaRuta,
          empresa: empresa,
        ));
        importadas++;
      } catch (e) {
        debugPrint('Error importando línea: $e');
        errores++;
      }
    }

    await storage.guardarRutasBatch(aSubir);

    return ImportResultado(
      importadas: importadas,
      reemplazadas: eliminadas,
      errores: errores,
    );
  }

  static bool _nombreCoincideConLinea(String nombre, Iterable<String> lineas) {
    for (var linea in lineas) {
      if (nombre == 'Línea $linea') return true;
      if (nombre.startsWith('Línea $linea:')) return true;
      if (nombre.startsWith('Línea $linea ')) return true;
    }
    return false;
  }

  // ─── Extraer puntos de cualquier geometría ───
  static List<LatLng> _extraerPuntos(List coordsRaw, String tipoGeom) {
    if (tipoGeom == 'MultiLineString') {
      final segmentos = coordsRaw.map<List<LatLng>>((seg) {
        return (seg as List).map<LatLng>((c) {
          final l = c as List;
          return LatLng((l[1] as num).toDouble(), (l[0] as num).toDouble());
        }).toList();
      }).toList();

      // FIX 2: Filtrar segmentos que son loops cerrados (inicio ≈ final)
      // o demasiado cortos (típicos artefactos de OSM).
      const Distance d = Distance();
      final utiles = segmentos.where((s) {
        if (s.length < 5) return false;
        final gap = d.as(LengthUnit.Meter, s.first, s.last);
        return gap > 100; // loops cerrados tienen gap ≈ 0
      }).toList();

      if (utiles.isEmpty) {
        // Si todo era loop, devolvemos el más largo igual
        segmentos.sort((a, b) => b.length.compareTo(a.length));
        return segmentos.isNotEmpty ? segmentos.first : [];
      }
      if (utiles.length == 1) return utiles.first;

      // FIX 3: Encadenar los segmentos útiles greedy por proximidad
      return _encadenarSegmentos(utiles);
    }

    // LineString simple: tal cual
    return coordsRaw.map<LatLng>((c) {
      final l = c as List;
      return LatLng((l[1] as num).toDouble(), (l[0] as num).toDouble());
    }).toList();
  }

  // ─── Encadenar segmentos greedy ───
  static List<LatLng> _encadenarSegmentos(List<List<LatLng>> segmentos) {
    const Distance d = Distance();
    final restantes = List<List<LatLng>>.from(segmentos);

    // Empezar por el más largo (suele ser el tramo principal)
    restantes.sort((a, b) => b.length.compareTo(a.length));
    final resultado = <LatLng>[];
    resultado.addAll(restantes.removeAt(0));

    while (restantes.isNotEmpty) {
      final finActual = resultado.last;
      int bestIdx = -1;
      bool invertir = false;
      double bestDist = double.infinity;

      for (int i = 0; i < restantes.length; i++) {
        final seg = restantes[i];
        final dInicio = d.as(LengthUnit.Meter, finActual, seg.first);
        final dFinal = d.as(LengthUnit.Meter, finActual, seg.last);
        if (dInicio < bestDist) {
          bestDist = dInicio;
          bestIdx = i;
          invertir = false;
        }
        if (dFinal < bestDist) {
          bestDist = dFinal;
          bestIdx = i;
          invertir = true;
        }
      }

      // Si el segmento más cercano está a más de 500m, no vale la pena
      if (bestIdx == -1 || bestDist > 500) break;

      final seg = restantes.removeAt(bestIdx);
      resultado.addAll(invertir ? seg.reversed : seg);
    }

    return resultado;
  }

  // ─── Samplear paradas cada N metros ───
  static List<LatLng> _samplearParadas(
    List<LatLng> puntos, {
    double espaciadoMetros = 400,
  }) {
    if (puntos.length < 2) return List.from(puntos);
    const Distance dist = Distance();
    final paradas = <LatLng>[puntos.first];
    double acumulado = 0.0;
    for (int i = 1; i < puntos.length; i++) {
      acumulado += dist.as(LengthUnit.Meter, puntos[i - 1], puntos[i]);
      if (acumulado >= espaciadoMetros) {
        paradas.add(puntos[i]);
        acumulado = 0.0;
      }
    }
    final last = paradas.last;
    final fin = puntos.last;
    if (last.latitude != fin.latitude || last.longitude != fin.longitude) {
      paradas.add(fin);
    }
    return paradas;
  }

  static int? _parseHexColor(String? hex) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
    try {
      return int.parse(hex.substring(1), radix: 16) | 0xFF000000;
    } catch (_) {
      return null;
    }
  }

  static int _colorPorCategoria(String cat) {
    return cat == 'santa_ana'
        ? const Color(0xFFF0F343).value
        : const Color(0xFFC51414).value;
  }
}
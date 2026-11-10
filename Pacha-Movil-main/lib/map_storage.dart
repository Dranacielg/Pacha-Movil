import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_data.dart';

class MapStorage {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── STREAMS ───

  Stream<List<PuntoInteres>> streamPuntos() {
    return _db.collection('puntos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PuntoInteres.fromJson(data);
      }).toList();
    });
  }

  Stream<List<RutaColectivo>> streamRutas() {
    return _db.collection('rutas').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RutaColectivo.fromJson(data);
      }).toList();
    });
  }

  // ─── GUARDAR ───

  Future<void> guardarPunto(PuntoInteres punto) async {
    final data = punto.toJson();
    data.remove('id');
    await _db.collection('puntos').add(data);
  }

  Future<void> guardarRuta(RutaColectivo ruta) async {
    final data = ruta.toJson();
    data.remove('id');
    await _db.collection('rutas').add(data);
  }

  /// NUEVO: guarda muchas rutas de una sola vez (más rápido que 57 writes).
  Future<void> guardarRutasBatch(List<RutaColectivo> rutas) async {
    if (rutas.isEmpty) return;
    final batch = _db.batch();
    for (var ruta in rutas) {
      final data = ruta.toJson();
      data.remove('id');
      final doc = _db.collection('rutas').doc();
      batch.set(doc, data);
    }
    await batch.commit();
  }

  // ─── ACTUALIZAR ───

  Future<void> actualizarPunto(PuntoInteres punto) async {
    final data = punto.toJson();
    data.remove('id');
    await _db.collection('puntos').doc(punto.id).update(data);
  }

  /// NUEVO: editar una ruta existente (nombre, empresa, color, etc.)
  Future<void> actualizarRuta(RutaColectivo ruta) async {
    if (ruta.id.isEmpty) return guardarRuta(ruta);
    final data = ruta.toJson();
    data.remove('id');
    await _db.collection('rutas').doc(ruta.id).set(data, SetOptions(merge: true));
  }

  // ─── ELIMINAR ───

  Future<void> eliminarPunto(String id) async {
    await _db.collection('puntos').doc(id).delete();
  }

  Future<void> eliminarRuta(String id) async {
    await _db.collection('rutas').doc(id).delete();
  }
}
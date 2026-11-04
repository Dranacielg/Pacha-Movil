import 'package:cloud_firestore/cloud_firestore.dart';
import 'map_data.dart';

class MapStorage {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── STREAMS (Para escuchar cambios en tiempo real) ───

  Stream<List<PuntoInteres>> streamPuntos() {
    return _db.collection('puntos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Le inyectamos el ID que le asignó Firestore al documento
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
    data.remove('id'); // Firestore genera su propio ID
    await _db.collection('puntos').add(data);
  }

  Future<void> guardarRuta(RutaColectivo ruta) async {
    final data = ruta.toJson();
    data.remove('id'); 
    await _db.collection('rutas').add(data);
  }

  // ─── ELIMINAR ───

  Future<void> eliminarPunto(String id) async {
    await _db.collection('puntos').doc(id).delete();
  }

  Future<void> eliminarRuta(String id) async {
    await _db.collection('rutas').doc(id).delete();
  }
}
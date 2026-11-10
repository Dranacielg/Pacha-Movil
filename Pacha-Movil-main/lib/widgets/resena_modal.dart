import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../map_data.dart';

class ResenaModal extends StatefulWidget {
  final PuntoInteres lugar;

  const ResenaModal({super.key, required this.lugar});

  @override
  State<ResenaModal> createState() => _ResenaModalState();
}

class _ResenaModalState extends State<ResenaModal> {
    final _nombreCtrl = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.displayName ??
        (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? ''),
  );
  final _comentarioCtrl = TextEditingController();

  static const int _maxNombre = 30;
  static const int _maxComentario = 300;

  double _estetica = 0;
  double _atencion = 0;
  double _servicios = 0;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Widget _buildEstrellas(
      String titulo, double valorActual, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < valorActual ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 28,
              ),
              onPressed: () => onChanged(index + 1.0),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Opinar sobre ${widget.lugar.nombre}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Colors.white),
              maxLength: _maxNombre,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxNombre),
              ],
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                counterText: '', // oculta el "0/30"
              ),
            ),
            const SizedBox(height: 15),

            // ESTRELLAS
            _buildEstrellas('Estética del lugar', _estetica,
                (v) => setState(() => _estetica = v)),
            _buildEstrellas('Atención', _atencion,
                (v) => setState(() => _atencion = v)),
            _buildEstrellas('Servicios y productos', _servicios,
                (v) => setState(() => _servicios = v)),

            const SizedBox(height: 10),
            TextField(
              controller: _comentarioCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              maxLength: _maxComentario,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_maxComentario),
              ],
              decoration: const InputDecoration(
                labelText: 'Dejá tu comentario...',
                border: OutlineInputBorder(),
                // el contador sí lo dejamos visible para que sepan cuánto les queda
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_nombreCtrl.text.trim().isEmpty ||
                      _comentarioCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Completá tu nombre y comentario')));
                    return;
                  }
                  if (_estetica == 0 || _atencion == 0 || _servicios == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Puntuá las 3 categorías con estrellas')));
                    return;
                  }

                  final nuevaResena = Resena(
                    usuario: _nombreCtrl.text.trim(),
                    comentario: _comentarioCtrl.text.trim(),
                    estetica: _estetica,
                    atencion: _atencion,
                    servicios: _servicios,
                  );

                  Navigator.pop(context, nuevaResena);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7F6C),
                  foregroundColor: const Color(0xFF131622),
                ),
                child: const Text('PUBLICAR RESEÑA',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
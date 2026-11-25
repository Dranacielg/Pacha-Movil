import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../map_data.dart';

class ResenaModal extends StatefulWidget {
  final PuntoInteres lugar;
  final Resena? existente;

  const ResenaModal({super.key, required this.lugar, this.existente});

  @override
  State<ResenaModal> createState() => _ResenaModalState();
}

class _ResenaModalState extends State<ResenaModal> {
  late final TextEditingController _comentarioCtrl;

  static const int _maxComentario = 200;

  late double _estetica;
  late double _atencion;
  late double _servicios;

  String get _nombreActual {
    final user = FirebaseAuth.instance.currentUser;
    final nombre = user?.displayName?.trim();
    if (nombre != null && nombre.isNotEmpty) return nombre;

    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Anónimo';
  }

  @override
  void initState() {
    super.initState();

    if (widget.existente != null) {
      _comentarioCtrl =
          TextEditingController(text: widget.existente!.comentario);
      _estetica = widget.existente!.estetica;
      _atencion = widget.existente!.atencion;
      _servicios = widget.existente!.servicios;
    } else {
      _comentarioCtrl = TextEditingController();
      _estetica = 0;
      _atencion = 0;
      _servicios = 0;
    }
  }

  @override
  void dispose() {
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
              widget.existente != null
                  ? 'Editar tu opinión sobre ${widget.lugar.nombre}'
                  : 'Opinar sobre ${widget.lugar.nombre}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Comentando como $_nombreActual',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

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
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_comentarioCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Escribí un comentario')));
                    return;
                  }
                  if (_estetica == 0 ||
                      _atencion == 0 ||
                      _servicios == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Puntuá las 3 categorías con estrellas')));
                    return;
                  }

                  final nuevaResena = Resena(
                    usuario: _nombreActual,
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
                child: Text(
                  widget.existente != null
                      ? 'ACTUALIZAR RESEÑA'
                      : 'PUBLICAR RESEÑA',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../map_data.dart';

class EditorPunto {
  // ═══ EDITOR DE EVENTO ═══
  static Future<PuntoInteres?> editarEvento(
    BuildContext context,
    PuntoInteres evento,
  ) async {
    final nombreCtrl = TextEditingController(text: evento.nombre);
    final descCtrl = TextEditingController(text: evento.descripcion);
    DateTime? fechaInicio = evento.fechaInicio != null
        ? DateTime.fromMillisecondsSinceEpoch(evento.fechaInicio!)
        : null;
    DateTime? fechaFin = evento.fechaFin != null
        ? DateTime.fromMillisecondsSinceEpoch(evento.fechaFin!)
        : null;

    return showModalBottomSheet<PuntoInteres>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Editar Evento',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nombre del evento'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 20),
                const Text('Fecha de inicio',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildFechaPicker(
                  context: ctx,
                  fecha: fechaInicio,
                  onPick: (f) => setS(() => fechaInicio = f),
                  onClear: () => setS(() => fechaInicio = null),
                ),
                const SizedBox(height: 16),
                const Text('Fecha de fin (opcional)',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                _buildFechaPicker(
                  context: ctx,
                  fecha: fechaFin,
                  onPick: (f) => setS(() => fechaFin = f),
                  onClear: () => setS(() => fechaFin = null),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final n = nombreCtrl.text.trim();
                      if (n.isEmpty) return;
                      Navigator.pop(
                        ctx,
                        PuntoInteres(
                          id: evento.id,
                          nombre: n,
                          descripcion: descCtrl.text.trim(),
                          lat: evento.lat,
                          lng: evento.lng,
                          iconoCode: evento.iconoCode,
                          colorValue: evento.colorValue,
                          categoria: evento.categoria,
                          categoriaLugar: evento.categoriaLugar,
                          horarios: evento.horarios,
                          resenas: evento.resenas,
                          fechaInicio: fechaInicio?.millisecondsSinceEpoch,
                          fechaFin: fechaFin?.millisecondsSinceEpoch,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('GUARDAR CAMBIOS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F6C),
                      foregroundColor: const Color(0xFF131622),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ EDITOR DE LUGAR ═══
  static Future<PuntoInteres?> editarLugar(
    BuildContext context,
    PuntoInteres lugar,
  ) async {
    final nombreCtrl = TextEditingController(text: lugar.nombre);
final descCtrl = TextEditingController(text: lugar.descripcion);
String categoriaLugar =
    lugar.categoriaLugar.isEmpty ? 'gastronomia' : lugar.categoriaLugar;
List<HorarioAtencion> horarios = List.from(lugar.horarios);
List<Resena> resenas = List.from(lugar.resenas);

    return showModalBottomSheet<PuntoInteres>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161925),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Editar Lugar',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Nombre del lugar'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categoriaLugar,
                  dropdownColor: const Color(0xFF1E2235),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Tipo de lugar'),
                  items: const [
                    DropdownMenuItem(
                        value: 'gastronomia', child: Text('Gastronomía')),
                    DropdownMenuItem(
                        value: 'recreacion', child: Text('Recreación')),
                    DropdownMenuItem(value: 'deportes', child: Text('Deportes')),
                    DropdownMenuItem(value: 'cultura', child: Text('Cultura')),
                    DropdownMenuItem(value: 'compras', child: Text('Compras')),
                  ],
                  onChanged: (v) => setS(() => categoriaLugar = v!),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Horarios',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () async {
                        final h = await _agregarHorario(ctx);
                        if (h != null) setS(() => horarios.add(h));
                      },
                      icon: const Icon(Icons.add,
                          color: Color(0xFFFF7F6C), size: 18),
                      label: const Text('Agregar',
                          style: TextStyle(color: Color(0xFFFF7F6C))),
                    ),
                  ],
                ),
                if (horarios.isEmpty)
  const Text('Sin horarios cargados',
      style: TextStyle(color: Colors.white38, fontSize: 12)),
...horarios.map((h) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text('${h.dia}: ${h.apertura} - ${h.cierre}',
          style: const TextStyle(
              color: Colors.white, fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.delete,
            color: Colors.redAccent, size: 18),
        onPressed: () => setS(() => horarios.remove(h)),
      ),
    )).toList(),

// ═══ RESEÑAS ═══
if (resenas.isNotEmpty) ...[
  const SizedBox(height: 24),
  Row(
    children: [
      const Icon(Icons.star, color: Colors.amber, size: 18),
      const SizedBox(width: 6),
      Text('RESEÑAS (${resenas.length})',
          style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    ],
  ),
  const SizedBox(height: 4),
  const Text(
    'Tocá la papelera para eliminar una reseña. Se aplica al guardar.',
    style: TextStyle(color: Colors.white38, fontSize: 11),
  ),
  const SizedBox(height: 10),
  ...resenas.map((r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF2E334D),
                  child: Text(
                    r.usuario.isNotEmpty ? r.usuario[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Color(0xFFFF7F6C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.usuario,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 11),
                          const SizedBox(width: 2),
                          Text(r.promedio.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.redAccent, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar esta reseña',
                  onPressed: () => setS(() => resenas.remove(r)),
                ),
              ],
            ),
            if (r.comentario.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                r.comentario,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12, height: 1.3),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      )),
],

const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final n = nombreCtrl.text.trim();
                      if (n.isEmpty) return;
                      Navigator.pop(
                        ctx,
                        PuntoInteres(
                          id: lugar.id,
                          nombre: n,
                          descripcion: descCtrl.text.trim(),
                          lat: lugar.lat,
                          lng: lugar.lng,
                          iconoCode: lugar.iconoCode,
                          colorValue: lugar.colorValue,
                          categoria: lugar.categoria,
                          categoriaLugar: categoriaLugar,
                          horarios: horarios,
                          resenas: resenas,
                          fechaInicio: lugar.fechaInicio,
                          fechaFin: lugar.fechaFin,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('GUARDAR CAMBIOS',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F6C),
                      foregroundColor: const Color(0xFF131622),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══ Helpers ═══
  static Widget _buildFechaPicker({
    required BuildContext context,
    required DateTime? fecha,
    required ValueChanged<DateTime> onPick,
    required VoidCallback onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final hoy = DateTime.now();
              final base = fecha ?? hoy;
              final d = await showDatePicker(
                context: context,
                initialDate: base,
                firstDate: DateTime(hoy.year - 1),
                lastDate: DateTime(hoy.year + 2),
              );
              if (d == null) return;
              if (!context.mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(base),
              );
              if (t == null) return;
              onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text(
              fecha == null
                  ? 'Sin fecha'
                  : '${fecha.day}/${fecha.month}/${fecha.year} · '
                      '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E334D)),
          ),
        ),
        if (fecha != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.redAccent, size: 20),
            onPressed: onClear,
          ),
        ],
      ],
    );
  }

  static Future<HorarioAtencion?> _agregarHorario(
      BuildContext context) async {
    String dia = 'Lunes';
    TimeOfDay? ap, ci;
    return showDialog<HorarioAtencion>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1E2235),
          title: const Text('Nuevo Horario',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: dia,
                dropdownColor: const Color(0xFF161925),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Día'),
                items: [
                  'Lunes',
                  'Martes',
                  'Miércoles',
                  'Jueves',
                  'Viernes',
                  'Sábado',
                  'Domingo'
                ]
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setS(() => dia = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 8, minute: 0));
                        if (t != null) setS(() => ap = t);
                      },
                      child: Text(
                        ap == null ? 'Apertura' : 'Abre: ${ap!.format(ctx)}',
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: ctx,
                            initialTime: const TimeOfDay(hour: 20, minute: 0));
                        if (t != null) setS(() => ci = t);
                      },
                      child: Text(
                        ci == null ? 'Cierre' : 'Cierra: ${ci!.format(ctx)}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (ap != null && ci != null) {
                  Navigator.pop(
                      ctx,
                      HorarioAtencion(
                        dia: dia,
                        apertura: ap!.format(ctx),
                        cierre: ci!.format(ctx),
                      ));
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }
}
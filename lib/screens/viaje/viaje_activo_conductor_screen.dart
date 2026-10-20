import 'package:flutter/material.dart';

class ViajeActivoConductorScreen extends StatefulWidget {
  final String nombre;
  final String run;
  final String vehiculo;
  final String patente;
  final String ruta;

  // Pasajeros aceptados que vienen desde HomeConductorScreen
  final List<Map<String, String>> pasajerosAceptados;

  const ViajeActivoConductorScreen({
    super.key,
    required this.nombre,
    required this.run,
    required this.vehiculo,
    required this.patente,
    required this.ruta,
    required this.pasajerosAceptados,
  });

  @override
  State<ViajeActivoConductorScreen> createState() =>
      _ViajeActivoConductorScreenState();
}

class _ViajeActivoConductorScreenState
    extends State<ViajeActivoConductorScreen> {
  // ── Genera el mensaje descriptivo por cada pasajero ──────────────
  String _mensajeViaje(Map<String, String> p) {
    final nombre = p['pasajero'] ?? '';
    final destino = p['destino'] ?? '';
    final cantidad = int.tryParse(p['cantidad'] ?? '1') ?? 1;
    final equipaje = p['equipaje'] ?? 'sin equipaje';
    // final distancia = p['distancia'] ?? '';

    final acompanante = cantidad > 1
        ? 'con ${cantidad - 1} acompañante${cantidad - 1 > 1 ? 's' : ''}'
        : 'sin acompañante';

    final equipajeTexto = equipaje.toLowerCase().contains('sin')
        ? 'sin equipaje'
        : 'con equipaje';

    return 'Usted está viajando con $nombre en dirección a $destino '
        '$acompanante y $equipajeTexto, que tenga buen viaje.';
  }

  String _mensajeBajada(Map<String, String> p) {
    final nombre = p['pasajero'] ?? '';
    final destino = p['destino'] ?? '';
    final cantidad = int.tryParse(p['cantidad'] ?? '1') ?? 1;
    final acomp = cantidad > 1 ? 'y acompañante' : '';
    return '$nombre $acomp baja en $destino';
  }

  String _distanciaTexto(Map<String, String> p) {
    final km = double.tryParse(p['distancia'] ?? '0') ?? 0;
    if (km >= 1) {
      return '${km.toStringAsFixed(1)} km hasta la parada';
    } else {
      final metros = (km * 1000).toStringAsFixed(0);
      return '$metros m hasta la parada';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            // ── Info del Conductor (parte superior fija) ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'Conductor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(valor: widget.nombre),
                  _InfoRow(valor: widget.run),
                  _InfoRow(valor: widget.vehiculo),
                  _InfoRow(valor: widget.patente),
                  const SizedBox(height: 4),
                  _InfoRow(valor: 'Ruta: ${widget.ruta}', bold: true),
                  const SizedBox(height: 6),
                  const Text(
                    'las paradas dentro de esta ruta también son\ntomadas en cuenta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Caja de mensajes de viaje (scrollable) ────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: widget.pasajerosAceptados.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay pasajeros en el viaje aún.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            widget.pasajerosAceptados.length +
                            1, // +1 para bajadas
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          // ── Mensajes de viaje por pasajero ──
                          if (i < widget.pasajerosAceptados.length) {
                            final p = widget.pasajerosAceptados[i];
                            return _MensajeViaje(
                              mensaje: _mensajeViaje(p),
                              distancia: _distanciaTexto(p),
                            );
                          }

                          // ── Resumen de bajadas al final ──
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.pasajerosAceptados.map((p) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  _mensajeBajada(p),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF555555),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String valor;
  final bool bold;
  const _InfoRow({required this.valor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        valor,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: const Color(0xFF2D2D2D),
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _MensajeViaje extends StatelessWidget {
  final String mensaje;
  final String distancia;

  const _MensajeViaje({required this.mensaje, required this.distancia});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mensaje,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF2D2D2D),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 13,
              color: Color(0xFFFFC107),
            ),
            const SizedBox(width: 4),
            Text(
              distancia,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFFFC107),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

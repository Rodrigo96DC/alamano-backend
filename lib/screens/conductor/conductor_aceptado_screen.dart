import 'package:flutter/material.dart';

class ConductorAceptadoScreen extends StatelessWidget {
  final String rutaDesde;
  final String rutaHasta;
  final bool tieneEquipaje;
  final int cantidadPasajeros;

  // Datos del conductor que acepta (vendrán de la API Laravel)
  final String nombreConductor;
  final String patente;
  final double distanciaKm;

  const ConductorAceptadoScreen({
    super.key,
    required this.rutaDesde,
    required this.rutaHasta,
    required this.tieneEquipaje,
    required this.cantidadPasajeros,
    required this.nombreConductor,
    required this.patente,
    required this.distanciaKm,
  });

  void _cancelar(BuildContext context) {
    // TODO: cancelar solicitud en la API Laravel
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _yaMeSubi(BuildContext context) {
    // TODO: confirmar subida en la API Laravel → navegar a pantalla de viaje en curso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Buen viaje!'),
        backgroundColor: Color(0xFF2E7D32),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título ────────────────────────────────────────
              const Center(
                child: Text(
                  'Pasajero',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Resumen del viaje ─────────────────────────────
              _ResumenRow(label: 'Ruta', valor: '$rutaDesde - $rutaHasta.'),
              const SizedBox(height: 10),
              _ResumenRow(
                label: 'Equipaje',
                valor: tieneEquipaje ? 'SÍ.' : 'NO.',
              ),
              const SizedBox(height: 10),
              _ResumenRow(label: 'Pasajeros', valor: '$cantidadPasajeros.'),
              const SizedBox(height: 24),

              // ── Mensaje del conductor aceptado ────────────────
              Text(
                'El conductor $nombreConductor aceptó su viaje en '
                'el vehículo patente $patente que esta a '
                '${distanciaKm.toStringAsFixed(1)} Km de distancia',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D2D2D),
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // ── Botón Cancelar ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _cancelar(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Botón Ya me subí ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _yaMeSubi(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ya me subí',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget fila resumen ────────────────────────────────────────────

class _ResumenRow extends StatelessWidget {
  final String label;
  final String valor;
  const _ResumenRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF2D2D2D),
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}

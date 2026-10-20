import 'package:flutter/material.dart';

class ViajeActivoPasajeroScreen extends StatelessWidget {
  final String nombre;
  final String run;
  final String rutaDesde;
  final String rutaHasta;
  final bool tieneEquipaje;
  final int cantidadPasajeros;

  // Datos del conductor aceptado (vendrán de la API Laravel)
  final String nombreConductor;
  final String vehiculo;
  final String patente;
  final String distanciaDestino; // ej: "1.5KM" o "800m"

  const ViajeActivoPasajeroScreen({
    super.key,
    required this.nombre,
    required this.run,
    required this.rutaDesde,
    required this.rutaHasta,
    required this.tieneEquipaje,
    required this.cantidadPasajeros,
    required this.nombreConductor,
    required this.vehiculo,
    required this.patente,
    required this.distanciaDestino,
  });

  void _bajar(BuildContext context) {
    // TODO: notificar a la API Laravel que el pasajero bajó
    Navigator.popUntil(context, (route) => route.isFirst);
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
              const SizedBox(height: 16),

              // ── Datos del pasajero ────────────────────────────
              Center(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  run,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Resumen del viaje ─────────────────────────────
              _ResumenRow(label: 'Ruta', valor: '$rutaDesde - $rutaHasta.'),
              const SizedBox(height: 10),
              _ResumenRow(
                label: 'Equipaje',
                valor: tieneEquipaje ? 'SÍ.' : 'NO.',
              ),
              const SizedBox(height: 10),
              _ResumenRow(label: 'Pasajeros', valor: '$cantidadPasajeros.'),
              const SizedBox(height: 28),

              // ── Mensaje del viaje activo ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Text(
                  'Usted esta viajando con el conductor $nombreConductor '
                  'en el vehículo $vehiculo $patente '
                  'en dirección a $rutaHasta.\n'
                  'distancia de su destino: $distanciaDestino\n'
                  'Que tenga buen viaje.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D2D2D),
                    height: 1.7,
                  ),
                ),
              ),

              const Spacer(),

              // ── Botón Bajar ───────────────────────────────────
              Center(
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _bajar(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bajar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ── Widget fila de resumen ─────────────────────────────────────────

class _ResumenRow extends StatelessWidget {
  final String label;
  final String valor;
  const _ResumenRow({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return RichText(
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
    );
  }
}

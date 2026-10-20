import 'package:flutter/material.dart';
import 'package:alamano2_0/screens/viaje/viaje_activo_pasajero_screen.dart';

class EsperaPasajeroScreen extends StatelessWidget {
  final String nombre;
  final String run;
  final String rutaDesde;
  final String rutaHasta;
  final bool tieneEquipaje;
  final int cantidadPasajeros;

  const EsperaPasajeroScreen({
    super.key,
    required this.nombre,
    required this.run,
    required this.rutaDesde,
    required this.rutaHasta,
    required this.tieneEquipaje,
    required this.cantidadPasajeros,
  });

  // TODO: Este método será llamado cuando la API Laravel confirme
  // que un conductor aceptó la solicitud. Recibe los datos del conductor
  // y navega a ViajeActivoPasajeroScreen.
  //
  // void _conductorAcepto(BuildContext context, Map<String, String> conductor) {
  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => ViajeActivoPasajeroScreen(
  //         nombre           : nombre,
  //         run              : run,
  //         rutaDesde        : rutaDesde,
  //         rutaHasta        : rutaHasta,
  //         tieneEquipaje    : tieneEquipaje,
  //         cantidadPasajeros: cantidadPasajeros,
  //         nombreConductor  : conductor['nombre']!,
  //         vehiculo         : conductor['vehiculo']!,
  //         patente          : conductor['patente']!,
  //         distanciaDestino : conductor['distancia']!,
  //       ),
  //     ),
  //   );
  // }

  void _cancelar(BuildContext context) {
    // TODO: cancelar solicitud en la API Laravel
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  // ── Botón solo para pruebas — simula que un conductor acepta ──
  void _simularAceptacion(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ViajeActivoPasajeroScreen(
          nombre: nombre,
          run: run,
          rutaDesde: rutaDesde,
          rutaHasta: rutaHasta,
          tieneEquipaje: tieneEquipaje,
          cantidadPasajeros: cantidadPasajeros,
          nombreConductor: 'Rodrigo Lopez',
          vehiculo: 'Nissan Prymera',
          patente: 'PK-25-56',
          distanciaDestino: '1.5KM',
        ),
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
              const SizedBox(height: 24),

              // ── Resumen ───────────────────────────────────────
              _ResumenRow(label: 'Ruta', valor: '$rutaDesde - $rutaHasta.'),
              const SizedBox(height: 10),
              _ResumenRow(
                label: 'Equipaje',
                valor: tieneEquipaje ? 'SÍ.' : 'NO.',
              ),
              const SizedBox(height: 10),
              _ResumenRow(label: 'Pasajeros', valor: '$cantidadPasajeros.'),
              const SizedBox(height: 28),

              // ── Mensaje de espera ─────────────────────────────
              const Text(
                'Su solicitud a sido enviada correctamente, espere mientras uno de los conductores acepta su viaje.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D2D2D),
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // ── Botón simulación (solo para pruebas) ──────────
              Center(
                child: TextButton(
                  onPressed: () => _simularAceptacion(context),
                  child: const Text(
                    '(Simular conductor acepta — solo pruebas)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Botón Cancelar ────────────────────────────────
              Center(
                child: SizedBox(
                  width: 200,
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

import 'package:flutter/material.dart';
import 'package:alamano2_0/screens/widgets/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/screens/conductor/home_conductor_screen.dart';
import 'package:alamano2_0/screens/pasajero/home_pasajero_screen.dart';

/// Widget base que reemplaza Scaffold en todas las pantallas.
/// El drawer lee los datos del usuario desde SharedPreferences automáticamente.
///
/// Uso mínimo:
///   AppScaffold(body: TuContenido())
///
/// Con ruta:
///   AppScaffold(onCambiarRuta: _cambiarRuta, body: TuContenido())
class AppScaffold extends StatelessWidget {
  final Widget body;
  final VoidCallback? onCambiarRuta;
  final String? titulo;

  const AppScaffold({
    super.key,
    required this.body,
    this.onCambiarRuta,
    this.titulo,
  });

  Future<void> _irAlInicio(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final tipoUsuario = prefs.getString('tipo_usuario') ?? '';
    final nombre = prefs.getString('nombre') ?? '';
    final run = prefs.getString('run') ?? '';
    final direccion = prefs.getString('direccion') ?? '';
    final vehiculo = prefs.getString('vehiculo') ?? 'Sin vehículo';
    final patente = prefs.getString('patente') ?? 'Sin patente';

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => tipoUsuario == 'conductor'
            ? HomeConductorScreen(
                nombre: nombre,
                run: run,
                vehiculo: vehiculo,
                patente: patente,
                ruta: 'Sin ruta asignada',
              )
            : HomePasajeroScreen(
                nombre: nombre,
                run: run,
                direccion: direccion,
              ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      // ── Drawer global ──────────────────────────────────────
      drawer: AppDrawer(onCambiarRuta: onCambiarRuta),
      // ── AppBar con menú izquierda y casa derecha ───────────
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        automaticallyImplyLeading: false,
        // Menú a la izquierda
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF2D2D2D), size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: titulo != null
            ? Text(
                titulo!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D),
                ),
              )
            : null,
        // Casa a la derecha
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.home_outlined,
                color: Color(0xFF2D2D2D),
                size: 28,
              ),
              onPressed: () => _irAlInicio(context),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}

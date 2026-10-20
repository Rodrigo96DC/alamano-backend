import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/screens/login/login_screen.dart';
import 'package:alamano2_0/screens/perfiles/mis_datos_screen.dart';
import 'package:alamano2_0/screens/perfiles/cambiar_contrasena_screen.dart';
import 'package:alamano2_0/screens/helper/reportar_error_screen.dart';
import 'package:alamano2_0/screens/helper/ayuda_screen.dart';
import 'package:alamano2_0/screens/conductor/home_conductor_screen.dart';
import 'package:alamano2_0/screens/pasajero/home_pasajero_screen.dart';
import 'package:alamano2_0/screens/vehiculo/vehiculos_screen.dart';
import 'package:alamano2_0/screens/dev/dev_config_screen.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback? onCambiarRuta;

  const AppDrawer({super.key, this.onCambiarRuta});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _nombre = '';
  String _run = '';
  String _tipoUsuario = '';
  String _direccion = ''; // ← agregar
  String _vehiculo = ''; // ← agregar
  String _patente = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? '';
      _run = prefs.getString('run') ?? '';
      _tipoUsuario = prefs.getString('tipo_usuario') ?? '';
      _direccion = prefs.getString('direccion') ?? ''; // ← agregar
      _vehiculo = prefs.getString('vehiculo') ?? 'Sin vehículo'; // ← agregar
      _patente = prefs.getString('patente') ?? 'Sin patente';
    });
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _mostrarProximamente(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Próximamente: $texto'),
        backgroundColor: const Color(0xFFFFC107),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esConductor = _tipoUsuario == 'conductor';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ── Cabecera con perfil ───────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: const Color(0xFFFFC107),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      esConductor ? Icons.directions_car : Icons.person,
                      size: 32,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _run,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      esConductor ? 'Conductor' : 'Pasajero',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Opciones ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _MenuItem(
                    icon: Icons.home_outlined,
                    label: 'Inicio',
                    onTap: () {
                      Navigator.pop(context); // cierra drawer
                      // Volver al inicio eliminando todo el historial
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _tipoUsuario == 'conductor'
                              ? HomeConductorScreen(
                                  nombre: _nombre,
                                  run: _run,
                                  vehiculo: _vehiculo,
                                  patente: _patente,
                                  ruta: 'Sin ruta asignada',
                                )
                              : HomePasajeroScreen(
                                  nombre: _nombre,
                                  run: _run,
                                  direccion: _direccion,
                                ),
                        ),
                        (route) => false,
                      );
                    },
                  ),

                  if (_tipoUsuario == 'conductor')
                    _MenuItem(
                      icon: Icons.directions_car_outlined,
                      label: 'Mis vehículos',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VehiculosScreen(),
                          ),
                        );
                      },
                    ),
                  _MenuItem(
                    icon: Icons.person_outline,
                    label: 'Mis datos',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MisDatosScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.route_outlined,
                    label: 'Cambiar ruta preferida',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onCambiarRuta != null) {
                        widget.onCambiarRuta!();
                      }
                    },
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline,
                    label: 'Cambiar contraseña',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CambiarContrasenaScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.bug_report_outlined,
                    label: 'Reportar error',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportarErrorScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'Ayuda',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AyudaScreen()),
                      );
                    },
                  ),

                  const Divider(height: 32, indent: 16, endIndent: 16),

                  _MenuItem(
                    icon: Icons.logout,
                    label: 'Cerrar sesión',
                    color: const Color(0xFFC62828),
                    onTap: () async {
                      // Primero mostrar diálogo (ANTES de cerrar el drawer)
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cerrar sesión'),
                          content: const Text(
                            '¿Estás seguro que deseas cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Cerrar sesión',
                                style: TextStyle(color: Color(0xFFC62828)),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmar == true) {
                        if (context.mounted)
                          Navigator.pop(context); // cierra drawer
                        await _cerrarSesion(context);
                      }
                    },
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: '[DEV] Configuracion',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DevConfigScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Versión ───────────────────────────────────────
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'A la Mano v1.0',
                style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF2D2D2D);
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

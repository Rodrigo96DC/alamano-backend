import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/helper/error_reporter.dart';
import 'screens/login/login_screen.dart';
import 'screens/conductor/home_conductor_screen.dart';
import 'screens/pasajero/home_pasajero_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorReporter.inicializar();

  // Verificar si hay sesión guardada
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final tipoUsuario = prefs.getString('tipo_usuario');
  final nombre = prefs.getString('nombre') ?? '';
  final run = prefs.getString('run') ?? '';
  final direccion = prefs.getString('direccion') ?? '';
  final vehiculo = prefs.getString('vehiculo') ?? 'Sin vehículo';
  final patente = prefs.getString('patente') ?? 'Sin patente';

  Widget pantallaInicial;

  if (token != null && token.isNotEmpty && tipoUsuario != null) {
    // Hay sesión guardada → ir directo a la pantalla correcta
    if (tipoUsuario == 'conductor') {
      pantallaInicial = HomeConductorScreen(
        nombre: nombre,
        run: run,
        vehiculo: vehiculo,
        patente: patente,
        ruta: 'Sin ruta asignada',
      );
    } else {
      pantallaInicial = HomePasajeroScreen(
        nombre: nombre,
        run: run,
        direccion: direccion,
      );
    }
  } else {
    // No hay sesión → mostrar login
    pantallaInicial = const LoginScreen();
  }

  runApp(MyApp(pantallaInicial: pantallaInicial));
}

class MyApp extends StatelessWidget {
  final Widget pantallaInicial;
  const MyApp({super.key, required this.pantallaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A la Mano',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: 'sans-serif',
      ),
      home: pantallaInicial,
    );
  }
}

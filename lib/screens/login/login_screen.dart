import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/screens/registro_usuario/register_screen.dart';
import 'package:alamano2_0/screens/registro_usuario/verification_screen.dart';
import 'package:alamano2_0/screens/pasajero/home_pasajero_screen.dart';
import 'package:alamano2_0/screens/conductor/home_conductor_screen.dart';
import 'package:alamano2_0/screens/dev/dev_config_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _verPassword = false;
  bool _cargando = false;

  // TODO: reemplaza con tu IP local actual (ver con ipconfig)
  static const String _baseUrl = 'http://10.55.70.103:9000/api';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      // ── Paso 1: Login ──────────────────────────────────────
      final loginResp = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        }),
      );

      final loginBody = jsonDecode(loginResp.body);

      // Cuenta no verificada → ir a verificación
      if (loginResp.statusCode == 403 && loginBody['verificar'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              idUsuario: loginBody['id_usuario'],
              email: loginBody['email'] ?? '',
            ),
          ),
        );
        return;
      }

      // Credenciales incorrectas u otro error
      if (loginResp.statusCode != 200 || loginBody['success'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loginBody['message'] ?? 'Error al iniciar sesión'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final token = loginBody['token'];
      final tipoUsuario = loginBody['tipo_usuario'];

      // ── Paso 2: Obtener perfil completo ────────────────────
      final perfilResp = await http.get(
        Uri.parse('$_baseUrl/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final perfilBody = jsonDecode(perfilResp.body);

      if (perfilResp.statusCode != 200 || perfilBody['success'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar el perfil'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final perfil = perfilBody['perfil'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('tipo_usuario', tipoUsuario);
      await prefs.setInt('id_usuario', perfil['id_usuario']);
      await prefs.setString('nombre', perfil['nombre'] ?? '');
      await prefs.setString('run', perfil['run'] ?? '');
      await prefs.setString('direccion', perfil['direccion'] ?? '');
      await prefs.setString('vehiculo', perfil['vehiculo'] ?? 'Sin vehículo');
      await prefs.setString('patente', perfil['patente'] ?? 'Sin patente');

      if (!mounted) return;

      // ── Paso 3: Navegar según tipo de usuario ──────────────
      if (tipoUsuario == 'conductor') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeConductorScreen(
              nombre: perfil['nombre'] ?? '',
              run: perfil['run'] ?? '',
              vehiculo: perfil['vehiculo'] ?? 'Sin vehículo',
              patente: perfil['patente'] ?? 'Sin patente',
              ruta: 'Sin ruta asignada',
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomePasajeroScreen(
              nombre: perfil['nombre'] ?? '',
              run: perfil['run'] ?? '',
              direccion: perfil['direccion'] ?? '',
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar con el servidor'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _irARegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 52),

                // ── Logo ──────────────────────────────────────────
                Image.asset(
                  'assets/image/logo.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),

                const SizedBox(height: 6),
                const Text(
                  'Inicia sesión para continuar',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 40),

                // ── Email ─────────────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresa tu email';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                  decoration: _deco(
                    hint: 'Correo electrónico',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Password ──────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_verPassword,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                  decoration:
                      _deco(
                        hint: 'Contraseña',
                        icon: Icons.lock_outline,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF888888),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                ),
                const SizedBox(height: 32),

                // ── Botón Login ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: const Color(0xFF2D2D2D),
                      disabledBackgroundColor: const Color(0xFFFFD96A),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF2D2D2D),
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Link a Registro ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿No tienes cuenta? ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                    GestureDetector(
                      onTap: _irARegistro,
                      child: const Text(
                        'Regístrate',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // ── [DEV] Config ──────────────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DevConfigScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '[DEV] Configuracion',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _deco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

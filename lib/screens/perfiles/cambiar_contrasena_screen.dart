import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  bool _verActual = false;
  bool _verNueva = false;
  bool _verConfirma = false;
  bool _guardando = false;

  static const String _baseUrl = 'http://10.55.70.103:9000/api';

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiarContrasena() async {
    final actual = _actualCtrl.text.trim();
    final nueva = _nuevaCtrl.text.trim();
    final confirma = _confirmaCtrl.text.trim();

    // Validaciones
    if (actual.isEmpty || nueva.isEmpty || confirma.isEmpty) {
      _mostrarError('Completa todos los campos');
      return;
    }
    if (nueva.length < 6) {
      _mostrarError('La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (nueva != confirma) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }
    if (actual == nueva) {
      _mostrarError('La nueva contraseña debe ser diferente a la actual');
      return;
    }

    setState(() => _guardando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final resp = await http.post(
        Uri.parse('$_baseUrl/cambiar-contrasena'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password_actual': actual, 'password_nuevo': nueva}),
      );

      final body = jsonDecode(resp.body);

      if (!mounted) return;

      if (resp.statusCode == 200 && body['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada correctamente'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      } else {
        _mostrarError(body['message'] ?? 'Error al cambiar contraseña');
      }
    } catch (_) {
      _mostrarError('No se pudo conectar con el servidor');
    }

    setState(() => _guardando = false);
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado ────────────────────────────────
              const Text(
                'Cambiar contraseña',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu contraseña actual y luego la nueva',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 32),

              // ── Contraseña actual ─────────────────────────
              const _Label(text: 'Contraseña actual'),
              const SizedBox(height: 6),
              _CampoPassword(
                controller: _actualCtrl,
                hint: 'Ingresa tu contraseña actual',
                ver: _verActual,
                onToggle: () => setState(() => _verActual = !_verActual),
              ),
              const SizedBox(height: 20),

              // ── Nueva contraseña ──────────────────────────
              const _Label(text: 'Nueva contraseña'),
              const SizedBox(height: 6),
              _CampoPassword(
                controller: _nuevaCtrl,
                hint: 'Mínimo 6 caracteres',
                ver: _verNueva,
                onToggle: () => setState(() => _verNueva = !_verNueva),
              ),
              const SizedBox(height: 20),

              // ── Confirmar contraseña ──────────────────────
              const _Label(text: 'Confirmar nueva contraseña'),
              const SizedBox(height: 6),
              _CampoPassword(
                controller: _confirmaCtrl,
                hint: 'Repite la nueva contraseña',
                ver: _verConfirma,
                onToggle: () => setState(() => _verConfirma = !_verConfirma),
              ),
              const SizedBox(height: 36),

              // ── Botón guardar ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _cambiarContrasena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF2D2D2D),
                    disabledBackgroundColor: const Color(0xFFFFD96A),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2D2D2D),
                          ),
                        )
                      : const Text(
                          'Guardar contraseña',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF555555),
      ),
    );
  }
}

class _CampoPassword extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool ver;
  final VoidCallback onToggle;

  const _CampoPassword({
    required this.controller,
    required this.hint,
    required this.ver,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !ver,
      style: const TextStyle(fontSize: 15, color: Color(0xFF2D2D2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF888888),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            ver ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF888888),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
        ),
      ),
    );
  }
}

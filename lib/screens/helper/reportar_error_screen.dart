import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';

class ReportarErrorScreen extends StatefulWidget {
  const ReportarErrorScreen({super.key});

  @override
  State<ReportarErrorScreen> createState() => _ReportarErrorScreenState();
}

class _ReportarErrorScreenState extends State<ReportarErrorScreen> {
  final _descripcionCtrl = TextEditingController();

  String _categoriaSeleccionada = 'general';
  bool _enviando = false;

  static const String _baseUrl = 'http://10.55.70.103:9000/api';

  final List<Map<String, String>> _categorias = [
    {'valor': 'general', 'label': 'Problema general'},
    {'valor': 'login', 'label': 'Inicio de sesión'},
    {'valor': 'ruta', 'label': 'Rutas / viajes'},
    {'valor': 'conductor', 'label': 'Conductor'},
    {'valor': 'pasajero', 'label': 'Pasajero'},
    {'valor': 'notificacion', 'label': 'Notificaciones'},
    {'valor': 'otro', 'label': 'Otro'},
  ];

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarReporte() async {
    if (_descripcionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor describe el problema'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final idUsuario = prefs.getInt('id_usuario');

      final resp = await http.post(
        Uri.parse('$_baseUrl/errores'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_usuario': idUsuario,
          'codigo_error': 'USR_REPORT',
          'mensaje': _descripcionCtrl.text.trim(),
          'detalle': 'Reporte manual del usuario',
          'pantalla': _categoriaSeleccionada,
          'accion': 'reporte_manual',
          'plataforma': 'flutter',
          'version_app': '1.0.0',
          'sistema_operativo': Platform.operatingSystem,
          'dispositivo': Platform.operatingSystemVersion,
          'severidad': 'warning',
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado. ¡Gracias por avisarnos!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar el reporte'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar con el servidor'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => _enviando = false);
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
                'Reportar problema',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cuéntanos qué pasó y lo revisaremos a la brevedad',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 28),

              // ── Categoría ─────────────────────────────────
              const _Label(text: 'Categoría del problema'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categorias.map((cat) {
                  final seleccionado = _categoriaSeleccionada == cat['valor'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _categoriaSeleccionada = cat['valor']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? const Color(0xFFFFC107)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: seleccionado
                              ? const Color(0xFFFFC107)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                      child: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: seleccionado
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: seleccionado
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Descripción ───────────────────────────────
              const _Label(text: 'Descripción del problema'),
              const SizedBox(height: 8),
              TextField(
                controller: _descripcionCtrl,
                maxLines: 6,
                maxLength: 500,
                style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
                decoration: InputDecoration(
                  hintText:
                      'Describe con detalle qué ocurrió, en qué pantalla y qué estabas haciendo...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
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
                    borderSide: const BorderSide(
                      color: Color(0xFFFFC107),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Botón enviar ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviarReporte,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF2D2D2D),
                    disabledBackgroundColor: const Color(0xFFFFD96A),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2D2D2D),
                          ),
                        )
                      : const Text(
                          'Enviar reporte',
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

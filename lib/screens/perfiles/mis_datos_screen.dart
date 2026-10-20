import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';

class MisDatosScreen extends StatefulWidget {
  const MisDatosScreen({super.key});

  @override
  State<MisDatosScreen> createState() => _MisDatosScreenState();
}

class _MisDatosScreenState extends State<MisDatosScreen> {
  // ── Controladores ─────────────────────────────────────
  final _nombreCtrl = TextEditingController();
  final _runCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _editando = false;
  bool _cargando = false;
  bool _guardando = false;

  static const String _baseUrl = 'http://10.55.70.103:9000/api';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _runCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    // Primero cargar desde SharedPreferences (rápido)
    final prefs = await SharedPreferences.getInstance();
    _nombreCtrl.text = prefs.getString('nombre') ?? '';
    _runCtrl.text = prefs.getString('run') ?? '';
    _direccionCtrl.text = prefs.getString('direccion') ?? '';
    _telefonoCtrl.text = prefs.getString('telefono') ?? '';
    _emailCtrl.text = prefs.getString('email') ?? '';

    // Luego actualizar desde la API (datos frescos)
    try {
      final token = prefs.getString('token') ?? '';
      final resp = await http.get(
        Uri.parse('$_baseUrl/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final perfil = body['perfil'];

        setState(() {
          _nombreCtrl.text = perfil['nombre'] ?? '';
          _runCtrl.text = perfil['run'] ?? '';
          _direccionCtrl.text = perfil['direccion'] ?? '';
          _telefonoCtrl.text = perfil['telefono'] ?? '';
          _emailCtrl.text = perfil['email'] ?? '';
        });

        // Actualizar SharedPreferences también
        await prefs.setString('nombre', perfil['nombre'] ?? '');
        await prefs.setString('run', perfil['run'] ?? '');
        await prefs.setString('direccion', perfil['direccion'] ?? '');
        await prefs.setString('telefono', perfil['telefono'] ?? '');
        await prefs.setString('email', perfil['email'] ?? '');
      }
    } catch (_) {
      // Si falla la API, igual se muestran los datos locales
    }

    setState(() => _cargando = false);
  }

  Future<void> _guardarCambios() async {
    if (_nombreCtrl.text.trim().isEmpty || _direccionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y dirección son obligatorios'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final resp = await http.put(
        Uri.parse('$_baseUrl/perfil'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': _nombreCtrl.text.trim(),
          'direccion': _direccionCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
        }),
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['success'] == true) {
        // Actualizar SharedPreferences
        await prefs.setString('nombre', _nombreCtrl.text.trim());
        await prefs.setString('direccion', _direccionCtrl.text.trim());
        await prefs.setString('telefono', _telefonoCtrl.text.trim());

        setState(() => _editando = false);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos actualizados correctamente'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Error al guardar'),
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

    setState(() => _guardando = false);
  }

  void _cancelarEdicion() {
    setState(() => _editando = false);
    _cargarDatos(); // restaurar datos originales
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC107)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Encabezado ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mis datos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        if (!_editando)
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF2D2D2D),
                              size: 24,
                            ),
                            tooltip: 'Editar datos',
                            onPressed: () => setState(() => _editando = true),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _editando
                          ? 'Modifica los campos que desees'
                          : 'Toca el lápiz para editar tu información',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Campos ────────────────────────────────
                    _CampoInfo(
                      label: 'Nombre completo',
                      controller: _nombreCtrl,
                      icon: Icons.person_outline,
                      editando: _editando,
                    ),
                    const SizedBox(height: 14),
                    _CampoInfo(
                      label: 'RUN',
                      controller: _runCtrl,
                      icon: Icons.badge_outlined,
                      editando: false, // RUN nunca se edita
                      bloqueado: true,
                    ),
                    const SizedBox(height: 14),
                    _CampoInfo(
                      label: 'Correo electrónico',
                      controller: _emailCtrl,
                      icon: Icons.email_outlined,
                      editando: false, // email no se edita aquí
                      bloqueado: true,
                    ),
                    const SizedBox(height: 14),
                    _CampoInfo(
                      label: 'Dirección',
                      controller: _direccionCtrl,
                      icon: Icons.home_outlined,
                      editando: _editando,
                    ),
                    const SizedBox(height: 14),
                    _CampoInfo(
                      label: 'Teléfono',
                      controller: _telefonoCtrl,
                      icon: Icons.phone_outlined,
                      editando: _editando,
                      teclado: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // ── Botones de acción ─────────────────────
                    if (_editando) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _guardando ? null : _guardarCambios,
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
                                  'Guardar cambios',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _cancelarEdicion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF888888),
                            side: const BorderSide(color: Color(0xFFCCCCCC)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Widget campo de información ───────────────────────────────────
class _CampoInfo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool editando;
  final bool bloqueado;
  final TextInputType teclado;

  const _CampoInfo({
    required this.label,
    required this.controller,
    required this.icon,
    required this.editando,
    this.bloqueado = false,
    this.teclado = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: bloqueado
                ? const Color(0xFFAAAAAA)
                : const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: !editando || bloqueado,
          keyboardType: teclado,
          style: TextStyle(
            fontSize: 15,
            color: bloqueado
                ? const Color(0xFFAAAAAA)
                : const Color(0xFF2D2D2D),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 20,
              color: bloqueado
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF888888),
            ),
            suffixIcon: bloqueado
                ? const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: Color(0xFFCCCCCC),
                  )
                : null,
            filled: true,
            fillColor: bloqueado
                ? const Color(0xFFF5F5F5)
                : editando
                ? Colors.white
                : const Color(0xFFFAFAFA),
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
              borderSide: BorderSide(
                color: editando && !bloqueado
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFE0E0E0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

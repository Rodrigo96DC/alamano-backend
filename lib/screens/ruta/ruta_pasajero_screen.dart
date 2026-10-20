import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';
import 'package:alamano2_0/helpers/config.dart';

class RutaPasajeroScreen extends StatefulWidget {
  const RutaPasajeroScreen({super.key});

  @override
  State<RutaPasajeroScreen> createState() => _RutaPasajeroScreenState();
}

class _RutaPasajeroScreenState extends State<RutaPasajeroScreen> {
  String _baseUrl = 'http://10.55.70.103:9000/api';

  final List<String> _regiones = [
    'Región Metropolitana',
    'Valparaíso',
    'O\'Higgins',
  ];

  final Map<String, List<String>> _comunasDesde = {
    'Región Metropolitana': ['Melipilla', 'Codigua', 'Santiago', 'Maipú'],
    'Valparaíso': ['Valparaíso', 'Viña del Mar', 'Quilpué'],
    'O\'Higgins': ['Rancagua', 'San Fernando', 'Pichilemu'],
  };

  final Map<String, List<String>> _comunasHasta = {
    'Región Metropolitana': ['Maria Pinto', 'Lolenco', 'Los Rulos', 'El Pico'],
    'Valparaíso': ['Casablanca', 'Olmué', 'Limache'],
    'O\'Higgins': ['Machalí', 'Graneros', 'Codegua'],
  };

  String? _regionSeleccionada;
  String? _comunaDesde;
  String? _comunaHasta;
  bool _rutaPreferida = false;
  bool _guardando = false;

  List<String> get _opcionesDesde => _regionSeleccionada != null
      ? (_comunasDesde[_regionSeleccionada] ?? [])
      : [];

  List<String> get _opcionesHasta => _regionSeleccionada != null
      ? (_comunasHasta[_regionSeleccionada] ?? [])
      : [];

  @override
  void initState() {
    super.initState();
    _cargarRutaFavorita();
    _cargarBaseUrl();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await Config.getBaseUrl();
    setState(() => _baseUrl = url);
  }

  // Cargar ruta favorita si existe
  Future<void> _cargarRutaFavorita() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final resp = await http.get(
        Uri.parse('$_baseUrl/ruta-favorita'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['tiene_favorita'] == true) {
        final region = body['region'] as String;
        setState(() {
          _regionSeleccionada = region;
          _comunaDesde = body['ruta_desde'];
          _comunaHasta = body['ruta_hasta'];
          _rutaPreferida = true;
        });
      }
    } catch (_) {
      // Si falla, simplemente no precarga nada
    }
  }

  Future<void> _guardarRuta() async {
    if (_regionSeleccionada == null ||
        _comunaDesde == null ||
        _comunaHasta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Si marcó guardar como favorita → llamar API
    if (_rutaPreferida) {
      setState(() => _guardando = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token') ?? '';

        final resp = await http.post(
          Uri.parse('$_baseUrl/ruta-favorita'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'ruta_desde': _comunaDesde,
            'ruta_hasta': _comunaHasta,
            'region': _regionSeleccionada,
          }),
        );

        final body = jsonDecode(resp.body);

        if (resp.statusCode != 200 || body['success'] != true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error ${resp.statusCode}: ${body['message'] ?? body.toString()}',
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 6),
            ),
          );
          setState(() => _guardando = false);
          return;
        }

        // Guardar también en SharedPreferences para acceso offline
        await prefs.setString('ruta_desde', _comunaDesde!);
        await prefs.setString('ruta_hasta', _comunaHasta!);
        await prefs.setString('region', _regionSeleccionada!);
        await prefs.setBool('tiene_ruta_favorita', true);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar con el servidor'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _guardando = false);
        return;
      }
      setState(() => _guardando = false);
    }

    if (!mounted) return;

    // Devolver la ruta a HomePasajeroScreen
    Navigator.pop(context, {
      'desde': _comunaDesde,
      'hasta': _comunaHasta,
      'region': _regionSeleccionada,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'A la Mano',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Selecciona tu ruta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Región ────────────────────────────────────────
              const _Label(text: 'Registre su ruta'),
              const SizedBox(height: 8),
              _Dropdown(
                hint: 'Seleccione Región',
                value: _regionSeleccionada,
                items: _regiones,
                onChanged: (val) => setState(() {
                  _regionSeleccionada = val;
                  _comunaDesde = null;
                  _comunaHasta = null;
                }),
              ),
              const SizedBox(height: 20),

              // ── Desde ─────────────────────────────────────────
              const _Label(text: 'Desde'),
              const SizedBox(height: 8),
              _Dropdown(
                hint: 'Seleccione',
                value: _comunaDesde,
                items: _opcionesDesde,
                onChanged: _regionSeleccionada == null
                    ? null
                    : (val) => setState(() => _comunaDesde = val),
              ),
              const SizedBox(height: 20),

              // ── Hasta ─────────────────────────────────────────
              const _Label(text: 'Hasta'),
              const SizedBox(height: 8),
              _Dropdown(
                hint: 'Seleccione',
                value: _comunaHasta,
                items: _opcionesHasta,
                onChanged: _regionSeleccionada == null
                    ? null
                    : (val) => setState(() => _comunaHasta = val),
              ),
              const SizedBox(height: 20),

              // ── Checkbox ruta preferida ───────────────────────
              _CheckRow(
                label: 'Guardar como ruta preferida',
                value: _rutaPreferida,
                onChanged: (v) => setState(() => _rutaPreferida = v!),
              ),
              const SizedBox(height: 36),

              // ── Botón ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarRuta,
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
                          'Guardar Ruta',
                          style: TextStyle(
                            fontSize: 16,
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

// ── Widgets reutilizables ──────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D2D2D),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
          ),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF888888)),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFC107),
            side: const BorderSide(color: Color(0xFFAAAAAA)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
        ),
      ],
    );
  }
}

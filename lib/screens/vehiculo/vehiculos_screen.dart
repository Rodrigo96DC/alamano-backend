import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';
import 'package:alamano2_0/helpers/config.dart';

class VehiculosScreen extends StatefulWidget {
  const VehiculosScreen({super.key});

  @override
  State<VehiculosScreen> createState() => _VehiculosScreenState();
}

class _VehiculosScreenState extends State<VehiculosScreen> {
  String _baseUrl = 'http://10.55.70.103:9000/api';

  List<dynamic> _vehiculos = [];
  List<dynamic> _historial = [];
  bool _cargando = true;
  int _tabActiva = 0; // 0=Activos, 1=Historial

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _cargarBaseUrl();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await Config.getBaseUrl();
    setState(() => _baseUrl = url);
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    await Future.wait([_cargarVehiculos(), _cargarHistorial()]);
    setState(() => _cargando = false);
  }

  Future<void> _cargarVehiculos() async {
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/vehiculos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        setState(() => _vehiculos = body['vehiculos']);
      }
    } catch (_) {}
  }

  Future<void> _cargarHistorial() async {
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/vehiculos/historial'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        setState(() => _historial = body['vehiculos']);
      }
    } catch (_) {}
  }

  Future<void> _activarVehiculo(int idVehiculo) async {
    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('$_baseUrl/vehiculos/$idVehiculo/activar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        await _cargarTodo();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo activado'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _deshabilitarVehiculo(int idVehiculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deshabilitar vehículo'),
        content: const Text(
          '¿Estás seguro? El vehículo quedará deshabilitado pero podrás reactivarlo desde el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Deshabilitar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final token = await _getToken();
      final resp = await http.delete(
        Uri.parse('$_baseUrl/vehiculos/$idVehiculo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        await _cargarTodo();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo deshabilitado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _reactivarVehiculo(int idVehiculo) async {
    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('$_baseUrl/vehiculos/$idVehiculo/reactivar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        await _cargarTodo();
        setState(() => _tabActiva = 0);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo reactivado'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (_) {}
  }

  void _mostrarFormularioAgregar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormularioVehiculo(
        baseUrl: _baseUrl,
        onGuardado: _cargarTodo,
        onReactivar: (idVehiculo) async {
          Navigator.pop(context);
          await _reactivarVehiculo(idVehiculo);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Encabezado ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Vehículos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      Text(
                        'Administra tus vehículos',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  if (_tabActiva == 0)
                    ElevatedButton.icon(
                      onPressed: _mostrarFormularioAgregar,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        foregroundColor: const Color(0xFF2D2D2D),
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Tabs ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _Tab(
                    label: 'Activos',
                    badge: _vehiculos.length,
                    activo: _tabActiva == 0,
                    onTap: () => setState(() => _tabActiva = 0),
                  ),
                  const SizedBox(width: 8),
                  _Tab(
                    label: 'Historial',
                    badge: _historial.length,
                    activo: _tabActiva == 1,
                    onTap: () => setState(() => _tabActiva = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── Contenido ─────────────────────────────────────
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFC107),
                      ),
                    )
                  : _tabActiva == 0
                  ? _vehiculos.isEmpty
                        ? _SinVehiculos(onAgregar: _mostrarFormularioAgregar)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _vehiculos.length,
                            itemBuilder: (_, i) {
                              final v = _vehiculos[i];
                              final bool activo =
                                  v['activo'] == true || v['activo'] == 1;
                              return _VehiculoCard(
                                vehiculo: v,
                                activo: activo,
                                deshabilitado: false,
                                onActivar: () =>
                                    _activarVehiculo(v['id_vehiculo']),
                                onDeshabilitar: () =>
                                    _deshabilitarVehiculo(v['id_vehiculo']),
                                onReactivar: null,
                              );
                            },
                          )
                  : _historial.isEmpty
                  ? const _SinHistorial()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _historial.length,
                      itemBuilder: (_, i) {
                        final v = _historial[i];
                        return _VehiculoCard(
                          vehiculo: v,
                          activo: false,
                          deshabilitado: true,
                          onActivar: null,
                          onDeshabilitar: null,
                          onReactivar: () =>
                              _reactivarVehiculo(v['id_vehiculo']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab ───────────────────────────────────────────────────────────
class _Tab extends StatelessWidget {
  final String label;
  final int badge;
  final bool activo;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.badge,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFFFC107) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? const Color(0xFFFFC107) : const Color(0xFFCCCCCC),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activo
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: activo ? Colors.white : const Color(0xFF888888),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sin vehículos ─────────────────────────────────────────────────
class _SinVehiculos extends StatelessWidget {
  final VoidCallback onAgregar;
  const _SinVehiculos({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes vehículos registrados',
            style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add),
            label: const Text(
              'Agregar vehículo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sin historial ─────────────────────────────────────────────────
class _SinHistorial extends StatelessWidget {
  const _SinHistorial();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text(
            'No hay vehículos deshabilitados',
            style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }
}

// ── Card de vehículo ──────────────────────────────────────────────
class _VehiculoCard extends StatelessWidget {
  final dynamic vehiculo;
  final bool activo;
  final bool deshabilitado;
  final VoidCallback? onActivar;
  final VoidCallback? onDeshabilitar;
  final VoidCallback? onReactivar;

  const _VehiculoCard({
    required this.vehiculo,
    required this.activo,
    required this.deshabilitado,
    required this.onActivar,
    required this.onDeshabilitar,
    required this.onReactivar,
  });

  @override
  Widget build(BuildContext context) {
    final String tipo = vehiculo['tipo_vehiculo'] ?? 'auto';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deshabilitado ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activo ? const Color(0xFFFFC107) : const Color(0xFFE0E0E0),
          width: activo ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: deshabilitado
                      ? const Color(0xFFEEEEEE)
                      : activo
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tipo == 'micro' ? Icons.directions_bus : Icons.directions_car,
                  color: deshabilitado
                      ? const Color(0xFFBBBBBB)
                      : activo
                      ? const Color(0xFFFFC107)
                      : const Color(0xFF888888),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehiculo['marca']} ${vehiculo['modelo']}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: deshabilitado
                            ? const Color(0xFF999999)
                            : const Color(0xFF2D2D2D),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          vehiculo['patente'],
                          style: TextStyle(
                            fontSize: 13,
                            color: deshabilitado
                                ? const Color(0xFFBBBBBB)
                                : const Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tipo == 'micro' ? 'Micro' : 'Auto',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (activo)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFC107)),
                  ),
                  child: const Text(
                    'Activo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFA000),
                    ),
                  ),
                ),
              if (deshabilitado)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                  ),
                  child: const Text(
                    'Deshabilitado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
            ],
          ),

          if (vehiculo['color'] != null ||
              vehiculo['anio'] != null ||
              vehiculo['capacidad_pasajeros'] != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (vehiculo['anio'] != null)
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: '${vehiculo['anio']}',
                  ),
                if (vehiculo['color'] != null)
                  _InfoChip(
                    icon: Icons.color_lens_outlined,
                    label: vehiculo['color'],
                  ),
                if (vehiculo['capacidad_pasajeros'] != null)
                  _InfoChip(
                    icon: Icons.people_outline,
                    label: '${vehiculo['capacidad_pasajeros']} pasajeros',
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              if (!activo && !deshabilitado && onActivar != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onActivar,
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text(
                      'Usar este',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (!activo && !deshabilitado && onActivar != null)
                const SizedBox(width: 8),
              if (!deshabilitado && onDeshabilitar != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeshabilitar,
                    icon: const Icon(Icons.block_outlined, size: 16),
                    label: const Text(
                      'Deshabilitar',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              if (deshabilitado && onReactivar != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReactivar,
                    icon: const Icon(Icons.restore_outlined, size: 16),
                    label: const Text(
                      'Reactivar',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF888888)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }
}

// ── Formulario agregar vehículo ───────────────────────────────────
class _FormularioVehiculo extends StatefulWidget {
  final String baseUrl;
  final VoidCallback onGuardado;
  final Function(int) onReactivar;

  const _FormularioVehiculo({
    required this.baseUrl,
    required this.onGuardado,
    required this.onReactivar,
  });

  @override
  State<_FormularioVehiculo> createState() => _FormularioVehiculoState();
}

class _FormularioVehiculoState extends State<_FormularioVehiculo> {
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _patenteCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _anioCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();
  String _tipoSeleccionado = 'auto';
  bool _guardando = false;

  final List<Map<String, dynamic>> _tipos = [
    {'valor': 'auto', 'label': 'Auto', 'icono': Icons.directions_car},
    {'valor': 'micro', 'label': 'Micro', 'icono': Icons.directions_bus},
  ];

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _patenteCtrl.dispose();
    _colorCtrl.dispose();
    _anioCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_marcaCtrl.text.trim().isEmpty ||
        _modeloCtrl.text.trim().isEmpty ||
        _patenteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marca, modelo y patente son obligatorios'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final resp = await http.post(
        Uri.parse('${widget.baseUrl}/vehiculos'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tipo_vehiculo': _tipoSeleccionado,
          'marca': _marcaCtrl.text.trim(),
          'modelo': _modeloCtrl.text.trim(),
          'patente': _patenteCtrl.text.trim(),
          'color': _colorCtrl.text.trim().isEmpty
              ? null
              : _colorCtrl.text.trim(),
          'anio': _anioCtrl.text.trim().isEmpty
              ? null
              : int.tryParse(_anioCtrl.text.trim()),
          'capacidad_pasajeros': _capacidadCtrl.text.trim().isEmpty
              ? 4
              : int.tryParse(_capacidadCtrl.text.trim()),
        }),
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 409 && body['deshabilitado'] == true) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Vehículo deshabilitado'),
            content: Text(body['message'] ?? ''),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onReactivar(body['id_vehiculo']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: const Color(0xFF2D2D2D),
                ),
                child: const Text('Reactivar'),
              ),
            ],
          ),
        );
        setState(() => _guardando = false);
        return;
      }

      if (resp.statusCode == 409) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Ya existe este vehículo'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _guardando = false);
        return;
      }

      if (resp.statusCode == 201 && body['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onGuardado();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo registrado'),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agregar vehículo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Los campos con * son obligatorios',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 20),

            const Text(
              'Tipo de vehículo *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _tipos.map((tipo) {
                final seleccionado = _tipoSeleccionado == tipo['valor'];
                return GestureDetector(
                  onTap: () => setState(
                    () => _tipoSeleccionado = tipo['valor'] as String,
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tipo['icono'] as IconData,
                          size: 18,
                          color: const Color(0xFF2D2D2D),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tipo['label'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _Campo(
              controller: _marcaCtrl,
              hint: 'Marca *',
              icon: Icons.directions_car_outlined,
            ),
            const SizedBox(height: 12),
            _Campo(
              controller: _modeloCtrl,
              hint: 'Modelo *',
              icon: Icons.car_repair_outlined,
            ),
            const SizedBox(height: 12),
            _Campo(
              controller: _patenteCtrl,
              hint: 'Patente *',
              icon: Icons.pin_outlined,
              caps: true,
            ),
            const SizedBox(height: 12),
            _Campo(
              controller: _colorCtrl,
              hint: 'Color (opcional)',
              icon: Icons.color_lens_outlined,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Campo(
                    controller: _anioCtrl,
                    hint: 'Año',
                    icon: Icons.calendar_today_outlined,
                    numero: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    controller: _capacidadCtrl,
                    hint: 'Capacidad',
                    icon: Icons.people_outline,
                    numero: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: const Color(0xFF2D2D2D),
                  disabledBackgroundColor: const Color(0xFFFFD96A),
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
                        'Guardar vehículo',
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
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool caps;
  final bool numero;

  const _Campo({
    required this.controller,
    required this.hint,
    required this.icon,
    this.caps = false,
    this.numero = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: caps
          ? TextCapitalization.characters
          : TextCapitalization.words,
      keyboardType: numero ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 20),
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

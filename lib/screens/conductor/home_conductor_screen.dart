import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';
import 'package:alamano2_0/screens/ruta/ruta_conductor_screen.dart';
import 'package:alamano2_0/screens/vehiculo/vehiculos_screen.dart';
import 'package:alamano2_0/helpers/config.dart';

class HomeConductorScreen extends StatefulWidget {
  final String nombre;
  final String run;
  final String vehiculo;
  final String patente;
  final String ruta;

  const HomeConductorScreen({
    super.key,
    required this.nombre,
    required this.run,
    required this.vehiculo,
    required this.patente,
    required this.ruta,
  });

  @override
  State<HomeConductorScreen> createState() => _HomeConductorScreenState();
}

class _HomeConductorScreenState extends State<HomeConductorScreen> {
  String _baseUrl = 'http://10.55.70.103:9000/api';

  // Ruta
  String _rutaDesde = '';
  String _rutaHasta = '';
  bool _idaVuelta = false;
  String _region = '';

  // Vehículo
  Map<String, dynamic>? _vehiculoActivo;
  List<dynamic> _todosVehiculos = [];
  bool _cargando = true;

  // Turno
  bool _enRuta = false;
  int? _idEstado;

  // Pasajeros esperando
  List<dynamic> _pasajeros = [];
  bool _cargandoPasajeros = false;
  Timer? _pollingTimer;
  Timer? _gpsTimer;

  // GPS
  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();
    _inicializar();
    _pedirPermisoGPS();
    _cargarBaseUrl();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await Config.getBaseUrl();
    setState(() => _baseUrl = url);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ── GPS ───────────────────────────────────────────────────
  Future<void> _pedirPermisoGPS() async {
    try {
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.whileInUse ||
          permiso == LocationPermission.always) {
        await _obtenerUbicacion();
      }
    } catch (_) {}
  }

  Future<void> _obtenerUbicacion() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitud = pos.latitude;
        _longitud = pos.longitude;
      });
    } catch (_) {}
  }

  // ── Inicializar ───────────────────────────────────────────
  Future<void> _inicializar() async {
    setState(() => _cargando = true);
    await Future.wait([
      _cargarVehiculos(),
      _cargarRutaFavorita(),
      _verificarTurnoActivo(),
    ]);
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
        final vehiculos = List<dynamic>.from(body['vehiculos']);
        setState(() => _todosVehiculos = vehiculos);

        if (vehiculos.length == 1) {
          setState(
            () => _vehiculoActivo = Map<String, dynamic>.from(vehiculos[0]),
          );
          if (vehiculos[0]['activo'] != true && vehiculos[0]['activo'] != 1) {
            await _activarVehiculo(
              vehiculos[0]['id_vehiculo'],
              silencioso: true,
            );
          }
        } else if (vehiculos.length > 1) {
          final activo = vehiculos.firstWhere(
            (v) => v['activo'] == true || v['activo'] == 1,
            orElse: () => null,
          );
          if (activo != null) {
            setState(() => _vehiculoActivo = Map<String, dynamic>.from(activo));
          } else {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _mostrarSelectorVehiculo(),
            );
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _activarVehiculo(
    int idVehiculo, {
    bool silencioso = false,
  }) async {
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('$_baseUrl/vehiculos/$idVehiculo/activar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehículo seleccionado'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _cargarRutaFavorita() async {
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/ruta-favorita-conductor'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['tiene_favorita'] == true) {
        setState(() {
          _rutaDesde = body['ruta_desde'] ?? '';
          _rutaHasta = body['ruta_hasta'] ?? '';
          _region = body['region'] ?? '';
          _idaVuelta = body['ida_vuelta'] ?? false;
        });
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('conductor_tiene_ruta_favorita') ?? false) {
        setState(() {
          _rutaDesde = prefs.getString('conductor_ruta_desde') ?? '';
          _rutaHasta = prefs.getString('conductor_ruta_hasta') ?? '';
          _region = prefs.getString('conductor_region') ?? '';
          _idaVuelta = prefs.getBool('conductor_ida_vuelta') ?? false;
        });
      }
    }
  }

  // ── Verificar turno activo al entrar ──────────────────────
  Future<void> _verificarTurnoActivo() async {
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/conductor/turno-activo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['en_ruta'] == true) {
        setState(() {
          _enRuta = true;
          _idEstado = body['turno']['id_estado'];
        });
        _iniciarPolling();
      }
    } catch (_) {}
  }

  // ── Iniciar turno ─────────────────────────────────────────
  Future<void> _iniciarTurno() async {
    if (_vehiculoActivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un vehículo primero'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_rutaDesde.isEmpty || _rutaHasta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asigna una ruta primero'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Confirmar dirección
    final confirmar = await _mostrarSelectorDireccion();
    if (confirmar == null) return;

    await _obtenerUbicacion();

    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('$_baseUrl/conductor/iniciar-turno'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'origen': confirmar['origen'],
          'destino': confirmar['destino'],
          'region': _region,
          'id_vehiculo': _vehiculoActivo!['id_vehiculo'],
          'asientos_disponibles': _vehiculoActivo!['capacidad_pasajeros'] ?? 4,
          'latitud': _latitud,
          'longitud': _longitud,
        }),
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['success'] == true) {
        setState(() {
          _enRuta = true;
          _idEstado = body['id_estado'];
          _rutaDesde = confirmar!['origen'] ?? '';
          _rutaHasta = confirmar!['destino'] ?? '';
        });
        _iniciarPolling();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Turno iniciado! Buen viaje 🚗'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar el turno'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Selector de dirección (ida o vuelta) ──────────────────
  Future<Map<String, String>?> _mostrarSelectorDireccion() async {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Hacia dónde vas ahora?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selecciona tu dirección de viaje',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 20),
            _DireccionOpcion(
              origen: _rutaDesde,
              destino: _rutaHasta,
              onTap: () => Navigator.pop(context, {
                'origen': _rutaDesde,
                'destino': _rutaHasta,
              }),
            ),
            const SizedBox(height: 10),
            _DireccionOpcion(
              origen: _rutaHasta,
              destino: _rutaDesde,
              onTap: () => Navigator.pop(context, {
                'origen': _rutaHasta,
                'destino': _rutaDesde,
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Finalizar turno ───────────────────────────────────────
  Future<void> _finalizarTurno() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar turno'),
        content: const Text('¿Deseas finalizar tu turno?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, finalizar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('$_baseUrl/conductor/finalizar-turno'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}

    _detenerPolling();
    setState(() {
      _enRuta = false;
      _idEstado = null;
      _pasajeros = [];
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Turno finalizado'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  // ── Polling pasajeros + actualizar GPS ────────────────────
  void _iniciarPolling() {
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();

    _consultarPasajeros();

    // Consultar pasajeros cada 60 seg
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _consultarPasajeros(),
    );

    // Actualizar GPS cada 30 seg
    _gpsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _actualizarUbicacion(),
    );
  }

  void _detenerPolling() {
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();
    _pollingTimer = null;
    _gpsTimer = null;
  }

  Future<void> _consultarPasajeros() async {
    if (!_enRuta) return;
    setState(() => _cargandoPasajeros = true);
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/conductor/pasajeros-esperando'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['success'] == true) {
        setState(() => _pasajeros = List<dynamic>.from(body['pasajeros']));
      }
    } catch (_) {}
    setState(() => _cargandoPasajeros = false);
  }

  Future<void> _actualizarUbicacion() async {
    if (!_enRuta) return;
    try {
      await _obtenerUbicacion();
      if (_latitud == null || _longitud == null) return;
      final token = await _getToken();
      await http.post(
        Uri.parse('$_baseUrl/conductor/actualizar-ubicacion'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'latitud': _latitud, 'longitud': _longitud}),
      );
    } catch (_) {}
  }

  void _mostrarSelectorVehiculo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isDismissible: _vehiculoActivo != null,
      enableDrag: _vehiculoActivo != null,
      builder: (_) => _SelectorVehiculo(
        vehiculos: _todosVehiculos,
        vehiculoActivo: _vehiculoActivo,
        onSeleccionado: (v) async {
          Navigator.pop(context);
          setState(() => _vehiculoActivo = Map<String, dynamic>.from(v));
          await _activarVehiculo(v['id_vehiculo']);
        },
      ),
    );
  }

  void _cambiarRuta() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RutaConductorScreen()),
    );
    if (resultado != null && resultado is Map) {
      setState(() {
        _rutaDesde = resultado['desde'] ?? '';
        _rutaHasta = resultado['hasta'] ?? '';
        _region = resultado['region'] ?? '';
        _idaVuelta = resultado['idaVuelta'] ?? false;
      });
    }
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes[0][0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días 🌅';
    if (hora < 20) return 'Buenas tardes ☀️';
    return 'Buenas noches 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final bool tieneVehiculo = _vehiculoActivo != null;
    final bool puedeIniciar =
        tieneVehiculo && _rutaDesde.isNotEmpty && !_enRuta;

    return AppScaffold(
      onCambiarRuta: _enRuta ? null : _cambiarRuta,
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFC107)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Encabezado ────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFC107),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _iniciales(widget.nombre),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _saludo(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                Text(
                                  widget.nombre,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.run,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _enRuta
                                  ? const Color(0xFFE8F5E9)
                                  : puedeIniciar
                                  ? const Color(0xFFFFF8E1)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _enRuta
                                    ? const Color(0xFF2E7D32)
                                    : puedeIniciar
                                    ? const Color(0xFFFFA000)
                                    : const Color(0xFFCCCCCC),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _enRuta
                                        ? const Color(0xFF2E7D32)
                                        : puedeIniciar
                                        ? const Color(0xFFFFA000)
                                        : const Color(0xFFAAAAAA),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _enRuta
                                      ? 'En ruta'
                                      : puedeIniciar
                                      ? 'Listo'
                                      : 'Inactivo',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _enRuta
                                        ? const Color(0xFF2E7D32)
                                        : puedeIniciar
                                        ? const Color(0xFFFFA000)
                                        : const Color(0xFFAAAAAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Card vehículo ──────────────────────────
                    GestureDetector(
                      onTap: _enRuta
                          ? null
                          : () async {
                              if (_todosVehiculos.length > 1) {
                                _mostrarSelectorVehiculo();
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const VehiculosScreen(),
                                  ),
                                );
                                _inicializar();
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: tieneVehiculo
                                ? const Color(0xFFE0E0E0)
                                : const Color(0xFFFFC107),
                          ),
                        ),
                        child: tieneVehiculo
                            ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: Color(0xFFFFC107),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_vehiculoActivo!['marca']} ${_vehiculoActivo!['modelo']}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2D2D2D),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              _vehiculoActivo!['patente'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF888888),
                                              ),
                                            ),
                                            if (_vehiculoActivo!['color'] !=
                                                null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '• ${_vehiculoActivo!['color']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF888888),
                                                ),
                                              ),
                                            ],
                                            if (_vehiculoActivo!['anio'] !=
                                                null) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '• ${_vehiculoActivo!['anio']}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF888888),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '${_vehiculoActivo!['capacidad_pasajeros']} pasajeros',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!_enRuta)
                                    Icon(
                                      _todosVehiculos.length > 1
                                          ? Icons.swap_horiz
                                          : Icons.chevron_right,
                                      color: const Color(0xFFCCCCCC),
                                    ),
                                ],
                              )
                            : const Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFFFFC107),
                                    size: 22,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Agregar vehículo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFA000),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    if (_todosVehiculos.length > 1 && !_enRuta)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Toca para cambiar de vehículo (${_todosVehiculos.length} disponibles)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // ── Card ruta ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _rutaDesde.isEmpty
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFFFFC107),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            color: Color(0xFFFFC107),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _rutaDesde.isEmpty
                                      ? 'Sin ruta asignada'
                                      : '$_rutaDesde - $_rutaHasta',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _rutaDesde.isEmpty
                                        ? const Color(0xFF999999)
                                        : const Color(0xFF2D2D2D),
                                  ),
                                ),
                                if (_rutaDesde.isNotEmpty)
                                  Row(
                                    children: [
                                      const Text(
                                        '* Ruta favorita',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFFFA000),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_idaVuelta) ...[
                                        const SizedBox(width: 8),
                                        const Text(
                                          '<-> Ida y vuelta',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (!_enRuta) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _cambiarRuta,
                              icon: const Icon(Icons.sync, size: 16),
                              label: Text(
                                _rutaDesde.isEmpty ? 'Asignar' : 'Cambiar',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: const Color(0xFF2D2D2D),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Botón iniciar / finalizar turno ────────
                    if (!_enRuta)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: puedeIniciar ? _iniciarTurno : null,
                          icon: const Icon(Icons.play_circle_outline, size: 20),
                          label: const Text(
                            'Iniciar turno',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFBDBDBD),
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _finalizarTurno,
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            size: 20,
                          ),
                          label: const Text(
                            'Finalizar turno',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC62828),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                    if (!puedeIniciar && !_enRuta)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            !tieneVehiculo
                                ? 'Agrega un vehículo para iniciar turno'
                                : 'Asigna una ruta para iniciar turno',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                      ),

                    // ── Pasajeros esperando ────────────────────
                    if (_enRuta) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pasajeros esperando',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          if (_cargandoPasajeros)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFC107),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _consultarPasajeros,
                              child: const Icon(
                                Icons.refresh,
                                color: Color(0xFFFFC107),
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_pasajeros.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 40,
                                color: Color(0xFFCCCCCC),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No hay pasajeros esperando en tu ruta',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._pasajeros.map((p) => _PasajeroCard(pasajero: p)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Opción de dirección ───────────────────────────────────────────
class _DireccionOpcion extends StatelessWidget {
  final String origen;
  final String destino;
  final VoidCallback onTap;

  const _DireccionOpcion({
    required this.origen,
    required this.destino,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.route_outlined,
              color: Color(0xFFFFC107),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              '$origen - $destino',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}

// ── Card pasajero ─────────────────────────────────────────────────
class _PasajeroCard extends StatelessWidget {
  final dynamic pasajero;
  const _PasajeroCard({required this.pasajero});

  @override
  Widget build(BuildContext context) {
    final int cantidad = pasajero['cantidad_pasajeros'] ?? 1;
    final bool equipaje =
        pasajero['tiene_equipaje'] == true || pasajero['tiene_equipaje'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFFFFC107),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pasajero['nombre'] ?? 'Pasajero',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 13,
                      color: const Color(0xFF888888),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cantidad pasajero${cantidad > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    if (equipaje) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.luggage_outlined,
                        size: 13,
                        color: Color(0xFF888888),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Con equipaje',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Selector de vehículo ──────────────────────────────────────────
class _SelectorVehiculo extends StatelessWidget {
  final List<dynamic> vehiculos;
  final Map<String, dynamic>? vehiculoActivo;
  final Function(dynamic) onSeleccionado;

  const _SelectorVehiculo({
    required this.vehiculos,
    required this.vehiculoActivo,
    required this.onSeleccionado,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecciona un vehículo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Con cuál trabajarás hoy?',
            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          ...vehiculos.map((v) {
            final bool esActivo =
                vehiculoActivo != null &&
                vehiculoActivo!['id_vehiculo'] == v['id_vehiculo'];
            return GestureDetector(
              onTap: () => onSeleccionado(v),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: esActivo ? const Color(0xFFFFF8E1) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: esActivo
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFE0E0E0),
                    width: esActivo ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      color: esActivo
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF888888),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${v['marca']} ${v['modelo']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          Text(
                            v['patente'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (esActivo)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFFFFC107),
                        size: 22,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

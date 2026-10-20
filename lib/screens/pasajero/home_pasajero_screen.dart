import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/helpers/config.dart';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';
import 'package:alamano2_0/screens/ruta/ruta_pasajero_screen.dart';
import 'package:alamano2_0/screens/pasajero/buen_viaje_screen.dart';

class HomePasajeroScreen extends StatefulWidget {
  final String nombre;
  final String run;
  final String direccion;

  const HomePasajeroScreen({
    super.key,
    required this.nombre,
    required this.run,
    required this.direccion,
  });

  @override
  State<HomePasajeroScreen> createState() => _HomePasajeroScreenState();
}

class _HomePasajeroScreenState extends State<HomePasajeroScreen> {
  String _baseUrl = 'http://10.55.70.103:9000/api';

  String _rutaDesde = '';
  String _rutaHasta = '';
  String _region = '';

  bool _tieneEquipaje = false;
  final _cantidadCtrl = TextEditingController(text: '1');

  bool _estoyEsperando = false;
  int? _idEspera;
  bool _registrando = false;
  bool _mostrarOverlay = false;
  String _mensajeOverlay = 'Obteniendo ubicacion...';

  List<dynamic> _conductores = [];
  bool _cargandoConductores = false;

  double? _latitud;
  double? _longitud;

  Timer? _pollingTimer;
  int _intervaloSegundos = 300;

  // Sonidos
  double? _ultimaDistanciaNotificada;

  @override
  void initState() {
    super.initState();
    _cargarBaseUrl();
    _cargarRutaFavorita();
    _verificarEsperaActiva();
    _pedirPermisoGPS();
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await Config.getBaseUrl();
    setState(() => _baseUrl = url);
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

  // ── Sonidos de notificación ───────────────────────────────
 

  // ── Ruta favorita ─────────────────────────────────────────
  Future<void> _cargarRutaFavorita() async {
    try {
      final token = await _getToken();
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
        setState(() {
          _rutaDesde = body['ruta_desde'] ?? '';
          _rutaHasta = body['ruta_hasta'] ?? '';
          _region = body['region'] ?? '';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ruta_desde', _rutaDesde);
        await prefs.setString('ruta_hasta', _rutaHasta);
        await prefs.setString('region', _region);
        await prefs.setBool('tiene_ruta_favorita', true);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('tiene_ruta_favorita') ?? false) {
        setState(() {
          _rutaDesde = prefs.getString('ruta_desde') ?? '';
          _rutaHasta = prefs.getString('ruta_hasta') ?? '';
          _region = prefs.getString('region') ?? '';
        });
      }
    }
  }

  Future<void> _verificarEsperaActiva() async {
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('$_baseUrl/pasajero/espera-activa'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 200 && body['esperando'] == true) {
        setState(() {
          _estoyEsperando = true;
          _idEspera = body['espera']['id_espera'];
        });
        _iniciarPolling();
      }
    } catch (_) {}
  }

  Future<void> _registrarEspera() async {
    if (_rutaDesde.isEmpty || _rutaHasta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero selecciona una ruta'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final cantidad = int.tryParse(_cantidadCtrl.text.trim());
    if (cantidad == null || cantidad < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa una cantidad valida de pasajeros'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConfirmarSolicitudDialog(
        rutaDesde: _rutaDesde,
        rutaHasta: _rutaHasta,
        cantidad: cantidad,
        tieneEquipaje: _tieneEquipaje,
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _registrando = true;
      _mostrarOverlay = true;
      _mensajeOverlay = 'Obteniendo ubicacion...';
    });

    await _obtenerUbicacion();
    setState(() => _mensajeOverlay = 'Registrando solicitud...');

    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('$_baseUrl/pasajero/esperar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'origen': _rutaDesde,
          'destino': _rutaHasta,
          'region': _region,
          'cantidad_pasajeros': cantidad,
          'tiene_equipaje': _tieneEquipaje,
          'latitud': _latitud,
          'longitud': _longitud,
        }),
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['success'] == true) {
        setState(() {
          _estoyEsperando = true;
          _idEspera = body['id_espera'];
          _registrando = false;
          _mostrarOverlay = false;
        });
        _ultimaDistanciaNotificada = null;
        _iniciarPolling();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrado. Te avisaremos cuando haya conductor'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } else {
        setState(() {
          _registrando = false;
          _mostrarOverlay = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al registrar la solicitud'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      setState(() {
        _registrando = false;
        _mostrarOverlay = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo conectar con el servidor'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _abordar() async {
    final conductorActual = _conductores.isNotEmpty ? _conductores[0] : null;

    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('$_baseUrl/pasajero/abordar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}

    _detenerPolling();
    _ultimaDistanciaNotificada = null;
    setState(() {
      _estoyEsperando = false;
      _conductores = [];
      _idEspera = null;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuenViajeScreen(
          conductor: conductorActual,
          nombrePasajero: widget.nombre,
        ),
      ),
    );
  }

  Future<void> _cancelarEspera() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar espera'),
        content: const Text('Deseas cancelar tu espera?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Si, cancelar',
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
        Uri.parse('$_baseUrl/pasajero/cancelar-espera'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}

    _detenerPolling();
    _ultimaDistanciaNotificada = null;
    setState(() {
      _estoyEsperando = false;
      _conductores = [];
      _idEspera = null;
    });
  }

  Future<void> _consultarConductores() async {
    if (_rutaDesde.isEmpty || _rutaHasta.isEmpty) return;
    if (!_estoyEsperando) return;

    setState(() => _cargandoConductores = true);

    try {
      await _obtenerUbicacion();
      final token = await _getToken();

      final uri = Uri.parse('$_baseUrl/pasajero/conductores-disponibles')
          .replace(
            queryParameters: {
              'origen': _rutaDesde,
              'destino': _rutaHasta,
              'region': _region,
              if (_latitud != null) 'latitud': '$_latitud',
              if (_longitud != null) 'longitud': '$_longitud',
            },
          );

      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200 && body['success'] == true) {
        final conductores = List<dynamic>.from(body['conductores']);
        setState(() => _conductores = conductores);

        if (conductores.isNotEmpty && conductores[0]['distancia_km'] != null) {
          final distancia = (conductores[0]['distancia_km'] as num).toDouble();
          
        }
      }
    } catch (_) {}

    setState(() => _cargandoConductores = false);
  }

  void _iniciarPolling() {
    _pollingTimer?.cancel();
    _consultarConductores();
    _pollingTimer = Timer.periodic(
      Duration(seconds: _intervaloSegundos),
      (_) => _consultarConductores(),
    );
  }

  void _detenerPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }


  void _cambiarRuta() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RutaPasajeroScreen()),
    );
    if (resultado != null && resultado is Map) {
      setState(() {
        _rutaDesde = resultado['desde'] ?? '';
        _rutaHasta = resultado['hasta'] ?? '';
        _region = resultado['region'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppScaffold(
          onCambiarRuta: _cambiarRuta,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.run,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Card ruta ─────────────────────────────
                  GestureDetector(
                    onTap: _estoyEsperando ? null : _cambiarRuta,
                    child: Container(
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
                                      ? 'Sin ruta seleccionada'
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
                                  const Text(
                                    '* Ruta favorita',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFFFA000),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_rutaDesde.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _estoyEsperando
                                  ? null
                                  : () => setState(() {
                                      final temp = _rutaDesde;
                                      _rutaDesde = _rutaHasta;
                                      _rutaHasta = temp;
                                    }),
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: const Text(
                                'Cambiar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: const Color(0xFF2D2D2D),
                                disabledBackgroundColor: const Color(
                                  0xFFEEEEEE,
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _estoyEsperando ? null : _cambiarRuta,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text(
                                'Seleccionar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                                foregroundColor: const Color(0xFF2D2D2D),
                                disabledBackgroundColor: const Color(
                                  0xFFEEEEEE,
                                ),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Formulario ────────────────────────────
                  if (!_estoyEsperando) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _tieneEquipaje,
                            onChanged: (v) =>
                                setState(() => _tieneEquipaje = v!),
                            activeColor: const Color(0xFFFFC107),
                            side: const BorderSide(color: Color(0xFFAAAAAA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tengo equipaje',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Cantidad de pasajeros',
                        hintStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.people_outline,
                          color: Color(0xFF888888),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCCCCC),
                          ),
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
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _registrando ? null : _registrarEspera,
                        icon: _registrando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF2D2D2D),
                                ),
                              )
                            : const Icon(Icons.access_time, size: 20),
                        label: Text(
                          _registrando ? 'Registrando...' : 'Estoy esperando',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          foregroundColor: const Color(0xFF2D2D2D),
                          disabledBackgroundColor: const Color(0xFFFFD96A),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ── Estado esperando ──────────────────────
                  if (_estoyEsperando) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Color(0xFFFFA000),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Estas esperando transporte',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFA000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _abordar,
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Ya subi',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                    side: const BorderSide(
                                      color: Color(0xFF2E7D32),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _cancelarEspera,
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Cancelar',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(
                                      color: Colors.redAccent,
                                    ),
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
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Conductores disponibles',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        if (_cargandoConductores)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFC107),
                            ),
                          )
                        else
                          Text(
                            'Actualiza en ${_intervaloSegundos >= 60 ? '${_intervaloSegundos ~/ 60} min' : '$_intervaloSegundos seg'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_conductores.isEmpty)
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
                              Icons.directions_car_outlined,
                              size: 40,
                              color: Color(0xFFCCCCCC),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No hay conductores disponibles en tu ruta por ahora',
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
                      ..._conductores.map((c) => _ConductorCard(conductor: c)),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Overlay de carga ──────────────────────────────
        if (_mostrarOverlay)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 28,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFFFFC107)),
                    const SizedBox(height: 20),
                    Text(
                      _mensajeOverlay,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Card conductor ────────────────────────────────────────────────
class _ConductorCard extends StatelessWidget {
  final dynamic conductor;
  const _ConductorCard({required this.conductor});

  @override
  Widget build(BuildContext context) {
    final String distancia = conductor['distancia_texto'] ?? 'Calculando...';
    final String tiempo = conductor['tiempo_estimado'] ?? '';
    final bool cerca = (conductor['distancia_km'] as num? ?? 99) < 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cerca ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cerca ? const Color(0xFF2E7D32) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cerca ? const Color(0xFFC8E6C9) : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_car,
              color: cerca ? const Color(0xFF2E7D32) : const Color(0xFFFFC107),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conductor['nombre'] ?? 'Conductor',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  '${conductor['marca']} ${conductor['modelo']} - ${conductor['patente']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distancia,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cerca
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF2D2D2D),
                ),
              ),
              if (tiempo.isNotEmpty)
                Text(
                  tiempo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dialog confirmar solicitud ────────────────────────────────────
class _ConfirmarSolicitudDialog extends StatefulWidget {
  final String rutaDesde;
  final String rutaHasta;
  final int cantidad;
  final bool tieneEquipaje;

  const _ConfirmarSolicitudDialog({
    required this.rutaDesde,
    required this.rutaHasta,
    required this.cantidad,
    required this.tieneEquipaje,
  });

  @override
  State<_ConfirmarSolicitudDialog> createState() =>
      _ConfirmarSolicitudDialogState();
}

class _ConfirmarSolicitudDialogState extends State<_ConfirmarSolicitudDialog> {
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF2F2F2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirmar solicitud',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Vas a solicitar transporte hacia:',
            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      color: Color(0xFF2E7D32),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.rutaDesde,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFAAAAAA),
                  size: 20,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.rutaHasta,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 16,
                color: Color(0xFF888888),
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.cantidad} pasajero${widget.cantidad > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              if (widget.tieneEquipaje) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.luggage_outlined,
                  size: 16,
                  color: Color(0xFF888888),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Con equipaje',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Color(0xFF888888)),
          ),
        ),
        ElevatedButton(
          onPressed: _cargando
              ? null
              : () async {
                  setState(() => _cargando = true);
                  await Future.delayed(const Duration(milliseconds: 200));
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF2D2D2D),
                  ),
                )
              : const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

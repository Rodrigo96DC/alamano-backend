import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alamano2_0/helpers/config.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _runCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _verPassword = false;
  bool _cargando = false;
  String? _tipoUsuario; // ← null = sin selección

  String _baseUrl = 'http://10.55.70.103:9000/api';

  @override
  void initState() {
    super.initState();
    _cargarBaseUrl();
  }

  Future<void> _cargarBaseUrl() async {
    final url = await Config.getBaseUrl();
    setState(() => _baseUrl = url);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _runCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Validador RUN chileno ─────────────────────────────────
  String? _validarRun(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu RUN';
    final run = v.trim().replaceAll('.', '').replaceAll('-', '');
    if (run.length < 8 || run.length > 9) return 'RUN invalido';
    final cuerpo = run.substring(0, run.length - 1);
    final dv = run.substring(run.length - 1).toUpperCase();
    if (!RegExp(r'^\d+$').hasMatch(cuerpo)) return 'RUN invalido';

    // Calcular dígito verificador
    int suma = 0;
    int factor = 2;
    for (int i = cuerpo.length - 1; i >= 0; i--) {
      suma += int.parse(cuerpo[i]) * factor;
      factor = factor == 7 ? 2 : factor + 1;
    }
    final resto = suma % 11;
    final dvEsperado = resto == 0
        ? '0'
        : resto == 1
        ? 'K'
        : '${11 - resto}';
    if (dv != dvEsperado) return 'RUN invalido (digito verificador incorrecto)';
    return null;
  }

  Future<void> _registrar() async {
    // Validar tipo de usuario primero
    if (_tipoUsuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona si eres Pasajero o Conductor'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registro'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nombre': _nombreCtrl.text.trim(),
          'run': _runCtrl.text.trim(),
          'direccion': _direccionCtrl.text.trim(),
          'telefono': _telefonoCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'tipo_usuario': _tipoUsuario,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 && body['success'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(
              idUsuario: body['id_usuario'],
              email: _emailCtrl.text.trim(),
            ),
          ),
        );
      } else {
        _mostrarError(body['message'] ?? 'Error al registrar');
      }
    } catch (e) {
      _mostrarError('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completa tus datos para registrarte',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
                const SizedBox(height: 28),

                // ── Tipo de usuario ───────────────────────
                const Text(
                  'Soy...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TipoBtn(
                      label: 'Pasajero',
                      icon: Icons.person_outline,
                      value: 'pasajero',
                      selected: _tipoUsuario,
                      onTap: (v) => setState(() => _tipoUsuario = v),
                    ),
                    const SizedBox(width: 12),
                    _TipoBtn(
                      label: 'Conductor',
                      icon: Icons.directions_car_outlined,
                      value: 'conductor',
                      selected: _tipoUsuario,
                      onTap: (v) => setState(() => _tipoUsuario = v),
                    ),
                  ],
                ),
                if (_tipoUsuario == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      'Debes seleccionar un perfil',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Nombre — solo letras y espacios ───────
                TextFormField(
                  controller: _nombreCtrl,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]'),
                    ),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresa tu nombre';
                    if (v.trim().split(' ').length < 2)
                      return 'Ingresa nombre y apellido';
                    return null;
                  },
                  decoration: _deco(
                    hint: 'Nombre completo',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 12),

                // ── RUN con validación ────────────────────
                TextFormField(
                  controller: _runCtrl,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-kK]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: _validarRun,
                  decoration: _deco(
                    hint: 'RUN (ej: 12.345.678-9)',
                    icon: Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Dirección ─────────────────────────────
                TextFormField(
                  controller: _direccionCtrl,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa tu direccion'
                      : null,
                  decoration: _deco(
                    hint: 'Direccion',
                    icon: Icons.home_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Teléfono — solo números ────────────────
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // opcional
                    if (v.trim().length < 9)
                      return 'Telefono invalido (minimo 9 digitos)';
                    return null;
                  },
                  decoration: _deco(
                    hint: 'Telefono (opcional)',
                    icon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Email ─────────────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresa tu email';
                    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim()))
                      return 'Email invalido';
                    return null;
                  },
                  decoration: _deco(
                    hint: 'Correo electronico',
                    icon: Icons.email_outlined,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Password ──────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_verPassword,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Ingresa una contrasena';
                    if (v.length < 6) return 'Minimo 6 caracteres';
                    return null;
                  },
                  decoration:
                      _deco(
                        hint: 'Contrasena',
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

                // ── Botón Registrar ───────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: const Color(0xFF2D2D2D),
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
                            'Crear cuenta',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
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

// ── Botón tipo usuario ────────────────────────────────────────────
class _TipoBtn extends StatelessWidget {
  final String label;
  final String value;
  final String? selected; // ← nullable
  final IconData icon;
  final ValueChanged<String> onTap;

  const _TipoBtn({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activo = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? const Color(0xFFFFC107) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo ? const Color(0xFFFFC107) : const Color(0xFFCCCCCC),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: activo
                    ? const Color(0xFF2D2D2D)
                    : const Color(0xFF888888),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activo
                      ? const Color(0xFF2D2D2D)
                      : const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

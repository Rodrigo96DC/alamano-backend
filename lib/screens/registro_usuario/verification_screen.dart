import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:alamano2_0/screens/login/login_screen.dart';

class VerificationScreen extends StatefulWidget {
  final int idUsuario;
  final String email;

  const VerificationScreen({
    super.key,
    required this.idUsuario,
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // 6 controladores — uno por cada dígito
  final List<TextEditingController> _ctrl = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());
  bool _cargando = false;
  bool _reenviando = false;

  // TODO: reemplaza con tu IP local
  static const String _baseUrl = 'http://10.55.70.103:9000/api';

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  String get _codigoCompleto => _ctrl.map((c) => c.text).join();

  Future<void> _verificar() async {
    if (_codigoCompleto.length < 6) {
      _mostrarError('Ingresa los 6 dígitos del código');
      return;
    }
    setState(() => _cargando = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verificar'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'id_usuario': widget.idUsuario,
          'codigo': _codigoCompleto,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta verificada! Ya puedes iniciar sesión'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        _mostrarError(body['message'] ?? 'Código inválido o expirado');
      }
    } catch (e) {
      _mostrarError('No se pudo conectar con el servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reenviar-codigo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'id_usuario': widget.idUsuario}),
      );
      final body = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['message'] ?? 'Código reenviado'),
          backgroundColor: body['success'] == true
              ? const Color(0xFF2E7D32)
              : Colors.redAccent,
        ),
      );
    } catch (_) {
      _mostrarError('No se pudo reenviar el código');
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Ícono ─────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFC107), width: 2),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 36,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 24),

              // ── Título ────────────────────────────────────────
              const Text(
                'Verifica tu correo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código de 6 dígitos que enviamos a\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),

              // ── 6 cajas de dígitos ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _CajaDigito(
                    controller: _ctrl[i],
                    focusNode: _focus[i],
                    onChanged: (val) {
                      if (val.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
                      if (val.isEmpty && i > 0) _focus[i - 1].requestFocus();
                      // Auto-verificar cuando se completan los 6 dígitos
                      if (_codigoCompleto.length == 6) _verificar();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Botón verificar ───────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _verificar,
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
                          'Verificar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Reenviar código ───────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No recibiste el código? ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                  GestureDetector(
                    onTap: _reenviando ? null : _reenviar,
                    child: _reenviando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE65100),
                            ),
                          )
                        : const Text(
                            'Reenviar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Caja individual de dígito ──────────────────────────────────────

class _CajaDigito extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _CajaDigito({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2D2D),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:alamano2_0/screens/ruta/ruta_pasajero_screen.dart';

class PasajeroScreen extends StatefulWidget {
  const PasajeroScreen({super.key});

  @override
  State<PasajeroScreen> createState() => _PasajeroScreenState();
}

class _PasajeroScreenState extends State<PasajeroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _runCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _runCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RutaPasajeroScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Títulos ───────────────────────────────────────
                const Center(
                  child: Text(
                    'A Seleccionado el Perfil de Pasajero',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Información del Pasajero',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Campos ────────────────────────────────────────
                _FormField(
                  controller: _nombreCtrl,
                  hint: 'Nombre',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 10),
                _FormField(
                  controller: _runCtrl,
                  hint: 'RUN',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 10),
                _FormField(
                  controller: _direccionCtrl,
                  hint: 'Dirección',
                  icon: Icons.home_outlined,
                ),

                const SizedBox(height: 36),

                // ── Botón ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: const Color(0xFF2D2D2D),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar Información',
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
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

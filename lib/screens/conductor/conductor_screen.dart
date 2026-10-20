import 'package:flutter/material.dart';
// import 'package:alamano2_0/screens/ruta/ruta_conductor_screen.dart';

class ConductorScreen extends StatefulWidget {
  const ConductorScreen({super.key});

  @override
  State<ConductorScreen> createState() => _ConductorScreenState();
}

class _ConductorScreenState extends State<ConductorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _runCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _patenteCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _runCtrl.dispose();
    _direccionCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _patenteCtrl.dispose();
    super.dispose();
  }

  // void _guardar() {
  //   if (_formKey.currentState!.validate()) {
  //     // TODO: enviar datos a la API Laravel antes de navegar
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) => RutaConductorScreen(
  //           nombre: _nombreCtrl.text.trim(),
  //           run: _runCtrl.text.trim(),
  //           vehiculo: '${_marcaCtrl.text.trim()} ${_modeloCtrl.text.trim()}',
  //           patente: _patenteCtrl.text.trim(),
  //         ),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'A Seleccionado el Perfil de Conductor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const _SectionTitle(title: 'Información del Conductor'),
                const SizedBox(height: 12),
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

                const SizedBox(height: 28),
                const Divider(color: Color(0xFFCCCCCC), thickness: 1),
                const SizedBox(height: 20),

                const _SectionTitle(title: 'Información del Vehículo'),
                const SizedBox(height: 12),
                _FormField(
                  controller: _marcaCtrl,
                  hint: 'Marca',
                  icon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: 10),
                _FormField(
                  controller: _modeloCtrl,
                  hint: 'Modelo',
                  icon: Icons.car_repair_outlined,
                ),
                const SizedBox(height: 10),
                _FormField(
                  controller: _patenteCtrl,
                  hint: 'Patente',
                  icon: Icons.pin_outlined,
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF555555),
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

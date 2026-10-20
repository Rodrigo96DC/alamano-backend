import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevConfigScreen extends StatefulWidget {
  const DevConfigScreen({super.key});

  @override
  State<DevConfigScreen> createState() => _DevConfigScreenState();
}

class _DevConfigScreenState extends State<DevConfigScreen> {
  final _ipCtrl = TextEditingController();
  final _puertoCtrl = TextEditingController();
  bool _guardando = false;
  String _urlActual = '';

  @override
  void initState() {
    super.initState();
    _cargarConfig();
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _puertoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('base_url') ?? 'http://10.55.70.103:9000/api';

    // Parsear IP y puerto desde la URL guardada
    final uri = Uri.tryParse(url);
    setState(() {
      _urlActual = url;
      _ipCtrl.text = uri?.host ?? '10.55.70.103';
      _puertoCtrl.text = uri?.port.toString() ?? '9000';
    });
  }

  Future<void> _guardar() async {
    final ip = _ipCtrl.text.trim();
    final puerto = _puertoCtrl.text.trim();

    if (ip.isEmpty || puerto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa IP y puerto'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final nuevaUrl = 'http://$ip:$puerto/api';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', nuevaUrl);

    setState(() {
      _urlActual = nuevaUrl;
      _guardando = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL actualizada: $nuevaUrl'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> _restaurar() async {
    const urlDefault = 'http://10.55.70.103:9000/api';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', urlDefault);
    setState(() {
      _urlActual = urlDefault;
      _ipCtrl.text = '10.55.70.103';
      _puertoCtrl.text = '9000';
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL restaurada al valor por defecto'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        elevation: 0,
        title: const Text(
          'Config. Desarrollo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        // Badge DEV
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'DEV',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Aviso ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Esta pantalla es solo para desarrollo. Eliminar antes de publicar.',
                        style: TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── URL actual ────────────────────────────────
              const Text(
                'URL actual',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  _urlActual.isEmpty ? 'Cargando...' : _urlActual,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Campos ────────────────────────────────────
              const Text(
                'Nueva configuracion',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 12),

              // IP
              TextField(
                controller: _ipCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco(
                  hint: 'IP del servidor (ej: 192.168.1.100)',
                  icon: Icons.computer_outlined,
                ),
              ),
              const SizedBox(height: 12),

              // Puerto
              TextField(
                controller: _puertoCtrl,
                keyboardType: TextInputType.number,
                decoration: _deco(
                  hint: 'Puerto (ej: 9000)',
                  icon: Icons.settings_ethernet_outlined,
                ),
              ),
              const SizedBox(height: 8),

              // Hint ipconfig
              const Text(
                'Obtener IP: ejecuta "ipconfig" en Windows y busca IPv4',
                style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
              const SizedBox(height: 24),

              // ── Botón guardar ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF2D2D2D),
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    _guardando ? 'Guardando...' : 'Guardar URL',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: const Color(0xFF2D2D2D),
                    disabledBackgroundColor: const Color(0xFFFFD96A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Botón restaurar ───────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _restaurar,
                  icon: const Icon(Icons.restore_outlined, size: 20),
                  label: const Text(
                    'Restaurar por defecto',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF888888),
                    side: const BorderSide(color: Color(0xFFCCCCCC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  InputDecoration _deco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }
}

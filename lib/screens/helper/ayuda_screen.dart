import 'package:flutter/material.dart';
import 'package:alamano2_0/screens/widgets/app_scaffold.dart';

class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> {
  int _seccionActiva = 0; // 0=FAQ, 1=Guía, 2=Contacto, 3=Términos

  final List<Map<String, String>> _faq = [
    {
      'pregunta': '¿Cómo solicito un viaje?',
      'respuesta':
          'Inicia sesión como pasajero, selecciona tu ruta desde y hasta dónde quieres ir, indica la cantidad de pasajeros y si tienes equipaje, luego presiona "Solicitar Transporte".',
    },
    {
      'pregunta': '¿Cómo me registro como conductor?',
      'respuesta':
          'Al registrarte selecciona el perfil "Conductor". Luego podrás configurar los datos de tu vehículo y tu ruta desde el menú de perfil.',
    },
    {
      'pregunta': '¿Qué pasa si el conductor no llega?',
      'respuesta':
          'Si el conductor no llega en un tiempo razonable, puedes cancelar la solicitud y volver a solicitarla. También puedes reportar el problema desde el menú "Reportar problema".',
    },
    {
      'pregunta': '¿Cómo cambio mi ruta preferida?',
      'respuesta':
          'Abre el menú lateral (≡) y selecciona "Cambiar ruta preferida". Ahí podrás seleccionar una nueva región, origen y destino.',
    },
    {
      'pregunta': '¿Cómo cancelo una solicitud?',
      'respuesta':
          'Mientras esperas al conductor puedes cancelar la solicitud desde la pantalla de espera. Una vez iniciado el viaje no es posible cancelarlo.',
    },
    {
      'pregunta': '¿La app funciona sin internet?',
      'respuesta':
          'No, A la Mano requiere conexión a internet para funcionar ya que comunica en tiempo real a conductores y pasajeros.',
    },
    {
      'pregunta': '¿Mis datos están seguros?',
      'respuesta':
          'Sí. Tus datos se almacenan de forma segura y nunca son compartidos con terceros. Consulta nuestra política de privacidad para más información.',
    },
  ];

  final List<Map<String, dynamic>> _guia = [
    {
      'paso': '1',
      'titulo': 'Regístrate',
      'descripcion':
          'Crea tu cuenta con tu nombre, RUN, dirección y correo. Recibirás un código de verificación por email.',
      'icono': Icons.person_add_outlined,
    },
    {
      'paso': '2',
      'titulo': 'Verifica tu cuenta',
      'descripcion':
          'Ingresa el código de 6 dígitos que llegó a tu correo para activar tu cuenta.',
      'icono': Icons.mark_email_read_outlined,
    },
    {
      'paso': '3',
      'titulo': 'Inicia sesión',
      'descripcion':
          'Usa tu correo y contraseña para entrar. La app recordará tu sesión.',
      'icono': Icons.login_outlined,
    },
    {
      'paso': '4',
      'titulo': 'Selecciona tu ruta',
      'descripcion':
          'Como pasajero, elige desde dónde y hasta dónde quieres viajar.',
      'icono': Icons.route_outlined,
    },
    {
      'paso': '5',
      'titulo': 'Solicita transporte',
      'descripcion':
          'Indica cuántos pasajeros viajan y si tienen equipaje, luego presiona "Solicitar Transporte".',
      'icono': Icons.directions_car_outlined,
    },
    {
      'paso': '6',
      'titulo': 'Espera confirmación',
      'descripcion':
          'Un conductor cercano recibirá tu solicitud y podrá aceptarla o rechazarla.',
      'icono': Icons.hourglass_empty_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Encabezado ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ayuda',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¿En qué podemos ayudarte?',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 16),

                  // ── Tabs ──────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Tab(
                          label: 'FAQ',
                          activo: _seccionActiva == 0,
                          onTap: () => setState(() => _seccionActiva = 0),
                        ),
                        _Tab(
                          label: 'Guía',
                          activo: _seccionActiva == 1,
                          onTap: () => setState(() => _seccionActiva = 1),
                        ),
                        _Tab(
                          label: 'Contacto',
                          activo: _seccionActiva == 2,
                          onTap: () => setState(() => _seccionActiva = 2),
                        ),
                        _Tab(
                          label: 'Términos',
                          activo: _seccionActiva == 3,
                          onTap: () => setState(() => _seccionActiva = 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),

            // ── Contenido según sección ───────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: _seccionActiva == 0
                    ? _SeccionFAQ(faq: _faq)
                    : _seccionActiva == 1
                    ? _SeccionGuia(guia: _guia)
                    : _seccionActiva == 2
                    ? const _SeccionContacto()
                    : const _SeccionTerminos(),
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
  final bool activo;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFFFC107) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? const Color(0xFFFFC107) : const Color(0xFFCCCCCC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }
}

// ── FAQ ───────────────────────────────────────────────────────────
class _SeccionFAQ extends StatelessWidget {
  final List<Map<String, String>> faq;
  const _SeccionFAQ({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: faq
          .map(
            (item) => _PreguntaItem(
              pregunta: item['pregunta']!,
              respuesta: item['respuesta']!,
            ),
          )
          .toList(),
    );
  }
}

class _PreguntaItem extends StatefulWidget {
  final String pregunta;
  final String respuesta;
  const _PreguntaItem({required this.pregunta, required this.respuesta});

  @override
  State<_PreguntaItem> createState() => _PreguntaItemState();
}

class _PreguntaItemState extends State<_PreguntaItem> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _abierto ? const Color(0xFFFFC107) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.pregunta,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            trailing: Icon(
              _abierto ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF888888),
            ),
            onTap: () => setState(() => _abierto = !_abierto),
          ),
          if (_abierto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.respuesta,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Guía ──────────────────────────────────────────────────────────
class _SeccionGuia extends StatelessWidget {
  final List<Map<String, dynamic>> guia;
  const _SeccionGuia({required this.guia});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: guia
          .map(
            (paso) => _PasoItem(
              paso: paso['paso'],
              titulo: paso['titulo'],
              descripcion: paso['descripcion'],
              icono: paso['icono'],
            ),
          )
          .toList(),
    );
  }
}

class _PasoItem extends StatelessWidget {
  final String paso;
  final String titulo;
  final String descripcion;
  final IconData icono;

  const _PasoItem({
    required this.paso,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              paso,
              style: const TextStyle(
                fontSize: 14,
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
                Row(
                  children: [
                    Icon(icono, size: 18, color: const Color(0xFF888888)),
                    const SizedBox(width: 6),
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contacto ──────────────────────────────────────────────────────
class _SeccionContacto extends StatelessWidget {
  const _SeccionContacto();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contáctanos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Estamos disponibles para ayudarte de lunes a viernes de 9:00 a 18:00 hrs.',
          style: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.5),
        ),
        const SizedBox(height: 20),
        _ContactoItem(
          icono: Icons.email_outlined,
          label: 'Correo',
          valor: 'soporte@alamano.cl',
        ),
        _ContactoItem(
          icono: Icons.phone_outlined,
          label: 'Teléfono',
          valor: '+56 9 XXXX XXXX',
        ),
        _ContactoItem(
          icono: Icons.chat_outlined,
          label: 'WhatsApp',
          valor: '+56 9 XXXX XXXX',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDE7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Para problemas urgentes dentro de la app, usa la opción "Reportar problema" del menú.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF555555),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactoItem extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _ContactoItem({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icono, size: 20, color: const Color(0xFFFFC107)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Términos ──────────────────────────────────────────────────────
class _SeccionTerminos extends StatelessWidget {
  const _SeccionTerminos();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TerminosSeccion(
          titulo: 'Términos y Condiciones',
          contenido:
              'Al usar A la Mano aceptas estos términos. La app conecta conductores y pasajeros para facilitar el transporte compartido. No somos responsables por retrasos o inconvenientes entre usuarios.',
        ),
        _TerminosSeccion(
          titulo: 'Uso del Servicio',
          contenido:
              'El servicio es solo para mayores de 18 años. Está prohibido el uso indebido de la plataforma, incluyendo información falsa o comportamiento inapropiado.',
        ),
        _TerminosSeccion(
          titulo: 'Privacidad de Datos',
          contenido:
              'Recopilamos nombre, RUN, dirección, teléfono y correo electrónico. Esta información se usa exclusivamente para el funcionamiento del servicio y nunca es vendida a terceros.',
        ),
        _TerminosSeccion(
          titulo: 'Modificaciones',
          contenido:
              'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios serán notificados a través de la app.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Última actualización: Marzo 2026',
          style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
        ),
      ],
    );
  }
}

class _TerminosSeccion extends StatelessWidget {
  final String titulo;
  final String contenido;

  const _TerminosSeccion({required this.titulo, required this.contenido});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

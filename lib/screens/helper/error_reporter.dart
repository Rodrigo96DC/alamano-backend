import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alamano2_0/helpers/config.dart';

class ErrorReporter {
  // ── Reporta un error a la API Laravel ────────────────────────
  static Future<void> reportar({
    int? idUsuario,
    String? codigoError,
    required String mensaje,
    String? detalle,
    required String pantalla,
    String? accion,
    String? endpoint,
    String severidad = 'error',
  }) async {
    try {
      final baseUrl = await Config.getBaseUrl(); // ← leer URL dinámica
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      await http.post(
        Uri.parse('$baseUrl/errores'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'id_usuario': idUsuario,
          'codigo_error': codigoError,
          'mensaje': mensaje,
          'detalle': detalle,
          'pantalla': pantalla,
          'accion': accion,
          'endpoint': endpoint,
          'plataforma': 'flutter',
          'version_app': '1.0.0',
          'sistema_operativo': Platform.operatingSystem,
          'dispositivo': Platform.operatingSystemVersion,
          'severidad': severidad,
        }),
      );
    } catch (_) {
      if (kDebugMode) {
        print('[ErrorReporter] No se pudo enviar el error a la API');
      }
    }
  }

  // ── Captura errores globales de Flutter ───────────────────────
  static void inicializar() {
    FlutterError.onError = (FlutterErrorDetails details) async {
      await reportar(
        mensaje: details.exceptionAsString(),
        detalle: details.stack.toString(),
        pantalla: details.library ?? 'desconocido',
        accion: 'FlutterError.onError',
        severidad: 'critico',
      );
    };
  }
}

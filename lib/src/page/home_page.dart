import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ia_restaurant/src/service/menu_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _recognizedText = "¿Cómo puedo ayudarte?";
  String _menu = "";
  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }

  // Función para iniciar el reconocimiento de voz
  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = "Escuchando...";
      });
      _speech.listen(onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
        _getMenu(
            _recognizedText); // Llamar a la función para obtener el menú usando el texto reconocido
      });
    } else {
      setState(() {
        _recognizedText = "No se pudo inicializar el reconocimiento de voz.";
      });
    }
  }

  // Función para detener el reconocimiento de voz
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // Función para obtener el menú generado por la IA
  Future<void> _getMenu(String query) async {
    try {
      final generatedMenu = await generateMenuWithAI(
          query); // Llamada a la función para generar el menú

      // Filtrar caracteres especiales antes de mostrar el menú
      String filteredMenu = removeSpecialCharacters(generatedMenu);

      setState(() {
        _menu = filteredMenu;
        _recognizedText =
            "Menú generado:\n$_menu"; // Muestra el menú generado sin caracteres especiales
      });

      // Hacer que la IA "hable" el menú generado
      await _speak(_menu);
    } catch (e) {
      setState(() {
        _recognizedText = "Error al obtener el menú.";
      });
      await _speak("Lo siento, ocurrió un error al generar el menú.");
    }
  }

  // Función para hacer que la IA "hable" el texto
  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("es-ES");
    await _flutterTts.setPitch(1);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  String decodeUtf8(String text) {
    try {
      // Intentamos decodificar el texto a UTF-8
      return utf8.decode(utf8.encode(text));
    } catch (e) {
      print('Error de codificación: $e');
      return text; // Devuelve el texto original si hay un error
    }
  }

  // Función para eliminar caracteres especiales del texto
  String removeSpecialCharacters(String input) {
    // Esta expresión regular elimina todo lo que no sean letras, números o espacios.
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  // Función para enviar el menú por WhatsApp
  Future<void> _sendMenuByWhatsApp(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Por favor, ingrese un número de teléfono válido")),
      );
      return;
    }

    final formattedPhoneNumber = phoneNumber.trim();

    // Construir el mensaje sin codificación de texto
    String message = "Este es el menú para hoy:\n\n$_menu";

    final Uri url = Uri(
      scheme: 'https',
      host: 'api.whatsapp.com',
      path: '/send',
      queryParameters: {
        'phone': formattedPhoneNumber,
        'text': message,
        'type': 'phone_number',
        'app_absent': '0',
      },
    );

    print("URL de WhatsApp: $url");

    // Usar canLaunchUrl en lugar de canLaunch
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo enviar el menú por WhatsApp")),
      );
    }
  }

  // Función para mostrar el dialog y obtener el número
  Future<void> _showPhoneNumberDialog() async {
    final TextEditingController _phoneController = TextEditingController();

    // Muestra el AlertDialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ingrese el número de teléfono'),
          content: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de teléfono (sin el +)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                String phoneNumber = _phoneController.text;
                if (phoneNumber.isNotEmpty) {
                  _sendMenuByWhatsApp(phoneNumber); // Enviar el menú
                }
                Navigator.pop(context); // Cierra el diálogo
              },
              child: const Text('Enviar Menú'),
            ),
          ],
        );
      },
    );
  }

  // Función para borrar los datos y reiniciar el estado
  void _clearData() {
    setState(() {
      _controller.clear(); // Borra el texto en el campo de entrada
      _recognizedText = "¿Cómo puedo ayudarte?"; // Restablece el texto
      _menu = ""; // Limpia el menú generado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generador de Menú - Restaurante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Escribe tu pregunta...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    String query = _controller.text;
                    if (query.isNotEmpty) {
                      _getMenu(
                          query); // Llamamos a la función para obtener el menú
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 242, 100, 36),
                  ),
                  child: const Text(
                    'Generar Menú',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _clearData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 242, 100, 36),
                  ),
                  child: const Text(
                    'Borrar Datos',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Mostrar el menú generado o el texto de espera
            Text(
              _menu.isEmpty ? 'Esperando menú...' : _menu,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _showPhoneNumberDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 242, 100, 36),
              ),
              child: const Text('Enviar Menú por WhatsApp',
                  style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            // Botón para hablar con la IA
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 242, 100, 36),
              ),
              child: Text(_isListening ? 'Detener Escucha' : 'Hablar con la IA',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
// Agregar icono a la app flutter pub run flutter_launcher_icons:main

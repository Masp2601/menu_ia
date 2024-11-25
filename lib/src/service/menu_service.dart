import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

Future<String> generateMenuWithAI(String query) async {
  const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  final body = jsonEncode({
    "model": "gpt-3.5-turbo", // O usa gpt-4 si prefieres
    "messages": [
      {
        "role": "system",
        "content":
            "Eres un asistente útil que genera menús para restaurantes y debes responder en español, específicamente en español de Colombia. Usa una ortografía y gramática correcta para el español de Colombia agrega tildes y la ñ si es necesario."
      },
      {"role": "user", "content": query},
    ],
    "max_tokens": 150,
    "temperature": 0.7,
  });

  // Realizamos la solicitud POST
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Authorization': 'Bearer ${Config.apiKey}',
      'Content-Type': 'application/json',
    },
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    // Asegúrate de que el texto esté bien codificado en UTF-8
    String menuContent = data['choices'][0]['message']['content'];

    // Si encuentras que el texto tiene problemas, puedes decodificarlo explícitamente
    return utf8.decode(utf8.encode(menuContent));
  } else {
    throw Exception(
        'Error al obtener el menú de la IA: ${response.statusCode}');
  }
}

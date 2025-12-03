import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class ApiService {
  // 🔹 Adresse de ton API Python (PC)
  static const String _baseUrl =
      "https://untragical-mozella-tetrastichous.ngrok-free.dev";

  static const Duration timeout = Duration(seconds: 30);

  // ------------------------------------------------------------
  // 🔹 Envoi d’une question à l’API JuridiBot
  // ------------------------------------------------------------
  static Future<Message> sendMessage(String question) async {
    try {
      final uri = Uri.parse(
        "$_baseUrl/ask?question=${Uri.encodeComponent(question)}",
      );

      final response = await http.get(uri).timeout(timeout);
      print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final answer = data["answer"] ?? "Aucune réponse trouvée.";
        return Message.bot(answer, source: "JuridiBot", category: "Réponse");
      } else {
        return Message.bot(
          "Erreur du serveur (${response.statusCode})",
          source: "Système",
          category: "Erreur",
        );
      }
    } catch (e) {
      return Message.bot(
        "Impossible de contacter JuridiBot.\n"
        "Vérifie que le serveur Python est bien lancé.\n\n"
        "Détail : $e",
        source: "Système",
        category: "Erreur",
      );
    }
  }

  // ------------------------------------------------------------
  // 🔹 Questions rapides (inchangées)
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getQuickQuestions() async {
    return [
      {
        'question': 'Quels sont mes droits en cas de licenciement ?',
        'category': 'Droit du travail',
        'icon': 'work',
      },
      {
        'question': 'Comment renouveler ma CIN ?',
        'category': 'Administratif',
        'icon': 'badge',
      },
      {
        'question': 'Durée maximale d’un CDD ?',
        'category': 'Contrats',
        'icon': 'description',
      },
      {
        'question': 'Procédure déclaration revenus ?',
        'category': 'Fiscal',
        'icon': 'receipt',
      },
    ];
  }
}

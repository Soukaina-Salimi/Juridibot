import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class ApiService {
  // 🔹 Adresse du serveur Python (change l'IP selon ton réseau)
  static const String _baseUrl =
      "http://192.168.100.109:8000"; // ton API locale
  // Exemple : "http://192.168.1.12:8000" si ton PC a une autre IP
  // ou "https://XXXX.ngrok.io" si tu utilises un tunnel

  static const Duration timeout = Duration(seconds: 30);

  /// Envoie une question à l'API Python JuridiBot
  static Future<Message> sendMessage(String question) async {
    try {
      final uri = Uri.parse(
        "$_baseUrl/ask?question=${Uri.encodeComponent(question)}",
      );
      final response = await http.get(uri).timeout(timeout);

      // Vérifie le code de statut
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final bool contextFound = data["context_found"] ?? true;
        final String answer = data["answer"] ?? "Aucune réponse reçue.";
        final List sources = data["sources"] ?? [];

        // 🧠 Si la question n'est pas dans la base juridique
        if (!contextFound) {
          return Message.bot(
            "Je ne peux pas répondre à cette question car elle ne figure pas dans ma base de connaissances juridiques.",
            source: "JuridiBot",
            category: "Hors contexte",
          );
        }

        // ✅ Réponse pertinente
        return Message.bot(
          answer,
          source: sources.isNotEmpty ? sources.join(", ") : "JuridiBot",
          category: "Réponse",
        );
      } else {
        // ⚠️ Erreur serveur
        return Message.bot(
          "Erreur du serveur (${response.statusCode}) lors de la communication avec JuridiBot.",
          source: "Système",
          category: "Erreur",
        );
      }
    } catch (e) {
      // 🚫 Erreur de connexion (serveur non joignable)
      return Message.bot(
        "Impossible de contacter JuridiBot.\nVérifie que le serveur Python est bien lancé sur ton PC.\n\nDétail : $e",
        source: "Système",
        category: "Erreur",
      );
    }
  }

  /// Questions rapides (pour ton écran d'accueil)
  static Future<List<Map<String, dynamic>>> getQuickQuestions() async {
    return [
      {
        'question': 'Quels sont mes droits en cas de licenciement ?',
        'category': 'Droit du travail',
        'icon': 'work',
      },
      {
        'question': 'Quelles sont les procédures de divorce au Maroc ?',
        'category': 'Droit de la famille',
        'icon': 'family_restroom',
      },
      {
        'question': 'Durée maximale d’un CDD au Maroc ?',
        'category': 'Contrats',
        'icon': 'description',
      },
      {
        'question': 'Procédure de renouvellement de la CIN ?',
        'category': 'Administratif',
        'icon': 'badge',
      },
    ];
  }
}

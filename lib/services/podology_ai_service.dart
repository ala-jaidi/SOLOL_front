import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Professional Podology AI Assistant Service
/// Uses Groq API (FREE) for foot scan analysis with LLaMA models
class PodologyAIService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  // Modèle texte pour les conversations
  static const String _textModel = 'llama-3.3-70b-versatile';
  // Modèle vision pour l'analyse d'images (Llama 4 Scout - nouveau modèle Groq)
  static const String _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const String _systemPrompt = '''
Vous êtes **SOLOL AI**, l'assistant intelligent intégré à l'application SOLOL de podologie numérique.

## 🎯 VOTRE MISSION
Accompagner les professionnels de santé dans l'analyse des scans de pieds réalisés avec l'app SOLOL qui utilise la segmentation SAM (Segment Anything Model) pour mesurer précisément les pieds.

## 📱 CONTEXTE DE L'APPLICATION
- L'utilisateur a pris des photos du pied (vue dessus + vue profil)
- Le système SAM a segmenté le pied et calculé les métriques
- Vous avez accès aux données patient et aux mesures du scan

## 🔬 EXPERTISE CLINIQUE

### Pathologies à identifier
- **Hallux Valgus**: Déviation gros orteil > 15°
- **Pronation/Supination**: Analyse de l'appui
- **Pieds plats/creux**: Évaluation de la voûte
- **Métatarsalgies**: Douleurs avant-pied

### Analyse des mesures
- Correspondance longueur/pointure déclarée
- Évaluation largeur avant-pied
- Fiabilité de la mesure (confidence)

### Recommandations semelles
- **Confort**: Pieds normaux
- **Soutien**: Pronation légère
- **Correctrices**: Pathologies marquées
- **Sport**: Activité physique
- **Diabétiques**: Protection zones à risque

## 💬 STYLE DE RÉPONSE
- **Concis et structuré** - Réponses claires, pas de pavés
- **Emojis modérés** - Pour la lisibilité (📊 🔍 ⚠️ 💡 👟)
- **Professionnel** - Terminologie médicale appropriée
- **Actionnable** - Recommandations pratiques

## ⚠️ RÈGLES IMPORTANTES
1. Ne jamais inventer de données - utiliser uniquement ce qui est fourni
2. Signaler si les mesures semblent incohérentes
3. Toujours contextualiser par rapport au profil patient
4. Réponses en français par défaut
''';

  final List<Map<String, dynamic>> _history = [];

  PodologyAIService();

  /// Initialize chat with patient and session context
  void initializeContext({
    required Patient patient,
    required Session session,
  }) {
    _history.clear();
    
    final contextMessage = _buildContextMessage(patient, session);
    _history.add({'role': 'user', 'content': contextMessage});
    _history.add({'role': 'assistant', 'content': _buildInitialResponse(patient, session)});
  }

  String _buildContextMessage(Patient patient, Session session) {
    final metrics = session.footMetrics;
    final buffer = StringBuffer();
    
    buffer.writeln('=== NOUVEAU DOSSIER PATIENT ===');
    buffer.writeln();
    buffer.writeln('📋 PROFIL PATIENT:');
    buffer.writeln('• Nom: ${patient.fullName}');
    buffer.writeln('• Âge: ${patient.age} ans');
    buffer.writeln('• Sexe: ${patient.sexeLabel()}');
    buffer.writeln('• Pointure: ${patient.pointure}');
    buffer.writeln('• Taille: ${patient.taille} cm');
    buffer.writeln('• Poids: ${patient.poids} kg');
    buffer.writeln('• IMC: ${(patient.poids / ((patient.taille / 100) * (patient.taille / 100))).toStringAsFixed(1)}');
    buffer.writeln();
    
    if (metrics.isNotEmpty) {
      buffer.writeln('📏 MÉTRIQUES DU SCAN:');
      for (final m in metrics) {
        buffer.writeln('• ${m.sideLabel}:');
        buffer.writeln('  - Longueur: ${m.formattedLongueur}');
        buffer.writeln('  - Largeur: ${m.formattedLargeur}');
        buffer.writeln('  - Confiance: ${m.confidencePercentage}');
      }
      buffer.writeln();
    }
    
    buffer.writeln('📅 Session du: ${session.formattedDate}');
    buffer.writeln('Statut: ${session.statusLabel}');
    
    return buffer.toString();
  }

  String _buildInitialResponse(Patient patient, Session session) {
    final metrics = session.footMetrics;
    final buffer = StringBuffer();
    
    buffer.writeln('Bonjour, j\'ai bien reçu le dossier de **${patient.fullName}**.');
    buffer.writeln();
    
    if (metrics.isNotEmpty) {
      buffer.writeln('📊 **Résumé des mesures:**');
      for (final m in metrics) {
        buffer.writeln('- ${m.sideLabel}: ${m.formattedLongueur} × ${m.formattedLargeur}');
      }
      buffer.writeln();
      buffer.writeln('Je suis prêt à analyser les images du scan ou à répondre à vos questions cliniques.');
      buffer.writeln();
      buffer.writeln('💡 *Vous pouvez me demander:*');
      buffer.writeln('- Une analyse détaillée des images');
      buffer.writeln('- Des recommandations de semelles');
      buffer.writeln('- L\'identification d\'anomalies potentielles');
      buffer.writeln('- La correspondance pointure/mesures');
    } else {
      buffer.writeln('Aucune mesure n\'est encore disponible pour ce patient.');
      buffer.writeln('Veuillez effectuer un scan pour obtenir une analyse complète.');
    }
    
    return buffer.toString();
  }

  /// Analyze foot scan image with context
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String mimeType,
    required Patient patient,
    required Session session,
    String? additionalPrompt,
  }) async {
    try {
      final prompt = additionalPrompt ?? 
        'Analysez cette image de scan podologique. Identifiez les anomalies visibles, '
        'évaluez la qualité de la segmentation, et fournissez vos observations cliniques.';

      // Compresser l'image pour Groq (max ~4MB en base64, donc ~3MB en bytes)
      Uint8List processedBytes = await _compressImage(imageBytes, mimeType);
      debugPrint('📦 Image après compression: ${processedBytes.length} bytes');
      
      final base64Image = base64Encode(processedBytes);
      const mediaType = 'image/jpeg'; // Toujours JPEG après compression

      // Format OpenAI/Groq pour les images (image_url avec data URI)
      final imageContent = {
        'role': 'user',
        'content': [
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:$mediaType;base64,$base64Image',
            }
          },
          {'type': 'text', 'text': prompt}
        ]
      };
      _history.add(imageContent);

      // Utiliser le modèle vision pour l'analyse d'images
      final reply = await _sendToGroqAPI(useVision: true);
      _history.add({'role': 'assistant', 'content': reply});

      return reply;
    } catch (e, st) {
      debugPrint('PodologyAI analyzeImage error: $e\n$st');
      return 'Erreur lors de l\'analyse de l\'image: $e';
    }
  }

  /// Analyze image from URL
  Future<String> analyzeImageFromUrl({
    required String imageUrl,
    required Patient patient,
    required Session session,
    String? additionalPrompt,
  }) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return 'Impossible de charger l\'image depuis le serveur.';
      }

      final mimeType = response.headers['content-type'] ?? 'image/png';
      return analyzeImage(
        imageBytes: response.bodyBytes,
        mimeType: mimeType,
        patient: patient,
        session: session,
        additionalPrompt: additionalPrompt,
      );
    } catch (e) {
      debugPrint('PodologyAI analyzeImageFromUrl error: $e');
      return 'Erreur lors du chargement de l\'image: $e';
    }
  }

  /// Send a text message to the AI
  Future<String> sendMessage(String message) async {
    try {
      _history.add({'role': 'user', 'content': message});
      final reply = await _sendToGroqAPI();
      _history.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e, st) {
      debugPrint('PodologyAI sendMessage error: $e\n$st');
      return 'Erreur de communication avec l\'assistant: $e';
    }
  }

  /// Stream response for better UX
  Stream<String> streamMessage(String message) async* {
    try {
      _history.add({'role': 'user', 'content': message});
      final reply = await _sendToGroqAPI();
      _history.add({'role': 'assistant', 'content': reply});
      yield reply;
    } catch (e, st) {
      debugPrint('PodologyAI streamMessage error: $e\n$st');
      yield 'Erreur: $e';
    }
  }

  /// Send request to Groq API (OpenAI-compatible format)
  /// [useVision] - Use vision model for image analysis
  Future<String> _sendToGroqAPI({bool useVision = false}) async {
    // Pour le modèle texte, convertir les messages image en texte
    final processedHistory = _history.map((msg) {
      final content = msg['content'];
      if (!useVision && content is List) {
        // Extraire le texte des messages multimodaux pour le modèle texte
        final textParts = (content as List)
            .where((part) => part is Map && part['type'] == 'text')
            .map((part) => part['text'] as String)
            .join('\n');
        return {
          'role': msg['role'],
          'content': textParts.isNotEmpty 
              ? '[Image analysée] $textParts' 
              : '[Image analysée précédemment]',
        };
      }
      return msg;
    }).toList();

    // Build messages with system prompt
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...processedHistory,
    ];

    final modelToUse = useVision ? _visionModel : _textModel;
    debugPrint('🤖 Using model: $modelToUse');

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': modelToUse,
        'max_tokens': 2048,
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        return choices[0]['message']['content'] as String;
      }
      return 'Pas de réponse.';
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'API Error: ${response.statusCode}');
    }
  }

  /// Compress image to reduce size for API
  /// Max size ~500KB for reliable Groq API calls
  Future<Uint8List> _compressImage(Uint8List imageBytes, String mimeType) async {
    try {
      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('⚠️ Impossible de décoder l\'image, envoi original');
        return imageBytes;
      }

      debugPrint('📐 Image originale: ${image.width}x${image.height}, ${imageBytes.length} bytes');

      // Resize if too large (max 1024px on longest side)
      const maxSize = 1024;
      if (image.width > maxSize || image.height > maxSize) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxSize);
        } else {
          image = img.copyResize(image, height: maxSize);
        }
        debugPrint('📐 Image redimensionnée: ${image.width}x${image.height}');
      }

      // Encode as JPEG with quality reduction
      int quality = 85;
      Uint8List compressed = Uint8List.fromList(img.encodeJpg(image, quality: quality));
      
      // Further reduce quality if still too large (target: ~500KB)
      while (compressed.length > 500000 && quality > 20) {
        quality -= 15;
        compressed = Uint8List.fromList(img.encodeJpg(image, quality: quality));
        debugPrint('🔄 Compression qualité $quality: ${compressed.length} bytes');
      }

      debugPrint('✅ Image compressée: ${compressed.length} bytes (qualité: $quality)');
      return compressed;
    } catch (e) {
      debugPrint('❌ Erreur compression: $e, envoi original');
      return imageBytes;
    }
  }

  /// Get quick analysis prompts
  static List<QuickPrompt> getQuickPrompts() {
    return [
      QuickPrompt(
        icon: '🔍',
        label: 'Analyse complète',
        prompt: 'Effectuez une analyse complète des métriques et identifiez toute anomalie potentielle.',
      ),
      QuickPrompt(
        icon: '👟',
        label: 'Semelles recommandées',
        prompt: 'Quelles semelles orthopédiques recommandez-vous pour ce patient en fonction des mesures?',
      ),
      QuickPrompt(
        icon: '📏',
        label: 'Vérifier pointure',
        prompt: 'La pointure indiquée correspond-elle aux mesures relevées? Y a-t-il un écart significatif?',
      ),
      QuickPrompt(
        icon: '⚠️',
        label: 'Anomalies',
        prompt: 'Identifiez les anomalies ou pathologies potentielles basées sur les métriques disponibles.',
      ),
      QuickPrompt(
        icon: '📊',
        label: 'Rapport clinique',
        prompt: 'Générez un rapport clinique synthétique pour ce patient incluant observations et recommandations.',
      ),
    ];
  }

  /// Clear conversation history (keep initial context)
  void clearHistory() {
    if (_history.length > 2) {
      final initial = _history.take(2).toList();
      _history.clear();
      _history.addAll(initial);
    }
  }

  /// Get full history for display
  List<AIMessage> getDisplayHistory() {
    final messages = <AIMessage>[];
    
    for (int i = 0; i < _history.length; i++) {
      final msg = _history[i];
      final isUser = msg['role'] == 'user';
      
      // Skip the initial context message (index 0)
      if (i == 0) continue;
      
      String text = '';
      bool hasImage = false;
      
      final content = msg['content'];
      if (content is String) {
        text = content;
      } else if (content is List) {
        for (final part in content) {
          if (part is Map && part['type'] == 'text') {
            text += part['text'] ?? '';
          } else if (part is Map && part['type'] == 'image') {
            hasImage = true;
          }
        }
      }
      
      if (text.isNotEmpty || hasImage) {
        messages.add(AIMessage(
          content: text,
          isUser: isUser,
          hasImage: hasImage,
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return messages;
  }
}

/// Quick prompt suggestion
class QuickPrompt {
  final String icon;
  final String label;
  final String prompt;

  QuickPrompt({
    required this.icon,
    required this.label,
    required this.prompt,
  });
}

/// AI Message for display
class AIMessage {
  final String content;
  final bool isUser;
  final bool hasImage;
  final DateTime timestamp;

  AIMessage({
    required this.content,
    required this.isUser,
    this.hasImage = false,
    required this.timestamp,
  });
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MeasurementService {
  // API Base URL from environment variables
  static String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.175:8000';

  /// Analyse hybride avec les deux vues (dessus + profil)
  /// Appelle séquentiellement /measure/top/ et /measure/side/
  Future<Map<String, dynamic>> analyzeHybrid({
    required File topView,
    required File sideView,
    String footSide = 'right', // 'right' ou 'left'
  }) async {
    try {
      debugPrint('🚀 Analyse hybride: envoi des deux vues (foot_side: $footSide)');
      
      // 1. Analyser la vue de dessus (largeur)
      debugPrint('📐 Étape 1/2: Analyse vue dessus...');
      final topResult = await analyzeTopView(image: topView, footSide: footSide);
      
      // 2. Analyser la vue de profil (longueur)
      debugPrint('📏 Étape 2/2: Analyse vue profil...');
      final sideResult = await analyzeSideView(image: sideView, footSide: footSide);
      
      // 3. Combiner les résultats
      final combinedResult = {
        'success': true,
        'foot_side': footSide,
        'length_cm': sideResult['length_cm'] ?? 0.0,
        'width_cm': topResult['width_cm'] ?? 0.0,
        'toe_angle_deg': topResult['toe_angle_deg'] ?? 0.0,
        'toe_width_cm': topResult['toe_width_cm'] ?? 0.0,
        'confidence': sideResult['confidence'] ?? 0.0,
        'top_debug_image_url': topResult['debug_image_url'],
        'side_debug_image_url': sideResult['debug_image_url'],
        'dxf_url': topResult['dxf_url'] ?? sideResult['dxf_url'],
      };
      
      debugPrint('✅ Analyse hybride terminée: L=${combinedResult['length_cm']}cm, W=${combinedResult['width_cm']}cm');
      return combinedResult;
      
    } catch (e) {
      debugPrint('❌ Erreur mesure hybride: $e');
      rethrow;
    }
  }

  /// Analyse la vue de dessus uniquement (Largeur, Angle orteil)
  /// Fallback si le backend supporte les endpoints séparés
  Future<Map<String, dynamic>> analyzeTopView({
    required File image,
    String footSide = 'right',
  }) async {
    final uri = Uri.parse('$_baseUrl/measure/top/');
    final request = http.MultipartRequest('POST', uri);
    request.fields['foot_side'] = footSide;
    
    final file = await http.MultipartFile.fromPath('image', image.path);
    request.files.add(file);

    try {
      debugPrint('🚀 Envoi TOP view vers $uri');
      final responseStream = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('Timeout TOP (120s)'),
      );
      
      final response = await http.Response.fromStream(responseStream);
      
      if (response.statusCode == 200) {
        debugPrint('✅ TOP view analysée avec succès');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erreur serveur TOP: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur TOP view: $e');
      rethrow;
    }
  }

  /// Analyse la vue de profil uniquement (Longueur)
  /// Fallback si le backend supporte les endpoints séparés
  Future<Map<String, dynamic>> analyzeSideView({
    required File image,
    String footSide = 'right',
  }) async {
    final uri = Uri.parse('$_baseUrl/measure/side/');
    final request = http.MultipartRequest('POST', uri);
    request.fields['foot_side'] = footSide;
    
    final file = await http.MultipartFile.fromPath('image', image.path);
    request.files.add(file);

    try {
      debugPrint('🚀 Envoi SIDE view vers $uri');
      final responseStream = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw Exception('Timeout SIDE (120s)'),
      );
      
      final response = await http.Response.fromStream(responseStream);
      
      if (response.statusCode == 200) {
        debugPrint('✅ SIDE view analysée avec succès');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erreur serveur SIDE: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Erreur SIDE view: $e');
      rethrow;
    }
  }

  // Helper to construct full URL for images served by the backend
  static String getImageUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    final path = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return '$_baseUrl/$path';
  }
}

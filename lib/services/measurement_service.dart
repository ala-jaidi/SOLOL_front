import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MeasurementService {
  // CONFIGURATION API
  // Pour la production (Podologue) : Remplacer par l'IP fixe du PC ou l'URL du serveur Cloud
  // Ex: 'http://192.168.1.15:8000' ou 'https://api.lidarmesure.com'
  static const String _baseUrl = 'http://192.168.1.175:8000';

  /// Analyse la vue de dessus (Largeur, Angle orteil)
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

  /// Analyse la vue de profil (Longueur)
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

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MeasurementService {
  // CONFIGURATION API
  // Pour la production (Podologue) : Remplacer par l'IP fixe du PC ou l'URL du serveur Cloud
  // Ex: 'http://192.168.1.15:8000' ou 'https://api.lidarmesure.com'
  static const String _baseUrl = 'http://192.168.1.175:8000';

  /// Analyse hybride avec les deux vues (dessus + profil) en une seule requête
  /// Compatible avec l'endpoint POST /measure du backend python_test_solol
  Future<Map<String, dynamic>> analyzeHybrid({
    required File topView,
    required File sideView,
    String footSide = 'right', // 'right' ou 'left'
  }) async {
    final uri = Uri.parse('$_baseUrl/measure');
    final request = http.MultipartRequest('POST', uri);
    
    // Ajouter le paramètre foot_side
    request.fields['foot_side'] = footSide;
    
    // Ajouter les deux images
    final topFile = await http.MultipartFile.fromPath('top_view', topView.path);
    final sideFile = await http.MultipartFile.fromPath('side_view', sideView.path);
    request.files.add(topFile);
    request.files.add(sideFile);

    try {
      debugPrint('🚀 Envoi mesure hybride vers $uri (foot_side: $footSide)');
      final responseStream = await request.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () => throw Exception('Timeout mesure hybride (180s)'),
      );
      
      final response = await http.Response.fromStream(responseStream);
      
      if (response.statusCode == 200) {
        debugPrint('✅ Mesure hybride analysée avec succès');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Erreur serveur: ${response.body}');
      }
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

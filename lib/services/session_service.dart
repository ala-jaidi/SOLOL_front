import 'package:flutter/foundation.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/foot_metrics.dart';
import 'package:lidarmesure/models/foot_scan.dart';
import 'package:lidarmesure/models/medical_questionnaire.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  Future<List<Session>> getAllSessions() async {
    try {
      final sessionsData = await SupabaseService.select(
        'sessions',
        orderBy: 'created_at',
        ascending: false,
      );
      
      List<Session> sessions = [];
      for (var sessionJson in sessionsData) {
        final session = await _buildSession(sessionJson);
        sessions.add(session);
      }
      
      return sessions;
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }

  Future<List<Session>> getSessionsByPatientId(String patientId) async {
    try {
      final sessionsData = await SupabaseService.select(
        'sessions',
        filters: {'patient_id': patientId},
        orderBy: 'created_at',
        ascending: false,
      );
      
      List<Session> sessions = [];
      for (var sessionJson in sessionsData) {
        final session = await _buildSession(sessionJson);
        sessions.add(session);
      }
      
      return sessions;
    } catch (e) {
      debugPrint('Error loading patient sessions: $e');
      return [];
    }
  }

  Future<Session?> getSessionById(String id) async {
    try {
      final sessionData = await SupabaseService.selectSingle(
        'sessions',
        filters: {'id': id},
      );
      
      if (sessionData == null) return null;
      
      return await _buildSession(sessionData);
    } catch (e) {
      debugPrint('Error getting session: $e');
      return null;
    }
  }

  Future<String> addSession(Session session) async {
    try {
      final sessionData = {
        'id': const Uuid().v4(),
        'patient_id': session.patientId,
        'status': session.status.name,
        'valid': session.valid,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final result = await SupabaseService.insert('sessions', sessionData);
      final sessionId = result.first['id'] as String;
      
      // Add related data
      for (var metric in session.footMetrics) {
        await _addFootMetric(sessionId, metric);
      }
      
      if (session.footScan != null) {
        await _addFootScan(sessionId, session.footScan!);
      }
      
      for (var questionnaire in session.questionnaires) {
        await _addQuestionnaire(sessionId, questionnaire);
      }
      return sessionId;
    } catch (e) {
      debugPrint('Error adding session: $e');
      throw Exception('Échec de l\'ajout de la session');
    }
  }

  Future<void> updateSession(Session session) async {
    try {
      await SupabaseService.update(
        'sessions',
        {
          'status': session.status.name,
          'valid': session.valid,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': session.id},
      );
      
      // Update related data (delete and re-add for simplicity)
      await SupabaseService.delete('foot_metrics', filters: {'session_id': session.id});
      await SupabaseService.delete('foot_scans', filters: {'session_id': session.id});
      await SupabaseService.delete('medical_questionnaires', filters: {'session_id': session.id});
      
      for (var metric in session.footMetrics) {
        await _addFootMetric(session.id, metric);
      }
      
      if (session.footScan != null) {
        await _addFootScan(session.id, session.footScan!);
      }
      
      for (var questionnaire in session.questionnaires) {
        await _addQuestionnaire(session.id, questionnaire);
      }
    } catch (e) {
      debugPrint('Error updating session: $e');
      throw Exception('Échec de la mise à jour de la session');
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      await SupabaseService.delete('sessions', filters: {'id': id});
    } catch (e) {
      debugPrint('Error deleting session: $e');
      throw Exception('Échec de la suppression de la session');
    }
  }

  // Private helper methods
  Future<Session> _buildSession(Map<String, dynamic> sessionData) async {
    final sessionId = sessionData['id'] as String;
    
    // Load foot metrics
    final metricsData = await SupabaseService.select(
      'foot_metrics',
      filters: {'session_id': sessionId},
    );
    final metrics = metricsData.map((json) => FootMetrics.fromJson(json)).toList();
    
    // Load foot scan
    final scanData = await SupabaseService.selectSingle(
      'foot_scans',
      filters: {'session_id': sessionId},
    );
    final scan = scanData != null ? FootScan.fromJson(scanData) : null;
    
    // Load questionnaires
    final questionnairesData = await SupabaseService.select(
      'medical_questionnaires',
      filters: {'session_id': sessionId},
    );
    final questionnaires = questionnairesData
        .map((json) => MedicalQuestionnaire.fromJson(json))
        .toList();
    
    // Robust date parsing (handle potential nulls or format issues if needed)
    final createdAtStr = sessionData['created_at'] as String?;
    final updatedAtStr = sessionData['updated_at'] as String?;

    return Session(
      id: sessionId,
      patientId: sessionData['patient_id'] as String,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == sessionData['status'],
        orElse: () => SessionStatus.completed,
      ),
      valid: sessionData['valid'] as bool? ?? true,
      footMetrics: metrics,
      footScan: scan,
      questionnaires: questionnaires,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now(),
    );
  }

  Future<void> _addFootMetric(String sessionId, FootMetrics metric) async {
    final data = {
      'id': const Uuid().v4(),
      'session_id': sessionId,
      'side': metric.side.name,
      'longueur': metric.longueur,
      'largeur': metric.largeur,
      'confidence': metric.confidence,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await SupabaseService.insert('foot_metrics', data);
  }

  Future<void> _addFootScan(String sessionId, FootScan scan) async {
    final data = {
      'id': const Uuid().v4(),
      'session_id': sessionId,
      'top_view': scan.topView,
      'side_view': scan.sideView,
      'angle': scan.angle.name,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await SupabaseService.insert('foot_scans', data);
  }

  Future<void> _addQuestionnaire(String sessionId, MedicalQuestionnaire questionnaire) async {
    final data = {
      'id': const Uuid().v4(),
      'session_id': sessionId,
      'cleDeLaQuestion': questionnaire.cleDeLaQuestion,
      if (questionnaire.condition != null) 'condition': questionnaire.condition!.name,
      'reponse': questionnaire.reponse,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    await SupabaseService.insert('medical_questionnaires', data);
  }
}

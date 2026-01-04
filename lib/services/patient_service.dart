import 'package:flutter/foundation.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';
import 'package:uuid/uuid.dart';

class PatientService {
  Future<List<Patient>> getAllPatients() async {
    try {
      final data = await SupabaseService.select(
        'patients',
        orderBy: 'created_at',
        ascending: false,
      );
      
      return data.map((json) => Patient.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading patients: $e');
      return [];
    }
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      final data = await SupabaseService.selectSingle(
        'patients',
        filters: {'id': id},
      );
      
      return data != null ? Patient.fromJson(data) : null;
    } catch (e) {
      debugPrint('Error getting patient: $e');
      return null;
    }
  }

  Future<Patient> addPatient(Patient patient) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      final patientData = patient.toJson();
      // Ensure id and timestamps exist and use snake_case keys to match DB
      patientData['id'] = patient.id.isNotEmpty ? patient.id : const Uuid().v4();
      patientData['created_at'] = patientData['created_at'] ?? nowIso;
      patientData['updated_at'] = nowIso;
      final rows = await SupabaseService.insert('patients', patientData);
      if (rows.isEmpty) throw Exception('Insertion sans retour');
      return Patient.fromJson(rows.first);
    } catch (e) {
      debugPrint('Error adding patient: $e');
      throw Exception('Échec de l\'ajout du patient: $e');
    }
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      final patientData = patient.toJson();
      patientData['updated_at'] = DateTime.now().toIso8601String();
      
      await SupabaseService.update(
        'patients',
        patientData,
        filters: {'id': patient.id},
      );
    } catch (e) {
      debugPrint('Error updating patient: $e');
      throw Exception('Échec de la mise à jour du patient');
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      await SupabaseService.delete('patients', filters: {'id': id});
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      throw Exception('Échec de la suppression du patient');
    }
  }

  /// Upload avatar to Supabase Storage
  Future<String?> uploadAvatar({
    required String patientId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final path = 'avatars/$patientId/$fileName';
      
      await SupabaseConfig.client.storage
          .from('patient-avatars')
          .uploadBinary(path, fileBytes);
      
      final publicUrl = SupabaseConfig.client.storage
          .from('patient-avatars')
          .getPublicUrl(path);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  /// Set avatar URL for patient
  Future<void> setAvatarUrl({required String patientId, required String avatarUrl}) async {
    try {
      await SupabaseService.update(
        'patients',
        {'avatar_url': avatarUrl, 'updated_at': DateTime.now().toIso8601String()},
        filters: {'id': patientId},
      );
    } catch (e) {
      debugPrint('Error setting avatar URL: $e');
      throw Exception('Échec de la mise à jour de l\'avatar');
    }
  }
}

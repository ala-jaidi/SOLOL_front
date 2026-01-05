import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';

class PodiatristProfileState extends ChangeNotifier {
  static const _kKey = 'app.podiatrist.profile';

  String fullName = '';
  String clinic = '';
  String email = '';
  String phone = '';
  String bio = '';
  String? avatarUrl;

  PodiatristProfileState() {
    _load();
  }

  Future<void> _load() async {
    try {
      // First try to load from Supabase
      final user = SupabaseConfig.auth.currentUser;
      if (user != null) {
        final data = await SupabaseConfig.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        if (data != null) {
          final prenom = data['prenom'] as String? ?? '';
          final nom = data['nom'] as String? ?? '';
          fullName = prenom.isNotEmpty ? '$prenom $nom' : nom;
          clinic = data['organisation'] as String? ?? '';
          email = data['email'] as String? ?? '';
          phone = data['telephone'] as String? ?? '';
          bio = data['specialite'] as String? ?? '';
          avatarUrl = data['avatar_url'] as String?;
          notifyListeners();
          await _persist();
          return;
        }
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      fullName = map['fullName'] as String? ?? '';
      clinic = map['clinic'] as String? ?? '';
      email = map['email'] as String? ?? '';
      phone = map['phone'] as String? ?? '';
      bio = map['bio'] as String? ?? '';
      avatarUrl = map['avatarUrl'] as String?;
      notifyListeners();
    } catch (e) {
      debugPrint('PodiatristProfileState load error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode({
        'fullName': fullName,
        'clinic': clinic,
        'email': email,
        'phone': phone,
        'bio': bio,
        'avatarUrl': avatarUrl,
      });
      await prefs.setString(_kKey, raw);
    } catch (e) {
      debugPrint('PodiatristProfileState persist error: $e');
    }
  }

  Future<void> update({
    String? fullName,
    String? clinic,
    String? email,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) async {
    this.fullName = fullName ?? this.fullName;
    this.clinic = clinic ?? this.clinic;
    this.email = email ?? this.email;
    this.phone = phone ?? this.phone;
    this.bio = bio ?? this.bio;
    this.avatarUrl = avatarUrl ?? this.avatarUrl;
    notifyListeners();
    await _persist();
  }
}

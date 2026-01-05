import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lidarmesure/auth/auth_manager.dart';
import 'package:lidarmesure/models/auth_user.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Concrete Supabase authentication manager
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  @override
  Future<User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get or create user profile
        return await _getOrCreateUserProfile(response.user!);
      }
      return null;
    } on sb.AuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('signInWithEmail error: $e');
      throw Exception('Erreur de connexion');
    }
  }

  @override
  Future<User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Try to create user profile in users table
        final profile = await _createUserProfile(response.user!, email);
        if (profile != null) {
          return profile;
        }
        // Even if profile creation fails, return a minimal user object
        // so the signup flow can continue to complete-profile page
        return User(
          id: response.user!.id,
          email: email,
          nom: email.split('@')[0],
          role: 'podologue',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      return null;
    } on sb.AuthException catch (e) {
      debugPrint('createAccountWithEmail error: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('createAccountWithEmail error: $e');
      throw Exception('Erreur de creation de compte');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await SupabaseConfig.auth.signOut();
    } catch (e) {
      debugPrint('signOut error: $e');
      throw Exception('Erreur de déconnexion');
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final user = SupabaseConfig.auth.currentUser;
      if (user != null) {
        // Delete user profile first (cascade will handle related data)
        await SupabaseConfig.client.from('users').delete().eq('id', user.id);
        
        // Delete auth user (admin operation, may require service role)
        await SupabaseConfig.auth.admin.deleteUser(user.id);
      }
    } catch (e) {
      debugPrint('deleteUser error: $e');
      throw Exception('Erreur de suppression du compte');
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.updateUser(sb.UserAttributes(email: email));
      
      // Update user profile
      final user = SupabaseConfig.auth.currentUser;
      if (user != null) {
        await SupabaseConfig.client
            .from('users')
            .update({'email': email, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', user.id);
      }
    } catch (e) {
      debugPrint('updateEmail error: $e');
      throw Exception('Erreur de mise à jour de l\'email');
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await SupabaseConfig.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('resetPassword error: $e');
      throw Exception('Erreur de réinitialisation du mot de passe');
    }
  }

  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final authUser = SupabaseConfig.auth.currentUser;
      if (authUser == null) return null;

      return await _getOrCreateUserProfile(authUser);
    } catch (e) {
      debugPrint('getCurrentUser error: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => SupabaseConfig.auth.currentUser != null;

  /// Get or create user profile from database
  Future<User?> _getOrCreateUserProfile(sb.User authUser) async {
    try {
      final data = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (data != null) {
        return User.fromJson(data);
      }

      // Create profile if it doesn't exist
      return await _createUserProfile(authUser, authUser.email ?? '');
    } catch (e) {
      debugPrint('_getOrCreateUserProfile error: $e');
      return null;
    }
  }

  /// Create user profile in database (uses upsert to avoid duplicate key errors)
  Future<User?> _createUserProfile(sb.User authUser, String email) async {
    try {
      final userData = {
        'id': authUser.id,
        'email': email,
        'nom': email.split('@')[0], // Default name from email
        'role': 'podologue', // Default role
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final data = await SupabaseConfig.client
          .from('users')
          .upsert(userData, onConflict: 'id')
          .select()
          .single();

      return User.fromJson(data);
    } catch (e) {
      debugPrint('_createUserProfile error: $e');
      return null;
    }
  }
}

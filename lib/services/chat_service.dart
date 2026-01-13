import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:lidarmesure/models/chat_message.dart';
import 'package:lidarmesure/models/chat_thread.dart';
import 'package:lidarmesure/supabase/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Chat client that uses Groq API (FREE) and persists chat history to Supabase.
class ChatService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _modelName = 'llama-3.3-70b-versatile';
  static const String _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';

  /// Optional default template key stored in the `prompt_templates` table.
  /// Set to null to skip template lookup on server.
  static const String? defaultTemplateKey = 'podology_default';

  // Cache for system prompts to avoid repeated DB calls
  final Map<String, String> _systemPromptCache = {};

  /// Get system prompt from cache or database
  Future<String?> _getSystemPrompt({String? templateKey}) async {
    final key = templateKey ?? defaultTemplateKey;

    if (key != null) {
      if (!_systemPromptCache.containsKey(key)) {
        try {
          final row = await SupabaseConfig.client
              .from('prompt_templates')
              .select('system_prompt')
              .eq('key', key)
              .maybeSingle();
          
          if (row != null && row['system_prompt'] != null) {
            _systemPromptCache[key] = row['system_prompt'] as String;
          }
        } catch (e) {
          debugPrint('Error fetching system prompt for $key: $e');
        }
      }

      if (_systemPromptCache.containsKey(key)) {
        return _systemPromptCache[key];
      }
    }
    return null;
  }

    // ---------------------------
    // Persistence: Threads & Messages
    // ---------------------------

    /// Load the most recently active thread for the current user.
    /// If none exists, creates a new empty thread.
    Future<ChatThread> loadOrCreateLatestThread({String? templateKey}) async {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non authentifié');
      try {
        final rows = await SupabaseConfig.client
            .from('chat_threads')
            .select()
            .eq('user_id', userId)
            .order('last_message_at', ascending: false)
            .limit(1);
        if (rows is List && rows.isNotEmpty) {
          return ChatThread.fromMap(rows.first as Map<String, dynamic>);
        }
      } catch (e, st) {
        debugPrint('loadOrCreateLatestThread/read error: $e\n$st');
      }
      // Create if none
      return createThread(templateKey: templateKey ?? defaultTemplateKey);
    }

    /// Create a new chat thread for the current user.
    Future<ChatThread> createThread({String? templateKey, String? title}) async {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non authentifié');
      final providerSessionId = const Uuid().v4();
      final payload = {
        'user_id': userId,
        'title': title,
        'template_key': templateKey ?? defaultTemplateKey,
        'provider_session_id': providerSessionId,
      };
      try {
        final inserted = await SupabaseConfig.client.from('chat_threads').insert(payload).select().single();
        return ChatThread.fromMap(inserted as Map<String, dynamic>);
      } catch (e, st) {
        debugPrint('createThread error: $e\n$st');
        rethrow;
      }
    }

    /// Load messages for a thread (ascending by creation time).
    Future<List<ChatMessage>> loadMessages(String threadId) async {
      try {
        final rows = await SupabaseConfig.client
            .from('chat_messages')
            .select('id, role, content, created_at')
            .eq('thread_id', threadId)
            .order('created_at', ascending: true);
        return (rows as List)
            .map((e) => ChatMessage(
                  id: e['id'] as String,
                  content: e['content'] as String,
                  isUser: (e['role'] as String) == 'user',
                  createdAt: DateTime.parse(e['created_at'] as String),
                  status: ChatDeliveryStatus.sent,
                ))
            .toList();
      } catch (e, st) {
        debugPrint('loadMessages error: $e\n$st');
        rethrow;
      }
    }

    /// Append a new message to a thread. Returns the DB id of the new message.
    Future<String> appendMessage({
      required String threadId,
      required bool isUser,
      required String content,
      int? tokensIn,
      int? tokensOut,
    }) async {
      final role = isUser ? 'user' : 'assistant';
      try {
        final inserted = await SupabaseConfig.client.from('chat_messages').insert({
          'thread_id': threadId,
          'role': role,
          'content': content,
          if (tokensIn != null) 'tokens_in': tokensIn,
          if (tokensOut != null) 'tokens_out': tokensOut,
        }).select('id').single();
        return inserted['id'] as String;
      } catch (e, st) {
        debugPrint('appendMessage error: $e\n$st');
        rethrow;
      }
    }

    /// Update the content of an existing message (e.g., after streaming completes).
    Future<void> updateMessageContent({required String messageId, required String content, int? tokensOut}) async {
      try {
        await SupabaseConfig.client
            .from('chat_messages')
            .update({'content': content, if (tokensOut != null) 'tokens_out': tokensOut})
            .eq('id', messageId);
      } catch (e, st) {
        debugPrint('updateMessageContent error: $e\n$st');
        rethrow;
      }
    }

    /// Touch the thread to reflect activity, and optionally retitle it.
    Future<void> touchThread(String threadId, {String? title}) async {
      if (title == null) return; // last_message_at is updated via trigger on insert into chat_messages
      try {
        await SupabaseConfig.client.from('chat_threads').update({'title': title}).eq('id', threadId);
      } catch (e, st) {
        debugPrint('touchThread error: $e\n$st');
      }
    }

    /// Delete a specific chat thread and all its messages.
    Future<void> deleteThread(String threadId) async {
      try {
        // Messages are deleted via CASCADE in DB, but we can also delete explicitly
        await SupabaseConfig.client.from('chat_messages').delete().eq('thread_id', threadId);
        await SupabaseConfig.client.from('chat_threads').delete().eq('id', threadId);
      } catch (e, st) {
        debugPrint('deleteThread error: $e\n$st');
        rethrow;
      }
    }

    /// Delete all chat threads and messages for the current user.
    Future<void> deleteAllThreads() async {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non authentifié');
      try {
        // Get all thread IDs for this user
        final threads = await SupabaseConfig.client
            .from('chat_threads')
            .select('id')
            .eq('user_id', userId);
        
        // Delete messages for each thread
        for (final thread in (threads as List)) {
          await SupabaseConfig.client.from('chat_messages').delete().eq('thread_id', thread['id']);
        }
        
        // Delete all threads
        await SupabaseConfig.client.from('chat_threads').delete().eq('user_id', userId);
      } catch (e, st) {
        debugPrint('deleteAllThreads error: $e\n$st');
        rethrow;
      }
    }

    /// Get all threads for the current user.
    Future<List<ChatThread>> getAllThreads() async {
      final userId = SupabaseConfig.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non authentifié');
      try {
        final rows = await SupabaseConfig.client
            .from('chat_threads')
            .select()
            .eq('user_id', userId)
            .order('last_message_at', ascending: false);
        return (rows as List).map((e) => ChatThread.fromMap(e as Map<String, dynamic>)).toList();
      } catch (e, st) {
        debugPrint('getAllThreads error: $e\n$st');
        rethrow;
      }
    }

  /// Sends a message and returns the assistant's reply.
  Future<String> sendMessage({
    required String message,
    String? sessionId,
    String? templateKey,
  }) async {
    try {
      final systemPrompt = await _getSystemPrompt(templateKey: templateKey);
      
      final messages = <Map<String, dynamic>>[];
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.add({'role': 'user', 'content': message});
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
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
        throw Exception('Réponse vide du modèle');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'API Error: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('ChatService error: $e\n$st');
      rethrow;
    }
  }

  /// Streams an assistant reply (returns full response for Groq).
  Stream<String> streamMessage({
    required String message,
    String? sessionId,
    String? templateKey,
  }) async* {
    try {
      final systemPrompt = await _getSystemPrompt(templateKey: templateKey);
      
      final messages = <Map<String, dynamic>>[];
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.add({'role': 'user', 'content': message});
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _modelName,
          'max_tokens': 2048,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List;
        if (choices.isNotEmpty) {
          yield choices[0]['message']['content'] as String;
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error']?['message'] ?? 'API Error: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('ChatService.stream error: $e\n$st');
      rethrow;
    }
  }

  /// Fetch available prompt template keys from the database.
  Future<List<String>> fetchTemplateKeys() async {
    try {
      final rows = await SupabaseConfig.client
          .from('prompt_templates')
          .select('key')
          .order('key');
      return (rows as List)
          .map((e) => e['key'] as String)
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e, st) {
      debugPrint('fetchTemplateKeys error: $e\n$st');
      return const ['podology_default'];
    }
  }
}

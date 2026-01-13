import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/models/chat_message.dart';
import 'package:lidarmesure/services/chat_service.dart';
import 'package:lidarmesure/models/chat_thread.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/services/podology_ai_service.dart';
import 'package:lidarmesure/services/measurement_service.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/components/app_sidebar.dart';
import 'package:uuid/uuid.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chat = ChatService();
  final PatientService _patientService = PatientService();
  final SessionService _sessionService = SessionService();
  PodologyAIService? _podologyAI;
  
  bool _isTyping = false;
  bool _showJumpToBottom = false;
  String _sessionId = const Uuid().v4();
  List<String> _templates = [];
  String? _selectedTemplate;
  bool _loadingTemplates = false;
  ChatThread? _thread;
  
  // Podology AI mode
  bool _isPodologyMode = false;
  Patient? _selectedPatient;
  Session? _selectedSession;
  List<Patient> _patients = [];
  bool _loadingPatients = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadTemplates().then((_) => _initThread());
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loadingPatients = true);
    try {
      final patients = await _patientService.getAllPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _loadingPatients = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading patients: $e');
      if (mounted) setState(() => _loadingPatients = false);
    }
  }

  Future<void> _selectPatient(Patient patient) async {
    setState(() => _loadingPatients = true);
    try {
      final sessions = await _sessionService.getSessionsByPatientId(patient.id);
      final latestSession = sessions.isNotEmpty ? sessions.first : null;
      
      _podologyAI = PodologyAIService();
      
      if (latestSession != null) {
        _podologyAI!.initializeContext(patient: patient, session: latestSession);
      }
      
      setState(() {
        _selectedPatient = patient;
        _selectedSession = latestSession;
        _isPodologyMode = true;
        _loadingPatients = false;
        _messages.clear();
        
        // Add welcome message
        _messages.add(ChatMessage(
          content: _buildPodologyWelcome(patient, latestSession),
          isUser: false,
          status: ChatDeliveryStatus.sent,
        ));
      });
    } catch (e) {
      debugPrint('Error selecting patient: $e');
      if (mounted) {
        setState(() => _loadingPatients = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  String _buildPodologyWelcome(Patient patient, Session? session) {
    final buffer = StringBuffer();
    buffer.writeln('👋 **Mode Analyse Podologique Activé**\n');
    buffer.writeln('📋 **Patient**: ${patient.fullName}');
    buffer.writeln('👤 **Âge**: ${patient.age} ans | **Pointure**: ${patient.pointure}');
    buffer.writeln('📏 **Taille**: ${patient.taille} cm | **Poids**: ${patient.poids} kg\n');
    
    if (session != null && session.footMetrics.isNotEmpty) {
      buffer.writeln('📊 **Dernières mesures** (${session.formattedDate}):');
      for (final m in session.footMetrics) {
        buffer.writeln('- ${m.sideLabel}: **${m.formattedLongueur}** × **${m.formattedLargeur}**');
      }
      buffer.writeln();
    }
    
    buffer.writeln('💡 **Comment puis-je vous aider ?**');
    buffer.writeln('- Analyser les images de scan');
    buffer.writeln('- Identifier les anomalies (Hallux Valgus, Pronation...)');
    buffer.writeln('- Recommander des semelles adaptées');
    
    return buffer.toString();
  }

  void _exitPodologyMode() {
    setState(() {
      _isPodologyMode = false;
      _selectedPatient = null;
      _selectedSession = null;
      _podologyAI = null;
      _messages.clear();
    });
    _initThread();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final threshold = 220.0;
    final shouldShow = _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent - _scrollController.offset > threshold;
    if (shouldShow != _showJumpToBottom) {
      setState(() => _showJumpToBottom = shouldShow);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    if (text.isEmpty || _isTyping) return;
    _controller.clear();

    final userMsg = ChatMessage(content: text, isUser: true, status: ChatDeliveryStatus.pending);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      // Use Podology AI if in podology mode
      if (_isPodologyMode && _podologyAI != null) {
        _updateMessageStatus(userMsg.id, ChatDeliveryStatus.sent);
        final botMsg = ChatMessage(content: '', isUser: false, status: ChatDeliveryStatus.pending);
        setState(() => _messages.add(botMsg));
        
        String buffer = '';
        try {
          await for (final delta in _podologyAI!.streamMessage(text)) {
            buffer += delta;
            final idx = _messages.indexWhere((m) => m.id == botMsg.id);
            if (idx != -1 && mounted) {
              setState(() => _messages[idx] = _messages[idx].copyWith(content: buffer));
              _scrollToBottom();
            }
          }
        } catch (e) {
          // Fallback to non-streaming
          buffer = await _podologyAI!.sendMessage(text);
          final idx = _messages.indexWhere((m) => m.id == botMsg.id);
          if (idx != -1 && mounted) {
            setState(() => _messages[idx] = _messages[idx].copyWith(content: buffer));
          }
        }
        
        final idx = _messages.indexWhere((m) => m.id == botMsg.id);
        if (idx != -1 && mounted) {
          setState(() => _messages[idx] = _messages[idx].copyWith(status: ChatDeliveryStatus.sent));
        }
      } else {
        // Normal chat mode
        final thread = _thread ?? await _initThread();
        await _chat.appendMessage(threadId: thread.id, isUser: true, content: text);
        _updateMessageStatus(userMsg.id, ChatDeliveryStatus.sent);
        
        final botMsg = ChatMessage(content: '', isUser: false, status: ChatDeliveryStatus.pending);
        setState(() => _messages.add(botMsg));
        String buffer = '';
        
        try {
          await for (final delta in _chat.streamMessage(
            message: text,
            sessionId: _sessionId,
            templateKey: _selectedTemplate,
          )) {
            buffer += delta;
            final idx = _messages.indexWhere((m) => m.id == botMsg.id);
            if (idx != -1 && mounted) {
              setState(() => _messages[idx] = _messages[idx].copyWith(content: buffer));
              _scrollToBottom();
            }
          }
        } catch (streamErr, st) {
          debugPrint('Chat stream failed, falling back to non-stream invoke: $streamErr\n$st');
          try {
            final reply = await _chat.sendMessage(
              message: text,
              sessionId: _sessionId,
              templateKey: _selectedTemplate,
            );
            buffer = reply;
            final idx = _messages.indexWhere((m) => m.id == botMsg.id);
            if (idx != -1 && mounted) {
              setState(() => _messages[idx] = _messages[idx].copyWith(content: buffer));
              _scrollToBottom();
            }
          } catch (invokeErr, st2) {
            debugPrint('Fallback invoke also failed: $invokeErr\n$st2');
            rethrow;
          }
        }
        
        await _chat.appendMessage(threadId: thread.id, isUser: false, content: buffer);
        final idx = _messages.indexWhere((m) => m.id == botMsg.id);
        if (idx != -1 && mounted) {
          setState(() => _messages[idx] = _messages[idx].copyWith(status: ChatDeliveryStatus.sent));
        }
      }
    } catch (e) {
      _updateMessageStatus(userMsg.id, ChatDeliveryStatus.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'envoi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  Future<void> _loadTemplates() async {
    setState(() => _loadingTemplates = true);
    try {
      final keys = await _chat.fetchTemplateKeys();
      setState(() {
        _templates = keys;
        _selectedTemplate = _selectedTemplate ?? (keys.contains(ChatService.defaultTemplateKey)
            ? ChatService.defaultTemplateKey
            : (keys.isNotEmpty ? keys.first : null));
      });
    } catch (e) {
      if (mounted) {
        final cs = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chargement des templates impossible'), backgroundColor: cs.error));
      }
    } finally {
      if (mounted) setState(() => _loadingTemplates = false);
    }
  }

  Future<ChatThread> _initThread() async {
    try {
      final t = await _chat.loadOrCreateLatestThread(templateKey: _selectedTemplate);
      final msgs = await _chat.loadMessages(t.id);
      if (!mounted) return t;
      setState(() {
        _thread = t;
        _sessionId = t.providerSessionId;
        _messages
          ..clear()
          ..addAll(msgs);
        _selectedTemplate = _selectedTemplate ?? t.templateKey;
      });
      // Jump to bottom after loading history
      _scrollToBottom();
      return t;
    } catch (e) {
      debugPrint('Init thread failed: $e');
      rethrow;
    }
  }

  Future<void> _newThread() async {
    try {
      final t = await _chat.createThread(templateKey: _selectedTemplate);
      if (!mounted) return;
      setState(() {
        _thread = t;
        _sessionId = t.providerSessionId;
        _messages.clear();
      });
    } catch (e) {
      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de créer un nouveau fil'), backgroundColor: cs.error));
    }
  }

  void _updateMessageStatus(String id, ChatDeliveryStatus status) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      setState(() {
        _messages[idx] = _messages[idx].copyWith(status: status);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _showDeleteHistoryDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Options: 'current' = current thread, 'all' = all threads
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2A2F) : cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_rounded, color: cs.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.isFrench ? 'Effacer les conversations' : 'Clear Conversations',
                style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.isFrench 
                  ? 'Que souhaitez-vous effacer ?'
                  : 'What do you want to clear?',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            // Option 1: Current conversation
            _DeleteOptionTile(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.isFrench ? 'Conversation actuelle' : 'Current conversation',
              subtitle: l10n.isFrench ? 'Effacer cette conversation uniquement' : 'Clear this conversation only',
              onTap: () => Navigator.of(ctx).pop('current'),
              cs: cs,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            // Option 2: All conversations
            _DeleteOptionTile(
              icon: Icons.delete_sweep_rounded,
              title: l10n.isFrench ? 'Toutes les conversations' : 'All conversations',
              subtitle: l10n.isFrench ? 'Supprimer tout l\'historique' : 'Delete all history',
              onTap: () => Navigator.of(ctx).pop('all'),
              cs: cs,
              isDark: isDark,
              isDestructive: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.isFrench ? 'Annuler' : 'Cancel'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      try {
        if (result == 'all') {
          // Delete ALL threads
          await _chat.deleteAllThreads();
        } else if (result == 'current' && _thread != null) {
          // Delete current thread only
          await _chat.deleteThread(_thread!.id);
        }
        // Clear local state and create new thread
        setState(() {
          _messages.clear();
          _thread = null;
        });
        await _initThread();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isFrench 
                  ? (result == 'all' ? 'Toutes les conversations effacées' : 'Conversation effacée')
                  : (result == 'all' ? 'All conversations cleared' : 'Conversation cleared')),
              backgroundColor: cs.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.isFrench ? 'Erreur: $e' : 'Error: $e'),
              backgroundColor: cs.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      endDrawer: const AppSideBar(),
      backgroundColor: isDark ? const Color(0xFF0A1A1F) : cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 18),
            ),
          ),
        ),
        title: _isPodologyMode && _selectedPatient != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.7)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPatient!.fullName,
                        style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l10n.isFrench ? 'Mode Podologie' : 'Podology Mode',
                        style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              )
            : Text(
                l10n.isFrench ? 'Assistant SOLOL' : 'SOLOL Assistant',
                style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
              ),
        centerTitle: !_isPodologyMode,
        actions: [
          // Exit podology mode button
          if (_isPodologyMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _exitPodologyMode,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.close_rounded, color: cs.tertiary, size: 18),
                ),
              ),
            ),
          // Delete chat history button
          if (_messages.isNotEmpty && !_isPodologyMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showDeleteHistoryDialog(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 18),
                ),
              ),
            ),
          Builder(
            builder: (ctx) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => Scaffold.of(ctx).openEndDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.1)
                        : cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: cs.onSurface, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0A1A1F),
                    Color(0xFF0D2428),
                    Color(0xFF0A1A1F),
                  ]
                : [
                    cs.primary.withValues(alpha: 0.08),
                    cs.surface,
                    cs.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Show welcome screen if no messages
              if (_messages.isEmpty && !_isTyping)
                Expanded(
                  child: _WelcomeScreen(
                    onTopicSelect: (text) => _sendText(text),
                    patients: _patients,
                    loadingPatients: _loadingPatients,
                    onPatientSelect: _selectPatient,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isTyping && index == _messages.length) {
                        return const _TypingBubble()
                            .animate()
                            .fadeIn(duration: 250.ms)
                            .slideY(begin: 0.2, end: 0);
                      }
                      final msg = _messages[index];
                      return _MessageRow(message: msg)
                          .animate()
                          .fadeIn(duration: 220.ms)
                          .slideY(begin: 0.08, end: 0);
                    },
                  ),
                ),
              // Composer at bottom
              _Composer(onSend: _send, controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Welcome screen - with patient selector for podology mode
class _WelcomeScreen extends StatelessWidget {
  final void Function(String) onTopicSelect;
  final List<Patient> patients;
  final bool loadingPatients;
  final void Function(Patient) onPatientSelect;
  
  const _WelcomeScreen({
    required this.onTopicSelect,
    required this.patients,
    required this.loadingPatients,
    required this.onPatientSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Modern AI Logo - Neural network style
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.2),
                      cs.primary.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary.withValues(alpha: 0.9), cs.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.psychology_rounded, color: cs.onPrimary, size: 32),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        child: Icon(Icons.auto_awesome, size: 8, color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1)),
          
          const SizedBox(height: 24),
          
          Text(
            l10n.isFrench 
                ? 'Bonjour, comment puis-je vous aider ?'
                : 'Hello, how can I help you?',
            style: TextStyle(color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          // Podology Analysis Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [cs.primary.withValues(alpha: 0.15), cs.primary.withValues(alpha: 0.05)]
                    : [cs.primary.withValues(alpha: 0.08), cs.primary.withValues(alpha: 0.02)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.7)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.isFrench ? 'Analyse Podologique' : 'Podology Analysis',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.isFrench
                      ? 'Sélectionnez un patient pour démarrer une analyse IA avec son historique de scans.'
                      : 'Select a patient to start an AI analysis with their scan history.',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                
                if (loadingPatients)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                    ),
                  )
                else if (patients.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.isFrench ? 'Aucun patient disponible' : 'No patients available',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: patients.length > 5 ? 5 : patients.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return _PatientChip(
                          patient: patient,
                          onTap: () => onPatientSelect(patient),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 24),
          
          // Quick prompts
          Text(
            l10n.isFrench ? 'Ou posez une question générale' : 'Or ask a general question',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickChip(
                icon: Icons.help_outline,
                label: l10n.isFrench ? 'Comment fonctionne SOLOL?' : 'How does SOLOL work?',
                onTap: () => onTopicSelect(l10n.isFrench ? 'Comment fonctionne l\'application SOLOL?' : 'How does the SOLOL app work?'),
              ),
              _QuickChip(
                icon: Icons.medical_information_outlined,
                label: l10n.isFrench ? 'Types de semelles' : 'Types of insoles',
                onTap: () => onTopicSelect(l10n.isFrench ? 'Quels sont les différents types de semelles orthopédiques?' : 'What are the different types of orthopedic insoles?'),
              ),
              _QuickChip(
                icon: Icons.analytics_outlined,
                label: l10n.isFrench ? 'Hallux Valgus' : 'Hallux Valgus',
                onTap: () => onTopicSelect(l10n.isFrench ? 'Comment identifier et traiter un Hallux Valgus?' : 'How to identify and treat Hallux Valgus?'),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

/// Patient selection chip
class _PatientChip extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  
  const _PatientChip({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Text(
                  patient.prenom.isNotEmpty ? patient.prenom[0].toUpperCase() : '?',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                patient.prenom,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'P. ${patient.pointure}',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action chip
class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Topic card widget
class _TopicCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _TopicCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.1)
                  : cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, 
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Composer - AI Companion style
class _Composer extends StatelessWidget {
  final VoidCallback onSend;
  final TextEditingController controller;

  const _Composer({required this.onSend, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : cs.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: l10n.isFrench ? 'Qu\'avez-vous en tête ?' : 'What is on your mind?',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      // TODO: Implement file picker
                    },
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        color: cs.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button - premium animated
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.9),
                    cs.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.send_rounded, color: cs.onPrimary, size: 22),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1500.ms),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final ChatMessage message;
  const _MessageRow({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isUser) {
      // User message - right aligned with avatar
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // "You" label
            Padding(
              padding: const EdgeInsets.only(right: 44, bottom: 4),
              child: Text(
                'You',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(child: _MessageBubble(message: message)),
                const SizedBox(width: 8),
                // User avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person_rounded, size: 18, color: cs.primary),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // AI message - left aligned with SOLOL label
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI label with modern logo
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _AILogo(size: 22),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4A9DFF), Color(0xFF9D4AFF)],
                    ).createShader(bounds),
                    child: Text(
                      'SOLOL AI',
                      style: TextStyle(
                        color: isDark ? Colors.white : cs.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _MessageBubble(message: message),
          ],
        ),
      );
    }
  }
}

/// Message bubble - AI Companion style
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message copied'),
            backgroundColor: cs.primary,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isUser
              ? cs.primary
              : isDark 
                  ? Colors.white.withValues(alpha: 0.08)
                  : cs.surfaceContainerHighest,
          border: isUser
              ? null
              : Border.all(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.1)
                      : cs.outline.withValues(alpha: 0.2),
                ),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser 
                ? cs.onPrimary 
                : isDark 
                    ? Colors.white.withValues(alpha: 0.9)
                    : cs.onSurface,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI label with modern logo
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _AILogo(size: 22),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF4A9DFF), Color(0xFF9D4AFF)],
                  ).createShader(bounds),
                  child: Text(
                    'SOLOL AI',
                    style: TextStyle(
                      color: isDark ? Colors.white : cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Typing indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.08)
                  : cs.surfaceContainerHighest,
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : cs.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: cs.primary).animate(onPlay: (c) => c.repeat()).fadeIn().scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms),
                const SizedBox(width: 6),
                _Dot(color: cs.primary).animate(onPlay: (c) => c.repeat()).fadeIn(delay: 150.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms),
                const SizedBox(width: 6),
                _Dot(color: cs.primary).animate(onPlay: (c) => c.repeat()).fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Modern AI Logo with gradient and neural network inspired design
class _AILogo extends StatelessWidget {
  final double size;
  const _AILogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A9DFF), Color(0xFF9D4AFF)],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9DFF).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _AILogoPainter(),
      ),
    );
  }
}

class _AILogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.15;

    // Central node (brain/AI core)
    canvas.drawCircle(center, radius, paint);

    // Orbital rings representing neural connections
    final orbitRadius = size.width * 0.32;
    
    // Draw connecting lines to outer nodes
    final nodePositions = [
      Offset(center.dx, center.dy - orbitRadius), // Top
      Offset(center.dx + orbitRadius * 0.87, center.dy + orbitRadius * 0.5), // Bottom right
      Offset(center.dx - orbitRadius * 0.87, center.dy + orbitRadius * 0.5), // Bottom left
    ];

    // Draw connection lines
    for (final pos in nodePositions) {
      canvas.drawLine(center, pos, strokePaint);
    }

    // Draw outer nodes
    final smallRadius = size.width * 0.08;
    for (final pos in nodePositions) {
      canvas.drawCircle(pos, smallRadius, paint);
    }

    // Add sparkle effect (AI magic)
    final sparklePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.2, center.dy - size.height * 0.2),
      size.width * 0.04,
      sparklePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DaySeparator extends StatelessWidget {
  final DateTime date;
  const _DaySeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = _formatDate(date);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.12), thickness: 0.5)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Text(label, style: textTheme.labelSmall?.withColor(cs.onSurfaceVariant)),
          ),
          Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.12), thickness: 0.5)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_isSameDay(dt, now)) return 'Aujourd\'hui';
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) return 'Hier';
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$d/$mo/$y';
  }
}

/// Quick action buttons - Revolut-style professional suggestions
class _QuickSuggestions extends StatelessWidget {
  final void Function(String) onSelect;
  const _QuickSuggestions({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    final suggestions = l10n.isFrench 
        ? <Map<String, dynamic>>[
            {'icon': Icons.analytics_outlined, 'text': 'Analyser'},
            {'icon': Icons.medical_services_outlined, 'text': 'Recommandations'},
            {'icon': Icons.summarize_outlined, 'text': 'Résumé'},
            {'icon': Icons.tips_and_updates_outlined, 'text': 'Conseils'},
          ]
        : <Map<String, dynamic>>[
            {'icon': Icons.analytics_outlined, 'text': 'Analyze'},
            {'icon': Icons.medical_services_outlined, 'text': 'Recommendations'},
            {'icon': Icons.summarize_outlined, 'text': 'Summary'},
            {'icon': Icons.tips_and_updates_outlined, 'text': 'Tips'},
          ];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: suggestions.map((s) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _QuickActionButton(
                icon: s['icon'] as IconData,
                label: s['text'] as String,
                onTap: () => onSelect(s['text'] as String),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Individual quick action button - clean and minimal
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------
// Decorative widgets
// ---------------------

class _AnimatedBlob extends StatelessWidget {
  final Color colorA;
  final Color colorB;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final int durationMs;

  const _AnimatedBlob({
    required this.colorA,
    required this.colorB,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.durationMs = 10000,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        ignoring: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [colorA, colorB],
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
              duration: Duration(milliseconds: durationMs),
              begin: const Offset(0, 0),
              end: const Offset(10, 18),
            ).blurXY(begin: 0, end: 10, duration: Duration(milliseconds: durationMs)),
      ),
    );
  }
}

class _GridOverlay extends CustomPainter {
  final Color color;
  const _GridOverlay({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridOverlay oldDelegate) => false;
}

class _NeonFab extends StatelessWidget {
  final VoidCallback onTap;
  const _NeonFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [cs.primary, cs.tertiary.withValues(alpha: 0.9)]),
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: 0.2),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.95,0.95), end: const Offset(1.1,1.1), duration: 1200.ms).fade(begin: 0.6, end: 0.2),
            Icon(Icons.arrow_downward_rounded, size: 22, color: Theme.of(context).colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _PulsingSendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PulsingSendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [cs.primary, cs.tertiary.withValues(alpha: 0.9)]),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.18),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9,0.9), end: const Offset(1.15,1.15), duration: 1200.ms).fade(begin: 0.2, end: 0.0),
          Icon(Icons.send_rounded, color: cs.onPrimary),
        ],
      ),
    );
  }
}

class _HoloChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _HoloChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(colors: [cs.primary.withValues(alpha: 0.8), cs.tertiary.withValues(alpha: 0.8)]),
        ),
        padding: const EdgeInsets.all(1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: cs.primaryContainer.withValues(alpha: 0.65),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: cs.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(text, style: Theme.of(context).textTheme.labelMedium?.withColor(cs.onPrimaryContainer)),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms).moveY(begin: 6, end: 0, curve: Curves.easeOut),
      ),
    );
  }
}

class _TemplateBar extends StatelessWidget {
  final List<String> templates;
  final String? selected;
  final bool loading;
  final String sessionId;
  final VoidCallback onRefresh;
  final VoidCallback onNewThread;
  final ValueChanged<String?> onChanged;

  const _TemplateBar({
    required this.templates,
    required this.selected,
    required this.loading,
    required this.sessionId,
    required this.onRefresh,
    required this.onNewThread,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
      ),
      child: Row(children: [
        // Template selector
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                icon: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
                hint: Text('Template', style: textTheme.labelMedium?.withColor(cs.onSurfaceVariant)),
                items: templates
                    .map((k) => DropdownMenuItem<String>(
                          value: k,
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, size: 16, color: cs.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(k, overflow: TextOverflow.ellipsis, style: textTheme.labelMedium?.withColor(cs.onSurface)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: loading ? null : onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // New thread button
        Tooltip(
          message: 'Nouveau fil',
          child: _GlassIconButton(icon: Icons.forum_outlined, onTap: onNewThread),
        ),
        const SizedBox(width: 8),
        // Refresh templates
        Tooltip(
          message: 'Rafraîchir les templates',
          child: _GlassIconButton(icon: loading ? Icons.hourglass_empty : Icons.refresh_rounded, onTap: onRefresh),
        ),
      ]),
    );
  }
}

/// Delete option tile for the delete dialog
class _DeleteOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool isDark;
  final bool isDestructive;

  const _DeleteOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.cs,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.06)
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive 
                  ? cs.error.withValues(alpha: 0.3)
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : cs.outline.withValues(alpha: 0.15)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive 
                      ? cs.error.withValues(alpha: 0.15)
                      : cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: isDestructive ? cs.error : cs.primary, 
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? cs.error : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/services/podology_ai_service.dart';
import 'package:lidarmesure/services/measurement_service.dart';
import 'package:lidarmesure/theme.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

/// Professional AI Chat Widget for Podology Analysis
class PodologyAIChat extends StatefulWidget {
  final Patient patient;
  final Session session;
  final String? topViewUrl;
  final String? sideViewUrl;

  const PodologyAIChat({
    super.key,
    required this.patient,
    required this.session,
    this.topViewUrl,
    this.sideViewUrl,
  });

  /// Show as bottom sheet
  static Future<void> show(
    BuildContext context, {
    required Patient patient,
    required Session session,
    String? topViewUrl,
    String? sideViewUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => PodologyAIChat(
          patient: patient,
          session: session,
          topViewUrl: topViewUrl,
          sideViewUrl: sideViewUrl,
        ),
      ),
    );
  }

  @override
  State<PodologyAIChat> createState() => _PodologyAIChatState();
}

class _PodologyAIChatState extends State<PodologyAIChat> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PodologyAIService _aiService = PodologyAIService();
  
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _initialized = false;
  String? _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    _aiService.initializeContext(
      patient: widget.patient,
      session: widget.session,
    );

    // Add initial assistant message
    final initialMessage = _buildWelcomeMessage();
    setState(() {
      _messages.add(_ChatMessage(
        content: initialMessage,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _initialized = true;
    });
  }

  String _buildWelcomeMessage() {
    final metrics = widget.session.footMetrics;
    final buffer = StringBuffer();
    
    buffer.writeln('👋 Bonjour, je suis votre **Assistant IA Podologique**.');
    buffer.writeln();
    buffer.writeln('📋 **Patient**: ${widget.patient.fullName}');
    buffer.writeln('👤 **Âge**: ${widget.patient.age} ans | **Pointure**: ${widget.patient.pointure}');
    buffer.writeln();
    
    if (metrics.isNotEmpty) {
      buffer.writeln('📊 **Métriques disponibles**:');
      for (final m in metrics) {
        buffer.writeln('- ${m.sideLabel}: **${m.formattedLongueur}** × **${m.formattedLargeur}** (${m.confidencePercentage})');
      }
      buffer.writeln();
    }
    
    if (widget.topViewUrl != null || widget.sideViewUrl != null) {
      buffer.writeln('🖼️ **Images de scan disponibles** - Cliquez sur une image ci-dessous pour l\'analyser.');
    }
    
    buffer.writeln();
    buffer.writeln('💡 Comment puis-je vous aider dans l\'analyse de ce dossier?');
    
    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      String response = '';
      
      // Stream the response
      await for (final chunk in _aiService.streamMessage(text)) {
        response += chunk;
        
        // Update the last message or add new one
        setState(() {
          final lastIndex = _messages.length - 1;
          if (lastIndex >= 0 && !_messages[lastIndex].isUser && _messages[lastIndex].isStreaming) {
            _messages[lastIndex] = _ChatMessage(
              content: response,
              isUser: false,
              timestamp: DateTime.now(),
              isStreaming: true,
            );
          } else {
            _messages.add(_ChatMessage(
              content: response,
              isUser: false,
              timestamp: DateTime.now(),
              isStreaming: true,
            ));
          }
        });
        _scrollToBottom();
      }

      // Mark as complete
      setState(() {
        final lastIndex = _messages.length - 1;
        if (lastIndex >= 0) {
          _messages[lastIndex] = _ChatMessage(
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: false,
          );
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          content: '❌ Erreur: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  Future<void> _analyzeImage(String imageUrl, String label) async {
    setState(() {
      _messages.add(_ChatMessage(
        content: '🖼️ Analyse de l\'image: **$label**',
        isUser: true,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _aiService.analyzeImageFromUrl(
        imageUrl: imageUrl,
        patient: widget.patient,
        session: widget.session,
        additionalPrompt: 'Analysez cette image ($label) du scan podologique. '
            'Identifiez la qualité de la segmentation, les anomalies visibles, '
            'et fournissez vos observations cliniques détaillées.',
      );

      setState(() {
        _messages.add(_ChatMessage(
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          content: '❌ Erreur lors de l\'analyse: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      });
    } finally {
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, cs, isDark),
          if (widget.topViewUrl != null || widget.sideViewUrl != null)
            _buildImageSelector(context, cs, isDark),
          Expanded(child: _buildMessageList(context, cs, isDark)),
          _buildQuickPrompts(context, cs),
          _buildInputArea(context, cs, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : cs.primary.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant IA Podologique',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Analyse clinique • ${widget.patient.fullName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurfaceVariant),
            onPressed: () {
              setState(() {
                _messages.clear();
                _initializeChat();
              });
            },
            tooltip: 'Nouvelle conversation',
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildImageSelector(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🖼️ Images du scan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.topViewUrl != null)
                Expanded(
                  child: _ImageThumbnail(
                    imageUrl: MeasurementService.getImageUrl(widget.topViewUrl!),
                    label: 'Vue dessus',
                    onTap: () => _analyzeImage(
                      MeasurementService.getImageUrl(widget.topViewUrl!),
                      'Vue de dessus',
                    ),
                    isLoading: _isTyping,
                  ),
                ),
              if (widget.topViewUrl != null && widget.sideViewUrl != null)
                const SizedBox(width: 12),
              if (widget.sideViewUrl != null)
                Expanded(
                  child: _ImageThumbnail(
                    imageUrl: MeasurementService.getImageUrl(widget.sideViewUrl!),
                    label: 'Vue profil',
                    onTap: () => _analyzeImage(
                      MeasurementService.getImageUrl(widget.sideViewUrl!),
                      'Vue de profil',
                    ),
                    isLoading: _isTyping,
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMessageList(BuildContext context, ColorScheme cs, bool isDark) {
    if (!_initialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text('Initialisation...', style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _TypingIndicator(cs: cs);
        }
        return _MessageBubble(
          message: _messages[index],
          cs: cs,
          isDark: isDark,
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildQuickPrompts(BuildContext context, ColorScheme cs) {
    final prompts = PodologyAIService.getQuickPrompts();
    
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = prompts[index];
          return _QuickPromptChip(
            icon: prompt.icon,
            label: prompt.label,
            onTap: _isTyping ? null : () => _sendMessage(prompt.prompt),
            cs: cs,
          );
        },
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ColorScheme cs, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        border: Border(
          top: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withOpacity(0.05)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.outline.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Posez votre question clinique...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                style: TextStyle(color: cs.onSurface),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isTyping 
                    ? [cs.outline, cs.outline]
                    : [cs.primary, cs.primary.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: _isTyping ? [] : [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isTyping
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isTyping ? null : () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;
  final bool isError;
  final String? imageUrl;

  _ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
    this.isError = false,
    this.imageUrl,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final ColorScheme cs;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? cs.primary
                    : isDark
                        ? Colors.white.withOpacity(0.08)
                        : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(
                  color: cs.outline.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.imageUrl!,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 60,
                          color: cs.surfaceContainerHighest,
                          child: Center(child: Icon(Icons.image, color: cs.onSurfaceVariant)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.white : cs.onSurface,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        color: isUser ? Colors.white : cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: TextStyle(
                        color: isUser ? Colors.white : cs.onSurface,
                      ),
                      h1: TextStyle(
                        color: isUser ? Colors.white : cs.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: isUser ? Colors.white : cs.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      code: TextStyle(
                        backgroundColor: isUser 
                            ? Colors.white.withOpacity(0.2)
                            : cs.surfaceContainerHighest,
                        color: isUser ? Colors.white : cs.onSurface,
                      ),
                    ),
                    selectable: true,
                  ),
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.person_rounded, color: cs.primary, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final ColorScheme cs;

  const _TypingIndicator({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0, cs: cs),
                const SizedBox(width: 4),
                _Dot(delay: 150, cs: cs),
                const SizedBox(width: 4),
                _Dot(delay: 300, cs: cs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  final ColorScheme cs;

  const _Dot({required this.delay, required this.cs});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.cs.primary.withOpacity(0.3 + _animation.value * 0.7),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final ColorScheme cs;

  const _QuickPromptChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.primary.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _ImageThumbnail({
    required this.imageUrl,
    required this.label,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withOpacity(0.2)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(Icons.image_not_supported, color: cs.onSurfaceVariant),
                    ),
                  ),
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withOpacity(0.9),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

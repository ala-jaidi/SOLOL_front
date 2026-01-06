import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/models/chat_message.dart';
import 'package:lidarmesure/services/chat_service.dart';
import 'package:lidarmesure/models/chat_thread.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/components/app_sidebar.dart';
import 'package:uuid/uuid.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

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
  bool _isTyping = false;
  bool _showJumpToBottom = false;
    String _sessionId = const Uuid().v4();
  List<String> _templates = [];
  String? _selectedTemplate;
  bool _loadingTemplates = false;
    ChatThread? _thread;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadTemplates().then((_) => _initThread());
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
      // Persist user message
      final thread = _thread ?? await _initThread();
      await _chat.appendMessage(threadId: thread.id, isUser: true, content: text);
      _updateMessageStatus(userMsg.id, ChatDeliveryStatus.sent);
      // Create assistant placeholder and stream deltas
      final botMsg = ChatMessage(content: '', isUser: false, status: ChatDeliveryStatus.pending);
      setState(() => _messages.add(botMsg));
      String buffer = '';
      bool gotStream = false;
      try {
        await for (final delta in _chat.streamMessage(
          message: text,
          sessionId: _sessionId,
          templateKey: _selectedTemplate,
        )) {
          gotStream = true;
          buffer += delta;
          final idx = _messages.indexWhere((m) => m.id == botMsg.id);
          if (idx != -1 && mounted) {
            setState(() => _messages[idx] = _messages[idx].copyWith(content: buffer));
            _scrollToBottom();
          }
        }
      } catch (streamErr, st) {
        debugPrint('Chat stream failed, falling back to non-stream invoke: $streamErr\n$st');
        // Fallback to non-stream call so the user still gets a reply
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
          rethrow; // Let outer catch display error
        }
      }
      // Persist assistant message once complete (from stream or fallback)
      await _chat.appendMessage(threadId: thread.id, isUser: false, content: buffer);
      final idx = _messages.indexWhere((m) => m.id == botMsg.id);
      if (idx != -1 && mounted) setState(() => _messages[idx] = _messages[idx].copyWith(status: ChatDeliveryStatus.sent));
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      endDrawer: const AppSideBar(),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Subtle glow behind avatar
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [cs.primary.withValues(alpha: 0.35), cs.tertiary.withValues(alpha: 0.25)],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 1200.ms).then().scale(begin: const Offset(1,1), end: const Offset(0.98,0.98), duration: 1200.ms),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.smart_toy_rounded, color: cs.onPrimaryContainer, size: 18),
                ),
                // Online status dot
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.secondary.withValues(alpha: 0.20),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.9,0.9), end: const Offset(1.1,1.1), duration: 1400.ms).fadeIn(duration: 600.ms).then(delay: 300.ms).scale(begin: const Offset(1.1,1.1), end: const Offset(0.9,0.9), duration: 1400.ms),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.secondary,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).chatTitle, style: context.textStyles.titleLarge?.semiBold),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context).isFrench ? 'Conseils orthopediques' : 'Orthopedic advice',
                        style: Theme.of(context).textTheme.labelSmall?.withColor(cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              icon: Icon(Icons.tune_rounded, color: cs.onSurface),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
              children: [
                _TemplateBar(
                  templates: _templates,
                  selected: _selectedTemplate,
                  loading: _loadingTemplates,
                  sessionId: _sessionId,
                  onRefresh: _loadTemplates,
                  onNewThread: _newThread,
                  onChanged: (v) => setState(() => _selectedTemplate = v),
                ),
                Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Container(height: 1, color: cs.outline.withValues(alpha: 0.08));
                }),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: AppSpacing.paddingMd,
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Day separator
                      Widget buildBubble(int i) {
                        if (_isTyping && i == _messages.length) {
                          return const _TypingBubble()
                              .animate()
                              .fadeIn(duration: 250.ms)
                              .slideY(begin: 0.2, end: 0);
                        }
                        final msg = _messages[i];
                        return _MessageRow(message: msg)
                            .animate()
                            .fadeIn(duration: 220.ms)
                            .slideY(begin: 0.08, end: 0);
                      }

                      final isTypingItem = _isTyping && index == _messages.length;
                      final isFirst = index == 0;
                      final msgDate = isTypingItem
                          ? DateTime.now()
                          : _messages[index].createdAt;
                      final prevDate = isFirst
                          ? null
                          : _messages[index - 1].createdAt;
                      final showSeparator = isFirst || !_isSameDay(msgDate, prevDate!);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showSeparator) _DaySeparator(date: msgDate),
                          buildBubble(index),
                        ],
                      );
                    },
                  ),
                ),
                // Thin separator to replace removed top border of composer
                Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Container(height: 1, color: cs.outline.withValues(alpha: 0.08));
                }),
                _QuickSuggestions(onSelect: (text) => _sendText(text)),
                _Composer(onSend: _send, controller: _controller),
              ],
            ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Clean composer - Revolut-inspired minimal input
class _Composer extends StatelessWidget {
  final VoidCallback onSend;
  final TextEditingController controller;

  const _Composer({required this.onSend, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: cs.surface,
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.isFrench ? 'Écrire un message...' : 'Write a message...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button - clean accent circle
          Material(
            color: cs.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
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
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final align = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: isUser ? cs.primaryContainer : cs.surfaceContainerHighest,
      child: Icon(isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
          size: 18, color: isUser ? cs.onPrimaryContainer : cs.onSurfaceVariant),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: align,
        children: [
          if (!isUser) avatar,
          if (!isUser) const SizedBox(width: 8),
          Flexible(child: _MessageBubble(message: message)),
          if (isUser) const SizedBox(width: 8),
          if (isUser) avatar,
        ],
      ),
    );
  }
}

/// Premium message bubble - Revolut-inspired clean design
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    
    // Clean, minimal bubble design
    final radius = BorderRadius.circular(18);
    
    // User: solid accent color, AI: subtle elevated surface
    final decoration = isUser
        ? BoxDecoration(
            borderRadius: radius,
            color: cs.primary,
          )
        : BoxDecoration(
            borderRadius: radius,
            color: cs.surfaceContainerHighest,
          );

    final textColor = isUser ? Colors.white : cs.onSurface;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () async {
            await Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Message copied'), backgroundColor: cs.primary),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 300),
            decoration: decoration,
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ),
        // Minimal timestamp
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
          child: Text(
            _formatTime(message.createdAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(color: cs.onSurfaceVariant).animate(onPlay: (c) => c.repeat()).fadeIn().moveX(begin: -2, end: 2, duration: 700.ms),
                const SizedBox(width: 4),
                _Dot(color: cs.onSurfaceVariant).animate(onPlay: (c) => c.repeat()).fadeIn(delay: 120.ms).moveX(begin: -2, end: 2, duration: 700.ms),
                const SizedBox(width: 4),
                _Dot(color: cs.onSurfaceVariant).animate(onPlay: (c) => c.repeat()).fadeIn(delay: 240.ms).moveX(begin: -2, end: 2, duration: 700.ms),
              ],
            ),
          ),
        ),
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

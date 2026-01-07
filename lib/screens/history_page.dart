import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/components/app_sidebar.dart';
import 'package:intl/intl.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final SessionService _sessionService = SessionService();
  final PatientService _patientService = PatientService();
  List<Session> _sessions = [];
  bool _isLoading = true;
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _sessionService.getAllSessions();
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      if (mounted) {
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Session> get _filteredSessions {
    if (_selectedFilter == 'Tous') return _sessions;
    
    SessionStatus status;
    switch (_selectedFilter) {
      case 'Terminé':
        status = SessionStatus.completed;
        break;
      case 'En cours':
        status = SessionStatus.pending;
        break;
      case 'Annulé':
        status = SessionStatus.cancelled;
        break;
      default:
        status = SessionStatus.completed;
    }
    
    return _sessions.where((s) => s.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      endDrawer: const AppSideBar(),
      backgroundColor: cs.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A1A1F),
                    const Color(0xFF0D2428),
                    cs.surface,
                  ]
                : [
                    cs.primary.withValues(alpha: 0.08),
                    cs.surface,
                  ],
            stops: isDark ? const [0.0, 0.15, 0.4] : const [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilters(context),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredSessions.isEmpty
                        ? _buildEmptyState(context)
                        : RefreshIndicator(
                            onRefresh: _loadSessions,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _filteredSessions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final session = _filteredSessions[index];
                                return _SessionHistoryCard(
                                  session: session,
                                  patientService: _patientService,
                                  onTap: () => context.push('/session/${session.id}'),
                                ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.historyTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  l10n.isFrench 
                      ? '${_sessions.length} session${_sessions.length > 1 ? 's' : ''} enregistrée${_sessions.length > 1 ? 's' : ''}'
                      : '${_sessions.length} session${_sessions.length > 1 ? 's' : ''} recorded',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Settings button
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openEndDrawer(),
              child: Container(
                width: 44,
                height: 44,
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
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFilters(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filters = l10n.isFrench 
        ? ['Tous', 'Termine', 'En cours', 'Annule']
        : ['All', 'Completed', 'Pending', 'Cancelled'];
    final icons = [Icons.list_rounded, Icons.check_circle_outline, Icons.schedule_rounded, Icons.cancel_outlined];
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected 
                      ? cs.primary
                      : isDark 
                          ? Colors.white.withValues(alpha: 0.08)
                          : cs.surface,
                  border: Border.all(
                    color: isSelected 
                        ? cs.primary
                        : isDark 
                            ? Colors.white.withValues(alpha: 0.1)
                            : cs.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 16,
                      color: isSelected ? Colors.white : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          SizedBox(height: AppSpacing.lg),
          Text(l10n.noHistory, style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.sm),
          Text(
            l10n.isFrench ? 'Les sessions apparaitront ici' : 'Sessions will appear here',
            style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryCard extends StatelessWidget {
  final Session session;
  final PatientService patientService;
  final VoidCallback onTap;

  const _SessionHistoryCard({
    required this.session,
    required this.patientService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Patient?>(
      future: patientService.getPatientById(session.patientId),
      builder: (context, snapshot) {
        final patient = snapshot.data;
        final hasMetrics = session.footMetrics.isNotEmpty;
        final avgConfidence = hasMetrics
            ? session.footMetrics.map((m) => m.confidence).reduce((a, b) => a + b) / session.footMetrics.length
            : 0.0;

        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.06)
                  : cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.1)
                    : cs.outline.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient?.fullName ?? 'Chargement...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(session.createdAt),
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(session.status, context).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(session.status, context),
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasMetrics) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.05)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricBadge(
                            icon: Icons.height,
                            label: 'Pied D',
                            value: session.footMetrics.firstWhere((m) => m.side.name == 'droite').formattedLongueur,
                          ),
                        ),
                        Container(width: 1, height: 24, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        Expanded(
                          child: _MetricBadge(
                            icon: Icons.height,
                            label: 'Pied G',
                            value: session.footMetrics.firstWhere((m) => m.side.name == 'gauche', orElse: () => session.footMetrics.first).formattedLongueur,
                          ),
                        ),
                        Container(width: 1, height: 24, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        Expanded(
                          child: _MetricBadge(
                            icon: Icons.speed,
                            label: 'Précision',
                            value: '${(avgConfidence * 100).toStringAsFixed(0)}%',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(SessionStatus status, BuildContext context) {
    switch (status) {
      case SessionStatus.pending:
        return Theme.of(context).colorScheme.tertiary;
      case SessionStatus.completed:
        return Theme.of(context).colorScheme.secondary;
      case SessionStatus.cancelled:
        return Theme.of(context).colorScheme.error;
    }
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: 2),
        Text(label, style: context.textStyles.labelSmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: context.textStyles.bodySmall?.semiBold),
      ],
    );
  }
}

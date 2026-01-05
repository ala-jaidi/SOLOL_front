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
    final sessions = await _sessionService.getAllSessions();
    sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
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
    return Scaffold(
      endDrawer: const AppSideBar(),
      body: SafeArea(
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
                            padding: AppSpacing.paddingLg,
                            itemCount: _filteredSessions.length,
                            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final session = _filteredSessions[index];
                              return _SessionHistoryCard(
                                session: session,
                                patientService: _patientService,
                                onTap: () => context.push('/session/${session.id}'),
                              ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.2);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () => context.pop(),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Historique', style: context.textStyles.headlineMedium?.bold),
                Text('${_sessions.length} session${_sessions.length > 1 ? 's' : ''} enregistrée${_sessions.length > 1 ? 's' : ''}', 
                  style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFilters(BuildContext context) {
    final filters = ['Tous', 'Terminé', 'En cours', 'Annulé'];
    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.horizontalLg,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedFilter = filter);
            },
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            selectedColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          SizedBox(height: AppSpacing.lg),
          Text('Aucune session trouvée', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Les sessions apparaîtront ici',
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

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient?.fullName ?? 'Chargement...', style: context.textStyles.titleMedium?.semiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                          SizedBox(height: AppSpacing.xs),
                          Text(DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(session.createdAt), 
                            style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(session.status, context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        session.statusLabel,
                        style: context.textStyles.labelSmall?.semiBold.withColor(_getStatusColor(session.status, context)),
                      ),
                    ),
                  ],
                ),
                if (hasMetrics) ...[
                  SizedBox(height: AppSpacing.md),
                  Container(
                    padding: AppSpacing.paddingSm,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
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

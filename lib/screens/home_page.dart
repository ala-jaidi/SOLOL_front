import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/services/session_service.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:lidarmesure/models/session.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/components/app_sidebar.dart';
import 'package:lidarmesure/components/gradient_header.dart';
import 'package:lidarmesure/components/scan_cta.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PatientService _patientService = PatientService();
  final SessionService _sessionService = SessionService();
  List<Patient> _patients = [];
  List<Session> _recentSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _patients = await _patientService.getAllPatients();
    final allSessions = await _sessionService.getAllSessions();
    allSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _recentSessions = allSessions.take(5).toList();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppSideBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      SizedBox(height: AppSpacing.xl),
                      _buildQuickActions(context),
                      SizedBox(height: AppSpacing.xl),
                      _buildStats(context),
                      SizedBox(height: AppSpacing.xl),
                      _buildRecentSessions(context),
                      SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GradientHeader(
      title: 'Bonjour, Dr. Leblanc 👋',
      subtitle: 'Bienvenue dans votre espace professionnel',
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.onPrimary, size: 24),
      ),
      trailing: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Scaffold.of(ctx).openEndDrawer(),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions Rapides', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.md),
          // Dominant primary CTA
          ScanCTA(
            onPressed: () => context.push('/scan'),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.people_outline,
                  label: 'Mes\nPatients',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => context.push('/patients'),
                ).animate().fadeIn(delay: 180.ms).scale(begin: const Offset(0.85, 0.85)),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.history,
                  label: 'Historique',
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => context.push('/history'),
                ).animate().fadeIn(delay: 260.ms).scale(begin: const Offset(0.85, 0.85)),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat_bubble_outline,
                  label: 'Assistant\nIA',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => context.push('/chat'),
                ).animate().fadeIn(delay: 340.ms).scale(begin: const Offset(0.9, 0.9)),
              ),
              const Spacer(),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final completedSessions = _recentSessions.where((s) => s.status == SessionStatus.termine).length;
    final avgConfidence = _recentSessions.isEmpty
        ? 0.0
        : _recentSessions
            .where((s) => s.footMetrics.isNotEmpty)
            .expand((s) => s.footMetrics)
            .map((m) => m.confidence)
            .fold(0.0, (a, b) => a + b) / _recentSessions.where((s) => s.footMetrics.isNotEmpty).expand((s) => s.footMetrics).length;

    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiques', style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.person_outline,
                  value: '${_patients.length}',
                  label: 'Patients',
                  color: Theme.of(context).colorScheme.primary,
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatCard(
                  icon: Icons.check_circle_outline,
                  value: '$completedSessions',
                  label: 'Scans complétés',
                  color: Theme.of(context).colorScheme.secondary,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _StatCard(
            icon: Icons.speed_outlined,
            value: '${(avgConfidence * 100).toStringAsFixed(0)}%',
            label: 'Précision moyenne',
            color: Theme.of(context).colorScheme.tertiary,
            isWide: true,
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(BuildContext context) {
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sessions Récentes', style: context.textStyles.titleLarge?.semiBold),
              TextButton(
                onPressed: () => context.push('/history'),
                child: Text('Voir tout', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (_recentSessions.isEmpty)
            Center(
              child: Padding(
                padding: AppSpacing.paddingXl,
                child: Text('Aucune session récente', style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentSessions.length,
              separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final session = _recentSessions[index];
                return _SessionCard(
                  session: session,
                  patientService: _patientService,
                  onTap: () => context.push('/session/${session.id}'),
                ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2);
              },
            ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(label, textAlign: TextAlign.center, style: context.textStyles.labelMedium?.semiBold.withColor(color)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: context.textStyles.headlineSmall?.bold),
                Text(label, style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final PatientService patientService;
  final VoidCallback onTap;

  const _SessionCard({
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
            child: Row(
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
                      Text(patient?.fullName ?? 'Chargement...', style: context.textStyles.titleMedium?.semiBold),
                      SizedBox(height: AppSpacing.xs),
                      Text(session.formattedDate, style: context.textStyles.bodySmall?.withColor(Theme.of(context).colorScheme.onSurfaceVariant)),
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
          ),
        );
      },
    );
  }

  Color _getStatusColor(SessionStatus status, BuildContext context) {
    switch (status) {
      case SessionStatus.enCours:
        return Theme.of(context).colorScheme.tertiary;
      case SessionStatus.termine:
        return Theme.of(context).colorScheme.secondary;
      case SessionStatus.annule:
        return Theme.of(context).colorScheme.error;
    }
  }
}

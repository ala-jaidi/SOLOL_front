import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidarmesure/theme.dart';
import 'package:lidarmesure/services/patient_service.dart';
import 'package:lidarmesure/models/user.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lidarmesure/components/app_sidebar.dart';
import 'package:lidarmesure/components/gradient_header.dart';
import 'package:lidarmesure/l10n/app_localizations.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final PatientService _patientService = PatientService();
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _genderFilter = 'Tous';
  String _sort = 'Récent';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    _patients = await _patientService.getAllPatients();
    _patients.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _filteredPatients = _patients;
    setState(() => _isLoading = false);
  }

  void _filterPatients(String query) {
    setState(() {
      Iterable<Patient> list = _patients;
      if (query.isNotEmpty) {
        final searchLower = query.toLowerCase();
        list = list.where((patient) {
          final fullName = '${patient.prenom} ${patient.nom}'.toLowerCase();
          return fullName.contains(searchLower) ||
              // patient.email.toLowerCase().contains(searchLower) ||
              patient.telephone.contains(searchLower);
        });
      }
      if (_genderFilter != 'Tous') {
        list = list.where((p) => p.sexeLabel().toLowerCase().startsWith(_genderFilter.toLowerCase()));
      }
      final tmp = list.toList();
      if (_sort == 'Nom') {
        tmp.sort((a, b) => ('${a.prenom} ${a.nom}').compareTo('${b.prenom} ${b.nom}'));
      } else {
        tmp.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      _filteredPatients = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppSideBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredPatients.isEmpty
                      ? _buildEmptyState(context)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width < 640
                                ? 1
                                : width < 1000
                                    ? 2
                                    : 3;
                            if (crossAxisCount == 1) {
                              final items = _buildItemsWithHeaders(_filteredPatients);
                              return RefreshIndicator(
                                onRefresh: _loadPatients,
                                child: ListView.builder(
                                  padding: AppSpacing.paddingLg,
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final it = items[index];
                                    if (it.isHeader) {
                                      return Padding(
                                        padding: EdgeInsets.only(top: index == 0 ? 0 : AppSpacing.lg),
                                        child: Text(
                                          it.header!,
                                          style: context.textStyles.titleSmall?.semiBold.withColor(Theme.of(context).colorScheme.onSurfaceVariant),
                                        ),
                                      );
                                    }
                                    final patient = it.patient!;
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                                      child: _PatientCard(
                                        patient: patient,
                                        onTap: () => context.push('/patient/${patient.id}'),
                                      ).animate().fadeIn(delay: (30 * index).ms).slideX(begin: 0.1),
                                    );
                                  },
                                ),
                              );
                            }
                            return RefreshIndicator(
                              onRefresh: _loadPatients,
                              child: GridView.builder(
                                padding: AppSpacing.paddingLg,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                  childAspectRatio: 3.2,
                                ),
                                itemCount: _filteredPatients.length,
                                itemBuilder: (context, index) {
                                  final patient = _filteredPatients[index];
                                  return _PatientCard(
                                    patient: patient,
                                    onTap: () => context.push('/patient/${patient.id}'),
                                  ).animate().fadeIn(delay: (40 * index).ms).moveX(begin: 12);
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-patient'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        label: Text(AppLocalizations.of(context).newPatient, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final count = _patients.length;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
          ),
          const SizedBox(width: 4),
          // Title & count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myPatients.replaceAll('\n', ' '),
                  style: context.textStyles.titleLarge?.bold,
                ),
                const SizedBox(height: 2),
                Text(
                  '$count ${l10n.isFrench ? 'patients' : 'patients'}',
                  style: context.textStyles.bodySmall?.withColor(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Settings
          Builder(
            builder: (ctx) => Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.tune_rounded, color: cs.onSurfaceVariant, size: 20),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSearchBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: AppSpacing.horizontalLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Row(
              children: [
                Icon(Icons.search, color: cs.onSurfaceVariant, size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterPatients,
                    decoration: InputDecoration(hintText: l10n.searchPatients, border: InputBorder.none, hintStyle: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: cs.onSurfaceVariant, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _filterPatients('');
                    },
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(context, l10n.isFrench ? 'Tous' : 'All', _genderFilter == 'Tous', () { setState(() { _genderFilter = 'Tous'; }); _filterPatients(_searchController.text); }),
                    const SizedBox(width: 8),
                    _chip(context, l10n.male, _genderFilter == 'Homme', () { setState(() { _genderFilter = 'Homme'; }); _filterPatients(_searchController.text); }),
                    const SizedBox(width: 8),
                    _chip(context, l10n.female, _genderFilter == 'Femme', () { setState(() { _genderFilter = 'Femme'; }); _filterPatients(_searchController.text); }),
                    const SizedBox(width: 8),
                    _chip(context, l10n.other, _genderFilter == 'Autre', () { setState(() { _genderFilter = 'Autre'; }); _filterPatients(_searchController.text); }),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _segSort(context),
          ]),
        ],
      ),
    );
  }

  Widget _segSort(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _segBtn(context, l10n.isFrench ? 'Recent' : 'Recent', _sort == 'Récent', () { setState(() { _sort = 'Récent'; }); _filterPatients(_searchController.text); }),
        _segBtn(context, l10n.isFrench ? 'Nom' : 'Name', _sort == 'Nom', () { setState(() { _sort = 'Nom'; }); _filterPatients(_searchController.text); }),
      ]),
    );
  }

  Widget _segBtn(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: selected ? cs.primary : Colors.transparent, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium?.withColor(selected ? cs.onPrimary : cs.onSurface)),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? cs.primary : cs.surface,
          border: Border.all(color: selected ? cs.primary : cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.filter_alt_outlined, size: 16, color: selected ? cs.onPrimary : cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.withColor(selected ? cs.onPrimary : cs.onSurface)),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          SizedBox(height: AppSpacing.lg),
          Text(l10n.noPatientFound, style: context.textStyles.titleLarge?.semiBold),
          SizedBox(height: AppSpacing.sm),
          Text(
            _searchController.text.isEmpty
                ? (l10n.isFrench ? 'Ajoutez votre premier patient' : 'Add your first patient')
                : (l10n.isFrench ? 'Essayez une autre recherche' : 'Try another search'),
            style: context.textStyles.bodyMedium?.withColor(Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ListItem {
  final String? header;
  final Patient? patient;
  const _ListItem._({this.header, this.patient});
  const _ListItem.header(String h) : this._(header: h);
  const _ListItem.patient(Patient p) : this._(patient: p);
  bool get isHeader => header != null;
}

List<_ListItem> _buildItemsWithHeaders(List<Patient> patients) {
  final items = <_ListItem>[];
  String? current;
  for (final p in patients) {
    final name = (p.fullName).trim();
    final ch = name.isNotEmpty ? name[0].toUpperCase() : '#';
    if (ch != current) {
      current = ch;
      items.add(_ListItem.header(current));
    }
    items.add(_ListItem.patient(p));
  }
  return items;
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String _initials(String prenom, String nom) {
      try {
        final p = (prenom.isNotEmpty) ? prenom.substring(0, 1) : '?';
        final n = (nom.isNotEmpty) ? nom.substring(0, 1) : '';
        return (p + n).toUpperCase();
      } catch (_) {
        return '?';
      }
    }

    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 64,
                height: 64,
                child: patient.avatarUrl != null && patient.avatarUrl!.isNotEmpty
                    ? Image.network(
                        patient.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _InitialsTile(text: _initials(patient.prenom, patient.nom)),
                      )
                    : _InitialsTile(text: _initials(patient.prenom, patient.nom)),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(patient.fullName, style: context.textStyles.titleMedium?.semiBold, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
                      child: Text(patient.sexeLabel(isFrench: AppLocalizations.of(context).isFrench), style: context.textStyles.labelSmall?.semiBold.withColor(cs.primary)),
                    ),
                  ]),
                  SizedBox(height: AppSpacing.xs),
                  Wrap(spacing: AppSpacing.md, runSpacing: 6, children: [
                    _InfoChip(icon: Icons.cake_outlined, label: '${patient.age} ${AppLocalizations.of(context).isFrench ? 'ans' : 'yrs'}'),
                    _InfoChip(icon: Icons.straighten, label: '${AppLocalizations.of(context).isFrench ? 'Pointure' : 'Size'} ${patient.pointure}'),
                    _InfoChip(icon: Icons.phone_outlined, label: patient.telephone),
                  ]),
                  SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    _PillButton(
                      icon: Icons.person_outline,
                      label: AppLocalizations.of(context).isFrench ? 'Fiche' : 'Profile',
                      onPressed: onTap,
                      background: cs.primary,
                      foreground: cs.onPrimary,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    _PillButton(
                      icon: Icons.add_circle_outline,
                      label: 'Session',
                      onPressed: () => context.push('/add-session?patientId=${patient.id}'),
                      background: cs.secondary,
                      foreground: cs.onSecondary,
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsTile extends StatelessWidget {
  final String text;
  const _InitialsTile({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(text, style: context.textStyles.titleLarge?.bold.withColor(Colors.white))),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: context.textStyles.bodySmall?.withColor(cs.onSurface)),
      ]),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.withColor(foreground)),
        ]),
      ),
    );
  }
}

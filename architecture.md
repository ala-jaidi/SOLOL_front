# Architecture - LiDAR Mesure

## Vue d'ensemble
Application Flutter professionnelle de mesure de pieds via technologie LiDAR pour podologues. Interface moderne et épurée avec palette de couleurs médicale (bleu professionnel, teal accent, violet pour highlights).

## Structure du Projet

### Modèles de Données (`/lib/models/`)
Basé sur le schéma UML fourni avec relations entre entités :

- **user.dart** : Classe abstraite `Professionnel` et `Patient` (hérite de Professionnel)
  - Patient : informations complètes (nom, prénom, âge, pointure, données médicales)
  - Role enum : podologue, patient

- **foot_metrics.dart** : Mesures du pied
  - FootMetrics : longueur, largeur, confiance, côté (droite/gauche)
  - FootSide enum : droite, gauche

- **foot_scan.dart** : Captures 3D du scan
  - FootScan : vues (dessus, latéral), angle
  - AngleType enum : top, side

- **medical_questionnaire.dart** : Questionnaire médical
  - MedicalQuestionnaire : question, condition, réponse
  - FootCondition enum : halluxvalgus, pronation, supination, plantarfasciitis

- **session.dart** : Session de scan complète
  - Session : relation avec patient, statut, métriques, scan, questionnaires
  - SessionStatus enum : enCours, termine, annule
  - Relations : 1 session → N footMetrics, 1 footScan, N questionnaires

### Services (`/lib/services/`)
Gestion des données avec stockage local (shared_preferences) :

- **patient_service.dart** : CRUD patients + données d'exemple (4 patients pré-remplis)
- **session_service.dart** : CRUD sessions + données d'exemple (3 sessions avec métriques)

Les services incluent des données de démonstration réalistes pour tester l'application immédiatement.

### Écrans (`/lib/screens/`)

1. **home_page.dart** : Page d'accueil
   - En-tête avec branding
   - Actions rapides (Nouveau Scan, Mes Patients, Historique)
   - Statistiques (nombre patients, scans complétés, précision moyenne)
   - Sessions récentes avec statuts
   - Animations fluides avec flutter_animate

2. **patients_page.dart** : Liste des patients
   - Barre de recherche (nom, email, téléphone)
   - Liste scrollable avec cards patients
   - Informations : avatar, nom complet, âge, pointure, téléphone
   - Bouton FAB pour ajouter un patient

3. **patient_detail_page.dart** : Détail d'un patient
   - Avatar circulaire avec dégradé
   - Informations complètes (email, téléphone, adresse, pointure, poids)
   - Liste des sessions du patient
   - Bouton pour nouveau scan

4. **scan_page.dart** : Interface de scan LiDAR
   - Sélection du patient (bottom sheet)
   - Zone de scan avec animations :
     - Icône radar rotative pendant le scan
     - Ligne de balayage verticale
     - Effet de pulsation radial
   - Instructions claires (position, éclairage, posture)
   - Progression avec statuts : initialisation → calibration → scan pieds → analyse → finalisation
   - Simulation réaliste du processus de scan (30 secondes)

5. **scan_result_page.dart** : Résultats du scan
   - Badge de succès avec précision
   - Métriques des deux pieds (longueur, largeur)
   - Visualisation 3D (vues dessus et latérale)
   - Analyse avec recommandations
   - Actions : retour accueil ou nouveau scan

6. **history_page.dart** : Historique des sessions
   - Filtres par statut (Tous, Terminé, En cours, Annulé)
   - Cards avec infos patient, date/heure, statut
   - Métriques résumées (pieds D/G, précision)
   - Pull-to-refresh

### Thème (`/lib/theme.dart`)
Design moderne et professionnel :

**Palette de couleurs :**
- Primary : Bleu professionnel #0052CC
- Secondary : Teal médical #00BFA5
- Tertiary : Violet #7C4DFF
- Erreur : Rouge #E53935

**Typographie :**
- Police : Inter (Google Fonts)
- Hiérarchie claire avec tailles et poids variés
- Extensions pour modifications rapides (.bold, .semiBold, .withColor())

**Espacement :**
- Système cohérent (xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48)
- Border radius (sm: 8, md: 12, lg: 16, xl: 24)

**Composants :**
- Cards avec bordures subtiles (pas d'élévation)
- Dégradés pour avatars et badges
- Animations avec flutter_animate
- Design plat et épuré

### Navigation (`/lib/nav.dart`)
go_router avec routes :
- `/` : HomePage
- `/patients` : PatientsPage
- `/patient/:id` : PatientDetailPage
- `/scan` : ScanPage
- `/scan-result` : ScanResultPage
- `/history` : HistoryPage

### Dépendances
- **google_fonts** : Typographie Inter
- **shared_preferences** : Stockage local
- **intl** : Formatage dates
- **uuid** : Identifiants uniques
- **flutter_animate** : Animations fluides
- **go_router** : Navigation déclarative
- **provider** : State management (prêt pour extension)

## Caractéristiques Techniques

### Animations
- Fade in/out progressifs
- Slide (X/Y) pour entrées d'éléments
- Scale pour effets de zoom
- Délais séquentiels pour animations en cascade
- Rotation continue pour icône radar
- Pulsation pour effet LiDAR

### UX/UI
- Interface épurée sans Material Design traditionnel
- Espacement généreux entre éléments
- Feedback visuel immédiat
- Statuts colorés et clairs
- Instructions pas-à-pas pour le scan
- Gestion d'états vides élégante

### Performance
- ListView.builder pour listes longues
- FutureBuilder pour chargement asynchrone
- Gestion d'erreurs avec try-catch
- Sauvegarde automatique dans SharedPreferences
- Images optimisées depuis assets

## Flux Utilisateur Principal

1. **Accueil** → Vue d'ensemble statistiques + sessions récentes
2. **Nouveau Scan** → Sélection patient → Scan LiDAR → Résultats
3. **Gestion Patients** → Liste → Détail → Sessions historiques
4. **Historique** → Filtrage → Consultation sessions passées

## Extensibilité

L'architecture permet facilement :
- Connexion Firebase/Supabase (services déjà structurés)
- Export PDF des résultats
- Partage des données avec patients
- Intégration API externe pour analyse IA
- Mode multi-utilisateur (podologues)
- Synchronisation cloud

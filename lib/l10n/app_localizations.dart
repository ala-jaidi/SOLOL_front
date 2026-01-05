import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lidarmesure/state/app_settings.dart';

/// Simple localization class for French/English support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final locale = settings.locale ?? const Locale('fr');
    return AppLocalizations(locale);
  }

  static AppLocalizations read(BuildContext context) {
    final settings = context.read<AppSettings>();
    final locale = settings.locale ?? const Locale('fr');
    return AppLocalizations(locale);
  }

  bool get isFrench => locale.languageCode == 'fr';
  bool get isEnglish => locale.languageCode == 'en';

  // Common
  String get appName => 'LiDAR Mesure';
  String get cancel => isFrench ? 'Annuler' : 'Cancel';
  String get confirm => isFrench ? 'Confirmer' : 'Confirm';
  String get save => isFrench ? 'Enregistrer' : 'Save';
  String get delete => isFrench ? 'Supprimer' : 'Delete';
  String get edit => isFrench ? 'Modifier' : 'Edit';
  String get add => isFrench ? 'Ajouter' : 'Add';
  String get search => isFrench ? 'Rechercher' : 'Search';
  String get loading => isFrench ? 'Chargement...' : 'Loading...';
  String get error => isFrench ? 'Erreur' : 'Error';
  String get success => isFrench ? 'Succes' : 'Success';
  String get yes => isFrench ? 'Oui' : 'Yes';
  String get no => isFrench ? 'Non' : 'No';

  // Home page
  String hello(String name) => isFrench ? 'Bonjour, $name' : 'Hello, $name';
  String get welcomeSubtitle => isFrench 
      ? 'Bienvenue dans votre espace professionnel' 
      : 'Welcome to your professional space';
  String get quickActions => isFrench ? 'Actions Rapides' : 'Quick Actions';
  String get newScan => isFrench ? 'Nouveau Scan' : 'New Scan';
  String get myPatients => isFrench ? 'Mes\nPatients' : 'My\nPatients';
  String get history => isFrench ? 'Historique' : 'History';
  String get aiAssistant => isFrench ? 'Assistant\nIA' : 'AI\nAssistant';
  String get statistics => isFrench ? 'Statistiques' : 'Statistics';
  String get patients => isFrench ? 'Patients' : 'Patients';
  String get completedScans => isFrench ? 'Scans completes' : 'Completed Scans';
  String get averagePrecision => isFrench ? 'Precision moyenne' : 'Average Precision';
  String get recentSessions => isFrench ? 'Sessions recentes' : 'Recent Sessions';
  String get noRecentSessions => isFrench ? 'Aucune session recente' : 'No recent sessions';
  String get viewAll => isFrench ? 'Voir tout' : 'View all';
  String get seeAll => isFrench ? 'Voir tout' : 'See all';

  // Sidebar
  String get scanner => isFrench ? 'Scanner' : 'Scanner';
  String get podiatristProfile => isFrench ? 'Profil podologue' : 'Podiatrist Profile';
  String get notifications => isFrench ? 'Notifications' : 'Notifications';
  String get help => isFrench ? 'Aide' : 'Help';
  String get preferences => isFrench ? 'Preferences' : 'Preferences';
  String get appearance => isFrench ? 'Apparence' : 'Appearance';
  String get light => isFrench ? 'Clair' : 'Light';
  String get dark => isFrench ? 'Sombre' : 'Dark';
  String get language => isFrench ? 'Langue' : 'Language';
  String get logout => isFrench ? 'Se deconnecter' : 'Log out';
  String get logoutConfirm => isFrench 
      ? 'Etes-vous sur de vouloir vous deconnecter ?' 
      : 'Are you sure you want to log out?';
  String get professionalSpace => isFrench ? 'Espace professionnel' : 'Professional Space';

  // Login/Signup
  String get login => isFrench ? 'Connexion' : 'Login';
  String get signup => isFrench ? 'Creer un compte' : 'Create Account';
  String get email => isFrench ? 'Email' : 'Email';
  String get password => isFrench ? 'Mot de passe' : 'Password';
  String get confirmPassword => isFrench ? 'Confirmer le mot de passe' : 'Confirm Password';
  String get forgotPassword => isFrench ? 'Mot de passe oublie ?' : 'Forgot password?';
  String get noAccount => isFrench ? 'Pas de compte ?' : 'No account?';
  String get alreadyHaveAccount => isFrench ? 'Deja un compte ?' : 'Already have an account?';
  String get signupSuccess => isFrench ? 'Compte cree avec succes !' : 'Account created successfully!';
  String get loginSuccess => isFrench ? 'Connexion reussie !' : 'Login successful!';

  // Complete Profile
  String get completeProfile => isFrench ? 'Completez votre profil' : 'Complete Your Profile';
  String get completeProfileSubtitle => isFrench 
      ? 'Ces informations nous aident a personnaliser votre experience' 
      : 'This information helps us personalize your experience';
  String get firstName => isFrench ? 'Prenom' : 'First Name';
  String get lastName => isFrench ? 'Nom' : 'Last Name';
  String get organization => isFrench ? 'Organisation / Cabinet' : 'Organization / Clinic';
  String get specialty => isFrench ? 'Specialite' : 'Specialty';
  String get phone => isFrench ? 'Telephone' : 'Phone';
  String get skipStep => isFrench ? 'Passer cette etape' : 'Skip this step';
  String get profileCompleted => isFrench ? 'Profil complete avec succes !' : 'Profile completed successfully!';

  // Patients
  String get addPatient => isFrench ? 'Ajouter un patient' : 'Add Patient';
  String get patientDetails => isFrench ? 'Details du patient' : 'Patient Details';
  String get noPatients => isFrench ? 'Aucun patient' : 'No patients';
  String get searchPatients => isFrench ? 'Rechercher des patients...' : 'Search patients...';

  // Sessions
  String get addSession => isFrench ? 'Ajouter une session' : 'Add Session';
  String get sessionDetails => isFrench ? 'Details de la session' : 'Session Details';
  String get noSessions => isFrench ? 'Aucune session' : 'No sessions';
  String get pending => isFrench ? 'En cours' : 'Pending';
  String get completed => isFrench ? 'Termine' : 'Completed';
  String get cancelled => isFrench ? 'Annule' : 'Cancelled';

  // Scan
  String get startScan => isFrench ? 'Demarrer le scan' : 'Start Scan';
  String get scanInProgress => isFrench ? 'Scan en cours...' : 'Scan in progress...';
  String get scanComplete => isFrench ? 'Scan termine' : 'Scan complete';
  String get rightFoot => isFrench ? 'Pied Droit' : 'Right Foot';
  String get leftFoot => isFrench ? 'Pied Gauche' : 'Left Foot';
  String get length => isFrench ? 'Longueur' : 'Length';
  String get width => isFrench ? 'Largeur' : 'Width';

  // Validation messages
  String get required => isFrench ? 'Requis' : 'Required';
  String get invalidEmail => isFrench ? 'Email invalide' : 'Invalid email';
  String get passwordTooShort => isFrench 
      ? 'Le mot de passe doit contenir au moins 6 caracteres' 
      : 'Password must be at least 6 characters';
  String get passwordsDoNotMatch => isFrench 
      ? 'Les mots de passe ne correspondent pas' 
      : 'Passwords do not match';
  String get pleaseEnterEmail => isFrench ? 'Veuillez entrer votre email' : 'Please enter your email';
  String get pleaseEnterPassword => isFrench ? 'Veuillez entrer un mot de passe' : 'Please enter a password';
  String get pleaseConfirmPassword => isFrench ? 'Veuillez confirmer votre mot de passe' : 'Please confirm your password';

  // Scan page
  String get scanTitle => isFrench ? 'Scanner LiDAR' : 'LiDAR Scanner';
  String get scanSubtitle => isFrench ? 'Positionnez le pied dans le cadre' : 'Position the foot in the frame';
  String get capture => isFrench ? 'Capturer' : 'Capture';
  String get retake => isFrench ? 'Reprendre' : 'Retake';
  String get analyze => isFrench ? 'Analyser' : 'Analyze';
  String get analyzing => isFrench ? 'Analyse en cours...' : 'Analyzing...';
  String get scanSuccess => isFrench ? 'Scan reussi !' : 'Scan successful!';
  String get scanError => isFrench ? 'Erreur lors du scan' : 'Scan error';
  String get noCamera => isFrench ? 'Camera non disponible' : 'Camera not available';
  String get cameraPermission => isFrench ? 'Permission camera requise' : 'Camera permission required';

  // Patients page
  String get patientsList => isFrench ? 'Liste des patients' : 'Patients List';
  String get noPatientFound => isFrench ? 'Aucun patient trouve' : 'No patient found';
  String get deletePatient => isFrench ? 'Supprimer le patient' : 'Delete patient';
  String get deletePatientConfirm => isFrench 
      ? 'Etes-vous sur de vouloir supprimer ce patient ?' 
      : 'Are you sure you want to delete this patient?';
  String get patientDeleted => isFrench ? 'Patient supprime' : 'Patient deleted';
  String get patientAdded => isFrench ? 'Patient ajoute avec succes' : 'Patient added successfully';
  String get patientUpdated => isFrench ? 'Patient mis a jour' : 'Patient updated';

  // Add patient page
  String get newPatient => isFrench ? 'Nouveau Patient' : 'New Patient';
  String get editPatient => isFrench ? 'Modifier Patient' : 'Edit Patient';
  String get gender => isFrench ? 'Sexe' : 'Gender';
  String get male => isFrench ? 'Homme' : 'Male';
  String get female => isFrench ? 'Femme' : 'Female';
  String get other => isFrench ? 'Autre' : 'Other';
  String get birthDate => isFrench ? 'Date de naissance' : 'Birth Date';
  String get height => isFrench ? 'Taille (cm)' : 'Height (cm)';
  String get weight => isFrench ? 'Poids (kg)' : 'Weight (kg)';
  String get shoeSize => isFrench ? 'Pointure' : 'Shoe Size';
  String get address => isFrench ? 'Adresse' : 'Address';

  // Session status
  String get statusPending => isFrench ? 'En cours' : 'Pending';
  String get statusCompleted => isFrench ? 'Termine' : 'Completed';
  String get statusCancelled => isFrench ? 'Annule' : 'Cancelled';

  // History page
  String get historyTitle => isFrench ? 'Historique' : 'History';
  String get noHistory => isFrench ? 'Aucun historique' : 'No history';
  String get filterByDate => isFrench ? 'Filtrer par date' : 'Filter by date';
  String get filterByPatient => isFrench ? 'Filtrer par patient' : 'Filter by patient';
  String get allPatients => isFrench ? 'Tous les patients' : 'All patients';

  // Chat/AI page
  String get chatTitle => isFrench ? 'Assistant IA' : 'AI Assistant';
  String get typeMessage => isFrench ? 'Tapez votre message...' : 'Type your message...';
  String get send => isFrench ? 'Envoyer' : 'Send';
  String get aiThinking => isFrench ? 'Reflexion en cours...' : 'Thinking...';

  // Profile page
  String get profileTitle => isFrench ? 'Mon Profil' : 'My Profile';
  String get editProfile => isFrench ? 'Modifier le profil' : 'Edit Profile';
  String get saveChanges => isFrench ? 'Enregistrer les modifications' : 'Save Changes';
  String get changesSaved => isFrench ? 'Modifications enregistrees' : 'Changes saved';

  // Notifications page
  String get notificationsTitle => isFrench ? 'Notifications' : 'Notifications';
  String get noNotifications => isFrench ? 'Aucune notification' : 'No notifications';
  String get markAllRead => isFrench ? 'Tout marquer comme lu' : 'Mark all as read';

  // Help page
  String get helpTitle => isFrench ? 'Aide' : 'Help';
  String get faq => isFrench ? 'Questions frequentes' : 'FAQ';
  String get contactSupport => isFrench ? 'Contacter le support' : 'Contact Support';
  String get userGuide => isFrench ? 'Guide utilisateur' : 'User Guide';

  // Session detail
  String get sessionInfo => isFrench ? 'Informations de la session' : 'Session Information';
  String get measurements => isFrench ? 'Mesures' : 'Measurements';
  String get generateReport => isFrench ? 'Generer le rapport' : 'Generate Report';
  String get shareReport => isFrench ? 'Partager le rapport' : 'Share Report';
  String get deleteSession => isFrench ? 'Supprimer la session' : 'Delete Session';
  String get deleteSessionConfirm => isFrench 
      ? 'Etes-vous sur de vouloir supprimer cette session ?' 
      : 'Are you sure you want to delete this session?';

  // Scan result
  String get scanResults => isFrench ? 'Resultats du scan' : 'Scan Results';
  String get precision => isFrench ? 'Precision' : 'Precision';
  String get saveResults => isFrench ? 'Enregistrer les resultats' : 'Save Results';
  String get newScanAction => isFrench ? 'Nouveau scan' : 'New scan';

  // Date/Time
  String get today => isFrench ? 'Aujourd\'hui' : 'Today';
  String get yesterday => isFrench ? 'Hier' : 'Yesterday';
  String get thisWeek => isFrench ? 'Cette semaine' : 'This week';
  String get thisMonth => isFrench ? 'Ce mois' : 'This month';

  // Actions
  String get close => isFrench ? 'Fermer' : 'Close';
  String get back => isFrench ? 'Retour' : 'Back';
  String get next => isFrench ? 'Suivant' : 'Next';
  String get finish => isFrench ? 'Terminer' : 'Finish';
  String get retry => isFrench ? 'Reessayer' : 'Retry';
  String get refresh => isFrench ? 'Actualiser' : 'Refresh';
}

import 'package:intl/intl.dart';

enum Role { podologue }

class Professionnel {
  final String id;
  final String nom;
  final String email;
  final String organisation;
  final String specialite;
  final Role role;
  final DateTime createdAt;
  final DateTime updatedAt;

  Professionnel({
    required this.id,
    required this.nom,
    required this.email,
    required this.organisation,
    required this.specialite,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'organisation': organisation,
    'specialite': specialite,
    'role': role.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Professionnel.fromJson(Map<String, dynamic> json) => Professionnel(
    id: json['id'] as String,
    nom: json['nom'] as String,
    email: json['email'] as String,
    organisation: json['organisation'] as String,
    specialite: json['specialite'] as String,
    role: Role.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => Role.podologue,
    ),
    createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
    updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String),
  );
}

class Patient {
  final String id;
  final String nom;
  final String prenom;
  final String pointure;
  final int sexe; // 0 for Male, 1 for Female (example convention)
  final DateTime dateNaissance;
  final double taille;
  final double poids;
  final String telephone;
  final int age;
  final String adresse;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// URL (ou chemin local) de la photo de profil du patient.
  final String? avatarUrl;

  Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.pointure,
    required this.sexe,
    required this.dateNaissance,
    required this.taille,
    required this.poids,
    required this.telephone,
    required this.age,
    required this.adresse,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'prenom': prenom,
    'pointure': pointure,
    'sexe': sexe,
    'date_naissance': dateNaissance.toIso8601String(),
    'taille': taille,
    'poids': poids,
    'telephone': telephone,
    'age': age,
    'adresse': adresse,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    nom: json['nom'] as String,
    prenom: json['prenom'] as String,
    pointure: json['pointure'] as String,
    sexe: json['sexe'] is int ? json['sexe'] as int : int.tryParse(json['sexe'].toString()) ?? 0,
    dateNaissance: DateTime.parse((json['dateNaissance'] ?? json['date_naissance']) as String),
    taille: (json['taille'] as num).toDouble(),
    poids: (json['poids'] as num).toDouble(),
    telephone: json['telephone'] as String,
    age: json['age'] as int,
    adresse: json['adresse'] as String,
    createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
    updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String),
    avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
  );

  Patient copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? pointure,
    int? sexe,
    DateTime? dateNaissance,
    double? taille,
    double? poids,
    String? telephone,
    int? age,
    String? adresse,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
  }) => Patient(
    id: id ?? this.id,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    pointure: pointure ?? this.pointure,
    sexe: sexe ?? this.sexe,
    dateNaissance: dateNaissance ?? this.dateNaissance,
    taille: taille ?? this.taille,
    poids: poids ?? this.poids,
    telephone: telephone ?? this.telephone,
    age: age ?? this.age,
    adresse: adresse ?? this.adresse,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );

  String get formattedDateNaissance => DateFormat('dd/MM/yyyy').format(dateNaissance);
  String get fullName => '$prenom $nom';
  
  String sexeLabel({bool isFrench = true}) {
    if (sexe == 0) return isFrench ? 'Homme' : 'Male';
    if (sexe == 1) return isFrench ? 'Femme' : 'Female';
    return isFrench ? 'Autre' : 'Other';
  }
}

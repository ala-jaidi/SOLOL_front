import 'package:intl/intl.dart';

enum Role { podologue, patient }

abstract class Professionnel {
  final String id;
  final String nom;
  final String email;
  final String organisation;
  final String specialite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Professionnel({
    required this.id,
    required this.nom,
    required this.email,
    required this.organisation,
    required this.specialite,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert to JSON using snake_case keys to match Postgres conventions.
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'organisation': organisation,
    'specialite': specialite,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Downcast helper if needed.
  factory Professionnel.fromJson(Map<String, dynamic> json) => Patient.fromJson(json);
}

class Patient extends Professionnel {
  final String prenom;
  final String pointure;
  final String sexe;
  final DateTime dateNaissance;
  final double taille;
  final double poids;
  final String telephone;
  final int age;
  final String adresse;
  /// URL (ou chemin local) de la photo de profil du patient.
  /// Peut être une URL http(s) retournée par votre backend Django,
  /// ou un chemin local (ex: file:///path/to/image.jpg) si non uploadé.
  final String? avatarUrl;

  Patient({
    required super.id,
    required super.nom,
    required super.email,
    required super.organisation,
    required super.specialite,
    required this.prenom,
    required this.pointure,
    required this.sexe,
    required this.dateNaissance,
    required this.taille,
    required this.poids,
    required this.telephone,
    required this.age,
    required this.adresse,
    required super.createdAt,
    required super.updatedAt,
    this.avatarUrl,
  });

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'prenom': prenom,
    'pointure': pointure,
    'sexe': sexe,
    // Use snake_case for DB columns; API may alias when reading
    'date_naissance': dateNaissance.toIso8601String(),
    'taille': taille,
    'poids': poids,
    'telephone': telephone,
    'age': age,
    'adresse': adresse,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as String,
    nom: json['nom'] as String,
    email: json['email'] as String,
    organisation: json['organisation'] as String,
    specialite: json['specialite'] as String,
    prenom: json['prenom'] as String,
    pointure: json['pointure'] as String,
    sexe: json['sexe'] as String,
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
    String? email,
    String? organisation,
    String? specialite,
    String? prenom,
    String? pointure,
    String? sexe,
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
    email: email ?? this.email,
    organisation: organisation ?? this.organisation,
    specialite: specialite ?? this.specialite,
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
}

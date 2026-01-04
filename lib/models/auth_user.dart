/// Authenticated user model for Supabase auth
class User {
  final String id;
  final String email;
  final String nom;
  final String? prenom;
  final String role;
  final String? organisation;
  final String? specialite;
  final String? telephone;
  final String? sexe;
  final DateTime? dateNaissance;
  final int? age;
  final double? taille;
  final double? poids;
  final String? pointure;
  final String? adresse;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.nom,
    this.prenom,
    required this.role,
    this.organisation,
    this.specialite,
    this.telephone,
    this.sexe,
    this.dateNaissance,
    this.age,
    this.taille,
    this.poids,
    this.pointure,
    this.adresse,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nom': nom,
    if (prenom != null) 'prenom': prenom,
    'role': role,
    if (organisation != null) 'organisation': organisation,
    if (specialite != null) 'specialite': specialite,
    if (telephone != null) 'telephone': telephone,
    if (sexe != null) 'sexe': sexe,
    if (dateNaissance != null) 'date_naissance': dateNaissance!.toIso8601String(),
    if (age != null) 'age': age,
    if (taille != null) 'taille': taille,
    if (poids != null) 'poids': poids,
    if (pointure != null) 'pointure': pointure,
    if (adresse != null) 'adresse': adresse,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    nom: json['nom'] as String,
    prenom: json['prenom'] as String?,
    role: json['role'] as String? ?? 'patient',
    organisation: json['organisation'] as String?,
    specialite: json['specialite'] as String?,
    telephone: json['telephone'] as String?,
    sexe: json['sexe'] as String?,
    dateNaissance: json['date_naissance'] != null 
        ? DateTime.parse(json['date_naissance'] as String)
        : null,
    age: json['age'] as int?,
    taille: json['taille'] != null ? (json['taille'] as num).toDouble() : null,
    poids: json['poids'] != null ? (json['poids'] as num).toDouble() : null,
    pointure: json['pointure'] as String?,
    adresse: json['adresse'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  User copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    String? role,
    String? organisation,
    String? specialite,
    String? telephone,
    String? sexe,
    DateTime? dateNaissance,
    int? age,
    double? taille,
    double? poids,
    String? pointure,
    String? adresse,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    role: role ?? this.role,
    organisation: organisation ?? this.organisation,
    specialite: specialite ?? this.specialite,
    telephone: telephone ?? this.telephone,
    sexe: sexe ?? this.sexe,
    dateNaissance: dateNaissance ?? this.dateNaissance,
    age: age ?? this.age,
    taille: taille ?? this.taille,
    poids: poids ?? this.poids,
    pointure: pointure ?? this.pointure,
    adresse: adresse ?? this.adresse,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  String get fullName => prenom != null ? '$prenom $nom' : nom;
}

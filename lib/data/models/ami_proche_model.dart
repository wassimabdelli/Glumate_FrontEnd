class AmiProcheModel {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String code;
  final bool lie;

  AmiProcheModel({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.code,
    required this.lie,
  });

  factory AmiProcheModel.fromJson(Map<String, dynamic> json) {
    return AmiProcheModel(
      id: json['id'] as int?,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String?,
      code: json['code'] as String? ?? '',
      lie: json['lie'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'code': code,
      'lie': lie,
    };
  }

  String get fullName => '$prenom $nom';
}

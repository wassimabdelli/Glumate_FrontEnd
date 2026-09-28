class UserModel {
  final int? id;
  final String email;
  final String firstname;
  final String lastname;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? weight;
  final double? height;
  final double? cibleGlycemiqueMin;
  final double? cibleGlycemiqueMax;
  final String? contactUrgenceNom;
  final String? contactUrgenceTel;
  final String? typeDiabete;
  final String? traitementsActuels;
  final String? regimeInsuline;
  final bool? insuffisanceRenale;
  final double? dfg;
  final bool? maladieCardiovasculaire;
  final bool? grossesse;

  UserModel({
    this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.weight,
    this.height,
    this.cibleGlycemiqueMin,
    this.cibleGlycemiqueMax,
    this.contactUrgenceNom,
    this.contactUrgenceTel,
    this.typeDiabete,
    this.traitementsActuels,
    this.regimeInsuline,
    this.insuffisanceRenale,
    this.dfg,
    this.maladieCardiovasculaire,
    this.grossesse,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int?,
      email: json['email'] as String? ?? '',
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      phone: json['phone'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'] as String)
          : null,
      gender: json['gender'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      cibleGlycemiqueMin:
          (json['cibleGlycemiqueMin'] as num?)?.toDouble(),
      cibleGlycemiqueMax:
          (json['cibleGlycemiqueMax'] as num?)?.toDouble(),
      contactUrgenceNom: json['contactUrgenceNom'] as String?,
      contactUrgenceTel: json['contactUrgenceTel'] as String?,
      typeDiabete: json['typeDiabete'] as String?,
      traitementsActuels: json['traitementsActuels'] as String?,
      regimeInsuline: json['regimeInsuline'] as String?,
      insuffisanceRenale: json['insuffisanceRenale'] as bool?,
      dfg: (json['dfg'] as num?)?.toDouble(),
      maladieCardiovasculaire: json['maladieCardiovasculaire'] as bool?,
      grossesse: json['grossesse'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstname': firstname,
      'lastname': lastname,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'height': height,
      'cibleGlycemiqueMin': cibleGlycemiqueMin,
      'cibleGlycemiqueMax': cibleGlycemiqueMax,
      'contactUrgenceNom': contactUrgenceNom,
      'contactUrgenceTel': contactUrgenceTel,
      'typeDiabete': typeDiabete,
      'traitementsActuels': traitementsActuels,
      'regimeInsuline': regimeInsuline,
      'insuffisanceRenale': insuffisanceRenale,
      'dfg': dfg,
      'maladieCardiovasculaire': maladieCardiovasculaire,
      'grossesse': grossesse,
    };
  }

  String get fullName => '$firstname $lastname';
}

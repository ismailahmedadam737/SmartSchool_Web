class TeacherModel {
  final int? id;
  final String name;
  final String district;
  final String phone;
  final String level;
  final String experience;

  TeacherModel({
    this.id,
    required this.name,
    required this.district,
    required this.phone,
    required this.level,
    required this.experience,
  });

  // Ka bedel JSON una bedel Object
  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      // Hubi in 'id' uu yahay int ama u bedel int.tryParse haddii uu string yahay
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      name: json['name'] ?? '',
      district: json['district'] ?? '',
      phone: json['phone'] ?? '',
      level: json['level'] ?? '',
      experience: json['experience'] ?? '',
    );
  }

  // Ka bedel Object una bedel JSON (si loogu diro API)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "name": name,
      "district": district,
      "phone": phone,
      "level": level,
      "experience": experience,
    };
    
    // Haddii uu ID jiro (Update) ku dar JSON-ka
    if (id != null) {
      data['id'] = id;
    }
    
    return data;
  }
}
import 'dart:convert';

class StudentModel {
  final int? id;
  final String name;
  final String phone;
  final String district;
  final String neighbor;
  final String className;

  StudentModel({
    this.id,
    required this.name,
    required this.phone,
    required this.district,
    required this.neighbor,
    required this.className, required String fullName,
  });

  // Mapper: Model -> JSON
  Map<String, dynamic> toJson() => {
        "id": id, // Waxaan ku darnay ID-ga si uu u raaco haddii loo baahdo
        "name": name,
        "phone": phone,
        "district": district,
        "neighbor": neighbor,
        "class_name": className,
      };

  // Mapper: JSON -> Model
  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        district: json['district'] ?? '',
        neighbor: json['neighbor'] ?? '',
        className: json['class_name'] ?? '', fullName: '',
      );
}
class StudentModel {
  final int? id;
  final String? stringId;
  final String name;
  final String phone;
  final String district;
  final String neighbor;
  final String className;

  StudentModel({
    this.id,
    this.stringId,
    required this.name,
    required this.phone,
    required this.district,
    required this.neighbor,
    required this.className,
    required String fullName,
  });

  String get idString => stringId ?? id?.toString() ?? '';

  // Mapper: Model -> JSON
  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (stringId != null && stringId!.isNotEmpty) "_id": stringId,
        "name": name,
        "full_name": name,
        "phone": phone,
        "district": district,
        "neighbor": neighbor,
        "class_name": className,
        "class": className,
      };

  // Mapper: JSON -> Model
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    var rawId = json['id'] ?? json['_id'] ?? json['student_id'] ?? json['studentId'] ?? json['ID'];
    int? parsedIntId;
    String? rawIdStr;
    if (rawId != null) {
      rawIdStr = rawId.toString();
      if (rawId is int) {
        parsedIntId = rawId;
      } else {
        parsedIntId = int.tryParse(rawIdStr);
      }
    }
    return StudentModel(
      id: parsedIntId,
      stringId: rawIdStr,
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? json['fullName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['phone_number']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      neighbor: json['neighbor']?.toString() ?? '',
      className: json['class_name']?.toString() ?? json['class']?.toString() ?? json['className']?.toString() ?? '',
      fullName: '',
    );
  }
}
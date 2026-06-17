class AttendanceModel {
  final String name;
  final bool isPresent;

  AttendanceModel({required this.name, required this.isPresent});

  Map<String, dynamic> toJson() => {
    'name': name,
    'isPresent': isPresent,
  };
}
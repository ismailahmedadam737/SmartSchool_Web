class Bus {
  final int? id;
  final String name;
  final String phone;
  final String plate;
  final String route;

  Bus({this.id, required this.name, required this.phone, required this.plate, required this.route});

  // U bedel xogta ka timaada Database-ka (JSON) una bedel Object
  factory Bus.fromJson(Map<String, dynamic> json) {
    var rawId = json['id'] ?? json['_id'];
    int? parsedId;
    if (rawId != null) {
      if (rawId is int) {
        parsedId = rawId;
      } else {
        parsedId = int.tryParse(rawId.toString());
      }
    }
    return Bus(
      id: parsedId,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      plate: json['plate']?.toString() ?? '',
      route: json['route']?.toString() ?? '',
    );
  }

  // U bedel Object-ga una bedel JSON si loogu diro Database-ka
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone": phone,
      "plate": plate,
      "route": route,
    };
  }
}
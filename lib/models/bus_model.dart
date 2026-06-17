class Bus {
  final int? id;
  final String name;
  final String phone;
  final String plate;
  final String route;

  Bus({this.id, required this.name, required this.phone, required this.plate, required this.route});

  // U bedel xogta ka timaada Database-ka (JSON) una bedel Object
  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      plate: json['plate'],
      route: json['route'],
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
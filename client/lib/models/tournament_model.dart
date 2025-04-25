class Tournament {
  final String id;
  final String name;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String category; // WTA1000, WTA500, etc.
  final String surface; // Clay, Hard, Grass
  final String countryCode;
  final String logoUrl;

  Tournament({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.surface,
    required this.countryCode,
    this.logoUrl = '',
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      category: json['category'] ?? '',
      surface: json['surface'] ?? '',
      countryCode: json['countryCode'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'category': category,
      'surface': surface,
      'countryCode': countryCode,
      'logoUrl': logoUrl,
    };
  }

  @override
  String toString() {
    return 'Tournament(id: $id, name: $name, startDate: $startDate, endDate: $endDate)';
  }
} 
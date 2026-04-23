class Vehicle {
  final String id;
  final String userId;
  final String make;
  final String model;
  final String year;
  final String plateNumber;
  final bool isPrimary;
  final String? type; // e.g., 'SUV', 'Sedan'

  Vehicle({
    required this.id,
    required this.userId,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    this.isPrimary = false,
    this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'isPrimary': isPrimary,
      'type': type,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String documentId) {
    return Vehicle(
      id: documentId,
      userId: map['userId'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      type: map['type'],
    );
  }

  Vehicle copyWith({
    String? id,
    String? userId,
    String? make,
    String? model,
    String? year,
    String? plateNumber,
    bool? isPrimary,
    String? type,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      plateNumber: plateNumber ?? this.plateNumber,
      isPrimary: isPrimary ?? this.isPrimary,
      type: type ?? this.type,
    );
  }
}

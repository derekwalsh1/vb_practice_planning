import 'package:uuid/uuid.dart';

class PlanGroup {
  final String id;
  String name;
  String? description;
  String color; // Hex color for visual organization
  DateTime createdDate;

  PlanGroup({
    String? id,
    required this.name,
    this.description,
    this.color = 'FF9800', // Default orange
    DateTime? createdDate,
  })  : id = id ?? const Uuid().v4(),
        createdDate = createdDate ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON
  factory PlanGroup.fromJson(Map<String, dynamic> json) {
    return PlanGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      color: json['color'] as String? ?? 'FF9800',
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'created_date': createdDate.toIso8601String(),
    };
  }

  // Create from database map
  factory PlanGroup.fromMap(Map<String, dynamic> map) {
    return PlanGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      color: map['color'] as String? ?? 'FF9800',
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }

  // Copy with
  PlanGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    DateTime? createdDate,
  }) {
    return PlanGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

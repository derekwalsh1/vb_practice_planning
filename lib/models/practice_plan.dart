import 'package:uuid/uuid.dart';
import 'activity.dart';

class PracticePlan {
  final String id;
  String name;
  List<Activity> activities;
  String notes;
  String? groupId;
  DateTime createdDate;
  DateTime? lastModifiedDate;
  DateTime? lastUsedDate;

  PracticePlan({
    String? id,
    required this.name,
    List<Activity>? activities,
    this.notes = '',
    this.groupId,
    DateTime? createdDate,
    this.lastModifiedDate,
    this.lastUsedDate,
  })  : id = id ?? const Uuid().v4(),
        activities = activities ?? [],
        createdDate = createdDate ?? DateTime.now();

  // Get total duration in minutes
  int get totalDuration {
    return activities.fold(0, (sum, activity) => sum + activity.durationMinutes);
  }

  // Get formatted duration string
  String get formattedDuration {
    final hours = totalDuration ~/ 60;
    final minutes = totalDuration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Create a copy of the practice plan
  PracticePlan copyWith({
    String? id,
    String? name,
    List<Activity>? activities,
    String? notes,
    String? groupId,
    DateTime? createdDate,
    DateTime? lastModifiedDate,
    DateTime? lastUsedDate,
  }) {
    return PracticePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      activities: activities ?? this.activities.map((a) => a.copyWith()).toList(),
      notes: notes ?? this.notes,
      groupId: groupId ?? this.groupId,
      createdDate: createdDate ?? this.createdDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
    );
  }

  // Clone the practice plan with a new ID
  PracticePlan clone({String? newName}) {
    return PracticePlan(
      id: const Uuid().v4(),
      name: newName ?? '$name (Copy)',
      activities: activities.map((a) => a.copyWith()).toList(),
      notes: notes,
      groupId: groupId,
      createdDate: DateTime.now(),
    );
  }

  // Convert to JSON (for database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'activities': activities.map((a) => a.toJson()).toList(),
      'groupId': groupId,
      'createdDate': createdDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'lastUsedDate': lastUsedDate?.toIso8601String(),
    };
  }

  // Convert to JSON with embedded images for export
  Future<Map<String, dynamic>> toJsonWithImages() async {
    final activitiesJson = <Map<String, dynamic>>[];
    for (final activity in activities) {
      activitiesJson.add(await activity.toJsonWithImage());
    }
    
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'activities': activitiesJson,
      'groupId': groupId,
      'createdDate': createdDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate?.toIso8601String(),
      'lastUsedDate': lastUsedDate?.toIso8601String(),
    };
  }

  // Create from JSON (handles embedded images)
  static Future<PracticePlan> fromJsonAsync(Map<String, dynamic> json) async {
    final activitiesList = json['activities'] as List;
    final activities = <Activity>[];
    
    // Process each activity and handle embedded images
    for (final activityJson in activitiesList) {
      final activity = await Activity.fromJsonAsync(activityJson as Map<String, dynamic>);
      activities.add(activity);
    }
    
    return PracticePlan(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String? ?? '',
      activities: activities,
      groupId: json['groupId'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.parse(json['lastModifiedDate'] as String)
          : null,
      lastUsedDate: json['lastUsedDate'] != null
          ? DateTime.parse(json['lastUsedDate'] as String)
          : null,
    );
  }

  // Create from JSON (sync version for backwards compatibility)
  factory PracticePlan.fromJson(Map<String, dynamic> json) {
    return PracticePlan(
      id: json['id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String? ?? '',
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      groupId: json['groupId'] as String?,
      createdDate: DateTime.parse(json['createdDate'] as String),
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.parse(json['lastModifiedDate'] as String)
          : null,
      lastUsedDate: json['lastUsedDate'] != null
          ? DateTime.parse(json['lastUsedDate'] as String)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'group_id': groupId,
      'created_date': createdDate.toIso8601String(),
      'last_modified_date': lastModifiedDate?.toIso8601String(),
      'last_used_date': lastUsedDate?.toIso8601String(),
    };
  }

  // Create from database map
  factory PracticePlan.fromMap(Map<String, dynamic> map) {
    return PracticePlan(
      id: map['id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String? ?? '',
      groupId: map['group_id'] as String?,
      createdDate: DateTime.parse(map['created_date'] as String),
      lastModifiedDate: map['last_modified_date'] != null
          ? DateTime.parse(map['last_modified_date'] as String)
          : null,
      lastUsedDate: map['last_used_date'] != null
          ? DateTime.parse(map['last_used_date'] as String)
          : null,
    );
  }
}

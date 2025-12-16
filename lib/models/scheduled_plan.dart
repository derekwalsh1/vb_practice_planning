import 'package:uuid/uuid.dart';

class ScheduledPlan {
  final String id;
  final String practicePlanId;
  DateTime scheduledDate;
  bool completed;
  DateTime? completedDate;
  String notes;

  ScheduledPlan({
    String? id,
    required this.practicePlanId,
    required this.scheduledDate,
    this.completed = false,
    this.completedDate,
    this.notes = '',
  }) : id = id ?? const Uuid().v4();

  // Mark as completed
  void markCompleted() {
    completed = true;
    completedDate = DateTime.now();
  }

  // Mark as incomplete
  void markIncomplete() {
    completed = false;
    completedDate = null;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'practicePlanId': practicePlanId,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completed': completed,
      'completedDate': completedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from JSON
  factory ScheduledPlan.fromJson(Map<String, dynamic> json) {
    return ScheduledPlan(
      id: json['id'] as String,
      practicePlanId: json['practicePlanId'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completed: json['completed'] as bool? ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'practice_plan_id': practicePlanId,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed': completed ? 1 : 0,
      'completed_date': completedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from database map
  factory ScheduledPlan.fromMap(Map<String, dynamic> map) {
    return ScheduledPlan(
      id: map['id'] as String,
      practicePlanId: map['practice_plan_id'] as String,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String),
      completed: map['completed'] == 1,
      completedDate: map['completed_date'] != null
          ? DateTime.parse(map['completed_date'] as String)
          : null,
      notes: map['notes'] as String? ?? '',
    );
  }

  // Create a copy
  ScheduledPlan copyWith({
    String? id,
    String? practicePlanId,
    DateTime? scheduledDate,
    bool? completed,
    DateTime? completedDate,
    String? notes,
  }) {
    return ScheduledPlan(
      id: id ?? this.id,
      practicePlanId: practicePlanId ?? this.practicePlanId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completed: completed ?? this.completed,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
    );
  }
}

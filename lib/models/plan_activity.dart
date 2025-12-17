import 'activity.dart';

/// A wrapper for an activity in a practice plan that allows for a custom duration
class PlanActivity {
  final Activity activity;
  final int customDurationMinutes;

  PlanActivity({
    required this.activity,
    int? customDurationMinutes,
  }) : customDurationMinutes = customDurationMinutes ?? activity.durationMinutes;

  /// Get the duration to use for this activity in the plan
  int get effectiveDuration => customDurationMinutes;

  /// Check if this activity has a custom duration different from the default
  bool get hasCustomDuration => customDurationMinutes != activity.durationMinutes;

  PlanActivity copyWith({
    Activity? activity,
    int? customDurationMinutes,
  }) {
    return PlanActivity(
      activity: activity ?? this.activity,
      customDurationMinutes: customDurationMinutes ?? this.customDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity.toJson(),
      'customDurationMinutes': customDurationMinutes,
    };
  }

  factory PlanActivity.fromJson(Map<String, dynamic> json) {
    return PlanActivity(
      activity: Activity.fromJson(json['activity'] as Map<String, dynamic>),
      customDurationMinutes: json['customDurationMinutes'] as int?,
    );
  }
}

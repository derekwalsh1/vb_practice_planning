import 'package:uuid/uuid.dart';
import 'diagram.dart';

class Activity {
  final String id;
  String name;
  int durationMinutes;
  String description;
  String coachingTips;
  String focus;
  List<String> tags;
  Diagram? diagram;
  DateTime createdDate;
  DateTime? lastUsedDate;

  Activity({
    String? id,
    required this.name,
    required this.durationMinutes,
    required this.description,
    required this.coachingTips,
    this.focus = '',
    List<String>? tags,
    this.diagram,
    DateTime? createdDate,
    this.lastUsedDate,
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [],
        createdDate = createdDate ?? DateTime.now();

  // Create a copy of the activity
  Activity copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    String? description,
    String? coachingTips,
    String? focus,
    List<String>? tags,
    Diagram? diagram,
    DateTime? createdDate,
    DateTime? lastUsedDate,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      coachingTips: coachingTips ?? this.coachingTips,
      focus: focus ?? this.focus,
      tags: tags ?? List<String>.from(this.tags),
      diagram: diagram ?? this.diagram,
      createdDate: createdDate ?? this.createdDate,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'description': description,
      'coachingTips': coachingTips,
      'focus': focus,
      if (lastUsedDate != null) 'lastUsedDate': lastUsedDate!.toIso8601String(),
      'tags': tags,
      if (diagram != null) 'diagram': diagram!.toJson(),
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      durationMinutes: json['durationMinutes'] as int,
      description: json['description'] as String,
      coachingTips: json['coachingTips'] as String,
      focus: json['focus'] as String? ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      diagram: json['diagram'] != null 
          ? Diagram.fromJson(json['diagram'] as Map<String, dynamic>)
          : null,
      lastUsedDate: json['lastUsedDate'] != null 
          ? DateTime.parse(json['lastUsedDate'] as String) 
          : null,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'duration_minutes': durationMinutes,
      'last_used_date': lastUsedDate?.toIso8601String(),
      'description': description,
      'coaching_tips': coachingTips,
      'focus': focus,
      'tags': tags.join(','),
      'diagram': diagram != null ? jsonEncode(diagram!.toJson()) : null,
      'created_date': createdDate.toIso8601String(),
    };
  }

  // Create from database map
  factory Activity.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String?;
    final diagramString = map['diagram'] as String?;
    
    Diagram? diagram;
    if (diagramString != null && diagramString.isNotEmpty) {
      try {
        final diagramJson = jsonDecode(diagramString) as Map<String, dynamic>;
        diagram = Diagram.fromJson(diagramJson);
      } catch (e) {
        print('Error parsing diagram: $e');
      }
    }
    
    return Activity(
      id: map['id'] as String,
      name: map['name'] as String,
      lastUsedDate: map['last_used_date'] != null 
          ? DateTime.parse(map['last_used_date'] as String) 
          : null,
      durationMinutes: map['duration_minutes'] as int,
      description: map['description'] as String,
      coachingTips: map['coaching_tips'] as String,
      focus: map['focus'] as String? ?? '',
      tags: tagsString != null && tagsString.isNotEmpty ? tagsString.split(',') : [],
      diagram: diagram,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}

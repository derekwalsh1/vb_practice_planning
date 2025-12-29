import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class Activity {
  final String id;
  String name;
  int durationMinutes;
  String description;
  String coachingTips;
  String focus;
  List<String> tags;
  String? imagePath;
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
    this.imagePath,
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
    String? imagePath,
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
      imagePath: imagePath ?? this.imagePath,
      createdDate: createdDate ?? this.createdDate,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
    );
  }

  // Convert to JSON (for database - keeps imagePath as is)
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
      if (imagePath != null) 'imagePath': imagePath,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Convert to JSON with base64 image for export/sharing
  Future<Map<String, dynamic>> toJsonWithImage() async {
    String? imageData;
    if (imagePath != null) {
      try {
        final file = File(imagePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          imageData = base64Encode(bytes);
        }
      } catch (e) {
        print('Error encoding image: $e');
      }
    }
    
    return {
      'id': id,
      'name': name,
      'durationMinutes': durationMinutes,
      'description': description,
      'coachingTips': coachingTips,
      'focus': focus,
      if (lastUsedDate != null) 'lastUsedDate': lastUsedDate!.toIso8601String(),
      'tags': tags,
      if (imageData != null) 'imageData': imageData,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  // Create from JSON (handles both imagePath and base64 imageData)
  static Future<Activity> fromJsonAsync(Map<String, dynamic> json) async {
    String? imagePath;
    
    // If JSON contains base64 image data, save it as a file
    if (json['imageData'] != null) {
      try {
        final imageBytes = base64Decode(json['imageData'] as String);
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'activity_${json['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(imageBytes);
        imagePath = file.path;
      } catch (e) {
        print('Error decoding image: $e');
      }
    } else if (json['imagePath'] != null) {
      imagePath = json['imagePath'] as String;
    }
    
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      durationMinutes: json['durationMinutes'] as int,
      description: json['description'] as String,
      coachingTips: json['coachingTips'] as String,
      focus: json['focus'] as String? ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      imagePath: imagePath,
      lastUsedDate: json['lastUsedDate'] != null 
          ? DateTime.parse(json['lastUsedDate'] as String) 
          : null,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  // Create from JSON (sync version for backwards compatibility)
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      name: json['name'] as String,
      durationMinutes: json['durationMinutes'] as int,
      description: json['description'] as String,
      coachingTips: json['coachingTips'] as String,
      focus: json['focus'] as String? ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      imagePath: json['imagePath'] as String?,
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
      'diagram': imagePath,
      'created_date': createdDate.toIso8601String(),
    };
  }

  // Create from database map
  factory Activity.fromMap(Map<String, dynamic> map) {
    final tagsString = map['tags'] as String?;
    
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
      imagePath: map['diagram'] as String?,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}

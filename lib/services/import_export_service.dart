import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/practice_plan.dart';
import '../models/activity.dart';

class ImportExportService {
  // Export a practice plan to JSON (with embedded images)
  Future<String> exportPlanToJson(PracticePlan plan) async {
    final json = jsonEncode(await plan.toJsonWithImages());
    return json;
  }

  // Export multiple plans to JSON (with embedded images)
  Future<String> exportPlansToJson(List<PracticePlan> plans) async {
    final plansJson = <Map<String, dynamic>>[];
    for (final plan in plans) {
      plansJson.add(await plan.toJsonWithImages());
    }
    
    final json = jsonEncode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'plans': plansJson,
    });
    return json;
  }

  // Export activities to JSON (with embedded images)
  Future<String> exportActivitiesToJson(List<Activity> activities) async {
    final activitiesJson = <Map<String, dynamic>>[];
    for (final activity in activities) {
      activitiesJson.add(await activity.toJsonWithImage());
    }
    
    final json = jsonEncode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'activities': activitiesJson,
    });
    return json;
  }

  // Save and share a practice plan
  Future<void> sharePlan(PracticePlan plan, {Rect? sharePositionOrigin}) async {
    try {
      final json = await exportPlanToJson(plan);
      final directory = await getTemporaryDirectory();
      final fileName = '${plan.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(json);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Practice Plan: ${plan.name}',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      print('Error sharing plan: $e');
      rethrow;
    }
  }

  // Save and share multiple plans
  Future<void> sharePlans(List<PracticePlan> plans, {Rect? sharePositionOrigin}) async {
    try {
      final json = await exportPlansToJson(plans);
      final directory = await getTemporaryDirectory();
      final fileName = 'practice_plans_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(json);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Practice Plans Export',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      print('Error sharing plans: $e');
      rethrow;
    }
  }

  // Save and share activities
  Future<void> shareActivities(List<Activity> activities, {Rect? sharePositionOrigin}) async {
    try {
      final json = await exportActivitiesToJson(activities);
      final directory = await getTemporaryDirectory();
      final fileName = 'activities_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(json);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Activities Export',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      print('Error sharing activities: $e');
      rethrow;
    }
  }

  // Import a practice plan from JSON file (with embedded images)
  Future<PracticePlan?> importPlanFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      return await PracticePlan.fromJsonAsync(json);
    } catch (e) {
      print('Error importing plan: $e');
      rethrow;
    }
  }

  // Import multiple plans from JSON file (with embedded images)
  Future<List<PracticePlan>> importPlansFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return [];

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      // Check if it's a single plan or multiple plans
      if (json['plans'] != null) {
        final plansList = json['plans'] as List;
        final plans = <PracticePlan>[];
        
        for (final planJson in plansList) {
          final plan = await PracticePlan.fromJsonAsync(planJson as Map<String, dynamic>);
          plans.add(plan);
        }
        
        return plans;
      } else {
        // Single plan
        return [await PracticePlan.fromJsonAsync(json)];
      }
    } catch (e) {
      print('Error importing plans: $e');
      rethrow;
    }
  }

  // Import activities from JSON file (with embedded images)
  Future<List<Activity>> importActivitiesFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return [];

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString);

      if (json['activities'] != null) {
        final activitiesList = json['activities'] as List;
        final activities = <Activity>[];
        
        // Process each activity and handle embedded images
        for (final activityJson in activitiesList) {
          final activity = await Activity.fromJsonAsync(activityJson as Map<String, dynamic>);
          activities.add(activity);
        }
        
        return activities;
      }

      return [];
    } catch (e) {
      print('Error importing activities: $e');
      rethrow;
    }
  }
}

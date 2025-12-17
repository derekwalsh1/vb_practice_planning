import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/practice_plan.dart';
import '../models/activity.dart';

class ImportExportService {
  // Export a practice plan to JSON
  Future<String> exportPlanToJson(PracticePlan plan) async {
    final json = jsonEncode(plan.toJson());
    return json;
  }

  // Export multiple plans to JSON
  Future<String> exportPlansToJson(List<PracticePlan> plans) async {
    final json = jsonEncode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'plans': plans.map((p) => p.toJson()).toList(),
    });
    return json;
  }

  // Export activities to JSON
  Future<String> exportActivitiesToJson(List<Activity> activities) async {
    final json = jsonEncode({
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'activities': activities.map((a) => a.toJson()).toList(),
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

  // Save and share multiple plans, {Rect? sharePositionOrigin}) async {
    try {
      final json = await exportPlansToJson(plans);
      final directory = await getTemporaryDirectory();
      final fileName = 'practice_plans_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(json);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Practice Plans Export',
        sharePositionOrigin: sharePositionOrigin
        subject: 'Practice Plans Export',
      );
    } catch (e) {
      print('Error sharing plans: $e');
      rethrow;
    }
  }

  // Save and share activities, {Rect? sharePositionOrigin}) async {
    try {
      final json = await exportActivitiesToJson(activities);
      final directory = await getTemporaryDirectory();
      final fileName = 'activities_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(json);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Activities Export',
        sharePositionOrigin: sharePositionOrigin
        subject: 'Activities Export',
      );
    } catch (e) {
      print('Error sharing activities: $e');
      rethrow;
    }
  }

  // Import a practice plan from JSON file
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

      return PracticePlan.fromJson(json);
    } catch (e) {
      print('Error importing plan: $e');
      rethrow;
    }
  }

  // Import multiple plans from JSON file
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
        return plansList.map((p) => PracticePlan.fromJson(p)).toList();
      } else {
        // Single plan
        return [PracticePlan.fromJson(json)];
      }
    } catch (e) {
      print('Error importing plans: $e');
      rethrow;
    }
  }

  // Import activities from JSON file
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
        return activitiesList.map((a) => Activity.fromJson(a)).toList();
      }

      return [];
    } catch (e) {
      print('Error importing activities: $e');
      rethrow;
    }
  }
}

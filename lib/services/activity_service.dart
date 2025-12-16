import 'package:flutter/foundation.dart';
import '../models/activity.dart';
import 'database_service.dart';

class ActivityService extends ChangeNotifier {
  final DatabaseService _db;
  List<Activity> _activities = [];
  List<Activity> _recentActivities = [];
  bool _isLoading = false;

  ActivityService(this._db) {
    loadActivities();
    loadRecentActivities();
  }

  List<Activity> get activities => _activities;
  List<Activity> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;

  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _activities = await _db.getActivities();
    } catch (e) {
      print('Error loading activities: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentActivities() async {
    try {
      _recentActivities = await _db.getRecentlyUsedActivities(limit: 5);
      notifyListeners();
    } catch (e) {
      print('Error loading recent activities: $e');
    }
  }

  Future<void> addActivity(Activity activity) async {
    try {
      await _db.insertActivity(activity);
      await loadActivities();
      await loadRecentActivities();
    } catch (e) {
      print('Error adding activity: $e');
      rethrow;
    }
  }

  Future<void> updateActivity(Activity activity) async {
    try {
      await _db.updateActivity(activity);
      await loadActivities();
      await loadRecentActivities();
    } catch (e) {
      print('Error updating activity: $e');
      rethrow;
    }
  }

  Future<void> markActivityAsUsed(String id) async {
    try {
      final activity = await _db.getActivity(id);
      if (activity != null) {
        activity.lastUsedDate = DateTime.now();
        await _db.updateActivity(activity);
        await loadRecentActivities();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking activity as used: $e');
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _db.deleteActivity(id);
      await loadActivities();
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }

  Future<Activity?> getActivity(String id) async {
    return await _db.getActivity(id);
  }

  List<Activity> getActivitiesByTag(String tag) {
    return _activities.where((a) => a.tags.contains(tag)).toList();
  }
}

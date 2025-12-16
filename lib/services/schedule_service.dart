import 'package:flutter/foundation.dart';
import '../models/scheduled_plan.dart';
import 'database_service.dart';

class ScheduleService extends ChangeNotifier {
  final DatabaseService _db;
  List<ScheduledPlan> _scheduledPlans = [];
  bool _isLoading = false;

  ScheduleService(this._db) {
    loadScheduledPlans();
  }

  List<ScheduledPlan> get scheduledPlans => _scheduledPlans;
  bool get isLoading => _isLoading;

  Future<void> loadScheduledPlans() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _scheduledPlans = await _db.getScheduledPlans();
    } catch (e) {
      print('Error loading scheduled plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> schedulePlan(ScheduledPlan scheduledPlan) async {
    try {
      await _db.insertScheduledPlan(scheduledPlan);
      await loadScheduledPlans();
    } catch (e) {
      print('Error scheduling plan: $e');
      rethrow;
    }
  }

  Future<void> updateScheduledPlan(ScheduledPlan scheduledPlan) async {
    try {
      await _db.updateScheduledPlan(scheduledPlan);
      await loadScheduledPlans();
    } catch (e) {
      print('Error updating scheduled plan: $e');
      rethrow;
    }
  }

  Future<void> deleteScheduledPlan(String id) async {
    try {
      await _db.deleteScheduledPlan(id);
      await loadScheduledPlans();
    } catch (e) {
      print('Error deleting scheduled plan: $e');
      rethrow;
    }
  }

  Future<void> markPlanCompleted(String id, bool completed) async {
    try {
      final scheduledPlan = await _db.getScheduledPlan(id);
      if (scheduledPlan != null) {
        if (completed) {
          scheduledPlan.markCompleted();
        } else {
          scheduledPlan.markIncomplete();
        }
        await _db.updateScheduledPlan(scheduledPlan);
        await loadScheduledPlans();
      }
    } catch (e) {
      print('Error marking plan completed: $e');
      rethrow;
    }
  }

  List<ScheduledPlan> getPlansForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _scheduledPlans.where((sp) {
      return sp.scheduledDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             sp.scheduledDate.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<ScheduledPlan> getUpcomingPlans({int days = 7}) {
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    
    return _scheduledPlans.where((sp) {
      return sp.scheduledDate.isAfter(now) && sp.scheduledDate.isBefore(future);
    }).toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  }
}

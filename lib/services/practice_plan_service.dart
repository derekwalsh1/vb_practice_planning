import 'package:flutter/foundation.dart';
import '../models/practice_plan.dart';
import 'database_service.dart';

class PracticePlanService extends ChangeNotifier {
  final DatabaseService _db;
  List<PracticePlan> _plans = [];
  List<PracticePlan> _recentPlans = [];
  bool _isLoading = false;

  PracticePlanService(this._db) {
    loadPlans();
    loadRecentPlans();
  }

  List<PracticePlan> get plans => _plans;
  List<PracticePlan> get recentPlans => _recentPlans;
  bool get isLoading => _isLoading;

  Future<void> loadPlans({String? groupId}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _plans = await _db.getPracticePlans(groupId: groupId);
    } catch (e) {
      print('Error loading practice plans: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentPlans() async {
    try {
      _recentPlans = await _db.getRecentlyUsedPlans(limit: 5);
      notifyListeners();
    } catch (e) {
      print('Error loading recent plans: $e');
    }
  }

  List<PracticePlan> getPlansForGroup(String? groupId) {
    if (groupId == null) {
      return _plans.where((p) => p.groupId == null).toList();
    }
    return _plans.where((p) => p.groupId == groupId).toList();
  }

  Future<void> addPlan(PracticePlan plan) async {
    try {
      await _db.insertPracticePlan(plan);
      await loadPlans();
      await loadRecentPlans();
    } catch (e) {
      print('Error adding practice plan: $e');
      rethrow;
    }
  }

  Future<void> updatePlan(PracticePlan plan) async {
    try {
      plan.lastModifiedDate = DateTime.now();
      await _db.updatePracticePlan(plan);
      await loadPlans();
      await loadRecentPlans();
    } catch (e) {
      print('Error updating practice plan: $e');
      rethrow;
    }
  }

  Future<void> markPlanAsUsed(String id) async {
    try {
      final plan = await _db.getPracticePlan(id);
      if (plan != null) {
        plan.lastUsedDate = DateTime.now();
        await _db.updatePracticePlan(plan);
        await loadRecentPlans();
        notifyListeners();
      }
    } catch (e) {
      print('Error marking plan as used: $e');
    }
  }

  Future<void> deletePlan(String id) async {
    try {
      await _db.deletePracticePlan(id);
      await loadPlans();
    } catch (e) {
      print('Error deleting practice plan: $e');
      rethrow;
    }
  }

  Future<PracticePlan?> getPlan(String id) async {
    return await _db.getPracticePlan(id);
  }

  Future<void> clonePlan(String id, {String? newName}) async {
    try {
      final originalPlan = await _db.getPracticePlan(id);
      if (originalPlan != null) {
        final clonedPlan = originalPlan.clone(newName: newName);
        await _db.insertPracticePlan(clonedPlan);
        await loadPlans();
      }
    } catch (e) {
      print('Error cloning practice plan: $e');
      rethrow;
    }
  }
}

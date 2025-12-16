import 'package:flutter/foundation.dart';
import '../models/plan_group.dart';
import 'database_service.dart';

class PlanGroupService extends ChangeNotifier {
  final DatabaseService _db;
  List<PlanGroup> _groups = [];
  bool _isLoading = false;

  PlanGroupService(this._db) {
    loadGroups();
  }

  List<PlanGroup> get groups => _groups;
  bool get isLoading => _isLoading;

  Future<void> loadGroups() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _groups = await _db.getPlanGroups();
    } catch (e) {
      print('Error loading plan groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGroup(PlanGroup group) async {
    try {
      await _db.insertPlanGroup(group);
      await loadGroups();
    } catch (e) {
      print('Error adding plan group: $e');
      rethrow;
    }
  }

  Future<void> updateGroup(PlanGroup group) async {
    try {
      await _db.updatePlanGroup(group);
      await loadGroups();
    } catch (e) {
      print('Error updating plan group: $e');
      rethrow;
    }
  }

  Future<void> deleteGroup(String id) async {
    try {
      await _db.deletePlanGroup(id);
      await loadGroups();
    } catch (e) {
      print('Error deleting plan group: $e');
      rethrow;
    }
  }

  Future<PlanGroup?> getGroup(String id) async {
    return await _db.getPlanGroup(id);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';
import '../services/practice_plan_service.dart';
import '../services/import_export_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Import & Export',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Plans'),
                  subtitle: const Text('Import practice plans from file'),
                  onTap: () => _importPlans(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export All Plans'),
                  subtitle: const Text('Share all your practice plans'),
                  onTap: () => _exportAllPlans(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_upload),
                  title: const Text('Import Activities'),
                  subtitle: const Text('Import activities from file'),
                  onTap: () => _importActivities(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export All Activities'),
                  subtitle: const Text('Share all your activities'),
                  onTap: () => _exportAllActivities(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sports_volleyball),
                  title: const Text('VB Practice Plan'),
                  subtitle: const Text('A volleyball coaching app'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'VB Practice Plan',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.sports_volleyball,
                        size: 48,
                        color: Colors.orange,
                      ),
                      children: [
                        const Text(
                          'A comprehensive app for volleyball coaches to create, '
                          'manage, and execute practice plans.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _importPlans(BuildContext context) async {
    final importExportService = ImportExportService();
    final planService = Provider.of<PracticePlanService>(context, listen: false);

    try {
      final plans = await importExportService.importPlansFromFile();
      if (plans.isNotEmpty) {
        for (final plan in plans) {
          await planService.addPlan(plan);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${plans.length} plan(s) successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing plans: $e')),
        );
      }
    }
  }

  void _exportAllPlans(BuildContext context) async {
    final importExportService = ImportExportService();
    final planService = Provider.of<PracticePlanService>(context, listen: false);

    if (planService.plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No plans to export')),
      );
      return;
    }

    try {
      // Get the screen size for share position
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      
      await importExportService.sharePlans(
        planService.plans,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting plans: $e')),
        );
      }
    }
  }

  void _importActivities(BuildContext context) async {
    final importExportService = ImportExportService();
    final activityService = Provider.of<ActivityService>(context, listen: false);

    try {
      final activities = await importExportService.importActivitiesFromFile();
      if (activities.isNotEmpty) {
        for (final activity in activities) {
          await activityService.addActivity(activity);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${activities.length} activity(ies) successfully')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing activities: $e')),
        );
      }
    }
  }

  void _exportAllActivities(BuildContext context) async {
    final importExportService = ImportExportService();
    final activityService = Provider.of<ActivityService>(context, listen: false);

    if (activityService.activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No activities to export')),
      );
      return;
    }

    try {
      // Get the screen size for share position
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      
      await importExportService.shareActivities(
        activityService.activities,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting activities: $e')),
        );
      }
    }
  }
}

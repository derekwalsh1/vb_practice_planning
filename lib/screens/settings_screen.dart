import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/activity_service.dart';
import '../services/practice_plan_service.dart';
import '../services/import_export_service.dart';
import '../providers/theme_provider.dart';
import '../models/app_theme.dart';

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
              'Appearance',
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
                  leading: const Icon(Icons.palette),
                  title: const Text('Color Theme'),
                  subtitle: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Text(
                        AppThemes.themeNames[themeProvider.currentTheme] ?? 'Ace Your Plans',
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeSelector(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                  title: const Text('Ace Your Plans'),
                  subtitle: const Text('A volleyball coaching app'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Ace Your Plans',
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
        int imported = 0;
        int skipped = 0;
        for (final activity in activities) {
          final existing = await activityService.getActivity(activity.id);
          if (existing == null) {
            await activityService.addActivity(activity);
            imported++;
          } else {
            skipped++;
          }
        }
        if (context.mounted) {
          final message = skipped > 0 
              ? 'Imported $imported activities, skipped $skipped duplicates'
              : 'Imported $imported activity(ies) successfully';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
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

  void _showThemeSelector(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Choose Color Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ...AppTheme.values.map((theme) {
                return _buildThemeOption(
                  context,
                  theme,
                  themeProvider.currentTheme == theme,
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(BuildContext context, AppTheme theme, bool isSelected) {
    final themeData = AppThemes.getTheme(theme);
    final themeName = AppThemes.themeNames[theme] ?? '';
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              themeData.colorScheme.primary,
              themeData.colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      title: Text(
        themeName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: themeData.colorScheme.primary)
          : null,
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).setTheme(theme);
        Navigator.pop(context);
      },
    );
  }
}

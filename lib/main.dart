import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/activity_service.dart';
import 'services/practice_plan_service.dart';
import 'services/schedule_service.dart';
import 'services/plan_group_service.dart';
import 'providers/theme_provider.dart';
import 'models/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = DatabaseService();
  await database.initDatabase();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: database),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProxyProvider<DatabaseService, ActivityService>(
          create: (_) => ActivityService(database),
          update: (_, db, previous) => previous ?? ActivityService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, PracticePlanService>(
          create: (_) => PracticePlanService(database),
          update: (_, db, previous) => previous ?? PracticePlanService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, ScheduleService>(
          create: (_) => ScheduleService(database),
          update: (_, db, previous) => previous ?? ScheduleService(db),
        ),
        ChangeNotifierProxyProvider<DatabaseService, PlanGroupService>(
          create: (_) => PlanGroupService(database),
          update: (_, db, previous) => previous ?? PlanGroupService(db),
        ),
      ],
      child: const VBPracticePlanApp(),
    ),
  );
}

class VBPracticePlanApp extends StatelessWidget {
  const VBPracticePlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Ace Your Plans',
          theme: AppThemes.getTheme(themeProvider.currentTheme),
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

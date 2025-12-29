import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/practice_plan_service.dart';
import '../services/activity_service.dart';
import '../services/plan_group_service.dart';
import '../models/plan_group.dart';
import '../models/practice_plan.dart';
import '../models/activity.dart';
import 'activities_screen.dart';
import 'plans_screen.dart';
import 'groups_screen.dart';
import 'settings_screen.dart';
import 'plan_execution_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const ActivitiesScreen(),
    const PlansScreen(),
    const GroupsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_volleyball_outlined),
            selectedIcon: Icon(Icons.sports_volleyball),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final planService = Provider.of<PracticePlanService>(context);
    final activityService = Provider.of<ActivityService>(context);
    final groupService = Provider.of<PlanGroupService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ace Your Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await planService.loadPlans();
          await planService.loadRecentPlans();
          await activityService.loadActivities();
          await activityService.loadRecentActivities();
          await groupService.loadGroups();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sports_volleyball, size: 40, color: Colors.orange),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Coach!',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Groups Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Groups',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GroupsScreen()),
                    );
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (groupService.groups.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No groups yet',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create groups to organize your plans',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: groupService.groups.length,
                  itemBuilder: (context, index) {
                    final group = groupService.groups[index];
                    final planCount = planService.getPlansForGroup(group.id).length;
                    return _buildGroupChip(context, group, planCount);
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Recently Used Plans
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Used Plans',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    );
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (planService.recentPlans.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.description, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No recent plans',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Run a practice plan to see it here',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...planService.recentPlans.map((plan) => _buildRecentPlanCard(context, plan)),

            const SizedBox(height: 24),

            // Recently Used Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Used Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
                    );
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activityService.recentActivities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_volleyball, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No recent activities',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete a practice to track activities',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activityService.recentActivities.map((activity) => _buildRecentActivityCard(context, activity)),

            const SizedBox(height: 24),

            // Quick Stats
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${planService.plans.length}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Practice Plans',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${activityService.activities.length}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Activities',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${groupService.groups.length}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Groups',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChip(BuildContext context, PlanGroup group, int planCount) {
    final color = _parseColor(group.color);
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlansScreen(groupId: group.id, groupName: group.name),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder, color: color, size: 28),
                const SizedBox(height: 6),
                Text(
                  group.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$planCount ${planCount == 1 ? 'plan' : 'plans'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  Future<DateTime?> _showStartTimeDialog(BuildContext context, PracticePlan plan) async {
    final now = DateTime.now();
    DateTime selectedDate = now;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(now);

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Start Practice'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.totalDuration} min • ${plan.activities.length} activities',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'When did/will practice start?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 7)),
                              lastDate: DateTime.now().add(const Duration(days: 1)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            DateFormat('MMM d').format(selectedDate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            selectedTime.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final startTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    Navigator.pop(dialogContext, startTime);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecentPlanCard(BuildContext context, PracticePlan plan) {
    final timeAgo = _getTimeAgo(plan.lastUsedDate!);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange,
          child: const Icon(Icons.description, color: Colors.white),
        ),
        title: Text(plan.name),
        subtitle: Text('$timeAgo • ${plan.totalDuration} min • ${plan.activities.length} activities'),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_outline),
          onPressed: () async {
            final startTime = await _showStartTimeDialog(context, plan);
            if (startTime != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanExecutionScreen(
                    plan: plan,
                    startTime: startTime,
                  ),
                ),
              );
            }
          },
        ),
        onTap: () async {
          final startTime = await _showStartTimeDialog(context, plan);
          if (startTime != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlanExecutionScreen(
                  plan: plan,
                  startTime: startTime,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, Activity activity) {
    final timeAgo = _getTimeAgo(activity.lastUsedDate!);
    final focusText = activity.focus.isNotEmpty ? activity.focus : null;
    final tagsText = activity.tags.isNotEmpty ? activity.tags.join(', ') : 'No tags';
    final subtitleParts = [timeAgo, '${activity.durationMinutes} min'];
    if (focusText != null) subtitleParts.add(focusText);
    subtitleParts.add(tagsText);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.sports_volleyball, color: Colors.white),
        ),
        title: Text(activity.name),
        subtitle: Text(subtitleParts.join(' • ')),
        trailing: IconButton(
          icon: const Icon(Icons.play_circle_filled),
          color: Colors.green,
          iconSize: 32,
          onPressed: () async {
            // Create a quick practice plan with just this activity
            final quickPlan = PracticePlan(
              id: 'quick_${activity.id}',
              name: activity.name,
              activities: [activity],
              notes: 'Quick practice',
              createdDate: DateTime.now(),
              lastModifiedDate: DateTime.now(),
            );
            
            // Show start time dialog
            final startTime = await _showStartTimeDialog(context, quickPlan);
            if (startTime != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanExecutionScreen(
                    plan: quickPlan,
                    startTime: startTime,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays ~/ 30 > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

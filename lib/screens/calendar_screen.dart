import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/scheduled_plan.dart';
import '../services/schedule_service.dart';
import '../services/practice_plan_service.dart';
import 'schedule_form_screen.dart';
import 'plan_execution_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final scheduleService = Provider.of<ScheduleService>(context);
    final planService = Provider.of<PracticePlanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                return scheduleService.getPlansForDate(day);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat('EEEE, MMMM d').format(_selectedDay!)
                      : 'Select a date',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_selectedDay != null)
                  FilledButton.icon(
                    onPressed: () => _schedulePlan(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Schedule'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay == null
                ? const Center(
                    child: Text('Select a date to view scheduled practices'),
                  )
                : _buildScheduledPlansList(context, scheduleService, planService),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledPlansList(
    BuildContext context,
    ScheduleService scheduleService,
    PracticePlanService planService,
  ) {
    final scheduledPlans = scheduleService.getPlansForDate(_selectedDay!);

    if (scheduledPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No practices scheduled',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _schedulePlan(context),
              icon: const Icon(Icons.add),
              label: const Text('Schedule Practice'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scheduledPlans.length,
      itemBuilder: (context, index) {
        final scheduledPlan = scheduledPlans[index];
        return FutureBuilder(
          future: planService.getPlan(scheduledPlan.practicePlanId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final plan = snapshot.data!;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Checkbox(
                  value: scheduledPlan.completed,
                  onChanged: (value) async {
                    await scheduleService.markPlanCompleted(
                      scheduledPlan.id,
                      value ?? false,
                    );
                  },
                ),
                title: Text(plan.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('h:mm a').format(scheduledPlan.scheduledDate)),
                    Text('${plan.totalDuration} min • ${plan.activities.length} activities'),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'execute',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text('Execute'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await scheduleService.deleteScheduledPlan(scheduledPlan.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Schedule removed')),
                        );
                      }
                    } else if (value == 'execute') {
                      final completed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanExecutionScreen(
                            plan: plan,
                            startTime: scheduledPlan.scheduledDate,
                          ),
                        ),
                      );
                      if (completed == true && context.mounted) {
                        await scheduleService.markPlanCompleted(scheduledPlan.id, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Practice completed!')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _schedulePlan(BuildContext context) {
    if (_selectedDay == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(selectedDate: _selectedDay!),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/scheduled_plan.dart';
import '../services/schedule_service.dart';
import '../services/practice_plan_service.dart';

class ScheduleFormScreen extends StatefulWidget {
  final DateTime selectedDate;

  const ScheduleFormScreen({super.key, required this.selectedDate});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  String? _selectedPlanId;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 16, minute: 0);
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planService = Provider.of<PracticePlanService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Practice'),
      ),
      body: planService.plans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No practice plans available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a practice plan first',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(widget.selectedDate),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Practice Plan',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...planService.plans.map((plan) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: plan.id,
                      groupValue: _selectedPlanId,
                      onChanged: (value) {
                        setState(() {
                          _selectedPlanId = value;
                        });
                      },
                      title: Text(plan.name),
                      subtitle: Text(
                        '${plan.formattedDuration} • ${plan.activities.length} activities',
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Text(
                  'Practice Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(_selectedTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any notes for this practice',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _selectedPlanId == null ? null : _schedulePractice,
                  icon: const Icon(Icons.check),
                  label: const Text('Schedule Practice'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
    );
  }

  void _schedulePractice() async {
    if (_selectedPlanId == null) return;

    final scheduleService = Provider.of<ScheduleService>(context, listen: false);

    final scheduledDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final scheduledPlan = ScheduledPlan(
      practicePlanId: _selectedPlanId!,
      scheduledDate: scheduledDateTime,
      notes: _notesController.text.trim(),
    );

    try {
      await scheduleService.schedulePlan(scheduledPlan);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Practice scheduled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling practice: $e')),
        );
      }
    }
  }
}

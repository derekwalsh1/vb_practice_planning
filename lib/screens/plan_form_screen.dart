import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/practice_plan.dart';
import '../models/activity.dart';
import '../models/plan_group.dart';
import '../services/practice_plan_service.dart';
import '../services/activity_service.dart';
import '../services/plan_group_service.dart';
import 'activity_form_screen.dart';

class PlanFormScreen extends StatefulWidget {
  final PracticePlan? plan;
  final String? initialGroupId;

  const PlanFormScreen({super.key, this.plan, this.initialGroupId});

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late List<Activity> _selectedActivities;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _notesController = TextEditingController(text: widget.plan?.notes ?? '');
    _selectedActivities = widget.plan?.activities.map((a) => a.copyWith()).toList() ?? [];
    _selectedGroupId = widget.plan?.groupId ?? widget.initialGroupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plan != null;
    final totalDuration = _selectedActivities.fold(0, (sum, a) => sum + a.durationMinutes);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plan' : 'New Plan'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Plan Name',
                      hintText: 'e.g., Tuesday Practice',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a plan name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'General notes about this practice',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Consumer<PlanGroupService>(
                    builder: (context, groupService, _) {
                      return DropdownButtonFormField<String>(
                        value: _selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Group (optional)',
                          hintText: 'Select a group',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...groupService.groups.map((group) {
                            return DropdownMenuItem<String>(
                              value: group.id,
                              child: Text(group.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGroupId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Activities (${_selectedActivities.length})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(totalDuration),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedActivities.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Icon(Icons.sports_volleyball_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'No activities added yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the button below to add activities',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedActivities.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedActivities.removeAt(oldIndex);
                          _selectedActivities.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final activity = _selectedActivities[index];
                        print('Building activity card $index: ${activity.name} (ID: ${activity.id})');
                        final focusText = activity.focus.isNotEmpty ? activity.focus : null;
                        final tagsText = activity.tags.isNotEmpty ? activity.tags.join(', ') : 'No tags';
                        final subtitleParts = ['${activity.durationMinutes} min'];
                        if (focusText != null) subtitleParts.add(focusText);
                        subtitleParts.add(tagsText);
                        return Card(
                          key: Key('activity_${activity.id}_$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(activity.name),
                            subtitle: Text(subtitleParts.join(' • ')),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedActivities.removeAt(index);
                                  print('Removed activity at index $index. Remaining: ${_selectedActivities.length}');
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showActivityPicker,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Activity'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed: _savePlan,
                  icon: const Icon(Icons.save),
                  label: Text(isEditing ? 'Update Plan' : 'Create Plan'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  void _showActivityPicker() async {
    final activityService = Provider.of<ActivityService>(context, listen: false);
    
    print('Activity picker opened. Available activities: ${activityService.activities.length}');
    
    if (activityService.activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No activities available. Create some activities first!'),
          action: SnackBarAction(
            label: 'Create',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivityFormScreen(),
                ),
              );
              if (context.mounted) {
                await activityService.loadActivities();
                if (context.mounted && activityService.activities.isNotEmpty) {
                  _showActivityPicker();
                }
              }
            },
          ),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Activity>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ActivityPickerSheet(
        activities: activityService.activities,
        onActivitySelected: (activity) => Navigator.pop(context, activity),
        onNewActivity: () async {
          final pickerContext = context;
          final scaffoldContext = this.context;
          Navigator.pop(pickerContext);
          await Navigator.push(
            scaffoldContext,
            MaterialPageRoute(
              builder: (_) => const ActivityFormScreen(),
            ),
          );
          if (scaffoldContext.mounted) {
            await Provider.of<ActivityService>(scaffoldContext, listen: false).loadActivities();
            if (scaffoldContext.mounted) {
              _showActivityPicker();
            }
          }
        },
      ),
    );

    print('Selected activity: ${selected?.name ?? "null"}');
    if (selected != null) {
      print('Before adding - activities count: ${_selectedActivities.length}');
      // Add the selected activity directly - it already has a valid ID from the database
      // We create a copy so the same activity can be added multiple times
      final newActivity = selected.copyWith();
      print('Adding activity with ID: ${newActivity.id}');
      setState(() {
        _selectedActivities.add(newActivity);
        print('After adding - activities count: ${_selectedActivities.length}');
        print('Activity IDs: ${_selectedActivities.map((a) => a.id).join(", ")}');
      });
    } else {
      print('Selected was null - modal was cancelled');
    }
  }

  void _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedActivities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one activity')),
      );
      return;
    }

    final planService = Provider.of<PracticePlanService>(context, listen: false);

    final plan = PracticePlan(
      id: widget.plan?.id,
      name: _nameController.text.trim(),
      notes: _notesController.text.trim(),
      activities: _selectedActivities,
      groupId: _selectedGroupId,
      createdDate: widget.plan?.createdDate,
    );

    try {
      if (widget.plan != null) {
        await planService.updatePlan(plan);
      } else {
        await planService.addPlan(plan);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.plan != null ? 'Plan updated' : 'Plan created',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving plan: $e')),
        );
      }
    }
  }
}

class _ActivityPickerSheet extends StatefulWidget {
  final List<Activity> activities;
  final Function(Activity) onActivitySelected;
  final VoidCallback onNewActivity;

  const _ActivityPickerSheet({
    required this.activities,
    required this.onActivitySelected,
    required this.onNewActivity,
  });

  @override
  State<_ActivityPickerSheet> createState() => _ActivityPickerSheetState();
}

class _ActivityPickerSheetState extends State<_ActivityPickerSheet> {
  final Set<String> _selectedTags = {};
  late List<String> _allTags;

  @override
  void initState() {
    super.initState();
    // Collect all unique tags from activities
    final tagsSet = <String>{};
    for (final activity in widget.activities) {
      tagsSet.addAll(activity.tags);
    }
    _allTags = tagsSet.toList()..sort();
  }

  List<Activity> get _filteredActivities {
    if (_selectedTags.isEmpty) {
      return widget.activities;
    }
    return widget.activities.where((activity) {
      return _selectedTags.every((tag) => activity.tags.contains(tag));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Select Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onNewActivity,
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Tag filters
          if (_allTags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Filter by tags',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (_selectedTags.isNotEmpty) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedTags.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        backgroundColor: Colors.white,
                        selectedColor: Theme.of(context).colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          // Activity list
          Expanded(
            child: _filteredActivities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No activities match the selected tags',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _filteredActivities[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(activity.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${activity.durationMinutes} min'),
                              if (activity.focus.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.flag_outlined, size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activity.focus,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (activity.tags.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 4,
                                  children: activity.tags.map((tag) {
                                    return Chip(
                                      label: Text(tag),
                                      visualDensity: VisualDensity.compact,
                                      labelStyle: const TextStyle(fontSize: 10),
                                      padding: EdgeInsets.zero,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => widget.onActivitySelected(activity),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

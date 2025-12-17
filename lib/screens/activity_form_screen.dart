import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../models/diagram.dart';
import '../services/activity_service.dart';
import '../services/import_export_service.dart';
import 'diagram_editor_screen.dart';

class ActivityFormScreen extends StatefulWidget {
  final Activity? activity;

  const ActivityFormScreen({super.key, this.activity});

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _durationController;
  late TextEditingController _focusController;
  late TextEditingController _descriptionController;
  late TextEditingController _coachingTipsController;
  late TextEditingController _tagController;
  late List<String> _tags;
  List<String> _availableTags = [];
  Diagram? _diagram;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activity?.name ?? '');
    _durationController = TextEditingController(
      text: widget.activity?.durationMinutes.toString() ?? '15',
    );
    _focusController = TextEditingController(text: widget.activity?.focus ?? '');
    _descriptionController = TextEditingController(text: widget.activity?.description ?? '');
    _coachingTipsController = TextEditingController(text: widget.activity?.coachingTips ?? '');
    _tagController = TextEditingController();
    _tags = widget.activity?.tags != null ? List<String>.from(widget.activity!.tags) : [];
    _diagram = widget.activity?.diagram;
    _loadAvailableTags();
  }

  void _loadAvailableTags() {
    final activityService = Provider.of<ActivityService>(context, listen: false);
    final allTags = <String>{};
    
    for (final activity in activityService.activities) {
      allTags.addAll(activity.tags);
    }
    
    setState(() {
      _availableTags = allTags.toList()..sort();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _focusController.dispose();
    _descriptionController.dispose();
    _coachingTipsController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activity != null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Activity' : 'New Activity'),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Export Activity',
                onPressed: () => _exportActivity(context),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Details'),
              Tab(icon: Icon(Icons.sports_volleyball), text: 'Diagram'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Details Tab
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                hintText: 'e.g., 6v6 Serve & Pass',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_volleyball),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an activity name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Invalid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _focusController,
              decoration: const InputDecoration(
                labelText: 'Focus/Goal',
                hintText: 'e.g., Improve serve receive, Build team communication',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the activity, setup, and objectives',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coachingTipsController,
              decoration: const InputDecoration(
                labelText: 'Coaching Tips',
                hintText: 'Key points to emphasize and watch for',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lightbulb_outline),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            // Tags section
            const Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            // Show existing tags that can be selected
            if (_availableTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.where((tag) => !_tags.contains(tag)).map((tag) {
                  return ActionChip(
                    label: Text(tag),
                    avatar: const Icon(Icons.add, size: 18),
                    onPressed: () {
                      setState(() {
                        _tags.add(tag);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Selected tags
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Add new tag input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Add new tag',
                      hintText: 'e.g., passing, defense',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    onSubmitted: (value) {
                      _addTag(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _addTag(_tagController.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveActivity,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update Activity' : 'Create Activity'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
                ],
              ),
            ),
            // Diagram Tab
            DiagramEditorScreen(
              initialDiagram: _diagram,
              onDiagramChanged: (diagram) {
                setState(() {
                  _diagram = diagram;
                });
              },
              embedded: true,
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String value) {
    final tag = value.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
        // Add to available tags if it's a new tag
        if (!_availableTags.contains(tag)) {
          _availableTags.add(tag);
          _availableTags.sort();
        }
      });
    }
  }

  void _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final activityService = Provider.of<ActivityService>(context, listen: false);

    final activity = Activity(
      id: widget.activity?.id,
      name: _nameController.text.trim(),
      durationMinutes: int.parse(_durationController.text),
      description: _descriptionController.text.trim(),
      coachingTips: _coachingTipsController.text.trim(),
      focus: _focusController.text.trim(),
      tags: _tags,
      diagram: _diagram,
      createdDate: widget.activity?.createdDate,
    );

    try {
      if (widget.activity != null) {
        await activityService.updateActivity(activity);
      } else {
        await activityService.addActivity(activity);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.activity != null ? 'Activity updated' : 'Activity created',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activity: $e')),
        );
      }
    }
  }

  void _exportActivity(BuildContext context) async {
    if (widget.activity == null) return;

    try {
      final importExportService = Provider.of<ImportExportService>(context, listen: false);
      
      // Get the screen size for share position
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      
      await importExportService.shareActivities(
        [widget.activity!],
        sharePositionOrigin: sharePositionOrigin,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

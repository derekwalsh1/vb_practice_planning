import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/practice_plan.dart';
import '../models/activity.dart';
import '../services/practice_plan_service.dart';
import '../services/activity_service.dart';
import 'package:intl/intl.dart';

class PlanExecutionScreen extends StatefulWidget {
  final PracticePlan plan;
  final DateTime? startTime;

  const PlanExecutionScreen({
    super.key,
    required this.plan,
    this.startTime,
  });

  @override
  State<PlanExecutionScreen> createState() => _PlanExecutionScreenState();
}

class _PlanExecutionScreenState extends State<PlanExecutionScreen> {
  int _currentActivityIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isPaused = false;
  DateTime? _actualStartTime;
  int _totalElapsedSeconds = 0;
  int _currentActivityElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _actualStartTime = DateTime.now();
    
    if (widget.plan.activities.isNotEmpty) {
      // Always start at the first activity
      _remainingSeconds = widget.plan.activities[0].durationMinutes * 60;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            _totalElapsedSeconds++;
            _currentActivityElapsedSeconds++;
          } else {
            // Time's up for this activity
            _onActivityComplete();
          }
        });
      }
    });
  }

  void _onActivityComplete() {
    _timer?.cancel();
    
    // Vibrate and play sound
    HapticFeedback.heavyImpact();
    
    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm, color: Colors.orange, size: 32),
            SizedBox(width: 8),
            Text('Time\'s Up!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plan.activities[_currentActivityIndex].name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildScheduleStatus(),
          ],
        ),
        actions: [
          if (_currentActivityIndex < widget.plan.activities.length - 1)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addExtraTime(5);
              },
              child: const Text('+5 min'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentActivityIndex < widget.plan.activities.length - 1) {
                _goToNextActivity();
              } else {
                _completePractice();
              }
            },
            child: Text(_currentActivityIndex < widget.plan.activities.length - 1 
                ? 'Next Activity' 
                : 'Finish Practice'),
          ),
        ],
      ),
    );
  }

  void _addExtraTime(int minutes) {
    setState(() {
      _remainingSeconds += minutes * 60;
      _isPaused = false;
    });
    _startTimer();
  }

  void _goToNextActivity() {
    if (_currentActivityIndex < widget.plan.activities.length - 1) {
      setState(() {
        _currentActivityIndex++;
        _currentActivityElapsedSeconds = 0;
        _remainingSeconds = widget.plan.activities[_currentActivityIndex].durationMinutes * 60;
        _isPaused = false;
      });
      _startTimer();
    }
  }

  void _goToPreviousActivity() {
    if (_currentActivityIndex > 0) {
      setState(() {
        _totalElapsedSeconds -= widget.plan.activities[_currentActivityIndex].durationMinutes * 60;
        _currentActivityIndex--;
        _currentActivityElapsedSeconds = 0;
        _remainingSeconds = widget.plan.activities[_currentActivityIndex].durationMinutes * 60;
        _isPaused = false;
      });
      _startTimer();
    }
  }

  void _completePractice() {
    // Mark plan and activities as used
    final planService = Provider.of<PracticePlanService>(context, listen: false);
    final activityService = Provider.of<ActivityService>(context, listen: false);
    
    planService.markPlanAsUsed(widget.plan.id);
    for (final activity in widget.plan.activities) {
      activityService.markActivityAsUsed(activity.id);
    }
    
    Navigator.pop(context, true); // Return true to indicate completion
  }

  int get _scheduledElapsedSeconds {
    // Calculate expected elapsed time based on completed activities
    int expectedSeconds = 0;
    for (int i = 0; i < _currentActivityIndex; i++) {
      expectedSeconds += widget.plan.activities[i].durationMinutes * 60;
    }
    // Add the time that should have elapsed for current activity
    final currentActivityDuration = widget.plan.activities[_currentActivityIndex].durationMinutes * 60;
    expectedSeconds += currentActivityDuration - _remainingSeconds;
    return expectedSeconds;
  }
  
  // Calculate when the next activity should start based on the schedule
  DateTime? get _nextActivityScheduledStartTime {
    if (_currentActivityIndex >= widget.plan.activities.length - 1) {
      return null; // No next activity
    }
    
    final startTime = widget.startTime ?? _actualStartTime!;
    int scheduledSecondsUntilNext = 0;
    
    // Add duration of all activities up to and including current
    for (int i = 0; i <= _currentActivityIndex; i++) {
      scheduledSecondsUntilNext += widget.plan.activities[i].durationMinutes * 60;
    }
    
    return startTime.add(Duration(seconds: scheduledSecondsUntilNext));
  }
  
  // Time remaining until next activity should start (can be negative)
  int get _remainingUntilNextActivity {
    final nextStart = _nextActivityScheduledStartTime;
    if (nextStart == null) return 0;
    
    final now = DateTime.now();
    return nextStart.difference(now).inSeconds;
  }
  
  // Calculate expected end time of practice
  DateTime get _expectedEndTime {
    final startTime = widget.startTime ?? _actualStartTime!;
    int totalSeconds = 0;
    for (final activity in widget.plan.activities) {
      totalSeconds += activity.durationMinutes * 60;
    }
    return startTime.add(Duration(seconds: totalSeconds));
  }

  int get _scheduleVariance {
    // Positive means behind schedule, negative means ahead
    // Compare actual elapsed time (wall clock) with where we should be in the schedule
    final startTime = widget.startTime ?? _actualStartTime!;
    final actualElapsedSeconds = DateTime.now().difference(startTime).inSeconds;
    return actualElapsedSeconds - _scheduledElapsedSeconds;
  }

  bool get _isAheadOfSchedule => _scheduleVariance < -60; // More than 1 minute ahead
  bool get _isBehindSchedule => _scheduleVariance > 60; // More than 1 minute behind

  Widget _buildScheduleStatus() {
    final variance = _scheduleVariance.abs();
    final minutes = variance ~/ 60;
    final seconds = variance % 60;
    
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (_isAheadOfSchedule) {
      statusText = 'Ahead of schedule';
      statusColor = Colors.green;
      statusIcon = Icons.trending_up;
    } else if (_isBehindSchedule) {
      statusText = 'Behind schedule';
      statusColor = Colors.red;
      statusIcon = Icons.trending_down;
    } else {
      statusText = 'On schedule';
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (variance > 30)
                  Text(
                    '${minutes}m ${seconds}s',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get _activityProgress {
    final totalSeconds = widget.plan.activities[_currentActivityIndex].durationMinutes * 60;
    return 1 - (_remainingSeconds / totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan.activities.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Execute Plan')),
        body: const Center(child: Text('No activities in this plan')),
      );
    }

    final currentActivity = widget.plan.activities[_currentActivityIndex];
    final isLastActivity = _currentActivityIndex == widget.plan.activities.length - 1;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Practice?'),
            content: const Text('Are you sure you want to exit? Timer will be stopped.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.plan.name),
          actions: [
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: () {
                setState(() {
                  _isPaused = !_isPaused;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentActivityIndex + _activityProgress) / widget.plan.activities.length,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Compact timing header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Activity counter
                          Text(
                            'Activity ${_currentActivityIndex + 1}/${widget.plan.activities.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          // Schedule times
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat.jm().format(widget.startTime ?? _actualStartTime!)} - ${DateFormat.jm().format(_expectedEndTime)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          // Current activity elapsed
                          Row(
                            children: [
                              Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(_currentActivityElapsedSeconds),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Compact timer display
                    if (!(_currentActivityIndex >= widget.plan.activities.length - 1))
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatTime(_remainingUntilNextActivity.abs()),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _remainingUntilNextActivity < 0 ? Colors.red : 
                                       _remainingUntilNextActivity < 60 ? Colors.orange : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _remainingUntilNextActivity < 0 ? 'over' : 'until',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'next at ${DateFormat.jm().format(_nextActivityScheduledStartTime!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            if (_isPaused) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PAUSED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _formatTime(_remainingSeconds),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _remainingSeconds < 60 ? Colors.red : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'remaining',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const Divider(height: 24),
                    const SizedBox(height: 8),
                    
                    // Activity details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentActivity.tags.isNotEmpty) ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: currentActivity.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              currentActivity.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentActivity.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (currentActivity.coachingTips.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.lightbulb, size: 20, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text(
                                          'Coaching Tips',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentActivity.coachingTips,
                                      style: const TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Next activity preview
                    if (!isLastActivity)
                      Card(
                        color: Colors.grey[100],
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Up Next',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.plan.activities[_currentActivityIndex + 1].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${widget.plan.activities[_currentActivityIndex + 1].durationMinutes} min',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Navigation buttons
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
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _currentActivityIndex > 0 ? _goToPreviousActivity : null,
                        icon: const Icon(Icons.skip_previous),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (isLastActivity) {
                            _completePractice();
                          } else {
                            _goToNextActivity();
                          }
                        },
                        icon: Icon(isLastActivity ? Icons.check : Icons.skip_next),
                        label: Text(isLastActivity ? 'Finish' : 'Next'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

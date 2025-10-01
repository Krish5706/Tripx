import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripx_frontend/models/schedule.dart';
import 'package:tripx_frontend/models/trip.dart';
import 'package:tripx_frontend/repositories/schedule_repository.dart';
import 'package:collection/collection.dart'; // Import for grouping

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

enum TimeFilter { all, today, upcoming }

class _ScheduleScreenState extends State<ScheduleScreen> {
  late Future<List<Schedule>> _scheduleFuture;
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  late Trip _trip;

  // State for filters
  TimeFilter _selectedTimeFilter = TimeFilter.all;
  String _selectedCategoryFilter = 'All';
  final List<String> _categoryFilters = [
    'All',
    'Transportation',
    'Accommodation',
    'Activity',
    'Food',
    'Other'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trip = ModalRoute.of(context)!.settings.arguments as Trip;
    _scheduleFuture = _fetchSchedule();
  }

  Future<List<Schedule>> _fetchSchedule() async {
    try {
      return await _scheduleRepository.getScheduleForTrip(_trip.id);
    } catch (e) {
      rethrow;
    }
  }

  void _refreshSchedule() {
    setState(() {
      _scheduleFuture = _fetchSchedule();
    });
  }

  void _showAddOrEditScheduleDialog({Schedule? item}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddScheduleDialog(
          trip: _trip,
          scheduleItem: item, // Pass the item to edit, or null to create
          onSave: () {
            _refreshSchedule();
          },
        );
      },
    );
  }

  void _deleteScheduleItem(String itemId) async {
    await _scheduleRepository.deleteScheduleItem(itemId);
    _refreshSchedule();
  }

  // --- FILTERING LOGIC ---
  List<Schedule> _filterScheduleItems(List<Schedule> items) {
    List<Schedule> filteredList = items;

    // Time Filter
    if (_selectedTimeFilter == TimeFilter.today) {
      final now = DateTime.now();
      filteredList = filteredList
          .where((item) =>
              item.startTime.year == now.year &&
              item.startTime.month == now.month &&
              item.startTime.day == now.day)
          .toList();
    } else if (_selectedTimeFilter == TimeFilter.upcoming) {
      final now = DateTime.now();
      filteredList =
          filteredList.where((item) => item.startTime.isAfter(now)).toList();
    }

    // Category Filter
    if (_selectedCategoryFilter != 'All') {
      filteredList = filteredList
          .where((item) => item.category == _selectedCategoryFilter)
          .toList();
    }

    // Sort by start time
    filteredList.sort((a, b) => a.startTime.compareTo(b.startTime));

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Schedule', style: theme.textTheme.titleLarge),
            Text(
              _trip.tripName,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: _buildTopFilters(theme),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(theme),
          _buildFilterChips(theme),
          Expanded(
            child: FutureBuilder<List<Schedule>>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(theme);
                }

                final filteredItems = _filterScheduleItems(snapshot.data!);

                if (filteredItems.isEmpty) {
                  return _buildEmptyState(theme, isFiltered: true);
                }

                // Group items by day
                final groupedByDay = groupBy(filteredItems, (Schedule item) {
                  return DateTime(item.startTime.year, item.startTime.month,
                      item.startTime.day);
                });

                final sortedKeys = groupedByDay.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final day = sortedKeys[index];
                    final itemsForDay = groupedByDay[day]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateHeader(theme, day),
                        ...itemsForDay
                            .map((item) => _ScheduleListItem(
                                  item: item,
                                  onEdit: () =>
                                      _showAddOrEditScheduleDialog(item: item),
                                  onDelete: () => _deleteScheduleItem(item.id),
                                ))
                            .toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule Item'),
            onPressed: () => _showAddOrEditScheduleDialog(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(ThemeData theme, DateTime date) {
    final now = DateTime.now();
    String headerText;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      headerText = 'Today, ${DateFormat.yMMMd().format(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      headerText = 'Tomorrow, ${DateFormat.yMMMd().format(date)}';
    } else {
      headerText = DateFormat.yMMMMEEEEd().format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        headerText,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTopFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: SegmentedButton<TimeFilter>(
        segments: const <ButtonSegment<TimeFilter>>[
          ButtonSegment<TimeFilter>(value: TimeFilter.all, label: Text('All')),
          ButtonSegment<TimeFilter>(
              value: TimeFilter.today, label: Text('Today')),
          ButtonSegment<TimeFilter>(
              value: TimeFilter.upcoming, label: Text('Upcoming')),
        ],
        selected: <TimeFilter>{_selectedTimeFilter},
        onSelectionChanged: (Set<TimeFilter> newSelection) {
          setState(() {
            _selectedTimeFilter = newSelection.first;
          });
        },
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: theme.colorScheme.secondaryContainer,
          selectedForegroundColor: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search schedule items...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categoryFilters.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(category),
                selected: _selectedCategoryFilter == category,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategoryFilter = category;
                  });
                },
                selectedColor: theme.colorScheme.secondaryContainer,
                checkmarkColor: theme.colorScheme.onSecondaryContainer,
                labelStyle: TextStyle(
                    color: _selectedCategoryFilter == category
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurface),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltered ? Icons.filter_list_off : Icons.watch_later_outlined,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No items match your filters'
                : 'No schedule items found',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (!isFiltered)
            Text(
              'Tap the "Add" button to add your first schedule item',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

// --- DIALOG WIDGET (Remains the same) ---
class _AddScheduleDialog extends StatefulWidget {
  final Trip trip;
  final Schedule? scheduleItem; // Can be null for creating new
  final VoidCallback onSave;
  const _AddScheduleDialog(
      {required this.trip, this.scheduleItem, required this.onSave});
  @override
  State<_AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<_AddScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = 'Activity';
  String _priority = 'Medium';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = false;
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  @override
  void initState() {
    super.initState();
    if (widget.scheduleItem != null) {
      // If editing, pre-fill the form
      final item = widget.scheduleItem!;
      _titleController.text = item.title;
      _descriptionController.text = item.description ?? '';
      _locationController.text = item.location ?? '';
      _category = item.category;
      _priority = item.priority;
      _startTime = item.startTime;
      _endTime = item.endTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? widget.trip.startDate,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      final selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startTime = selectedDateTime;
      } else {
        _endTime = selectedDateTime;
      }
    });
  }

  Future<void> _saveScheduleItem() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a start time.'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      if (widget.scheduleItem == null) {
        // Create new item
        await _scheduleRepository.createScheduleItem(
          tripId: widget.trip.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          category: _category,
          priority: _priority,
          startTime: _startTime!,
          endTime: _endTime,
        );
      } else {
        // Update existing item
        await _scheduleRepository.updateScheduleItem(
          itemId: widget.scheduleItem!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          category: _category,
          priority: _priority,
          startTime: _startTime!,
          endTime: _endTime,
        );
      }
      if (!mounted) return;
      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        widget.scheduleItem == null ? 'Add Schedule Item' : 'Edit Schedule Item',
        style: theme.textTheme.titleLarge,
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  'Activity',
                  'Transportation',
                  'Accommodation',
                  'Food',
                  'Other'
                ]
                    .map((label) =>
                        DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['Low', 'Medium', 'High']
                    .map((label) =>
                        DropdownMenuItem(value: label, child: Text(label)))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 16),
              _buildDateTimePicker(
                  'Start', _startTime, () => _pickDateTime(true), theme),
              const SizedBox(height: 8),
              _buildDateTimePicker(
                  'End', _endTime, () => _pickDateTime(false), theme),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
            onPressed: _isLoading ? null : _saveScheduleItem,
            child: const Text('Save')),
      ],
    );
  }

  Widget _buildDateTimePicker(
      String label, DateTime? time, VoidCallback onPressed, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${time != null ? DateFormat.yMMMd().add_Hm().format(time) : 'Not set'}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        IconButton(
            icon: const Icon(Icons.calendar_today), onPressed: onPressed),
      ],
    );
  }
}

// --- NEW SCHEDULE LIST ITEM WIDGET ---
class _ScheduleListItem extends StatelessWidget {
  final Schedule item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ScheduleListItem(
      {required this.item, required this.onEdit, required this.onDelete});

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Transportation':
        return Icons.directions_bus_outlined;
      case 'Accommodation':
        return Icons.hotel_outlined;
      case 'Food':
        return Icons.fastfood_outlined;
      case 'Activity':
        return Icons.local_activity_outlined;
      default:
        return Icons.task_alt;
    }
  }

  Color _getColorForPriority(String priority, ThemeData theme) {
    switch (priority) {
      case 'High':
        return theme.colorScheme.error;
      case 'Medium':
        return theme.colorScheme.tertiary;
      case 'Low':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String timeRange = DateFormat.Hm().format(item.startTime);
    if (item.endTime != null) {
      timeRange += ' - ${DateFormat.Hm().format(item.endTime!)}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(_getIconForCategory(item.category),
                color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(timeRange,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Chip(
              label: Text(item.priority),
              color: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                return _getColorForPriority(item.priority, theme)
                    .withValues(alpha: 0.15);
              }),
              side: BorderSide(
                  color: _getColorForPriority(item.priority, theme), width: 1),
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                  color: _getColorForPriority(item.priority, theme),
                  fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
            ),
            IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
                onPressed: onEdit),
            IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: theme.colorScheme.error),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
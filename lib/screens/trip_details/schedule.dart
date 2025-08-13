import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  final int tripId;
  final String tripName;

  const ScheduleScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with TickerProviderStateMixin {
  final ScheduleService _scheduleService = ScheduleService();
  final TextEditingController _searchController = TextEditingController();

  List<ScheduleItem> _scheduleItems = [];
  List<ScheduleItem> _filteredItems = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;

  late TabController _tabController;

  final List<String> _categories = [
    'All',
    'Transportation',
    'Accommodation',
    'Activity',
    'Food',
    'Meeting',
    'Sightseeing',
    'Shopping',
    'Other',
  ];

  final Map<String, IconData> _categoryIcons = {
    'Transportation': Icons.directions_car,
    'Accommodation': Icons.hotel,
    'Activity': Icons.local_activity,
    'Food': Icons.restaurant,
    'Meeting': Icons.people,
    'Sightseeing': Icons.camera_alt,
    'Shopping': Icons.shopping_bag,
    'Other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScheduleItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadScheduleItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _scheduleService.getScheduleItemsByTrip(
        widget.tripId,
      );
      setState(() {
        _scheduleItems = items;
        _filterItems();
      });
    } catch (e) {
      _showSnackBar('Failed to load schedule items', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    List<ScheduleItem> filtered = _scheduleItems;
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((item) => item.category == _selectedCategory)
          .toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (item) =>
                item.title.toLowerCase().contains(query) ||
                item.description.toLowerCase().contains(query) ||
                item.location.toLowerCase().contains(query),
          )
          .toList();
    }
    setState(() => _filteredItems = filtered);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              widget.tripName,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(colorScheme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleView(_filteredItems),
                _buildTodayView(),
                _buildUpcomingView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 18.0, bottom: 16.0),
          child: FloatingActionButton.extended(
            onPressed: _addScheduleItem,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Add Schedule'),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterItems(),
            decoration: InputDecoration(
              hintText: 'Search schedule items...',
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              filled: true,
              fillColor: colorScheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterItems();
                      });
                    },
                    backgroundColor: colorScheme.surface,
                    selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView(List<ScheduleItem> items) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadScheduleItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildScheduleCard(items[index]),
      ),
    );
  }

  Widget _buildTodayView() {
    final today = DateTime.now();
    final todayItems = _filteredItems.where((item) {
      return item.startTime.year == today.year &&
          item.startTime.month == today.month &&
          item.startTime.day == today.day;
    }).toList();
    return _buildScheduleView(todayItems);
  }

  Widget _buildUpcomingView() {
    final now = DateTime.now();
    final upcomingItems = _filteredItems
        .where((item) => item.startTime.isAfter(now) && !item.isCompleted)
        .toList();
    return _buildScheduleView(upcomingItems);
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 80, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'No schedule items found',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first schedule item',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final priorityColors = {
      'High': Colors.red,
      'Medium': Colors.orange,
      'Low': Colors.green,
    };
    final priorityColor = priorityColors[item.priority] ?? Colors.grey;
    final categoryIcon = _categoryIcons[item.category] ?? Icons.event;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showItemDetails(item),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : priorityColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isCompleted
                                ? colorScheme.onSurface.withValues(alpha: 0.6)
                                : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (item.location.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.location,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.priority,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (item.description.isNotEmpty)
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM dd, HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      item.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: item.isCompleted
                          ? Colors.green
                          : colorScheme.outline,
                    ),
                    onPressed: () => _toggleCompletion(item),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: colorScheme.primary),
                    onPressed: () => _editItem(item),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Text('Description: ${item.description}'),
            Text(
              'Time: ${DateFormat('MMM dd, yyyy HH:mm').format(item.startTime)} - ${DateFormat('HH:mm').format(item.endTime)}',
            ),
            if (item.location.isNotEmpty) Text('Location: ${item.location}'),
            Text('Category: ${item.category}'),
            Text('Priority: ${item.priority}'),
            Text('Status: ${item.isCompleted ? 'Completed' : 'Pending'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addScheduleItem() {
    _showItemForm();
  }

  void _editItem(ScheduleItem item) {
    _showItemForm(item: item);
  }

  void _showItemForm({ScheduleItem? item}) {
    showDialog(
      context: context,
      builder: (context) => ScheduleItemDialog(
        tripId: widget.tripId,
        item: item,
        onSaved: () {
          _loadScheduleItems();
          _showSnackBar(
            item == null ? 'Schedule item added' : 'Schedule item updated',
            Colors.green,
          );
        },
      ),
    );
  }

  Future<void> _toggleCompletion(ScheduleItem item) async {
    try {
      await _scheduleService.toggleCompletion(item.id!);
      _loadScheduleItems();
      _showSnackBar(
        item.isCompleted ? 'Marked as pending' : 'Marked as completed',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar('Failed to update item status', Colors.red);
    }
  }

  Future<void> _deleteItem(ScheduleItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _scheduleService.deleteScheduleItem(item.id!);
        _loadScheduleItems();
        _showSnackBar('Schedule item deleted', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to delete schedule item', Colors.red);
      }
    }
  }
}

class ScheduleItemDialog extends StatefulWidget {
  final int tripId;
  final ScheduleItem? item;
  final VoidCallback onSaved;

  const ScheduleItemDialog({
    super.key,
    required this.tripId,
    this.item,
    required this.onSaved,
  });

  @override
  State<ScheduleItemDialog> createState() => _ScheduleItemDialogState();
}

class _ScheduleItemDialogState extends State<ScheduleItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  String _category = 'Activity';
  String _priority = 'Medium';

  final List<String> _categories = [
    'Transportation',
    'Accommodation',
    'Activity',
    'Food',
    'Meeting',
    'Sightseeing',
    'Shopping',
    'Other',
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleController.text = widget.item!.title;
      _descriptionController.text = widget.item!.description;
      _locationController.text = widget.item!.location;
      _startTime = widget.item!.startTime;
      _endTime = widget.item!.endTime;
      _category = widget.item!.category;
      _priority = widget.item!.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // 👈 wider dialog
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item == null
                            ? 'Add Schedule Item'
                            : 'Edit Schedule Item',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter a title'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Row with two dropdowns: Category & Priority
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _category = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _priority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                              ),
                              items: _priorities
                                  .map(
                                    (pri) => DropdownMenuItem(
                                      value: pri,
                                      child: Text(pri),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _priority = value!),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      ListTile(
                        title: Text(
                          'Start: ${DateFormat('MMM dd, yyyy HH:mm').format(_startTime)}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectDateTime(true),
                      ),
                      ListTile(
                        title: Text(
                          'End: ${DateFormat('MMM dd, yyyy HH:mm').format(_endTime)}',
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selectDateTime(false),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveItem,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );
      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart) {
            _startTime = newDateTime;
            if (_startTime.isAfter(_endTime))
              _endTime = _startTime.add(const Duration(hours: 1));
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final scheduleService = ScheduleService();
      final item = ScheduleItem(
        id: widget.item?.id,
        tripId: widget.tripId,
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: _startTime,
        endTime: _endTime,
        category: _category,
        priority: _priority,
        createdAt: widget.item?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.item == null) {
        await scheduleService.createScheduleItem(item);
      } else {
        await scheduleService.updateScheduleItem(item);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

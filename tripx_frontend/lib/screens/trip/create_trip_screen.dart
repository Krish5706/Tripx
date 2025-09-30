import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripx_frontend/repositories/trip_repository.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _plannedActivities = [];
  final List<String> _popularActivities = [
    'Sightseeing', 'Museums', 'Food Tours', 'Shopping', 'Beach', 'Hiking',
    'Photography', 'Cultural Sites', 'Adventure Sports', 'Relaxation',
    'Nightlife', 'Local Markets', 'Historical Tours', 'Nature Walks'
  ];
  bool _isLoading = false;
  final TripRepository _tripRepository = TripRepository();

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (_plannedActivities.contains(activity)) {
        _plannedActivities.remove(activity);
      } else {
        _plannedActivities.add(activity);
      }
    });
  }

  Future<void> _createTrip() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select travel dates.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _tripRepository.createTrip(
      tripName: _tripNameController.text,
      destination: _destinationController.text,
      description: _descriptionController.text,
      startDate: _startDate!,
      endDate: _endDate!,
      budget: _budgetController.text,
      activities: _plannedActivities,
    );

    if (!mounted) return;

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip created successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create trip: ${result['message']}'), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Trip'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createTrip,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                color: _isLoading
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                  : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(theme),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      theme,
                      icon: Icons.info_outline,
                      title: 'Basic Information',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _tripNameController,
                            decoration: const InputDecoration(labelText: 'Trip Name *'),
                            validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _destinationController,
                            decoration: const InputDecoration(labelText: 'Destination *'),
                            validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description'),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      theme,
                      icon: Icons.calendar_today_outlined,
                      title: 'Travel Dates',
                      child: _buildDateRangeField(),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      theme,
                      icon: Icons.currency_rupee,
                      title: 'Budget',
                      child: TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Budget',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionCard(
                      theme,
                      icon: Icons.local_activity_outlined,
                      title: 'Activities',
                      child: _buildActivitiesSection(),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 24.0,
                      ),
                      child: ElevatedButton.icon(
                        icon: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Icon(Icons.add, color: theme.colorScheme.onPrimary),
                        label: Text(
                          _isLoading ? 'Creating Trip...' : 'Create Trip',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        onPressed: _isLoading ? null : _createTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 56),
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

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Column(
        children: [
          Icon(Icons.flight_takeoff,
            size: 40,
            color: theme.colorScheme.primary
          ),
          const SizedBox(height: 8),
          Text(
            'Plan Your Perfect Trip',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            )
          ),
          const SizedBox(height: 4),
          Text(
            'Fill in the details below to create your dream vacation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, {required IconData icon, required String title, required Widget child}) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeField() {
    final theme = Theme.of(context);
    String displayDate;
    int duration = 0;
    if (_startDate == null || _endDate == null) {
      displayDate = 'Select Start & End Dates';
    } else {
      duration = _endDate!.difference(_startDate!).inDays + 1;
      displayDate = '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}';
    }

    return Column(
      children: [
        InkWell(
          onTap: _selectDateRange,
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayDate,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        if (duration > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 18
              ),
              const SizedBox(width: 4),
              Text(
                'Duration: $duration days',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Planned Activities',
            labelStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          child: Text(
            _plannedActivities.isEmpty
                ? 'Select from popular activities below'
                : _plannedActivities.join(', '),
            style: TextStyle(
              color: _plannedActivities.isEmpty
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Popular Activities:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: _popularActivities.map((activity) {
            final isSelected = _plannedActivities.contains(activity);
            return FilterChip(
              label: Text(
                activity,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                _toggleActivity(activity);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripx_frontend/models/trip.dart';
import 'package:tripx_frontend/repositories/trip_repository.dart';
import 'package:tripx_frontend/utils/secure_storage_service.dart';
import 'package:tripx_frontend/models/schedule.dart';
import 'package:tripx_frontend/models/expense.dart';
import 'package:tripx_frontend/models/note.dart';
import 'package:tripx_frontend/models/packing_list_item.dart';
import 'package:tripx_frontend/repositories/schedule_repository.dart';
import 'package:tripx_frontend/repositories/expense_repository.dart';
import 'package:tripx_frontend/repositories/note_repository.dart';
import 'package:tripx_frontend/repositories/packing_list_repository.dart';

enum TripStatusFilter { all, upcoming, ongoing, completed }

class TripSelectionScreen extends StatefulWidget {
  const TripSelectionScreen({super.key});

  @override
  State<TripSelectionScreen> createState() => _TripSelectionScreenState();
}

class _TripSelectionScreenState extends State<TripSelectionScreen> {
  final TripRepository _tripRepository = TripRepository();
  final SecureStorageService _storageService = SecureStorageService();
  final TextEditingController _searchController = TextEditingController();

  List<Trip>? _allTrips;
  List<Trip> _filteredTrips = [];
  bool _isLoading = true;
  String _error = '';

  TripStatusFilter _selectedFilter = TripStatusFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchTrips();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    _searchQuery = _searchController.text;
    _applyFiltersAndSearch();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final trips = await _tripRepository.getTrips();
      _allTrips = trips;
      _applyFiltersAndSearch();
    } catch (e) {
      if (e.toString().contains('Invalid token')) {
        await _storageService.deleteToken();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _refreshTrips() {
    _fetchTrips();
  }

  void _navigateToCreateTrip() async {
    final result = await Navigator.of(context).pushNamed('/create-trip');
    if (result == true) {
      _refreshTrips();
    }
  }

  void _showTripStatistics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _StatisticsSheet(trips: _allTrips ?? []);
      },
    );
  }

  void _applyFiltersAndSearch() {
    if (_allTrips == null) return;

    List<Trip> tempTrips = List.from(_allTrips!);
    final now = DateTime.now();

    switch (_selectedFilter) {
      case TripStatusFilter.upcoming:
        tempTrips = tempTrips.where((trip) => trip.startDate.isAfter(now)).toList();
        break;
      case TripStatusFilter.ongoing:
        tempTrips = tempTrips.where((trip) =>
            !trip.startDate.isAfter(now) && !trip.endDate.isBefore(now)).toList();
        break;
      case TripStatusFilter.completed:
        tempTrips = tempTrips.where((trip) => trip.endDate.isBefore(now)).toList();
        break;
      case TripStatusFilter.all:
      default:
        break;
    }

    if (_searchQuery.isNotEmpty) {
      tempTrips = tempTrips.where((trip) {
        final queryLower = _searchQuery.toLowerCase();
        final nameLower = trip.tripName.toLowerCase();
        final destinationLower = trip.destination.toLowerCase();
        return nameLower.contains(queryLower) || destinationLower.contains(queryLower);
      }).toList();
    }

    setState(() {
      _filteredTrips = tempTrips;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Trip Planner', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: theme.colorScheme.onSurface),
            onPressed: _showTripStatistics,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _refreshTrips,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCreateNewTripCard(context),
          _buildSearchBar(theme),
          _buildFilterChips(theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Trips', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                // TODO: Show trip statistics
              ],
            ),
          ),
          Expanded(
            child: _buildTripList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildTripList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error)));
    }
    if (_allTrips == null || _allTrips!.isEmpty) {
      return Center(child: Text('No trips found. Plan your first one!', style: theme.textTheme.bodyLarge));
    }
    if (_filteredTrips.isEmpty) {
      return Center(child: Text('No trips match your search or filter.', style: theme.textTheme.bodyLarge));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredTrips.length,
      itemBuilder: (context, index) {
        return _TripListItem(trip: _filteredTrips[index]);
      },
    );
  }

  Widget _buildCreateNewTripCard(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Card(
        elevation: 1,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: const Icon(Icons.add),
          ),
          title: Text('Create New Trip', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text('Plan your next adventure with ease', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          onTap: _navigateToCreateTrip,
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search trips by name or destination...',
          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
        ),
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            FilterChip(
              label: const Text('All Trips'),
              selected: _selectedFilter == TripStatusFilter.all,
              onSelected: (selected) {
                _selectedFilter = TripStatusFilter.all;
                _applyFiltersAndSearch();
              },
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              labelStyle: TextStyle(color: _selectedFilter == TripStatusFilter.all ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurface),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Upcoming'),
              selected: _selectedFilter == TripStatusFilter.upcoming,
              onSelected: (selected) {
                _selectedFilter = TripStatusFilter.upcoming;
                _applyFiltersAndSearch();
              },
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              labelStyle: TextStyle(color: _selectedFilter == TripStatusFilter.upcoming ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurface),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Ongoing'),
              selected: _selectedFilter == TripStatusFilter.ongoing,
              onSelected: (selected) {
                _selectedFilter = TripStatusFilter.ongoing;
                _applyFiltersAndSearch();
              },
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              labelStyle: TextStyle(color: _selectedFilter == TripStatusFilter.ongoing ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurface),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Completed'),
              selected: _selectedFilter == TripStatusFilter.completed,
              onSelected: (selected) {
                _selectedFilter = TripStatusFilter.completed;
                _applyFiltersAndSearch();
              },
              selectedColor: theme.colorScheme.secondaryContainer,
              checkmarkColor: theme.colorScheme.onSecondaryContainer,
              labelStyle: TextStyle(color: _selectedFilter == TripStatusFilter.completed ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripListItem extends StatelessWidget {
  final Trip trip;
  const _TripListItem({required this.trip});

  String _getTripStatus(DateTime now) {
    if (trip.endDate.isBefore(now)) {
      return 'Completed';
    } else if (trip.startDate.isAfter(now)) {
      return 'Upcoming';
    } else {
      return 'Ongoing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;
    final status = _getTripStatus(now);

    Color statusBackgroundColor;
    Color statusForegroundColor;
    switch (status) {
      case 'Completed':
        statusBackgroundColor = theme.colorScheme.surfaceContainerHighest;
        statusForegroundColor = theme.colorScheme.onSurfaceVariant;
        break;
      case 'Ongoing':
        statusBackgroundColor = theme.colorScheme.primaryContainer;
        statusForegroundColor = theme.colorScheme.onPrimaryContainer;
        break;
      case 'Upcoming':
        statusBackgroundColor = theme.colorScheme.secondaryContainer;
        statusForegroundColor = theme.colorScheme.onSecondaryContainer;
        break;
      default:
        statusBackgroundColor = theme.colorScheme.surfaceContainerHighest;
        statusForegroundColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/trip-detail-dashboard', arguments: trip);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.tripName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Text(trip.destination, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(status, style: TextStyle(color: statusForegroundColor, fontWeight: FontWeight.bold)),
                    backgroundColor: statusBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('${DateFormat.yMMMd().format(trip.startDate)} - ${DateFormat.yMMMd().format(trip.endDate)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text('$duration days', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatisticsSheet extends StatefulWidget {
  final List<Trip> trips;
  const _StatisticsSheet({required this.trips});

  @override
  State<_StatisticsSheet> createState() => _StatisticsSheetState();
}

class _StatisticsSheetState extends State<_StatisticsSheet> {
  late Future<List<dynamic>> _statisticsFuture;
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final NoteRepository _noteRepository = NoteRepository();
  final PackingListRepository _packingListRepository = PackingListRepository();

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _fetchAllStatistics();
  }

  Future<List<dynamic>> _fetchAllStatistics() async {
    final futures = widget.trips.map((trip) async {
      final schedules = await _scheduleRepository.getScheduleForTrip(trip.id);
      final expenses = await _expenseRepository.getExpensesForTrip(trip.id);
      final notes = await _noteRepository.getNotesForTrip(trip.id);
      final packingListItems = await _packingListRepository.getPackingListForTrip(trip.id);
      return {
        'schedules': schedules,
        'expenses': expenses,
        'notes': notes,
        'packingListItems': packingListItems,
        'trip': trip,
      };
    }).toList();
    return Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: FutureBuilder<List<dynamic>>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load statistics.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          final allData = snapshot.data!;

          final totalDays = allData.fold(0, (sum, data) {
            final Trip trip = data['trip'];
            return sum + (trip.endDate.difference(trip.startDate).inDays + 1);
          });
          final totalActivities = allData.fold(0, (sum, data) => sum + (data['schedules'] as List<Schedule>).length);
          final totalExpenses = allData.fold(0.0, (sum, data) => sum + (data['expenses'] as List<Expense>).fold(0.0, (subSum, e) => subSum + e.amount));
          final totalNotes = allData.fold(0, (sum, data) => sum + (data['notes'] as List<Note>).length);
          final packedItemsCount = allData.fold(0, (sum, data) => sum + (data['packingListItems'] as List<PackingListItem>).where((item) => item.isPacked).length);
          final totalItemsCount = allData.fold(0, (sum, data) => sum + (data['packingListItems'] as List<PackingListItem>).length);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Trip Statistics',
                  style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.extent(
                    maxCrossAxisExtent: 200,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Changed from 1.2 to 1.0 to give more height
                    children: [
                      _StatCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Total Trip Days',
                        value: '$totalDays',
                        color: theme.colorScheme.tertiary,
                      ),
                      _StatCard(
                        icon: Icons.checklist,
                        title: 'Activities',
                        value: '$totalActivities',
                        color: theme.colorScheme.primary,
                      ),
                      _StatCard(
                        icon: Icons.attach_money,
                        title: 'Total Expenses',
                        value: '\$${totalExpenses.toStringAsFixed(2)}',
                        color: theme.colorScheme.secondary,
                      ),
                      _StatCard(
                        icon: Icons.note,
                        title: 'Notes Added',
                        value: '$totalNotes',
                        color: theme.colorScheme.error,
                      ),
                      _StatCard(
                        icon: Icons.backpack,
                        title: 'Packing List',
                        value: '$packedItemsCount/$totalItemsCount packed',
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced from 16.0
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, // Reduced from 48
              height: 40, // Reduced from 48
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, size: 20, color: color), // Reduced from 24
            ),
            const SizedBox(height: 8), // Reduced from 12
            Flexible( // Added Flexible wrapper
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith( // Changed from labelLarge
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2, // Allow text to wrap
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4), // Reduced from default
            Flexible( // Added Flexible wrapper
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith( // Changed from headlineSmall
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2, // Allow text to wrap
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
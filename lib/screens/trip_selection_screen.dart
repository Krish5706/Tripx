import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/trip_service.dart';
import 'create_trip_screen.dart';

class TripSelectionScreen extends StatefulWidget {
  const TripSelectionScreen({super.key});

  @override
  State<TripSelectionScreen> createState() => _TripSelectionScreenState();
}

class _TripSelectionScreenState extends State<TripSelectionScreen>
    with TickerProviderStateMixin {
  final TripService _tripService = TripService();
  List<Trip> _trips = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all'; // all, upcoming, ongoing, completed
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _loadTrips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await _tripService.getAllTrips();
      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Trip> get _filteredTrips {
    List<Trip> filtered = _trips;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((trip) {
        return trip.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               trip.destination.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply status filter
    switch (_selectedFilter) {
      case 'upcoming':
        filtered = filtered.where((trip) => trip.isUpcoming).toList();
        break;
      case 'ongoing':
        filtered = filtered.where((trip) => trip.isOngoing).toList();
        break;
      case 'completed':
        filtered = filtered.where((trip) => trip.isCompleted).toList();
        break;
      default:
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text(
          'Select Trip',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadTrips,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your trips...',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCreateTripCard(colorScheme),
                      const SizedBox(height: 24),
                      _buildSearchAndFilter(colorScheme),
                      const SizedBox(height: 16),
                      _buildSectionHeader(colorScheme),
                      const SizedBox(height: 16),
                      Expanded(child: _buildTripsList(colorScheme)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCreateTripCard(ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: _navigateToCreateTrip,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.15),
                colorScheme.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_circle,
                  size: 32,
                  color: colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Trip',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan your next adventure with ease',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme) {
    return Column(
      children: [
        // Search Bar
        TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Search trips by name or destination...',
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
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
        
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'All Trips', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('upcoming', 'Upcoming', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('ongoing', 'Ongoing', colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('completed', 'Completed', colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, ColorScheme colorScheme) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme) {
    final filteredTrips = _filteredTrips;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Your Trips (${filteredTrips.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        if (_trips.isNotEmpty)
          TextButton.icon(
            onPressed: () => _showTripStats(colorScheme),
            icon: Icon(Icons.analytics, size: 16, color: colorScheme.primary),
            label: Text(
              'Stats',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildTripsList(ColorScheme colorScheme) {
    final filteredTrips = _filteredTrips;
    
    if (filteredTrips.isEmpty) {
      return _buildEmptyState(colorScheme);
    }
    
    return ListView.builder(
      itemCount: filteredTrips.length,
      itemBuilder: (context, index) {
        final trip = filteredTrips[index];
        return _buildTripCard(trip, colorScheme);
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.luggage,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No trips found'
                : _selectedFilter == 'all' 
                    ? 'No trips yet'
                    : 'No $_selectedFilter trips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Create your first trip to get started!',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _selectedFilter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateTrip,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Trip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip, ColorScheme colorScheme) {
    final statusColor = trip.isUpcoming 
        ? Colors.blue
        : trip.isOngoing 
            ? Colors.green
            : Colors.grey;
    
    final statusText = trip.isUpcoming 
        ? 'Upcoming'
        : trip.isOngoing 
            ? 'Ongoing'
            : 'Completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToSchedule(trip),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trip.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trip.destination,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat('MMM dd').format(trip.startDate)} - ${DateFormat('MMM dd, yyyy').format(trip.endDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.duration} days',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (trip.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  trip.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTripScreen(),
      ),
    );
    
    if (result == true) {
      _loadTrips(); // Refresh the trip list
    }
  }

  void _navigateToSchedule(Trip trip) {
    Navigator.pushNamed(
      context,
      '/schedule',
      arguments: {
        'tripId': trip.id,
        'tripName': trip.name,
      },
    );
  }

  Future<void> _showTripStats(ColorScheme colorScheme) async {
    final stats = await _tripService.getTripStats();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trip Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Trips', stats['total'].toString(), colorScheme),
            _buildStatRow('Upcoming', stats['upcoming'].toString(), colorScheme),
            _buildStatRow('Ongoing', stats['ongoing'].toString(), colorScheme),
            _buildStatRow('Completed', stats['completed'].toString(), colorScheme),
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

  Widget _buildStatRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

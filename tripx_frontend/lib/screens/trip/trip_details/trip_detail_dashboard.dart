import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tripx_frontend/models/trip.dart';

class TripDetailDashboard extends StatelessWidget {
  const TripDetailDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = ModalRoute.of(context)!.settings.arguments as Trip;
    final tripDates =
        '${DateFormat.yMMMd().format(trip.startDate)} - ${DateFormat.yMMMd().format(trip.endDate)}';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Trip Dashboard'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.05),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.tripName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.date_range_outlined,
                            color: theme.colorScheme.onSurfaceVariant, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          tripDates,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Trip Tools',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _FeatureCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Schedule',
                    color: theme.colorScheme.tertiary,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/schedule', arguments: trip);
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.attach_money_outlined,
                    title: 'Expenses',
                    color: theme.colorScheme.primary,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/expenses', arguments: trip);
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.check_circle_outline,
                    title: 'Packing List',
                    color: theme.colorScheme.secondary,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/packing-list', arguments: trip);
                    },
                  ),
                  _FeatureCard(
                    icon: Icons.edit_note_outlined,
                    title: 'Notes',
                    color: theme.colorScheme.error,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed('/notes', arguments: trip);
                    },
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

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                ),
                child: Center(
                  child: Icon(icon, size: 30, color: color),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
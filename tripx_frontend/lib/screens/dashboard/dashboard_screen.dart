import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isHeaderVisible = false;
  bool _isGridVisible = false;

  @override
  void initState() {
    super.initState();
    // Trigger animations with a slight delay for a staggered effect.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isHeaderVisible = true);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isGridVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const userName = "Adventurer"; // Placeholder name. Replace with dynamic data in real app.

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: const Text(
          'TripX',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 28),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
        automaticallyImplyLeading: false, // Removes back button
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(theme, userName),
            _buildFeaturesGrid(context),
          ],
        ),
      ),
    );
  }

  // Dynamic User Greeting
  Widget _buildGreeting(ThemeData theme, String userName) {
    return AnimatedOpacity(
      opacity: _isHeaderVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userName!',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your next adventure awaits.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Feature Card Builder with Dynamic Data
  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      Feature(
        icon: Icons.explore_outlined,
        title: 'Destination Ideas',
        routeName: '/destination-ideas',
      ),
      Feature(
        icon: Icons.map_outlined,
        title: 'Trip Planner',
        routeName: '/trip-selection',
      ),
      Feature(
        icon: Icons.translate,
        title: 'Translator',
        routeName: '/translator',
      ),
    ];

    return AnimatedOpacity(
      opacity: _isGridVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GridView.builder(
          itemCount: features.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final feature = features[index];
            return _FeatureCard(
              icon: feature.icon,
              title: feature.title,
              onTap: () {
                Navigator.of(context).pushNamed(feature.routeName);
              },
            );
          },
        ),
      ),
    );
  }
}

// Model for a feature
class Feature {
  final IconData icon;
  final String title;
  final String routeName;

  Feature({
    required this.icon,
    required this.title,
    required this.routeName,
  });
}

// A reusable card widget for features
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          label: title, // Add semantics for screen readers
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
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
      ),
    );
  }
}

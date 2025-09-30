import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_DashboardItem> items = [
      _DashboardItem(
        title: 'Destination Ideas',
        icon: Icons.explore,
        color: Colors.deepPurple,
        onTap: () {
          Navigator.pushNamed(context, '/destination_ideas');
        },
      ),
      // _DashboardItem(
      //   title: 'Trip Planner',
      //   icon: Icons.map,
      //   color: Colors.teal,
      //   onTap: () {
      //     Navigator.pushNamed(context, '/trip_planner');
      //   },
      // ),
      
      _DashboardItem(
        title: 'Trip Planner',
        icon: Icons.map,
        color: Colors.teal,
        onTap: () {
          Navigator.pushNamed(context, '/trip_selection');
        },
      ),

      // _DashboardItem(
      //   title: 'Daily Schedule',
      //   icon: Icons.calendar_today,
      //   color: Colors.orange,
      //   onTap: () {
      //     Navigator.pushNamed(context, '/trip_selection');
      //   },
      // ),
      _DashboardItem(
        title: 'Packing List',
        icon: Icons.checklist,
        color: Colors.indigo,
        onTap: () {
          Navigator.pushNamed(context, '/packing_list');
        },
      ),
      _DashboardItem(
        title: 'Travel Notes',
        icon: Icons.note,
        color: Colors.blueGrey,
        onTap: () {
          Navigator.pushNamed(context, '/notes');
        },
      ),
      _DashboardItem(
        title: 'Expense Tracker',
        icon: Icons.attach_money,
        color: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, '/expenses');
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TripX Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/settings');
              if (result != null) {
                // Handle result if needed
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Adventurer!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your next move below.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return _DashboardCard(item: items[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _DashboardItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DashboardCard extends StatefulWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller.drive(Tween(begin: 1.0, end: 0.95));
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward();
    widget.item.onTap();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Material(
        color: Theme.of(context).cardColor,
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        shadowColor: widget.item.color.withAlpha((0.3 * 255).toInt()),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 26, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: widget.item.color.withAlpha((0.15 * 255).toInt()),
                  radius: 30,
                  child: Icon(
                    widget.item.icon,
                    size: 30,
                    color: widget.item.color,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.item.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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

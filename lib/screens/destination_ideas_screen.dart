// lib/screens/destination_ideas_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart'; // if not installed, replace map with a placeholder
import 'package:latlong2/latlong.dart';
import '../services/destination_ideas_service.dart';

/// Screen follows the interaction style of packing_list.dart:
/// - Search in AppBar
/// - Filter chips row & filter bottom sheet
/// - Card list with primary actions (Save, Add Note, Add to Trip)
/// - FAB for sync + map toggle
class DestinationIdeasScreen extends StatefulWidget {
  const DestinationIdeasScreen({super.key});

  @override
  State<DestinationIdeasScreen> createState() => _DestinationIdeasScreenState();
}

class _DestinationIdeasScreenState extends State<DestinationIdeasScreen> {
  final _svc = DestinationIdeasService.instance;

  final _searchCtrl = TextEditingController();
  String _season = 'All';
  String _weather = '';
  final Set<String> _categories = {};
  final Set<String> _tags = {};
  bool _onlySaved = false;
  bool _showMap = false;

  // personalization inputs
  String? _userSeason;
  String? _userWeather;
  final Set<String> _userInterests = {};

  List<DestinationIdea> _all = [];
  List<DestinationIdea> _view = [];

  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final list = await _svc.syncAndGetIdeas(
        forceRefresh: false,
        userSeason: _userSeason,
        userInterests: _userInterests.toList(),
        userWeather: _userWeather,
      );
      _all = list;
      _applyFilters();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _applyFilters);
  }

  void _applyFilters() {
    final filtered = _svc.filterSort(
      _all,
      search: _searchCtrl.text,
      season: _season,
      weather: _weather,
      categories: _categories.toList(),
      tags: _tags.toList(),
      onlySaved: _onlySaved,
      trendingFirst: true,
    );
    setState(() => _view = filtered);
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final list = await _svc.syncAndGetIdeas(
        forceRefresh: true,
        userSeason: _userSeason,
        userInterests: _userInterests.toList(),
        userWeather: _userWeather,
      );
      _all = list;
      _applyFilters();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _SearchBar(
          controller: _searchCtrl,
          hint: 'Search by destination or country...',
          onClear: () {
            _searchCtrl.clear();
            _applyFilters();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.tune),
            onPressed: _openFiltersSheet,
          ),
          IconButton(
            tooltip: _onlySaved ? 'Show all' : 'Show saved only',
            icon: Icon(_onlySaved ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() => _onlySaved = !_onlySaved);
              _applyFilters();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _ChipsRow(
            season: _season,
            onSeasonChanged: (s) {
              setState(() => _season = s);
              _applyFilters();
            },
            categories: _categories,
            onCategoryToggle: (c) {
              setState(() {
                if (_categories.contains(c)) {
                  _categories.remove(c);
                } else {
                  _categories.add(c);
                }
              });
              _applyFilters();
            },
            weather: _weather,
            onWeatherChanged: (w) {
              setState(() => _weather = w);
              _applyFilters();
            },
            tags: _tags,
            onTagToggle: (t) {
              setState(() {
                if (_tags.contains(t)) {
                  _tags.remove(t);
                } else {
                  _tags.add(t);
                }
              });
              _applyFilters();
            },
          ),
          if (_loading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _showMap ? _buildMap(theme) : _buildList(theme),
          ),
        ],
      ),
      floatingActionButton: _FABStack(
        onSync: _refresh,
        mapOn: _showMap,
        onToggleMap: () {
          setState(() => _showMap = !_showMap);
        },
        onPersonalize: _openPersonalizeSheet,
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_view.isEmpty) {
      return Center(
        child: Text(
          _loading ? 'Loading destinations...' : 'No destinations match your filters.',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96, top: 8),
        itemCount: _view.length,
        itemBuilder: (context, i) {
          final d = _view[i];
          return _DestinationCard(
            idea: d,
            onSaveToggle: (val) async {
              await _svc.toggleSave(d.id, val);
              final idxAll = _all.indexWhere((x) => x.id == d.id);
              if (idxAll != -1) _all[idxAll] = _all[idxAll].copyWith(isSaved: val);
              _applyFilters();
            },
            onAddNote: () => _openNotesDialog(d),
            onAddToTrip: () => _addToTrip(d),
          );
        },
      ),
    );
  }

  Widget _buildMap(ThemeData theme) {
    if (_view.isEmpty) {
      return const Center(child: Text('No markers to show.'));
    }
    final markers = _view.where((d) => d.lat != null && d.lng != null).map((d) {
      return Marker(
        width: 44,
        height: 44,
        point: LatLng(d.lat!, d.lng!),
        child: Tooltip(
          message: '${d.name} • ${d.country}',
          child: const Icon(Icons.location_on, size: 36),
        ),
      );
    }).toList();

    final center = markers.isNotEmpty
        ? markers.first.point
        : const LatLng(20.5937, 78.9629); // India center fallback

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 3.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Future<void> _openNotesDialog(DestinationIdea d) async {
    final ctrl = TextEditingController(text: d.userNotes ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Notes • ${d.name}'),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Add your notes (what to do, where to eat, etc.)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (res != null) {
      await DestinationIdeasService.instance.updateNotes(d.id, res.isEmpty ? null : res);
      final idx = _all.indexWhere((x) => x.id == d.id);
      if (idx != -1) _all[idx] = _all[idx].copyWith(userNotes: res.isEmpty ? null : res);
      _applyFilters();
    }
  }

  void _addToTrip(DestinationIdea d) {
    // Hook this into your trips module.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${d.name} to your trip plan.')),
    );
  }

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _FiltersSheet(
        season: _season,
        onSeasonChanged: (s) {
          _season = s;
        },
        weather: _weather,
        onWeatherChanged: (w) {
          _weather = w;
        },
        categories: _categories,
        tags: _tags,
        onApply: () {
          Navigator.pop(ctx);
          _applyFilters();
        },
        onReset: () {
          _season = 'All';
          _weather = '';
          _categories.clear();
          _tags.clear();
          _onlySaved = false;
          Navigator.pop(ctx);
          _applyFilters();
        },
      ),
    );
  }

  void _openPersonalizeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        String season = _userSeason ?? '';
        String weather = _userWeather ?? '';
        final interests = Set<String>.from(_userInterests);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(title: 'Personalize Recommendations'),
              const SizedBox(height: 8),
              _LabeledField(
                label: 'Your season (e.g., Winter, Summer)',
                child: TextField(
                  controller: TextEditingController(text: season),
                  onChanged: (v) => season = v.trim(),
                  decoration: const InputDecoration(hintText: 'Winter'),
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Your weather now (e.g., Cold, Rainy)',
                child: TextField(
                  controller: TextEditingController(text: weather),
                  onChanged: (v) => weather = v.trim(),
                  decoration: const InputDecoration(hintText: 'Cold'),
                ),
              ),
              const SizedBox(height: 12),
              _InterestsChips(
                selected: interests,
                onToggle: (s) {
                  if (interests.contains(s)) {
                    interests.remove(s);
                  } else {
                    interests.add(s);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        _userSeason = season.isEmpty ? null : season;
                        _userWeather = weather.isEmpty ? null : weather;
                        _userInterests
                          ..clear()
                          ..addAll(interests);
                        Navigator.pop(ctx);
                        await _refresh();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------- UI components ----------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  final String season;
  final ValueChanged<String> onSeasonChanged;

  final Set<String> categories;
  final void Function(String) onCategoryToggle;

  final String weather;
  final ValueChanged<String> onWeatherChanged;

  final Set<String> tags;
  final void Function(String) onTagToggle;

  const _ChipsRow({
    required this.season,
    required this.onSeasonChanged,
    required this.categories,
    required this.onCategoryToggle,
    required this.weather,
    required this.onWeatherChanged,
    required this.tags,
    required this.onTagToggle,
  });

  @override
  Widget build(BuildContext context) {
    const seasonOptions = ['All', 'Spring', 'Summer', 'Fall', 'Winter'];
    const categoryOptions = ['Beach', 'Mountains', 'City', 'Adventure', 'Cultural', 'General'];
    const tagOptions = ['Family-friendly', 'Budget', 'Luxury', 'Historic', 'Scenic', 'Wellness'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          DropdownButton<String>(
            value: seasonOptions.contains(season) ? season : 'All',
            items: seasonOptions
                .map((s) => DropdownMenuItem(value: s, child: Text('Season: $s')))
                .toList(),
            onChanged: (v) => onSeasonChanged(v ?? 'All'),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: Row(
              children: categoryOptions.map((c) {
                final sel = categories.contains(c);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c),
                    selected: sel,
                    onSelected: (_) => onCategoryToggle(c),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: Row(
              children: tagOptions.map((t) {
                final sel = tags.contains(t);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(t),
                    selected: sel,
                    onSelected: (_) => onTagToggle(t),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: TextField(
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Weather filter',
                hintText: 'Sunny / Rainy…',
                border: OutlineInputBorder(),
              ),
              onChanged: onWeatherChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final DestinationIdea idea;
  final ValueChanged<bool> onSaveToggle;
  final VoidCallback onAddNote;
  final VoidCallback onAddToTrip;

  const _DestinationCard({
    required this.idea,
    required this.onSaveToggle,
    required this.onAddNote,
    required this.onAddToTrip,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAddToTrip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(url: idea.imageUrl, fallbackText: idea.name),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${idea.name} • ${idea.country}',
                        style: t.textTheme.titleMedium),
                  ),
                  Tooltip(
                    message: 'Trending score: ${idea.score.toStringAsFixed(0)}',
                    child: const Icon(Icons.trending_up, size: 18),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: -8,
                children: [
                  _Pill(icon: Icons.category, text: idea.category),
                  _Pill(icon: Icons.calendar_month, text: 'Best: ${idea.bestSeason}'),
                  if (idea.currentWeather != null && idea.currentWeather!.isNotEmpty)
                    _Pill(icon: Icons.wb_sunny, text: idea.currentWeather!),
                  ...idea.tags.take(4).map((e) => _Pill(icon: Icons.label, text: e)),
                ],
              ),
            ),
            if (idea.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Text(
                  idea.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: idea.isSaved ? 'Unsave' : 'Save',
                    icon: Icon(idea.isSaved ? Icons.favorite : Icons.favorite_border),
                    onPressed: () => onSaveToggle(!idea.isSaved),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.note_alt_outlined),
                    label: const Text('Notes'),
                    onPressed: onAddNote,
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Trip'),
                    onPressed: onAddToTrip,
                  ),
                  const Spacer(),
                  if (idea.lat != null && idea.lng != null)
                    IconButton(
                      tooltip: 'Open in Maps',
                      icon: const Icon(Icons.map),
                      onPressed: () {
                        // Navigate to your map screen or deep link; placeholder snackbar:
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Map: ${idea.lat}, ${idea.lng}')),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String url;
  final String fallbackText;
  const _HeroImage({required this.url, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Text(
              fallbackText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Image.network(url, fit: BoxFit.cover),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _FABStack extends StatelessWidget {
  final VoidCallback onSync;
  final bool mapOn;
  final VoidCallback onToggleMap;
  final VoidCallback onPersonalize;

  const _FABStack({
    required this.onSync,
    required this.mapOn,
    required this.onToggleMap,
    required this.onPersonalize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: 'fab-sync',
          onPressed: onSync,
          label: const Text('Sync'),
          icon: const Icon(Icons.sync),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'fab-map',
          onPressed: onToggleMap,
          label: Text(mapOn ? 'List' : 'Map'),
          icon: Icon(mapOn ? Icons.list : Icons.map),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          heroTag: 'fab-personalize',
          onPressed: onPersonalize,
          label: const Text('Personalize'),
          icon: const Icon(Icons.auto_fix_high),
        ),
      ],
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  final String season;
  final ValueChanged<String> onSeasonChanged;
  final String weather;
  final ValueChanged<String> onWeatherChanged;
  final Set<String> categories;
  final Set<String> tags;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _FiltersSheet({
    required this.season,
    required this.onSeasonChanged,
    required this.weather,
    required this.onWeatherChanged,
    required this.categories,
    required this.tags,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String _season;
  late TextEditingController _weatherCtrl;
  late Set<String> _categories;
  late Set<String> _tags;

  @override
  void initState() {
    super.initState();
    _season = widget.season;
    _weatherCtrl = TextEditingController(text: widget.weather);
    _categories = Set.of(widget.categories);
    _tags = Set.of(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    const seasonOptions = ['All', 'Spring', 'Summer', 'Fall', 'Winter'];
    const categoryOptions = ['Beach', 'Mountains', 'City', 'Adventure', 'Cultural', 'General'];
    const tagOptions = ['Family-friendly', 'Budget', 'Luxury', 'Historic', 'Scenic', 'Wellness'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHeader(title: 'Filters'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _season,
            items: seasonOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _season = v ?? 'All'),
            decoration: const InputDecoration(labelText: 'Best season'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weatherCtrl,
            decoration: const InputDecoration(
              labelText: 'Weather contains',
              hintText: 'Sunny / Rainy / Snowy…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _CheckGroup(
            title: 'Categories',
            options: categoryOptions,
            selected: _categories,
            onToggle: (s) => setState(() {
              if (_categories.contains(s)) {
                _categories.remove(s);
              } else {
                _categories.add(s);
              }
            }),
          ),
          const SizedBox(height: 12),
          _CheckGroup(
            title: 'Tags',
            options: tagOptions,
            selected: _tags,
            onToggle: (s) => setState(() {
              if (_tags.contains(s)) {
                _tags.remove(s);
              } else {
                _tags.add(s);
              }
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onReset();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onSeasonChanged(_season);
                    widget.onWeatherChanged(_weatherCtrl.text.trim());
                    widget.categories
                      ..clear()
                      ..addAll(_categories);
                    widget.tags
                      ..clear()
                      ..addAll(_tags);
                    widget.onApply();
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600));
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _InterestsChips extends StatelessWidget {
  final Set<String> selected;
  final void Function(String) onToggle;

  const _InterestsChips({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const ints = [
      'Beach',
      'Mountains',
      'Cultural',
      'Adventure',
      'City',
      'Family-friendly',
      'Budget',
      'Luxury',
      'Historic',
      'Scenic',
      'Wellness',
    ];
    return Wrap(
      spacing: 6,
      children: ints.map((e) {
        final sel = selected.contains(e);
        return FilterChip(
          label: Text(e),
          selected: sel,
          onSelected: (_) => onToggle(e),
        );
      }).toList(),
    );
  }
}

class _CheckGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _CheckGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: options.map((e) {
            final sel = selected.contains(e);
            return FilterChip(
              label: Text(e),
              selected: sel,
              onSelected: (_) => onToggle(e),
            );
          }).toList(),
        ),
      ],
    );
  }
}

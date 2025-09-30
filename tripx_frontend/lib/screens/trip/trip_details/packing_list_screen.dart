import 'package:flutter/material.dart';
import 'package:tripx_frontend/models/packing_list_item.dart';
import 'package:tripx_frontend/models/trip.dart';
import 'package:tripx_frontend/repositories/packing_list_repository.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen> {
  late Future<List<PackingListItem>> _itemsFuture;
  final PackingListRepository _repository = PackingListRepository();
  late Trip _trip;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  FilterOptions _filter = FilterOptions.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trip = ModalRoute.of(context)!.settings.arguments as Trip;
    _itemsFuture = _fetchAndGenerateItems();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PackingListItem>> _fetchAndGenerateItems() async {
    List<PackingListItem> existingItems =
        await _repository.getPackingListForTrip(_trip.id);

    if (existingItems.isNotEmpty) {
      return existingItems;
    }

    List<PackingListItem> generatedItems = _generateSmartList(_trip);
    for (var item in generatedItems) {
      await _repository.createPackingListItem(
        tripId: _trip.id,
        itemName: item.itemName,
        category: item.category,
      );
    }
    return _repository.getPackingListForTrip(_trip.id);
  }

  void _refreshItems() {
    setState(() {
      _itemsFuture = _fetchItems();
    });
  }

  Future<List<PackingListItem>> _fetchItems() async {
    return _repository.getPackingListForTrip(_trip.id);
  }

  void _updateItem(PackingListItem item, bool isPacked) async {
    try {
      await _repository.updatePackingListItem(item.id, isPacked);
      setState(() {
        item.isPacked = isPacked;
      });
    } catch (e) {
      // Handle error
    }
  }

  void _deleteItem(String itemId) async {
    try {
      await _repository.deletePackingListItem(itemId);
      _refreshItems();
    } catch (e) {
      // Handle error
    }
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        tripId: _trip.id,
        onSave: _refreshItems,
      ),
    );
  }

  List<PackingListItem> _getFilteredItems(List<PackingListItem> allItems) {
    var filteredItems = allItems.where((item) {
      final matchesSearch =
          item.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == FilterOptions.all ||
          (_filter == FilterOptions.unpacked && !item.isPacked) ||
          (_filter == FilterOptions.packed && item.isPacked);
      return matchesSearch && matchesFilter;
    }).toList();
    // Sort items so packed items go to the bottom
    filteredItems.sort(
        (a, b) => a.isPacked == b.isPacked ? 0 : a.isPacked ? 1 : -1);
    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Packing List for ${_trip.tripName}',
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<List<PackingListItem>>(
        future: _itemsFuture,
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

          final allItems = snapshot.data!;
          final filteredItems = _getFilteredItems(allItems);

          return Column(
            children: [
              _buildSearchBarAndFilters(theme),
              _buildProgressBar(theme, allItems),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: filteredItems.isEmpty
                      ? _buildEmptyState(theme,
                          message: 'No items match your search or filter.')
                      : _buildPackedItemList(theme, filteredItems),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBarAndFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<FilterOptions>(
            segments: const <ButtonSegment<FilterOptions>>[
              ButtonSegment<FilterOptions>(
                value: FilterOptions.all,
                label: Text('All'),
              ),
              ButtonSegment<FilterOptions>(
                value: FilterOptions.unpacked,
                label: Text('Unpacked'),
              ),
              ButtonSegment<FilterOptions>(
                value: FilterOptions.packed,
                label: Text('Packed'),
              ),
            ],
            selected: <FilterOptions>{_filter},
            onSelectionChanged: (Set<FilterOptions> newSelection) {
              setState(() {
                _filter = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.secondaryContainer,
              selectedForegroundColor: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, List<PackingListItem> allItems) {
    final totalItems = allItems.length;
    final packedItems = allItems.where((item) => item.isPacked).length;
    final progress = totalItems > 0 ? packedItems / totalItems : 0.0;
    final formattedProgress = NumberFormat.percentPattern().format(progress);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Packing Progress', style: theme.textTheme.labelLarge),
              Semantics(
                label: '$packedItems of $totalItems items packed',
                child: Text('$packedItems / $totalItems Packed',
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                formattedProgress,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackedItemList(ThemeData theme, List<PackingListItem> items) {
    final groupedItems =
        groupBy(items, (PackingListItem item) => item.category);
    final categories = groupedItems.keys.toList();

    return ListView.builder(
      itemCount: categories.length,
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
      itemBuilder: (context, index) {
        final category = categories[index];
        final itemsForCategory = groupedItems[category]!;
        return Card(
          elevation: 1,
          color: theme.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            children: itemsForCategory.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListTile(
                  title: Text(item.itemName),
                  leading: Checkbox(
                    value: item.isPacked,
                    onChanged: (bool? value) {
                      _updateItem(item, value ?? false);
                    },
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return theme.colorScheme.primary;
                      }
                      return theme.colorScheme.onSurfaceVariant;
                    }),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    onPressed: () => _deleteItem(item.id),
                    tooltip: 'Delete item',
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme,
      {String message = 'Your packing list is empty.'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            message,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (message == 'Your packing list is empty.')
            Text(
              'Tap the "Add Item" button to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  List<PackingListItem> _generateSmartList(Trip trip) {
    List<PackingListItem> smartList = [];
    smartList.addAll([
      // Travel Documents
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Passport',
          category: 'Travel Documents',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Visa (if required)',
          category: 'Travel Documents',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'ID card / Driver\'s license',
          category: 'Travel Documents',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Travel insurance',
          category: 'Travel Documents',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Flight tickets',
          category: 'Travel Documents',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Hotel booking confirmations',
          category: 'Travel Documents',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Itinerary / Travel plans',
          category: 'Travel Documents',
          isPacked: false),
      // Electronics
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Phone charger',
          category: 'Electronics',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Portable power bank',
          category: 'Electronics',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Headphones',
          category: 'Electronics',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Universal travel adapter',
          category: 'Electronics',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Camera',
          category: 'Electronics',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Laptop/Tablet & charger',
          category: 'Electronics',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'USB cable',
          category: 'Electronics',
          isPacked: false),
      // Toiletries
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Toothbrush & toothpaste',
          category: 'Toiletries',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Shampoo & conditioner',
          category: 'Toiletries',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Soap / body wash',
          category: 'Toiletries',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Deodorant',
          category: 'Toiletries',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Razor & shaving cream',
          category: 'Toiletries',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Sunscreen',
          category: 'Toiletries',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Face wash & moisturizer',
          category: 'Toiletries',
          isPacked: false),
      // Clothing
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Shirts',
          category: 'Clothing',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Pants',
          category: 'Clothing',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Jacket',
          category: 'Clothing',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Socks',
          category: 'Clothing',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Underwear',
          category: 'Clothing',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Shoes',
          category: 'Clothing',
          isPacked: false),
      // Medicines & Health
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'First aid kit',
          category: 'Medicines & Health',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Prescribed medicines',
          category: 'Medicines & Health',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Band-aids',
          category: 'Medicines & Health',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Hand sanitizer',
          category: 'Medicines & Health',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Pain relievers',
          category: 'Medicines & Health',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Vitamins',
          category: 'Medicines & Health',
          isPacked: false),
      // Snacks & Food
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Protein bars',
          category: 'Snacks & Food',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Chips / nuts',
          category: 'Snacks & Food',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Gum',
          category: 'Snacks & Food',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Refillable water bottle',
          category: 'Snacks & Food',
          isPacked: false),
      // Entertainment
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Book / magazine',
          category: 'Entertainment',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Playing cards',
          category: 'Entertainment',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Kindle',
          category: 'Entertainment',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Notebook & pen',
          category: 'Entertainment',
          isPacked: false),
      // Baby/Kids Essentials
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Diapers',
          category: 'Baby/Kids Essentials',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Baby wipes',
          category: 'Baby/Kids Essentials',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Baby food',
          category: 'Baby/Kids Essentials',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Toys',
          category: 'Baby/Kids Essentials',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Stroller',
          category: 'Baby/Kids Essentials',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Baby clothes',
          category: 'Baby/Kids Essentials',
          isPacked: false),
      // Beach/Adventure Gear
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Sunglasses',
          category: 'Beach/Adventure Gear',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Snorkel',
          category: 'Beach/Adventure Gear',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Hiking shoes',
          category: 'Beach/Adventure Gear',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Camping tent',
          category: 'Beach/Adventure Gear',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Flashlight',
          category: 'Beach/Adventure Gear',
          isPacked: false),
      // Miscellaneous
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Umbrella',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Sewing kit',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Ziplock bags',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Travel pillow',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Eye mask',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Earplugs',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Laundry bag',
          category: 'Miscellaneous',
          isPacked: false),
      PackingListItem(
          id: '',
          tripId: trip.id,
          itemName: 'Safety locks',
          category: 'Miscellaneous',
          isPacked: false),
    ]);
    String destinationLower = trip.destination.toLowerCase();
    if (destinationLower.contains('beach') ||
        destinationLower.contains('goa') ||
        destinationLower.contains('summer')) {
      smartList.addAll([
        PackingListItem(
            id: '',
            tripId: trip.id,
            itemName: 'Swimwear',
            category: 'Clothing',
            isPacked: false),
        PackingListItem(
            id: '',
            tripId: trip.id,
            itemName: 'Hat',
            category: 'Clothing',
            isPacked: false),
      ]);
    }
    if (destinationLower.contains('snow') ||
        destinationLower.contains('winter') ||
        destinationLower.contains('mountain')) {
      smartList.addAll([
        PackingListItem(
            id: '',
            tripId: trip.id,
            itemName: 'Gloves',
            category: 'Clothing',
            isPacked: false),
        PackingListItem(
            id: '',
            tripId: trip.id,
            itemName: 'Scarf',
            category: 'Clothing',
            isPacked: false),
      ]);
    }
    return smartList;
  }
}

enum FilterOptions { all, unpacked, packed }

class _AddItemDialog extends StatefulWidget {
  final String tripId;
  final VoidCallback onSave;

  const _AddItemDialog({required this.tripId, required this.onSave});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final PackingListRepository _repository = PackingListRepository();
  final TextEditingController _categoryController = TextEditingController();

  final List<String> _defaultCategories = [
    'Travel Documents',
    'Electronics',
    'Toiletries',
    'Clothing',
    'Medicines & Health',
    'Snacks & Food',
    'Entertainment',
    'Baby/Kids Essentials',
    'Beach/Adventure Gear',
    'Miscellaneous',
    'Other...',
  ];
  String? _selectedCategory;
  bool _showCustomCategoryField = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _customCategoryController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveItem() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String finalCategory;
        if (_showCustomCategoryField) {
          finalCategory = _customCategoryController.text;
        } else {
          finalCategory = _selectedCategory ?? 'Miscellaneous';
        }

        await _repository.createPackingListItem(
          tripId: widget.tripId,
          itemName: _itemNameController.text,
          category: finalCategory,
        );
        widget.onSave();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        'Add New Item',
        style: theme.textTheme.titleLarge,
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
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
              DropdownMenu<String>(
                controller: _categoryController,
                label: const Text('Category'),
                dropdownMenuEntries: _defaultCategories
                    .map<DropdownMenuEntry<String>>((String category) {
                  return DropdownMenuEntry<String>(
                      value: category, label: category);
                }).toList(),
                onSelected: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                    if (newValue == 'Other...') {
                      _showCustomCategoryField = true;
                    } else {
                      _showCustomCategoryField = false;
                    }
                  });
                },
                initialSelection: _selectedCategory,
                width: MediaQuery.of(context).size.width * 0.7,
              ),
              if (_showCustomCategoryField)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextFormField(
                    controller: _customCategoryController,
                    decoration: InputDecoration(
                      labelText: 'New Category Name',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (_showCustomCategoryField &&
                          (value == null || value.isEmpty)) {
                        return 'Please enter a category name';
                      }
                      return null;
                    },
                  ),
                ),
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
          onPressed: _saveItem,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
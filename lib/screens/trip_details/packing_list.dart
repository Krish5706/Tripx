import 'package:flutter/material.dart';

class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<PackingItem> _allItems = [];
  List<PackingItem> _filteredItems = [];
  String _selectedCategory = 'All';
  bool _showOnlyPacked = false;
  bool _showOnlyUnpacked = false;

  // Pre-defined categories with suggested items
  final Map<String, List<String>> _categoryTemplates = {
    'Clothing': [
      'T-shirts',
      'Pants/Jeans',
      'Underwear',
      'Socks',
      'Pajamas',
      'Jacket/Coat',
      'Shoes',
      'Sandals',
      'Dress/Formal wear',
      'Swimwear'
    ],
    'Toiletries': [
      'Toothbrush',
      'Toothpaste',
      'Shampoo',
      'Soap/Body wash',
      'Deodorant',
      'Sunscreen',
      'Medications',
      'Contact lenses',
      'Razor',
      'Makeup'
    ],
    'Electronics': [
      'Phone charger',
      'Power bank',
      'Camera',
      'Headphones',
      'Laptop/Tablet',
      'Travel adapter',
      'Cables',
      'Memory cards',
      'Portable speaker'
    ],
    'Documents': [
      'Passport',
      'ID/Driver\'s license',
      'Tickets',
      'Hotel confirmations',
      'Travel insurance',
      'Visa',
      'Credit cards',
      'Cash',
      'Emergency contacts',
      'Itinerary'
    ],
    'Essentials': [
      'Wallet',
      'Keys',
      'Sunglasses',
      'Watch',
      'Umbrella',
      'First aid kit',
      'Snacks',
      'Water bottle',
      'Travel pillow',
      'Eye mask'
    ]
  };

  final List<String> _categories = ['All', 'Clothing', 'Toiletries', 'Electronics', 'Documents', 'Essentials'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeWithSampleData();
    _filteredItems = List.from(_allItems);
  }

  void _initializeWithSampleData() {
    // Add some sample items for demonstration
    _allItems = [
      PackingItem(name: 'Passport', category: 'Documents', priority: Priority.high),
      PackingItem(name: 'Phone charger', category: 'Electronics', priority: Priority.medium),
      PackingItem(name: 'T-shirts', category: 'Clothing', quantity: 3),
      PackingItem(name: 'Sunscreen', category: 'Toiletries', priority: Priority.medium),
    ];
  }

  @override
  void dispose() {
    _itemController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _addItem(String name, String category, {int quantity = 1, Priority priority = Priority.medium}) {
    if (name.trim().isEmpty) return;

    setState(() {
      _allItems.add(PackingItem(
        name: name.trim(),
        category: category,
        quantity: quantity,
        priority: priority,
      ));
      _filterItems();
    });
    _itemController.clear();
  }

  void _toggleItemPacked(int index) {
    setState(() {
      _filteredItems[index].isPacked = !_filteredItems[index].isPacked;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      PackingItem itemToDelete = _filteredItems[index];
      _allItems.remove(itemToDelete);
      _filterItems();
    });
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        bool matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
        bool matchesSearch = _searchController.text.isEmpty ||
            item.name.toLowerCase().contains(_searchController.text.toLowerCase());
        bool matchesPackedFilter = (!_showOnlyPacked && !_showOnlyUnpacked) ||
            (_showOnlyPacked && item.isPacked) ||
            (_showOnlyUnpacked && !item.isPacked);

        return matchesCategory && matchesSearch && matchesPackedFilter;
      }).toList();

      // Sort by priority and then by name
      _filteredItems.sort((a, b) {
        int priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return a.name.compareTo(b.name);
      });
    });
  }

  void _showAddItemDialog() {
    String selectedCategory = 'Clothing';
    int quantity = 1;
    Priority priority = Priority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.skip(1).map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                                        }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: quantity.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        quantity = int.tryParse(value) ?? 1;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<Priority>(
                      value: priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: Priority.values.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                color: _getPriorityColor(p),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  p.name.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          priority = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addItem(_itemController.text, selectedCategory,
                    quantity: quantity, priority: priority);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add from Templates'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _categoryTemplates.keys.length,
            itemBuilder: (context, index) {
              String category = _categoryTemplates.keys.elementAt(index);
              List<String> items = _categoryTemplates[category]!;
              
              return ExpansionTile(
                title: Text(category),
                leading: Icon(_getCategoryIcon(category)),
                children: items.map((item) {
                  bool alreadyExists = _allItems.any((existingItem) => 
                      existingItem.name.toLowerCase() == item.toLowerCase());
                  
                  return ListTile(
                    title: Text(item),
                    trailing: alreadyExists 
                        ? const Icon(Icons.check, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              _addItem(item, category);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added $item to packing list')),
                              );
                            },
                          ),
                    enabled: !alreadyExists,
                  );
                }).toList(),
              );
            },
          ),
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

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Clothing':
        return Icons.checkroom;
      case 'Toiletries':
        return Icons.soap;
      case 'Electronics':
        return Icons.devices;
      case 'Documents':
        return Icons.description;
      case 'Essentials':
        return Icons.star;
      default:
        return Icons.category;
    }
  }

  void _showStatsDialog() {
    int totalItems = _allItems.length;
    int packedItems = _allItems.where((item) => item.isPacked).length;
    int unpackedItems = totalItems - packedItems;
    double progress = totalItems > 0 ? packedItems / totalItems : 0;

    Map<String, int> categoryStats = {};
    for (String category in _categories.skip(1)) {
      categoryStats[category] = _allItems.where((item) => item.category == category).length;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Packing Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress: ${(progress * 100).toInt()}%'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text('Total Items: $totalItems'),
            Text('Packed: $packedItems', style: const TextStyle(color: Colors.green)),
            Text('Remaining: $unpackedItems', style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 16),
            const Text('By Category:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...categoryStats.entries.map((entry) => 
              Text('${entry.key}: ${entry.value}')),
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

  @override
  Widget build(BuildContext context) {
    int packedCount = _allItems.where((item) => item.isPacked).length;
    int totalCount = _allItems.length;
    double progress = totalCount > 0 ? packedCount / totalCount : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packing List'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatsDialog,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Clear All'),
                onTap: () {
                  setState(() {
                    _allItems.clear();
                    _filterItems();
                  });
                },
              ),
              PopupMenuItem(
                child: const Text('Mark All Packed'),
                onTap: () {
                  setState(() {
                    for (var item in _allItems) {
                      item.isPacked = true;
                    }
                  });
                },
              ),
              PopupMenuItem(
                child: const Text('Mark All Unpacked'),
                onTap: () {
                  setState(() {
                    for (var item in _allItems) {
                      item.isPacked = false;
                    }
                  });
                },
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$packedCount of $totalCount items packed',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterItems();
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => _filterItems(),
                ),
                const SizedBox(height: 12),
                
                // Filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filters
                      ..._categories.map((category) {
                        bool isSelected = _selectedCategory == category;
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
                          ),
                        );
                      }),
                      
                      const SizedBox(width: 16),
                      
                      // Status Filters
                      FilterChip(
                        label: const Text('Packed'),
                        selected: _showOnlyPacked,
                        onSelected: (selected) {
                          setState(() {
                            _showOnlyPacked = selected;
                            if (selected) _showOnlyUnpacked = false;
                            _filterItems();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Unpacked'),
                        selected: _showOnlyUnpacked,
                        onSelected: (selected) {
                          setState(() {
                            _showOnlyUnpacked = selected;
                            if (selected) _showOnlyPacked = false;
                            _filterItems();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.luggage,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _allItems.isEmpty
                              ? 'No items in your packing list'
                              : 'No items match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _allItems.isEmpty
                              ? 'Add some items to get started!'
                              : 'Try adjusting your search or filters',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      PackingItem item = _filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isPacked,
                            onChanged: (value) => _toggleItemPacked(index),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isPacked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: item.isPacked
                                  ? Colors.grey.shade600
                                  : Colors.black,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(item.category),
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(item.category),
                              if (item.quantity > 1) ...[
                                const SizedBox(width: 8),
                                Text('× ${item.quantity}'),
                              ],
                              const SizedBox(width: 8),
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: _getPriorityColor(item.priority),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.priority.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getPriorityColor(item.priority),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () {
                                  // Edit functionality can be implemented here
                                },
                              ),
                              PopupMenuItem(
                                child: const Text('Delete'),
                                onTap: () => _deleteItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "templates",
            mini: true,
            onPressed: _showTemplateDialog,
            backgroundColor: Colors.blue.shade300,
            child: const Icon(Icons.list_alt),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "add",
            onPressed: _showAddItemDialog,
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

enum Priority { low, medium, high }

class PackingItem {
  String name;
  String category;
  bool isPacked;
  int quantity;
  Priority priority;
  DateTime createdAt;

  PackingItem({
    required this.name,
    required this.category,
    this.isPacked = false,
    this.quantity = 1,
    this.priority = Priority.medium,
  }) : createdAt = DateTime.now();
}
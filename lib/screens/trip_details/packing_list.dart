import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/packing_service.dart';

class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  final PackingService _packingService = PackingService();
  List<PackingItem> _allItems = [];
  List<PackingItem> _filteredItems = [];
  String _selectedCategory = 'All';
  bool _showOnlyPacked = false;
  bool _showOnlyUnpacked = false;
  String _sortBy = 'Priority';
  bool _showFab = true;
  Timer? _scrollTimer;

  // Category definitions for filtering
  final List<String> _categories = [
    'All',
    'Clothing',
    'Toiletries',
    'Electronics',
    'Documents',
    'Essentials',
    'Baby Essentials',
    'Children\'s Items',
    'Elderly Care',
    'Couple Items',
    'Business Travel',
    'Adventure/Outdoor',
    'Beach/Summer',
    'Winter/Ski',
    'Medical/Health',
    'Photography',
    'Sports/Fitness',
    'Entertainment',
    'Kitchen/Food',
    'Accessories',
  ];

  // Category templates with predefined items
  final Map<String, List<Map<String, String>>> _categoryTemplates = {
    'Clothing': [
      {'name': 'T-shirts', 'description': 'Casual wear'},
      {'name': 'Jeans', 'description': 'Comfortable pants'},
      {'name': 'Underwear', 'description': 'Essential undergarments'},
      {'name': 'Socks', 'description': 'Foot comfort'},
      {'name': 'Jacket', 'description': 'Weather protection'},
      {'name': 'Pajamas', 'description': 'Sleepwear'},
      {'name': 'Shoes', 'description': 'Footwear'},
      {'name': 'Dress', 'description': 'Formal/casual dress'},
      {'name': 'Shorts', 'description': 'Summer wear'},
      {'name': 'Sweater', 'description': 'Warm clothing'},
    ],
    'Toiletries': [
      {'name': 'Toothbrush', 'description': 'Dental hygiene'},
      {'name': 'Toothpaste', 'description': 'Dental care'},
      {'name': 'Shampoo', 'description': 'Hair care'},
      {'name': 'Conditioner', 'description': 'Hair treatment'},
      {'name': 'Body Wash', 'description': 'Body cleaning'},
      {'name': 'Deodorant', 'description': 'Personal hygiene'},
      {'name': 'Towel', 'description': 'Drying'},
      {'name': 'Razor', 'description': 'Shaving'},
      {'name': 'Moisturizer', 'description': 'Skin care'},
      {'name': 'Sunscreen', 'description': 'Sun protection'},
    ],
    'Electronics': [
      {'name': 'Phone Charger', 'description': 'Device charging'},
      {'name': 'Laptop', 'description': 'Computing device'},
      {'name': 'Camera', 'description': 'Photography'},
      {'name': 'Headphones', 'description': 'Audio device'},
      {'name': 'Power Bank', 'description': 'Portable charging'},
      {'name': 'Tablet', 'description': 'Portable computer'},
      {'name': 'E-reader', 'description': 'Digital books'},
      {'name': 'Travel Adapter', 'description': 'Power conversion'},
    ],
    'Documents': [
      {'name': 'Passport', 'description': 'Travel identification'},
      {'name': 'Tickets', 'description': 'Travel documents'},
      {'name': 'ID Card', 'description': 'Identification'},
      {'name': 'Insurance', 'description': 'Travel insurance'},
      {'name': 'Visa', 'description': 'Entry permit'},
      {'name': 'Driver\'s License', 'description': 'Driving permit'},
      {'name': 'Hotel Reservations', 'description': 'Booking confirmations'},
      {'name': 'Emergency Contacts', 'description': 'Important numbers'},
    ],
    'Essentials': [
      {'name': 'Money', 'description': 'Currency'},
      {'name': 'Credit Cards', 'description': 'Payment cards'},
      {'name': 'Keys', 'description': 'Access items'},
      {'name': 'Medications', 'description': 'Health items'},
      {'name': 'First Aid Kit', 'description': 'Emergency medical'},
      {'name': 'Snacks', 'description': 'Food items'},
      {'name': 'Water Bottle', 'description': 'Hydration'},
      {'name': 'Hand Sanitizer', 'description': 'Hygiene'},
    ],
    'Baby Essentials': [
      {'name': 'Diapers', 'description': 'Baby hygiene'},
      {'name': 'Baby Wipes', 'description': 'Cleaning'},
      {'name': 'Baby Formula', 'description': 'Feeding'},
      {'name': 'Baby Bottles', 'description': 'Feeding bottles'},
      {'name': 'Baby Clothes', 'description': 'Infant clothing'},
      {'name': 'Pacifier', 'description': 'Soothing item'},
      {'name': 'Baby Food', 'description': 'Nutrition'},
      {'name': 'Stroller', 'description': 'Transportation'},
      {'name': 'Car Seat', 'description': 'Safety'},
      {'name': 'Baby Blanket', 'description': 'Comfort'},
      {'name': 'Diaper Bag', 'description': 'Storage'},
      {'name': 'Baby Monitor', 'description': 'Safety device'},
    ],
    'Children\'s Items': [
      {'name': 'Toys', 'description': 'Entertainment'},
      {'name': 'Coloring Books', 'description': 'Activity books'},
      {'name': 'Crayons', 'description': 'Art supplies'},
      {'name': 'Games', 'description': 'Travel games'},
      {'name': 'Tablet/iPad', 'description': 'Digital entertainment'},
      {'name': 'Snacks', 'description': 'Kid-friendly food'},
      {'name': 'Extra Clothes', 'description': 'Backup clothing'},
      {'name': 'Comfort Item', 'description': 'Stuffed animal/blanket'},
      {'name': 'Children\'s Books', 'description': 'Reading material'},
    ],
    'Elderly Care': [
      {'name': 'Prescription Medications', 'description': 'Daily medicines'},
      {'name': 'Pill Organizer', 'description': 'Medication management'},
      {'name': 'Walking Cane', 'description': 'Mobility aid'},
      {'name': 'Compression Socks', 'description': 'Circulation help'},
      {'name': 'Reading Glasses', 'description': 'Vision aid'},
      {'name': 'Hearing Aid', 'description': 'Hearing assistance'},
      {'name': 'Blood Pressure Monitor', 'description': 'Health monitoring'},
      {'name': 'Comfortable Shoes', 'description': 'Supportive footwear'},
      {'name': 'Cushion', 'description': 'Comfort support'},
    ],
    'Couple Items': [
      {'name': 'Romantic Dinner Outfit', 'description': 'Special occasion wear'},
      {'name': 'Perfume/Cologne', 'description': 'Fragrance'},
      {'name': 'Jewelry', 'description': 'Accessories'},
      {'name': 'Camera for Photos', 'description': 'Memory capture'},
      {'name': 'Massage Oil', 'description': 'Relaxation'},
      {'name': 'Wine/Champagne', 'description': 'Celebration'},
      {'name': 'Candles', 'description': 'Ambiance'},
      {'name': 'Lingerie', 'description': 'Intimate wear'},
      {'name': 'Couple\'s Games', 'description': 'Entertainment'},
    ],
    'Business Travel': [
      {'name': 'Business Suit', 'description': 'Professional attire'},
      {'name': 'Dress Shoes', 'description': 'Formal footwear'},
      {'name': 'Laptop Bag', 'description': 'Professional carrier'},
      {'name': 'Business Cards', 'description': 'Networking'},
      {'name': 'Presentation Materials', 'description': 'Work documents'},
      {'name': 'Portable Printer', 'description': 'Document printing'},
      {'name': 'Conference Badge', 'description': 'Event access'},
      {'name': 'Professional Portfolio', 'description': 'Document organizer'},
    ],
    'Adventure/Outdoor': [
      {'name': 'Hiking Boots', 'description': 'Trail footwear'},
      {'name': 'Backpack', 'description': 'Gear carrier'},
      {'name': 'Sleeping Bag', 'description': 'Outdoor sleeping'},
      {'name': 'Tent', 'description': 'Shelter'},
      {'name': 'Flashlight', 'description': 'Illumination'},
      {'name': 'Compass', 'description': 'Navigation'},
      {'name': 'Multi-tool', 'description': 'Utility tool'},
      {'name': 'Water Purification', 'description': 'Clean water'},
      {'name': 'Energy Bars', 'description': 'Quick nutrition'},
      {'name': 'Rain Gear', 'description': 'Weather protection'},
    ],
    'Beach/Summer': [
      {'name': 'Swimsuit', 'description': 'Swimming attire'},
      {'name': 'Beach Towel', 'description': 'Drying/lounging'},
      {'name': 'Flip Flops', 'description': 'Beach footwear'},
      {'name': 'Sunscreen', 'description': 'UV protection'},
      {'name': 'Beach Umbrella', 'description': 'Shade'},
      {'name': 'Cooler', 'description': 'Food/drink storage'},
      {'name': 'Snorkel Gear', 'description': 'Water exploration'},
      {'name': 'Beach Ball', 'description': 'Entertainment'},
      {'name': 'Waterproof Phone Case', 'description': 'Device protection'},
    ],
    'Winter/Ski': [
      {'name': 'Ski Jacket', 'description': 'Winter sports wear'},
      {'name': 'Thermal Underwear', 'description': 'Base layer'},
      {'name': 'Gloves', 'description': 'Hand warmth'},
      {'name': 'Winter Hat', 'description': 'Head warmth'},
      {'name': 'Snow Boots', 'description': 'Winter footwear'},
      {'name': 'Ski Goggles', 'description': 'Eye protection'},
      {'name': 'Hand Warmers', 'description': 'Heat packs'},
      {'name': 'Scarf', 'description': 'Neck warmth'},
      {'name': 'Wool Socks', 'description': 'Warm feet'},
    ],
    'Medical/Health': [
      {'name': 'Prescription Drugs', 'description': 'Required medications'},
      {'name': 'Thermometer', 'description': 'Temperature check'},
      {'name': 'Band-aids', 'description': 'Wound care'},
      {'name': 'Pain Relievers', 'description': 'Pain management'},
      {'name': 'Antacids', 'description': 'Stomach relief'},
      {'name': 'Allergy Medicine', 'description': 'Allergy treatment'},
      {'name': 'Medical Insurance Card', 'description': 'Healthcare access'},
      {'name': 'Emergency Medical Info', 'description': 'Health details'},
    ],
    'Photography': [
      {'name': 'DSLR Camera', 'description': 'Professional camera'},
      {'name': 'Extra Lenses', 'description': 'Photography options'},
      {'name': 'Memory Cards', 'description': 'Storage'},
      {'name': 'Camera Battery', 'description': 'Power source'},
      {'name': 'Tripod', 'description': 'Camera support'},
      {'name': 'Camera Bag', 'description': 'Equipment protection'},
      {'name': 'Lens Cleaning Kit', 'description': 'Maintenance'},
    ],
    'Sports/Fitness': [
      {'name': 'Workout Clothes', 'description': 'Exercise attire'},
      {'name': 'Running Shoes', 'description': 'Athletic footwear'},
      {'name': 'Water Bottle', 'description': 'Hydration'},
      {'name': 'Fitness Tracker', 'description': 'Activity monitor'},
      {'name': 'Yoga Mat', 'description': 'Exercise surface'},
      {'name': 'Protein Bars', 'description': 'Nutrition'},
      {'name': 'Gym Towel', 'description': 'Sweat management'},
    ],
    'Entertainment': [
      {'name': 'Books', 'description': 'Reading material'},
      {'name': 'Magazines', 'description': 'Light reading'},
      {'name': 'Playing Cards', 'description': 'Card games'},
      {'name': 'Board Games', 'description': 'Group entertainment'},
      {'name': 'Music Player', 'description': 'Audio entertainment'},
      {'name': 'Downloaded Movies', 'description': 'Video content'},
      {'name': 'Puzzle Books', 'description': 'Brain teasers'},
    ],
    'Kitchen/Food': [
      {'name': 'Travel Mug', 'description': 'Beverage container'},
      {'name': 'Utensils', 'description': 'Eating tools'},
      {'name': 'Cooler Bag', 'description': 'Food storage'},
      {'name': 'Snacks', 'description': 'Quick food'},
      {'name': 'Coffee/Tea', 'description': 'Beverages'},
      {'name': 'Can Opener', 'description': 'Food preparation'},
      {'name': 'Napkins', 'description': 'Cleaning'},
    ],
    'Accessories': [
      {'name': 'Sunglasses', 'description': 'Eye protection'},
      {'name': 'Hat', 'description': 'Sun protection'},
      {'name': 'Backpack', 'description': 'Carry your items'},
      {'name': 'Wallet', 'description': 'Money and cards holder'},
      {'name': 'Watch', 'description': 'Timekeeping accessory'},
      {'name': 'Belt', 'description': 'Clothing accessory'},
      {'name': 'Jewelry', 'description': 'Personal adornment'},
      {'name': 'Scarf', 'description': 'Fashion/warmth'},
    ],
  };

  // Default user ID - in a real app, this would come from authentication
  final int _userId = 1;
  final int? _tripId = null; // Can be set based on selected trip

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializePackingData();
    _searchController.addListener(_filterItems);

    // Add scroll listener to control FAB visibility
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializePackingData() async {
    try {
      // Initialize loading state

      // Initialize the database tables
      await _packingService.initializePackingTables();

      // Load existing packing items for the user
      final items = await _packingService.getPackingItems(_userId, tripId: _tripId);

      if (mounted) {
        setState(() {
          _allItems = items;
        });
        _filterItems();
      }
    } catch (e) {
      if (mounted) {
        // Handle loading error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load packing items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  bool _itemExists(String name) {
    return _allItems.any(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
    );
  }

  Future<void> _addItem(
    String name,
    String category, {
    int quantity = 1,
    Priority priority = Priority.medium,
  }) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item name cannot be empty',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
      return;
    }

    if (_itemExists(name.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item "$name" already exists in the list',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
      return;
    }

    try {
      final newItem = PackingItem(
        name: name.trim(),
        category: category,
        quantity: quantity.clamp(1, 99),
        priority: priority,
        userId: _userId,
        tripId: _tripId,
      );

      final itemId = await _packingService.addPackingItem(newItem);

      if (itemId != null && mounted) {
        final itemWithId = newItem.copyWith(id: itemId);
        setState(() {
          _allItems.add(itemWithId);
          _filterItems();
        });
        _itemController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $name to packing list',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editItem(
    int index,
    String name,
    String category,
    int quantity,
    Priority priority,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item name cannot be empty',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
      return;
    }

    String oldName = _filteredItems[index].name;
    if (name.trim() != oldName && _itemExists(name.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item "$name" already exists in the list',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
        ),
      );
      return;
    }

    try {
      final updatedItem = _filteredItems[index].copyWith(
        name: name.trim(),
        category: category,
        quantity: quantity.clamp(1, 99),
        priority: priority,
      );

      final success = await _packingService.updatePackingItem(updatedItem);

      if (success && mounted) {
        setState(() {
          _filteredItems[index] = updatedItem;
          // Update in _allItems as well
          final allIndex = _allItems.indexWhere((item) => item.id == updatedItem.id);
          if (allIndex != -1) {
            _allItems[allIndex] = updatedItem;
          }
          _filterItems();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated $name',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleItemPacked(int index) async {
    try {
      final updatedItem = _filteredItems[index].copyWith(
        isPacked: !_filteredItems[index].isPacked,
      );

      final success = await _packingService.updatePackingItem(updatedItem);

      if (success && mounted) {
        setState(() {
          _filteredItems[index] = updatedItem;
          // Update in _allItems as well
          final allIndex = _allItems.indexWhere((item) => item.id == updatedItem.id);
          if (allIndex != -1) {
            _allItems[allIndex] = updatedItem;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    String itemName = _filteredItems[index].name;
    PackingItem itemToDelete = _filteredItems[index];

    try {
      final success = await _packingService.deletePackingItem(itemToDelete.id!, _userId);

      if (success && mounted) {
        setState(() {
          _allItems.remove(itemToDelete);
          _filterItems();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted $itemName',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                try {
                  final newId = await _packingService.addPackingItem(itemToDelete.copyWith(id: null));
                  if (newId != null && mounted) {
                    setState(() {
                      _allItems.add(itemToDelete.copyWith(id: newId));
                      _filterItems();
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to restore item: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterItems() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        bool matchesCategory =
            _selectedCategory == 'All' || item.category == _selectedCategory;
        bool matchesSearch = _searchController.text.isEmpty ||
            item.name.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
        bool matchesPackedFilter = (!_showOnlyPacked && !_showOnlyUnpacked) ||
            (_showOnlyPacked && item.isPacked) ||
            (_showOnlyUnpacked && !item.isPacked);

        return matchesCategory && matchesSearch && matchesPackedFilter;
      }).toList();

      if (_sortBy == 'Priority') {
        _filteredItems.sort((a, b) {
          int priorityComparison = b.priority.index.compareTo(a.priority.index);
          if (priorityComparison != 0) return priorityComparison;
          return a.name.compareTo(b.name);
        });
      } else if (_sortBy == 'Name') {
        _filteredItems.sort((a, b) => a.name.compareTo(b.name));
      } else if (_sortBy == 'Category') {
        _filteredItems.sort((a, b) {
          int categoryComparison = a.category.compareTo(b.category);
          if (categoryComparison != 0) return categoryComparison;
          return a.name.compareTo(b.name);
        });
      }
    });
  }

  void _showAddItemDialog({PackingItem? item, int? index}) {
    String selectedCategory = item?.category ?? 'Clothing';
    int quantity = item?.quantity ?? 1;
    Priority priority = item?.priority ?? Priority.medium;
    _itemController.text = item?.name ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            item == null ? 'Add Item' : 'Edit Item',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText:
                        _itemController.text.trim().isEmpty ? 'Required' : null,
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setDialogState(() {}),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  items: _categories.skip(1).map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: quantity.toString(),
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          quantity = int.tryParse(value) ?? 1;
                        },
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.04),
                    Expanded(
                      child: DropdownButtonFormField<Priority>(
                        initialValue: priority,
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        items: Priority.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: _getPriorityColor(p),
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(p.name.toUpperCase()),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                if (item == null) {
                  _addItem(
                    _itemController.text,
                    selectedCategory,
                    quantity: quantity,
                    priority: priority,
                  );
                } else {
                  _editItem(
                    index!,
                    _itemController.text,
                    selectedCategory,
                    quantity,
                    priority,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(item == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog() {
    Map<String, bool> selectedItems = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add from Templates',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: ListView.builder(
              itemCount: _categoryTemplates.keys.length,
              itemBuilder: (context, index) {
                String category = _categoryTemplates.keys.elementAt(index);
                List<Map<String, String>> items = _categoryTemplates[category]!;

                return ExpansionTile(
                  title: Text(
                    category,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                  leading: Icon(
                    _getCategoryIcon(category),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: items.map((item) {
                    bool alreadyExists = _itemExists(item['name']!);
                    selectedItems[item['name']!] ??= false;

                    return CheckboxListTile(
                      title: Text(
                        item['name']!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        item['description']!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                        ),
                      ),
                      value: alreadyExists ? true : selectedItems[item['name']!],
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: alreadyExists
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedItems[item['name']!] = value!;
                              });
                            },
                      secondary: alreadyExists
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                selectedItems.forEach((name, selected) {
                  if (selected && !_itemExists(name)) {
                    String category = _categoryTemplates.entries
                        .firstWhere(
                          (entry) => entry.value.any((item) => item['name'] == name),
                        )
                        .key;
                    _addItem(name, category);
                  }
                });
                Navigator.pop(context);
                if (selectedItems.values.any((selected) => selected)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected items added to packing list',
                        style:
                            TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add Selected'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsDialog() {
    int totalItems = _allItems.length;
    int packedItems = _allItems.where((item) => item.isPacked).length;
    int unpackedItems = totalItems - packedItems;
    double progress = totalItems > 0 ? packedItems / totalItems : 0;

    Map<String, int> categoryStats = {};
    for (String category in _categories.skip(1)) {
      categoryStats[category] =
          _allItems.where((item) => item.category == category).length;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Packing Statistics',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress: ${(progress * 100).toInt()}%',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'Total Items: $totalItems',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Text(
                'Packed: $packedItems',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              Text(
                'Remaining: $unpackedItems',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              Text(
                'By Category:',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              ...categoryStats.entries.map(
                (entry) => Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red.shade600;
      case Priority.medium:
        return Colors.orange.shade600;
      case Priority.low:
        return Colors.green.shade600;
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
      case 'Baby Essentials':
        return Icons.child_care;
      case 'Children\'s Items':
        return Icons.toys;
      case 'Elderly Care':
        return Icons.elderly;
      case 'Couple Items':
        return Icons.favorite;
      case 'Business Travel':
        return Icons.business_center;
      case 'Adventure/Outdoor':
        return Icons.hiking;
      case 'Beach/Summer':
        return Icons.beach_access;
      case 'Winter/Ski':
        return Icons.ac_unit;
      case 'Medical/Health':
        return Icons.medical_services;
      case 'Photography':
        return Icons.camera_alt;
      case 'Sports/Fitness':
        return Icons.fitness_center;
      case 'Entertainment':
        return Icons.games;
      case 'Kitchen/Food':
        return Icons.restaurant;
      case 'Accessories':
        return Icons.watch;
      default:
        return Icons.category;
    }
  }

  void _onScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 300), () {
        if (!_scrollController.position.isScrollingNotifier.value) {
          setState(() {
            _showFab = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    int packedCount = _allItems.where((item) => item.isPacked).length;
    int totalCount = _allItems.length;
    double progress = totalCount > 0 ? packedCount / totalCount : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            title: const Text('Packing List'),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics),
                tooltip: 'View Statistics',
                onPressed: _showStatsDialog,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: 'Sort Items',
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                    _filterItems();
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Priority',
                    child: Text(
                      'Sort by Priority',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Name',
                    child: Text(
                      'Sort by Name',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Category',
                    child: Text(
                      'Sort by Category',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More Options',
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(
                            'Clear All Items',
                            style:
                                TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          content: Text(
                            'Are you sure you want to clear all items from the packing list?',
                            style:
                                TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary)),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  final success = await _packingService.clearAllPackingItems(_userId, tripId: _tripId);
                                  
                                  if (success && mounted) {
                                    setState(() {
                                      _allItems.clear();
                                      _filterItems();
                                    });
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'All items cleared successfully',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary),
                                        ),
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to clear items',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onError),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error clearing items: $e',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onError),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                'Clear',
                                style:
                                    TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: Text(
                      'Mark All Packed',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    onTap: () {
                      setState(() {
                        for (var item in _allItems) {
                          item.isPacked = true;
                        }
                        _filterItems();
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Text(
                      'Mark All Unpacked',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    onTap: () {
                      setState(() {
                        for (var item in _allItems) {
                          item.isPacked = false;
                        }
                        _filterItems();
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
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.015,
                horizontal: screenWidth * 0.04,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).colorScheme.onSurface),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () {
                            _searchController.clear();
                            _filterItems();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                ),
                textInputAction: TextInputAction.search,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: screenHeight * 0.08,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
                child: Row(
                  children: [
                    ..._categories.map(
                      (category) => Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.02),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: _selectedCategory == category
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          selected: _selectedCategory == category,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = category;
                              _filterItems();
                            });
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.02),
                      child: FilterChip(
                        label: Text(
                          'Packed',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: _showOnlyPacked
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        selected: _showOnlyPacked,
                        selectedColor: Colors.green.shade600,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        onSelected: (selected) {
                          setState(() {
                            _showOnlyPacked = selected;
                            if (selected) _showOnlyUnpacked = false;
                            _filterItems();
                          });
                        },
                      ),
                    ),
                    FilterChip(
                      label: Text(
                        'Unpacked',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: _showOnlyUnpacked
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        selected: _showOnlyUnpacked,
                        selectedColor: Colors.orange.shade600,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
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
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '$packedCount of $totalCount items packed',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: '$packedCount of $totalCount items packed',
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (_filteredItems.isEmpty) {
                  return SizedBox(
                    height: screenHeight * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.luggage,
                            size: screenWidth * 0.15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            _allItems.isEmpty
                                ? 'No items in your packing list'
                                : 'No items match your filters',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            semanticsLabel: _allItems.isEmpty
                                ? 'No items in your packing list'
                                : 'No items match your filters',
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            _allItems.isEmpty
                                ? 'Add some items to get started!'
                                : 'Try adjusting your search or filters',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                PackingItem item = _filteredItems[index];
                return Card(
                  elevation: 2,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.01,
                    ),
                    leading: Checkbox(
                      value: item.isPacked,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (value) => _toggleItemPacked(index),
                      semanticLabel:
                          item.isPacked ? 'Unpack ${item.name}' : 'Pack ${item.name}',
                    ),
                    title: Text(
                      item.name,
                      style: TextStyle(
                        decoration: item.isPacked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: item.isPacked
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.04,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Flexible(
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(item.category),
                            size: screenWidth * 0.04,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.category,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.quantity > 1) ...[
                            const SizedBox(width: 8),
                            Text(
                              '× ${item.quantity}',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle,
                            size: screenWidth * 0.02,
                            color: _getPriorityColor(item.priority),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.priority.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: _getPriorityColor(item.priority),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text(
                            'Edit',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          onTap: () {
                            Future.delayed(Duration.zero, () {
                              _showAddItemDialog(item: item, index: index);
                            });
                          },
                        ),
                        PopupMenuItem(
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          onTap: () => _deleteItem(index),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _filteredItems.isEmpty ? 1 : _filteredItems.length),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: screenHeight * 0.1),
            ),
          ],
        ),
        floatingActionButton: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _showFab ? 1.0 : 0.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    right: screenWidth * 0.04, bottom: screenHeight * 0.01),
                child: FloatingActionButton(
                  heroTag: "templates",
                  mini: true,
                  onPressed: _showTemplateDialog,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  tooltip: 'Add from Templates',
                  child: const Icon(Icons.list_alt),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Padding(
                padding: EdgeInsets.only(
                    right: screenWidth * 0.04, bottom: screenHeight * 0.04),
                child: FloatingActionButton(
                  heroTag: "add",
                  onPressed: _showAddItemDialog,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  tooltip: 'Add New Item',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    }
}

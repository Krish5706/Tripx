import 'package:flutter/material.dart';
import 'package:tripx_frontend/screens/translator/language_data.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final String selectedLanguageCode;
  const LanguageSelectionScreen({super.key, required this.selectedLanguageCode});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late final TextEditingController _searchController;
  late List<MapEntry<String, String>> _filteredLanguages;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredLanguages = availableLanguages.entries.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages(String query) {
    setState(() {
      _filteredLanguages = availableLanguages.entries
          .where((entry) =>
              entry.value.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterLanguages,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search language...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredLanguages.length,
        itemBuilder: (context, index) {
          final entry = _filteredLanguages[index];
          final isSelected = widget.selectedLanguageCode == entry.key;
          
          return ListTile(
            title: Text(
              entry.value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelected 
              ? Icon(
                  Icons.check,
                  color: theme.colorScheme.primary,
                ) 
              : null,
            onTap: () {
              Navigator.of(context).pop(entry.key);
            },
            tileColor: theme.colorScheme.surface,
            selectedTileColor: theme.colorScheme.primaryContainer,
            selected: isSelected,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
          );
        },
      ),
    );
  }
}


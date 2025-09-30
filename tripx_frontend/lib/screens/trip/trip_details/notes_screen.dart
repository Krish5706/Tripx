import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tripx_frontend/models/note.dart';
import 'package:tripx_frontend/models/trip.dart';
import 'package:tripx_frontend/repositories/note_repository.dart';

// --- THEME-AWARE STICKY NOTE COLORS ---

// Colors for Light Mode
const List<Color> _lightNoteColors = [
  Color(0xFFFFFACD), // LemonChiffon
  Color(0xFF87CEFA), // LightSkyBlue
  Color(0xFF98FB98), // PaleGreen
  Color(0xFFFFB6C1), // LightPink
  Color(0xFFE6E6FA), // Lavender
  Color(0xFFFFF0F5), // LavenderBlush
];

// A custom palette for Dark Mode
const List<Color> _darkNoteColors = [
  Color(0xFF5A5A4D),
  Color(0xFF3C5F79),
  Color(0xFF4A7B4A),
  Color(0xFF7F5961),
  Color(0xFF6C6C9A),
  Color(0xFF7F7377),
];

/// The main screen that displays a grid of notes for a specific trip.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<Note>> _notesFuture;
  final NoteRepository _repository = NoteRepository();
  late Trip _trip;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trip = ModalRoute.of(context)!.settings.arguments as Trip;
    _notesFuture = _fetchNotes();
  }

  Future<List<Note>> _fetchNotes() async {
    return _repository.getNotesForTrip(_trip.id);
  }

  void _refreshNotes() {
    setState(() {
      _notesFuture = _fetchNotes();
    });
  }

  void _navigateToAddNotePage() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddNotePage(
          tripId: _trip.id,
          onSave: _refreshNotes,
        ),
      ),
    );

    if (result == true) _refreshNotes();
  }

  void _navigateToEditNotePage(Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditNotePage(
          note: note,
          onSave: _refreshNotes,
        ),
      ),
    );
  }

  void _deleteNoteWithConfirmation(BuildContext context, String noteId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final localContext = context;
              Navigator.of(dialogContext).pop();
              await _repository.deleteNote(noteId);
              if (!mounted) return;
              _refreshNotes();
              if (mounted) {
                ScaffoldMessenger.of(localContext).showSnackBar(
                  const SnackBar(content: Text('Note deleted')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- Detect theme and select the correct color palette ---
    final isDarkMode = theme.brightness == Brightness.dark;
    final noteColors = isDarkMode ? _darkNoteColors : _lightNoteColors;

    return Scaffold(
      appBar: AppBar(
        title: Text('Notes for ${_trip.tripName}',
            style: theme.textTheme.titleLarge),
        centerTitle: true,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: FutureBuilder<List<Note>>(
        future: _notesFuture,
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

          final notes = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              // --- Assign a color from the theme-appropriate palette ---
              final color = noteColors[index % noteColors.length];
              return NoteCard(
                note: note,
                color: color,
                onTap: () => _navigateToEditNotePage(note),
                onDelete: () => _deleteNoteWithConfirmation(context, note.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddNotePage,
        label: const Text('Add Note'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_alt_outlined,
                size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text('No notes yet.', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Tap the "+" button to add your first note.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A Material 3 card styled to look like a colorful sticky note.
/// It now automatically adjusts its text color for readability.
class NoteCard extends StatelessWidget {
  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rotation = (Random().nextDouble() - 0.5) * 0.05;

    // --- Dynamically determine text color based on background brightness ---
    final isColorDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final mainTextColor = isColorDark ? Colors.white.withValues(alpha: 0.90) : Colors.black.withValues(alpha: 0.87);
    final secondaryTextColor = isColorDark ? Colors.white.withValues(alpha: 0.70) : Colors.black.withValues(alpha: 0.54);


    return Transform.rotate(
      angle: rotation,
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: mainTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        note.content ?? '',
                        overflow: TextOverflow.fade,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: secondaryTextColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: Icon(Icons.close, size: 20, color: secondaryTextColor),
                onPressed: onDelete,
                tooltip: 'Delete Note',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-screen page for adding a new note.
class AddNotePage extends StatefulWidget {
  final String tripId;
  final VoidCallback onSave;

  const AddNotePage({super.key, required this.tripId, required this.onSave});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final NoteRepository _repository = NoteRepository();
  bool _isSaving = false;

  void _saveNote() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    await _repository.createNote(
      tripId: widget.tripId,
      title: _titleController.text,
      content: _contentController.text,
    );
    widget.onSave();
    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
        centerTitle: true,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonal(
              onPressed: _isSaving ? null : _saveNote,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Title',
                ),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Start writing your note here...',
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-screen page for viewing and editing an existing note.
class EditNotePage extends StatefulWidget {
  final Note note;
  final VoidCallback onSave;

  const EditNotePage({super.key, required this.note, required this.onSave});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final NoteRepository _repository = NoteRepository();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content ?? '');
  }

  void _saveNote() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await _repository.updateNote(
      noteId: widget.note.id,
      title: _titleController.text,
      content: _contentController.text,
    );
    widget.onSave();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
        centerTitle: true,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonal(
              onPressed: _isSaving ? null : _saveNote,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Title',
              ),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Start writing your note here...',
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

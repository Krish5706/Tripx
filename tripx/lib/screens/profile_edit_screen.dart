import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/db_helper.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  int? _userId;
  bool _isLoading = true;
  bool _isSaving = false;

  File? _profileImage;
  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    _profileImagePath = prefs.getString('profileImagePath');

    if (_userId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final profile = await _databaseHelper.getUserById(_userId!);

    File? imageFile;
    if (_profileImagePath != null && _profileImagePath!.isNotEmpty) {
      final file = File(_profileImagePath!);
      final exists = await file.exists();
      // Removed print statement for production code; consider using a logging framework instead.
      // print("Trying to load image at: $_profileImagePath, exists: $exists");

      if (exists) {
        imageFile = file;
      } else {
        // Removed print statement for production code; consider using a logging framework instead.
        // print("Image file not found at path: $_profileImagePath");
        _profileImagePath = null;
        await prefs.remove('profileImagePath');
      }
    }

    if (!mounted) return;

    setState(() {
      _nameController.text = profile?['name'] ?? '';
      _emailController.text = profile?['email'] ?? '';
      _profileImage = imageFile;
      _isLoading = false;
    });
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
      // Removed print statement for production code; consider using a logging framework instead.
      // print("No image picked.");
        return;
      }

      // Removed print statement for production code; consider using a logging framework instead.
      // print("Picked file path: ${pickedFile.path}");

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImagePath = '${appDir.path}/$fileName';

      final savedImage = await File(pickedFile.path).copy(savedImagePath);

      final exists = await savedImage.exists();
      // Removed print statement for production code; consider using a logging framework instead.
      // print("Saved image to: $savedImagePath, exists: $exists");

      setState(() {
        _profileImage = savedImage;
        _profileImagePath = savedImage.path;
      });
    } catch (e) {
      // Removed print statement for production code; consider using a logging framework instead.
      // print("Error picking image: $e");
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (_userId == null) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final success = await _databaseHelper.updateUser(
      _userId!,
      name: newName,
      email: newEmail,
    );

    if (success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', newEmail);
      if (_profileImagePath != null) {
        await prefs.setString('profileImagePath', _profileImagePath!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context, true);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Email may already exist.')),
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceActionSheet,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

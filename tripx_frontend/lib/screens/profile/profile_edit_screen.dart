import 'package:flutter/material.dart';
import 'package:tripx_frontend/api/api_constants.dart';
import 'package:tripx_frontend/repositories/user_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tripx_frontend/models/user.dart' as user_model;

class ProfileEditScreen extends StatefulWidget {
  final user_model.User? initialUser;

  const ProfileEditScreen({super.key, this.initialUser});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _profileImageFile;
  String? _currentProfilePicture;
  bool _removeImage = false;
  final UserRepository _userRepository = UserRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentProfilePicture = widget.initialUser?.profilePicture;
    if (widget.initialUser != null) {
      _nameController.text = widget.initialUser!.name;
      _emailController.text = widget.initialUser!.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImageFile = File(image.path);
        _removeImage = false;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userRepository.updateUser(
          name: _nameController.text,
          email: _emailController.text,
          phone: null,
          bio: null,
          profileImage: _profileImageFile,
          removeImage: _removeImage,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to signal success
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfilePicture(),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Saving...' : 'Save Profile'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    ImageProvider? backgroundImage;
    if (_profileImageFile != null) {
      backgroundImage = FileImage(_profileImageFile!);
    } else if (_currentProfilePicture != null && _currentProfilePicture!.isNotEmpty) {
      backgroundImage = NetworkImage(_constructImageUrl(_currentProfilePicture!));
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: backgroundImage,
                child: backgroundImage == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: _pickImage,
                  ),
                ),
              ),
            ],
          ),
          if (backgroundImage != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _profileImageFile = null;
                  _currentProfilePicture = null;
                  _removeImage = true;
                });
              },
              child: const Text('Remove Photo'),
            ),
        ],
      ),
    );
  }

  String _constructImageUrl(String path) {
    if (path.startsWith('http')) {
      return path;
    }
    // Normalize path: replace backslashes and remove leading slashes
    String normalizedPath = path.replaceAll(r'\', '/').replaceAll(r'public/', '');
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }
    // The staticFilesUrl already contains '.../public'
    return '${ApiConstants.staticFilesUrl}/$normalizedPath';
  }
}

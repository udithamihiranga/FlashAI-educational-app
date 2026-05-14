import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:flashai/features/auth/presentation/providers/auth_provider.dart';
import 'package:flashai/features/auth/data/firebase_auth_service.dart';
import 'package:flashai/features/auth/presentation/screens/login_screen.dart';

/// EditProfileScreen allows users to edit their username and profile picture
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _imageBytes;
  String? _pickedExtension;
  String? _currentPhotoURL;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final firebaseUser = FirebaseAuthService().currentUser;

    _usernameController = TextEditingController(
      text: authProvider.userName ?? firebaseUser?.displayName ?? '',
    );
    _currentPhotoURL = firebaseUser?.photoURL;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  /// Pick a profile image from device
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final originalBytes = result.files.single.bytes!;
        final originalName = result.files.single.name;
        
        print('Picked image: $originalName, size: ${originalBytes.length} bytes');

        // Compress and resize image to reduce upload time
        Uint8List processedBytes = originalBytes;
        try {
          final image = img.decodeImage(originalBytes);
          if (image != null) {
            // Resize to max 400x400 while preserving aspect ratio
            final resized = img.copyResize(
              image,
              width: 400,
              height: 400,
              maintainAspect: true,
            );
            // Encode as JPEG with 85% quality
            final compressed = img.encodeJpg(resized, quality: 85);
            processedBytes = Uint8List.fromList(compressed);
            print('Image compressed: ${originalBytes.length} -> ${processedBytes.length} bytes');
          }
        } catch (e) {
          print('Image compression skipped: $e');
          // Use original bytes if compression fails
        }

        setState(() {
          _imageBytes = processedBytes;
          _pickedExtension = result.files.single.extension ?? 'jpg';
          _currentPhotoURL = null; // Clear existing URL when new image picked
        });
      }
    } catch (e) {
      print('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Save profile changes
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();

    try {
      if (_imageBytes != null) {
        // Upload new image and update profile
        print('Attempting to upload image: ${_imageBytes!.length} bytes, extension: ${_pickedExtension ?? "jpg"}');
        
        final success = await authProvider.updateProfileWithImage(
          displayName: _usernameController.text.trim(),
          imageBytes: _imageBytes!,
          extension: _pickedExtension ?? 'jpg',
        );

        print('Update profile with image result: $success');

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          final errorMsg = authProvider.errorMessage ?? 'Failed to update profile';
          print('Update failed: $errorMsg');
          setState(() {
            _errorMessage = errorMsg;
          });
        }
      } else {
        // Only update display name
        final success = await authProvider.updateProfile(
          displayName: _usernameController.text.trim(),
        );

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          setState(() {
            _errorMessage = authProvider.errorMessage ?? 'Failed to update profile';
          });
        }
      }
    } catch (e, stack) {
      print('Profile save error: $e');
      print('Stack trace: $stack');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: Text(
              'Log Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle logout action
  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Your Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : _currentPhotoURL != null
                                      ? DecorationImage(
                                          image: NetworkImage(_currentPhotoURL!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: _imageBytes == null && _currentPhotoURL == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                          if (!_isLoading)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to change profile picture',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Username Field
              TextFormField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  prefixIcon: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username cannot be empty';
                  }
                  if (value.trim().length < 2) {
                    return 'Username must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email Display (readonly)
              TextFormField(
                initialValue: authProvider.userEmail,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Your email',
                  prefixIcon: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.email_outlined,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 32),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

               // Save Button
               FilledButton(
                 onPressed: _isLoading ? null : _saveProfile,
                 style: FilledButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(12),
                   ),
                 ),
                 child: _isLoading
                     ? SizedBox(
                         height: 20,
                         width: 20,
                         child: CircularProgressIndicator(
                           strokeWidth: 2,
                           color: theme.colorScheme.onPrimary,
                         ),
                       )
                     : const Text('Save Changes'),
               ),
                const SizedBox(height: 20),

                // Logout Button
                FilledButton(
                  onPressed: () => _showLogoutDialog(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Log Out'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

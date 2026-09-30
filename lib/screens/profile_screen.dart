import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String _profilePicBase64 = '';

  @override
  void initState() {
    super.initState();
    final taskProvider = context.read<TaskProvider>();
    _nameController.text = taskProvider.userName;
    _profilePicBase64 = taskProvider.userProfilePic;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profilePicBase64 = base64Encode(bytes);
      });
    }
  }

  void _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    
    // Update name
    String? error = await authProvider.updateProfile(_nameController.text.trim());
    
    // Update profile pic if changed
    if (error == null && _profilePicBase64.isNotEmpty) {
      error = await authProvider.updateProfilePicture(_profilePicBase64);
    }
    
    setState(() => _isLoading = false);
    
    if (error == null) {
      if (!mounted) return;
      
      final taskProvider = context.read<TaskProvider>();
      taskProvider.setUserName(_nameController.text.trim());
      if (_profilePicBase64.isNotEmpty) {
        taskProvider.setUserProfilePic(_profilePicBase64);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final initial = taskProvider.userName.isNotEmpty ? taskProvider.userName.substring(0, 1).toUpperCase() : 'U';
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: isDesktop ? const Color(0xFFF8FAFC) : AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24, vertical: 24),
              child: Container(
                padding: isDesktop ? const EdgeInsets.all(32) : EdgeInsets.zero,
                decoration: isDesktop
                    ? BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3), width: 2),
                            ),
                            child: ClipOval(
                              child: _profilePicBase64.isNotEmpty
                                  ? Image.memory(
                                      base64Decode(_profilePicBase64),
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Name Field
                    Container(
                      decoration: BoxDecoration(
                        color: isDesktop ? const Color(0xFFF8FAFC) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: isDesktop ? const Color(0xFFF8FAFC) : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Email Field (Read Only)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: TextEditingController(text: taskProvider.userEmail),
                        enabled: false,
                        style: const TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          labelText: 'Email Address (Cannot be changed)',
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded, color: Colors.red),
                        label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

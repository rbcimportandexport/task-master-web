import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  DateTime? _selectedDob;
  DateTime? _selectedJoiningDate;

  @override
  void initState() {
    super.initState();
    final taskProvider = context.read<TaskProvider>();
    _nameController.text = taskProvider.userName;
    _profilePicBase64 = taskProvider.userProfilePic;
    _selectedDob = taskProvider.userDob;
    _selectedJoiningDate = taskProvider.userCreatedAt;
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

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 22, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      helpText: 'Select Your Date of Birth (Birthday)',
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _pickJoiningDate() async {
    final now = DateTime.now();
    final initialDate = _selectedJoiningDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2015),
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Select Official Joining Date',
    );
    if (picked != null) {
      setState(() {
        _selectedJoiningDate = picked;
      });
    }
  }

  void _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final dobStr = _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null;
    
    // Update name and dob
    String? error = await authProvider.updateProfile(_nameController.text.trim(), dob: dobStr);
    
    // Update profile pic if changed
    if (error == null && _profilePicBase64.isNotEmpty) {
      error = await authProvider.updateProfilePicture(_profilePicBase64);
    }

    // Save joining date and birthday (dob) to Firestore user document
    if (error == null && taskProvider.uid != null) {
      try {
        final Map<String, dynamic> updateMap = {};
        if (_selectedJoiningDate != null) {
          updateMap['joiningDate'] = Timestamp.fromDate(_selectedJoiningDate!);
          updateMap['createdAt'] = Timestamp.fromDate(_selectedJoiningDate!);
          taskProvider.setUserCreatedAt(_selectedJoiningDate);
        }
        if (_selectedDob != null) {
          updateMap['dob'] = dobStr;
          updateMap['dobTimestamp'] = Timestamp.fromDate(_selectedDob!);
          taskProvider.setUserDob(_selectedDob);
        }
        if (updateMap.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(taskProvider.uid).set(
            updateMap,
            SetOptions(merge: true),
          );
        }
      } catch (_) {}
    }
    
    setState(() => _isLoading = false);
    
    if (error == null) {
      if (!mounted) return;
      
      final taskProvider = context.read<TaskProvider>();
      taskProvider.setUserName(_nameController.text.trim());
      taskProvider.setUserDob(_selectedDob);
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
                    const SizedBox(height: 20),

                    // Birthday / Date of Birth Selector Field
                    InkWell(
                      onTap: _pickDob,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDesktop ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF2F8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.cake_rounded, color: Color(0xFFDB2777), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date of Birth (Birthday)',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedDob != null
                                        ? DateFormat('dd MMMM yyyy').format(_selectedDob!)
                                        : 'Tap to select birthday',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedDob != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: Color(0xFF64748B), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Joining Details & Organization Tenure Card (Tap to Edit)
                    InkWell(
                      onTap: _pickJoiningDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Icon(Icons.business_center_rounded, color: AppTheme.primaryBlue, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Text(
                                        'Company Joining Date',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.primaryBlue),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedJoiningDate != null
                                        ? DateFormat('dd MMMM yyyy').format(_selectedJoiningDate!)
                                        : 'Tap to select joining date',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedJoiningDate != null
                                        ? 'Joined: ${DateTime.now().difference(_selectedJoiningDate!).inDays < 0 ? 0 : DateTime.now().difference(_selectedJoiningDate!).inDays + 1} days ago'
                                        : 'Tap to set official joining date',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _selectedJoiningDate != null
                                    ? '${DateTime.now().difference(_selectedJoiningDate!).inDays < 0 ? 0 : DateTime.now().difference(_selectedJoiningDate!).inDays + 1} Days'
                                    : 'Edit',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
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

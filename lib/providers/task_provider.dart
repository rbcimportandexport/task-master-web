import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/category.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/fcm_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final List<CategoryItem> _categories = List.from(CategoryItem.defaultCategories);
  String _selectedCategory = 'All';
  DateTime _selectedCalendarDate = DateUtils.dateOnly(DateTime.now());
  bool _isFirstLaunch = true;
  bool _hasCompletedFirstTask = false;
  bool _showSubtasks = false;
  bool _taskCompletionTone = true;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _userProfilePic = '';
  String _sortBy = 'default';
  bool _isMultiSelectMode = false;
  final Set<String> _selectedTaskIds = {};
  bool _isGridView = false;
  String _filterStatus = 'all'; // 'all', 'pending', 'completed'
  String? _uid;
  String _userRole = 'employee';
  String _managerId = '';

  Color _selectedThemeColor = const Color(0xFF3B82F6);

  List<Task> get tasks => _tasks;
  List<CategoryItem> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  DateTime get selectedCalendarDate => _selectedCalendarDate;
  bool get isFirstLaunch => _isFirstLaunch;
  bool get hasCompletedFirstTask => _hasCompletedFirstTask;
  bool get showSubtasks => _showSubtasks;
  bool get taskCompletionTone => _taskCompletionTone;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userProfilePic => _userProfilePic;
  String get managerId => _managerId;
  String get userRole {
    if (_userEmail.trim().toLowerCase() == 'rbcitsupport@gmail.com') return 'super_admin';
    if (_userEmail.trim().toLowerCase().contains('inquiry')) return 'manager';
    if (_userEmail.trim().toLowerCase() == 'rbcsaurabhyadav@gmail.com') return 'employee';
    return _userRole;
  }
  String? get uid => _uid;

  void setUserProfilePic(String base64) {
    _userProfilePic = base64;
    notifyListeners();
  }

  Future<void> injectMockEmployee() async {
    try {
      final String mockUid = 'mock_employee_saurabh';
      await FirebaseFirestore.instance.collection('users').doc(mockUid).set({
        'role': 'employee',
        'email': 'rbcsaurabhyadav@gmail.com',
        'name': 'Saurabh Yadav',
        'profilePic': '', 
      });

      // Add a couple of tasks
      final tasksRef = FirebaseFirestore.instance.collection('users').doc(mockUid).collection('tasks');
      await tasksRef.add({
        'title': 'Complete UI Design',
        'category': 'Work',
        'isCompleted': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'completedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'dueDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'priority': 2,
        'progress': 100,
        'flagColor': 0,
        'subtasks': [],
        'assignedBy': 'Manager',
        'isStarred': true,
      });

      await tasksRef.add({
        'title': 'Integrate Firebase API',
        'category': 'Work',
        'isCompleted': false,
        'createdAt': DateTime.now().toIso8601String(),
        'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'priority': 3,
        'progress': 40,
        'flagColor': 1,
        'subtasks': [],
        'assignedBy': 'Manager',
        'isStarred': false,
      });
      debugPrint('Mock employee injected successfully');
    } catch (e) {
      debugPrint('Error injecting mock employee: $e');
    }
  }

  Future<void> upgradeToManager() async {
    if (_uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set(
          {'role': 'manager'},
          SetOptions(merge: true),
        );
        _userRole = 'manager';
        notifyListeners();
      } catch (e) {
        debugPrint('Error upgrading to manager: $e');
      }
    }
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }
  String get sortBy => _sortBy;
  bool get isMultiSelectMode => _isMultiSelectMode;
  Set<String> get selectedTaskIds => _selectedTaskIds;
  bool get isGridView => _isGridView;
  String get filterStatus => _filterStatus;
  Color get selectedThemeColor => _selectedThemeColor;

  void setThemeColor(Color color) {
    _selectedThemeColor = color;
    _saveToPrefs();
    notifyListeners();
  }

  TaskProvider() {
    _loadFromPrefs();
    _initFirebaseAuth();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('profilePic')) {
          _userProfilePic = data['profilePic'] ?? '';
        }
        if (data.containsKey('role')) {
          _userRole = data['role'] ?? 'employee';
        }
        if (data.containsKey('managerId')) {
          _managerId = data['managerId'] ?? '';
        }
        
        // Ensure support email is always super admin
        if (_userEmail == 'rbcitsupport@gmail.com') {
           _userRole = 'super_admin';
           try { await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'super_admin'}); } catch(e) {}
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  void _initFirebaseAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _isLoggedIn = true;
        _uid = user.uid;
        _userName = user.displayName ?? '';
        _userEmail = user.email ?? '';
        _loadUserProfile(user.uid);
        _loadFromFirestore();
      } else {
        _isLoggedIn = false;
        _uid = null;
        _userName = '';
        _userEmail = '';
        _userProfilePic = '';
        _tasks.clear();
      }
      notifyListeners();
    });
  }

  CollectionReference? get _tasksCollection {
    if (_uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(_uid).collection('tasks');
  }

  Future<void> _loadFromFirestore() async {
    if (_tasksCollection == null) return;
    try {
      final snapshot = await _tasksCollection!.get();
      _tasks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // ensure ID matches document ID
        return Task.fromJson(data);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from Firestore: $e');
    }
  }

  Future<void> _saveTaskToFirestore(Task task) async {
    if (_tasksCollection == null) return;
    try {
      await _tasksCollection!.doc(task.id).set(task.toJson());
    } catch (e) {
      debugPrint('Error saving task to Firestore: $e');
    }
  }
  
  Future<void> _deleteTaskFromFirestore(String id) async {
    if (_tasksCollection == null) return;
    try {
      await _tasksCollection!.doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting task from Firestore: $e');
    }
  }

    void markFirstTaskCompleted() {
    _hasCompletedFirstTask = true;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final hasSeenWelcome = prefs.getBool('has_seen_welcome_screen') ?? false;
      _isFirstLaunch = !hasSeenWelcome;
        _hasCompletedFirstTask = prefs.getBool('hasCompletedFirstTask') ?? false;
      
      _showSubtasks = prefs.getBool('show_subtasks') ?? false;
      _taskCompletionTone = prefs.getBool('task_tone') ?? true;
      final savedThemeColor = prefs.getInt('selected_theme_color');
      if (savedThemeColor != null) {
        _selectedThemeColor = Color(savedThemeColor);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_subtasks', _showSubtasks);
      await prefs.setBool('hasCompletedFirstTask', _hasCompletedFirstTask);
      await prefs.setBool('task_tone', _taskCompletionTone);
      await prefs.setInt('selected_theme_color', _selectedThemeColor.value);
    } catch (e) {
      debugPrint('Error saving preferences: $e');
    }
  }

  Future<void> completeOnboarding() async {
    _isFirstLaunch = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome_screen', true);
    notifyListeners();
  }

  void login(String name, String email) {
    // Migrated to Firebase Auth, this is unused
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedCalendarDate(DateTime date) {
    _selectedCalendarDate = date;
    notifyListeners();
  }

  void setShowSubtasks(bool value) {
    _showSubtasks = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setTaskCompletionTone(bool value) {
    _taskCompletionTone = value;
    _saveToPrefs();
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void toggleMultiSelectMode() {
    _isMultiSelectMode = !_isMultiSelectMode;
    _selectedTaskIds.clear();
    notifyListeners();
  }

  void toggleGridView() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void toggleTaskSelection(String taskId) {
    if (_selectedTaskIds.contains(taskId)) {
      _selectedTaskIds.remove(taskId);
    } else {
      _selectedTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void selectAllTasks() {
    _selectedTaskIds.clear();
    for (var task in filteredTasks) {
      _selectedTaskIds.add(task.id);
    }
    notifyListeners();
  }

  void deleteSelectedTasks() {
    for (var id in _selectedTaskIds) {
      _deleteTaskFromFirestore(id);
    }
    _tasks.removeWhere((task) => _selectedTaskIds.contains(task.id));
    _selectedTaskIds.clear();
    _isMultiSelectMode = false;
    notifyListeners();
  }

  List<Task> get filteredTasks {
    List<Task> list;
    if (_selectedCategory == 'All') {
      list = List.from(_tasks);
    } else {
      list = _tasks.where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    if (_filterStatus == 'pending') {
      list = list.where((t) => !t.isCompleted).toList();
    } else if (_filterStatus == 'completed') {
      list = list.where((t) => t.isCompleted).toList();
    }

    if (_sortBy == 'date') {
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    } else if (_sortBy == 'priority') {
      list.sort((a, b) => b.priority.compareTo(a.priority));
    } else if (_sortBy == 'alphabetical') {
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }

  List<Task> tasksForDate(DateTime date) {
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
    }).toList();
  }

  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingTasksCount => _tasks.where((t) => !t.isCompleted).length;
  List<Task> get starredTasks => _tasks.where((t) => t.isStarred).toList();

  void addTask({
    required String title,
    String category = 'No Category',
    DateTime? dueDate,
    int priority = 0,
    int progress = 0,
    int flagColor = 0,
    List<Subtask>? subtasks,
    String? estimatedTime,
    String? voiceNoteUrl,
    int? voiceDurationSeconds,
  }) {
    final newTask = Task(
      id: FirebaseFirestore.instance.collection('users').doc().id, // Generate a unique ID
      title: title,
      category: category,
      dueDate: dueDate ?? _selectedCalendarDate,
      priority: priority,
      progress: progress,
      flagColor: flagColor,
      subtasks: subtasks ?? [],
      estimatedTime: estimatedTime,
      voiceNoteUrl: voiceNoteUrl,
      voiceDurationSeconds: voiceDurationSeconds,
      createdAt: DateTime.now(),
    );
    _tasks.insert(0, newTask);
    _saveTaskToFirestore(newTask);
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      _tasks[index].completedAt = _tasks[index].isCompleted ? DateTime.now() : null;
      _saveTaskToFirestore(_tasks[index]);
      notifyListeners();
    }
  }

  void toggleTaskStar(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isStarred = !_tasks[index].isStarred;
      _saveTaskToFirestore(_tasks[index]);
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _deleteTaskFromFirestore(id);
    notifyListeners();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _saveTaskToFirestore(task);
      notifyListeners();
    }
  }

  void addSubtask(String taskId, String title) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.subtasks.add(Subtask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    ));
    _saveTaskToFirestore(task);
    notifyListeners();
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final subtask = task.subtasks.firstWhere((s) => s.id == subtaskId);
    subtask.isCompleted = !subtask.isCompleted;
    _saveTaskToFirestore(task);
    notifyListeners();
  }

  void addCategory(String name, IconData icon, Color color) {
    _categories.add(CategoryItem(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      icon: icon,
      color: color,
    ));
    notifyListeners();
  }

  void deleteCategory(String id) {
    // Prevent deleting default categories
    if (CategoryItem.defaultCategories.any((cat) => cat.id == id)) return;
    
    _categories.removeWhere((cat) => cat.id == id);
    if (_selectedCategory.toLowerCase() == id) {
      _selectedCategory = 'All';
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // MANAGER METHODS
  // ----------------------------------------------------

  
  Future<void> addEmployee(String name, String email, String password, String department) async {
    try {
      // Use secondary app to prevent logging out current manager
      FirebaseApp app = await Firebase.initializeApp(
          name: 'SecondaryApp', options: Firebase.app().options);
      
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: app)
          .createUserWithEmailAndPassword(email: email, password: password);
          
      String newUid = userCredential.user!.uid;
      
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'name': name,
        'email': email,
        'role': 'employee',
        'department': department,
        'managerId': _uid, // The current logged-in manager
        'profilePic': '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await app.delete(); // Cleanup secondary app
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding employee: ');
      rethrow;
    }
  }

        Future<void> debugPrintAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    for (var doc in snapshot.docs) {
      debugPrint('USER: \ -> ');
    }
    debugPrint('CURRENT UID: ');
    debugPrint('CURRENT ROLE: ');
  }

    Future<void> forceRoles() async {
    try {
      final snap1 = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: 'rbcsaurabhyadav@gmail.com').get();
      if (snap1.docs.isNotEmpty) {
        await snap1.docs.first.reference.update({'role': 'super_admin'});
        if (_uid == snap1.docs.first.id) _userRole = 'super_admin';
      }
      
      final snap2 = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: 'rbcitsupport@gmail.com').get();
      if (snap2.docs.isNotEmpty) {
        await snap2.docs.first.reference.update({'role': 'manager', 'department': 'IT'});
        if (_uid == snap2.docs.first.id) _userRole = 'manager';
      }
      notifyListeners();
      debugPrint('Forced roles updated!');
    } catch (e) {
      debugPrint('Error forcing roles: ');
    }
  }

  Future<void> makeRbcItSupportManager() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: 'rbcitsupport@gmail.com')
          .get();
      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({'role': 'manager', 'department': 'IT'});
        debugPrint('Successfully made rbcitsupport@gmail.com a manager!');
      } else {
        debugPrint('User rbcitsupport@gmail.com not found in Firestore.');
      }
    } catch (e) {
      debugPrint('Error: ');
    }
  }

  
  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------
  
  Stream<List<Map<String, dynamic>>> get notificationsStream {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> sendNotification(String targetUid, String message) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(targetUid).collection('notifications').add({
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending notification: ');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: ');
    }
  }

  
  // ---------------------------------------------------------------------------
  // Attendance System
  // ---------------------------------------------------------------------------
  
  Stream<List<Map<String, dynamic>>> getMyAttendanceStream() {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).where((d) => d['uid'] == _uid).toList();
          docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          return docs;
        });
  }

  Stream<List<Map<String, dynamic>>> getTeamAttendanceStream() {
    if (_uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).where((d) => d['managerId'] == _uid).toList();
          docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          return docs;
        });
  }

  Stream<List<Map<String, dynamic>>> getAllAttendanceStream() {
    return FirebaseFirestore.instance
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          return docs.take(3000).toList();
        });
  }
  
  Stream<List<Map<String, dynamic>>> getSpecificUserAttendanceStream(String uid) {
    return FirebaseFirestore.instance
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).where((d) => d['uid'] == uid).toList();
          docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          return docs;
        });
  }

  Stream<List<Map<String, dynamic>>> getSpecificTeamAttendanceStream(String managerId) {
    return FirebaseFirestore.instance
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).where((d) => d['managerId'] == managerId).toList();
          docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
          return docs;
        });
  }

  Future<void> punchIn(String base64Photo, double lat, double lng) async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${_uid}_$today';
    
    // Check if doc exists locally or on server
    DocumentSnapshot<Map<String, dynamic>>? existingDoc;
    try {
      existingDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(docId)
          .get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      try {
        existingDoc = await FirebaseFirestore.instance
            .collection('attendance')
            .doc(docId)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {}
    }

    if (existingDoc != null && existingDoc.exists && existingDoc.data()?['checkIn'] != null) {
      throw 'Aapne aaj ki attendance pehle hi Punch In kar li hai!';
    }

    // Check if doc exists to preserve or adapt status for Half Day or Hourly leave
    String defaultStatus = 'Present';
    if (existingDoc != null && existingDoc.exists) {
      final data = existingDoc.data();
      if (data != null) {
        if (data['durationMode'] == 'Half Day') {
          defaultStatus = 'Half Day Present';
        } else if (data['durationMode'] == 'Hourly') {
          defaultStatus = 'Present (${data['hourlyHours'] ?? 2}h Leave)';
        }
      }
    }

    // Use cached managerId if offline
    String mId = _managerId;
    if (mId.isEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .get(const GetOptions(source: Source.serverAndCache));
        if (userDoc.exists && userDoc.data() != null) {
          mId = userDoc.data()!['managerId'] ?? '';
          _managerId = mId;
        }
      } catch (_) {}
    }
    
    // Firestore set with persistence enabled will immediately succeed locally and sync to cloud
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'uid': _uid,
      'userName': _userName,
      'role': _userRole,
      'managerId': mId,
      'date': today,
      'checkIn': FieldValue.serverTimestamp(),
      'status': defaultStatus,
      'photo': base64Photo,
      'latIn': lat,
      'lngIn': lng,
    }, SetOptions(merge: true));
  }

  Future<void> punchOut(double lat, double lng) async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${_uid}_$today';
    
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'checkOut': FieldValue.serverTimestamp(),
      'latOut': lat,
      'lngOut': lng,
    }, SetOptions(merge: true));
  }

  Future<void> punchHourlyLeaveOut(double lat, double lng, {String? reason}) async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${_uid}_$today';
    
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'hourlyBreakOut': FieldValue.serverTimestamp(),
      'hourlyBreakOutLat': lat,
      'hourlyBreakOutLng': lng,
      if (reason != null) 'hourlyLeaveReason': reason,
      'onHourlyLeave': true,
      'status': 'On Hourly Leave',
    }, SetOptions(merge: true));
  }

  Future<void> punchHourlyLeaveIn(double lat, double lng) async {
    if (_uid == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${_uid}_$today';
    
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'hourlyBreakIn': FieldValue.serverTimestamp(),
      'hourlyBreakInLat': lat,
      'hourlyBreakInLng': lng,
      'onHourlyLeave': false,
      'status': 'Present (Hourly Leave Taken)',
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getTodayAttendanceStream() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${_uid}_$today';
    return FirebaseFirestore.instance.collection('attendance').doc(docId).snapshots();
  }

  Future<void> upgradeToSuperAdmin() async {
    try {
      if (_uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set(
          {'role': 'super_admin'},
          SetOptions(merge: true),
        );
        _userRole = 'super_admin';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error upgrading to super admin: ');
    }
  }

  Future<List<String>> getDepartments() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final Set<String> depts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['role'] == 'manager' && data['department'] != null) {
          depts.add(data['department'] as String);
        }
      }
      return depts.toList();
    } catch (e) {
      debugPrint('Error fetching departments: ');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getManagersByDepartment(String dept) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> managers = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['role'] == 'manager' && data['department'] == dept) {
          data['uid'] = doc.id;
          managers.add(data);
        }
      }
      return managers;
    } catch (e) {
      debugPrint('Error fetching managers: ');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeesByManager(String managerId) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> employees = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['managerId'] == managerId) {
          data['uid'] = doc.id;
          employees.add(data);
        }
      }
      return employees;
    } catch (e) {
      debugPrint('Error fetching employees: ');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      // Fetch all users to ensure we get Saurabh's real data regardless of role
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      List<Map<String, dynamic>> emps = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
      
      // Filter out the current user (the manager) so they don't see themselves as an employee
      emps.removeWhere((e) => e['uid'] == _uid);
      
      return emps;
    } catch (e) {
      debugPrint('Error fetching employees: ');
      return [];
    }
  }

  Stream<List<Task>> getEmployeeTasksStream(String employeeId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(employeeId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();
    });
  }

  Future<void> assignTaskToEmployee(String employeeId, {
    required String title,
    required String category,
    DateTime? dueDate,
    int priority = 0,
    int progress = 0,
    int flagColor = 0,
    List<Subtask>? subtasks,
    String? estimatedTime,
    String? voiceNoteUrl,
    int? voiceDurationSeconds,
  }) async {
    try {
      final taskId = FirebaseFirestore.instance.collection('users').doc().id;
      final newTask = Task(
        id: taskId,
        title: title,
        category: category,
        dueDate: dueDate ?? DateUtils.dateOnly(DateTime.now()),
        createdAt: DateTime.now(),
        priority: priority,
        progress: progress,
        flagColor: flagColor,
        subtasks: subtasks ?? [],
        assignedBy: _userName,
        estimatedTime: estimatedTime,
        voiceNoteUrl: voiceNoteUrl,
        voiceDurationSeconds: voiceDurationSeconds,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employeeId)
          .collection('tasks')
          .doc(taskId)
          .set(newTask.toJson());
          
      // Create In-App Notification
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employeeId)
          .collection('notifications')
          .add({
        'title': voiceNoteUrl != null ? '🎤 Voice Task Assigned' : 'New Task Assigned',
        'message': voiceNoteUrl != null
            ? 'Voice note task assigned by $_userName: $title'
            : (estimatedTime != null && estimatedTime.isNotEmpty
                ? 'Assigned by $_userName: $title (Est. Time: $estimatedTime)'
                : 'You have been assigned a new task: $title'),
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      // Push notification via FCM
      final empDoc = await FirebaseFirestore.instance.collection('users').doc(employeeId).get();
      if (empDoc.exists && empDoc.data()!.containsKey('fcmToken')) {
        final fcmToken = empDoc.data()!['fcmToken'];
        await FCMService.sendPushNotification(
          fcmToken: fcmToken,
          title: 'New Task Assigned',
          body: 'You have been assigned a new task: $title',
        );
      }
    } catch (e) {
      debugPrint('Error assigning task to employee: $e');
    }
  }

  Future<void> transferTask({
    required String fromEmployeeId,
    required String toEmployeeId,
    required Task task,
    String? reason,
  }) async {
    try {
      // 1. Delete task from current employee
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fromEmployeeId)
          .collection('tasks')
          .doc(task.id)
          .delete();

      // 2. Add task to new employee
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        category: task.category,
        dueDate: task.dueDate,
        createdAt: task.createdAt,
        priority: task.priority,
        progress: task.progress,
        flagColor: task.flagColor,
        subtasks: task.subtasks,
        isCompleted: task.isCompleted,
        isStarred: task.isStarred,
        notes: task.notes.isNotEmpty ? '${task.notes}\n[Transferred by $_userName]' : '[Transferred by $_userName]',
        attachments: task.attachments,
        assignedBy: _userName,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toEmployeeId)
          .collection('tasks')
          .doc(task.id)
          .set(updatedTask.toJson());

      // 3. Create In-App Notification for new assignee
      await FirebaseFirestore.instance
          .collection('users')
          .doc(toEmployeeId)
          .collection('notifications')
          .add({
        'title': 'Task Transferred To You',
        'message': '$_userName transferred task "${task.title}" to you${reason != null && reason.isNotEmpty ? " (Reason: $reason)" : ""}.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 4. Send FCM Push Notification to new assignee
      final empDoc = await FirebaseFirestore.instance.collection('users').doc(toEmployeeId).get();
      if (empDoc.exists && empDoc.data()!.containsKey('fcmToken')) {
        final fcmToken = empDoc.data()!['fcmToken'];
        await FCMService.sendPushNotification(
          fcmToken: fcmToken,
          title: 'Task Transferred To You',
          body: '$_userName transferred task "${task.title}" to you.',
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error transferring task: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Leave Management
  // ---------------------------------------------------------------------------
  Future<void> applyLeave({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
    String durationMode = 'Full Day',
    String? halfDayType,
    int? hourlyHours,
    String? hourlyTimeSlot,
  }) async {
    if (_uid == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final mId = userDoc.data()?['managerId'] ?? '';

      final docRef = await FirebaseFirestore.instance.collection('leaves').add({
        'uid': _uid,
        'userName': _userName,
        'userEmail': _userEmail,
        'managerId': mId,
        'leaveType': leaveType,
        'durationMode': durationMode,
        if (halfDayType != null) 'halfDayType': halfDayType,
        if (hourlyHours != null) 'hourlyHours': hourlyHours,
        if (hourlyTimeSlot != null) 'hourlyTimeSlot': hourlyTimeSlot,
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'status': 'Pending',
        'appliedAt': FieldValue.serverTimestamp(),
      });

      // If applied for today, record in today's attendance document as well
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (startDate == today) {
        final docId = '${_uid}_$today';
        await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
          'leaveId': docRef.id,
          'leaveType': leaveType,
          'durationMode': durationMode,
          if (halfDayType != null) 'halfDayType': halfDayType,
          if (hourlyHours != null) 'hourlyHours': hourlyHours,
          if (hourlyTimeSlot != null) 'hourlyTimeSlot': hourlyTimeSlot,
          'leaveStatus': 'Pending',
          'leaveReason': reason,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error applying leave: $e');
      rethrow;
    }
  }
}







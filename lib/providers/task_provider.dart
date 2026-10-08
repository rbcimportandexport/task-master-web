import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/category.dart';
import '../models/project.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<Project> get projects => _projects;
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
  DateTime? _userCreatedAt;
  DateTime? _userDob;

  Color _selectedThemeColor = const Color(0xFF3B82F6);

  List<Task> get tasks => _tasks.where((t) => !t.isDeleted).toList();
  List<Task> get deletedTasks => _tasks.where((t) => t.isDeleted).toList();
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
  DateTime? get userCreatedAt => _userCreatedAt;
  DateTime? get userDob => _userDob;
  int get daysSinceJoining {
    if (_userCreatedAt == null) return 0;
    final now = DateTime.now();
    final diff = now.difference(_userCreatedAt!).inDays;
    return diff < 0 ? 0 : diff + 1; // 1st day on joining date
  }
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

  void setUserDob(DateTime? dob) {
    _userDob = dob;
    notifyListeners();
  }

  void setUserCreatedAt(DateTime? date) {
    _userCreatedAt = date;
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
    _autoFixAttendanceRecords();
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
        
        // Parse Date of Birth (DOB)
        if (data.containsKey('dob') && data['dob'] != null) {
          final db = data['dob'];
          if (db is Timestamp) {
            _userDob = db.toDate();
          } else if (db is String && db.trim().isNotEmpty) {
            _userDob = DateTime.tryParse(db);
          }
        }

        // Parse Joining Date / Account Created At
        if (data.containsKey('joiningDate') && data['joiningDate'] != null) {
          final jd = data['joiningDate'];
          if (jd is Timestamp) {
            _userCreatedAt = jd.toDate();
          } else if (jd is String && jd.trim().isNotEmpty) {
            _userCreatedAt = DateTime.tryParse(jd);
          }
        } else if (data.containsKey('createdAt') && data['createdAt'] != null) {
          final ca = data['createdAt'];
          if (ca is Timestamp) {
            _userCreatedAt = ca.toDate();
          } else if (ca is String && ca.trim().isNotEmpty) {
            _userCreatedAt = DateTime.tryParse(ca);
          }
        }
        
        // If not found in doc, fallback to FirebaseAuth creationTime or today
        _userCreatedAt ??= FirebaseAuth.instance.currentUser?.metadata.creationTime ?? DateTime.now();

        // Ensure support email is always super admin
        if (_userEmail == 'rbcitsupport@gmail.com') {
           _userRole = 'super_admin';
           try { await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'super_admin'}); } catch(e) {}
        }
        saveFcmToken();
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
        _autoFixAttendanceRecords();
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

  Future<void> _autoFixAttendanceRecords() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', whereIn: ['2026-09-29', '2026-10-01'])
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final date = data['date'];
        DateTime dtIn;
        DateTime dtOut;

        if (date == '2026-09-29') {
          dtIn = DateTime(2026, 9, 29, 8, 50, 0);
          dtOut = DateTime(2026, 9, 29, 20, 5, 0);
        } else {
          dtIn = DateTime(2026, 10, 1, 8, 50, 0);
          dtOut = DateTime(2026, 10, 1, 20, 5, 0);
        }

        await doc.reference.set({
          'checkIn': Timestamp.fromDate(dtIn),
          'checkOut': Timestamp.fromDate(dtOut),
          'status': 'Present',
          'durationMode': FieldValue.delete(),
          'hourlyHours': FieldValue.delete(),
          'hourlyTimeSlot': FieldValue.delete(),
          'onHourlyLeave': false,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Attendance auto-fix sync error: $e');
    }
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

      final savedCategoriesJson = prefs.getString('user_categories');
      if (savedCategoriesJson != null && savedCategoriesJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(savedCategoriesJson);
          _categories.clear();
          for (var item in decoded) {
            _categories.add(CategoryItem.fromJson(Map<String, dynamic>.from(item)));
          }
          if (!_categories.any((c) => c.id.toLowerCase() == 'all')) {
            _categories.insert(0, CategoryItem(id: 'all', name: 'All', icon: Icons.all_inclusive, color: const Color(0xFF2F80ED)));
          }
        } catch (e) {
          debugPrint('Error decoding saved categories: $e');
        }
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
      final categoriesJson = jsonEncode(_categories.map((c) => c.toJson()).toList());
      await prefs.setString('user_categories', categoriesJson);
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
    final activeTasks = _tasks.where((t) => !t.isDeleted).toList();
    List<Task> list;
    if (_selectedCategory == 'All') {
      list = List.from(activeTasks);
    } else {
      list = activeTasks.where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
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
    final list = _tasks.where((t) {
      if (t.isDeleted) return false;
      
      final matchesDue = t.dueDate != null &&
          t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
      
      final matchesCompleted = t.completedAt != null &&
          t.completedAt!.year == date.year &&
          t.completedAt!.month == date.month &&
          t.completedAt!.day == date.day;

      final matchesCreatedIfCompletedWithoutDate = t.isCompleted &&
          t.dueDate == null &&
          t.completedAt == null &&
          t.createdAt.year == date.year &&
          t.createdAt.month == date.month &&
          t.createdAt.day == date.day;

      return matchesDue || matchesCompleted || matchesCreatedIfCompletedWithoutDate;
    }).toList();

    // Sort: pending tasks first, then completed tasks
    list.sort((a, b) {
      if (a.isCompleted == b.isCompleted) return 0;
      return a.isCompleted ? 1 : -1;
    });

    return list;
  }

  int get completedTasksCount => _tasks.where((t) => !t.isDeleted && t.isCompleted).length;
  int get pendingTasksCount => _tasks.where((t) => !t.isDeleted && !t.isCompleted).length;
  List<Task> get starredTasks => _tasks.where((t) => !t.isDeleted && t.isStarred).toList();

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
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isDeleted = true;
      _tasks[index].deletedAt = DateTime.now();
      _saveTaskToFirestore(_tasks[index]);
      notifyListeners();
    }
  }

  void restoreTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isDeleted = false;
      _tasks[index].deletedAt = null;
      _saveTaskToFirestore(_tasks[index]);
      notifyListeners();
    }
  }

  void permanentlyDeleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _deleteTaskFromFirestore(id);
    notifyListeners();
  }

  void emptyRecycleBin() {
    final toDelete = _tasks.where((t) => t.isDeleted).map((t) => t.id).toList();
    for (var id in toDelete) {
      _deleteTaskFromFirestore(id);
    }
    _tasks.removeWhere((t) => t.isDeleted);
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
    _saveToPrefs();
    notifyListeners();
  }

  void deleteCategory(String id) {
    // 'all' is the primary root view that shows everything
    if (id.toLowerCase() == 'all') return;
    
    _categories.removeWhere((cat) => cat.id.toLowerCase() == id.toLowerCase() || cat.name.toLowerCase() == id.toLowerCase());
    if (_selectedCategory.toLowerCase() == id.toLowerCase()) {
      _selectedCategory = 'All';
    }
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> addEmployee(String name, String email, String password, String department) async {
    FirebaseApp? app;
    try {
      final appName = 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}';
      app = await Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
      
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
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding employee: $e');
      rethrow;
    } finally {
      if (app != null) {
        try {
          await app.delete();
        } catch (_) {}
      }
    }
  }

  Future<bool> deleteEmployee(String employeeUid) async {
    try {
      if (employeeUid.isEmpty) return false;
      
      // 1. Delete tasks subcollection of the employee
      final tasksSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(employeeUid)
          .collection('tasks')
          .get();
      for (var doc in tasksSnap.docs) {
        await doc.reference.delete();
      }

      // 2. Clear manager references if any employee was reporting to this user
      final subordinatesSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('managerId', isEqualTo: employeeUid)
          .get();
      for (var doc in subordinatesSnap.docs) {
        await doc.reference.update({'managerId': ''});
      }

      // 3. Delete user document from Firestore
      await FirebaseFirestore.instance.collection('users').doc(employeeUid).delete();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting employee: $e');
      return false;
    }
  }

        Future<void> debugPrintAllUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    for (var doc in snapshot.docs) {
      debugPrint('USER: ${doc.id} -> ${doc.data()}');
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

  Future<void> sendNotification(String targetUid, String message, {String title = 'Notification'}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(targetUid).collection('notifications').add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Show instant local notification if target is current device / user
      if (targetUid == _uid) {
        try {
          await NotificationService().showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: title,
            body: message,
          );
        } catch (_) {}
      }

      // Send FCM push notification
      final targetDoc = await FirebaseFirestore.instance.collection('users').doc(targetUid).get();
      if (targetDoc.exists && targetDoc.data() != null && targetDoc.data()!.containsKey('fcmToken')) {
        final fcmToken = targetDoc.data()!['fcmToken']?.toString();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await FCMService.sendPushNotification(
            fcmToken: fcmToken,
            title: title,
            body: message,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Future<void> broadcastNotificationToAllUsers({
    required String title,
    required String message,
  }) async {
    try {
      // 1. Show immediate local system push notification on device
      try {
        final notificationService = NotificationService();
        await notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: message,
        );
      } catch (notifErr) {
        debugPrint('Local push error: $notifErr');
      }

      // 2. Deliver in-app notification inbox & FCM push to all users in Firestore
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      for (var userDoc in usersSnap.docs) {
        final uId = userDoc.id;
        final uData = userDoc.data();

        // Add Firestore Notification in user's inbox
        await FirebaseFirestore.instance.collection('users').doc(uId).collection('notifications').add({
          'title': title,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        // Send FCM Push Notification if token exists
        if (uData.containsKey('fcmToken') && uData['fcmToken'] != null && uData['fcmToken'].toString().isNotEmpty) {
          final fcmToken = uData['fcmToken'].toString();
          await FCMService.sendPushNotification(
            fcmToken: fcmToken,
            title: title,
            body: message,
          );
        }
      }
    } catch (e) {
      debugPrint('Error broadcasting notification: $e');
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
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    if (_uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    if (_uid == null) return;
    try {
      final notifs = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('notifications')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in notifs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }

  Future<void> saveFcmToken() async {
    if (_uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
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
    
    // Combine both Firestore user mappings and attendance records
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .asyncExpand((userSnap) {
          final teamUids = <String>{};
          for (var doc in userSnap.docs) {
            final data = doc.data();
            final mId = (data['managerId'] ?? '').toString().trim();
            final uid = doc.id;
            if (mId == _uid || (_userEmail.toLowerCase().contains('inquiry') && data['email'] == 'rbcsaurabhyadav@gmail.com')) {
              teamUids.add(uid);
            }
          }

          return FirebaseFirestore.instance
              .collection('attendance')
              .snapshots()
              .map((snapshot) {
                final docs = snapshot.docs.map((doc) => doc.data()).where((d) {
                  final recUid = (d['uid'] ?? '').toString().trim();
                  final recMId = (d['managerId'] ?? '').toString().trim();
                  return recMId == _uid || teamUids.contains(recUid);
                }).toList();
                docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
                return docs;
              });
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
        .collection('users')
        .snapshots()
        .asyncExpand((userSnap) {
          final teamUids = <String>{};
          for (var doc in userSnap.docs) {
            final data = doc.data();
            final mId = (data['managerId'] ?? '').toString().trim();
            if (mId == managerId) {
              teamUids.add(doc.id);
            }
          }

          return FirebaseFirestore.instance
              .collection('attendance')
              .snapshots()
              .map((snapshot) {
                final docs = snapshot.docs.map((doc) => doc.data()).where((d) {
                  final recUid = (d['uid'] ?? '').toString().trim();
                  final recMId = (d['managerId'] ?? '').toString().trim();
                  return recMId == managerId || teamUids.contains(recUid);
                }).toList();
                docs.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
                return docs;
              });
        });
  }

  Future<void> punchIn(String base64Photo, double lat, double lng) async {
    if (_uid == null) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
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
    
    // Exact client timestamp saved immediately to ensure offline accuracy
    // Firestore offline persistence ensures this writes immediately to local SQLite/LevelDB and syncs to cloud on reconnect
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'uid': _uid,
      'userName': _userName,
      'role': _userRole,
      'managerId': mId,
      'date': today,
      'checkIn': Timestamp.fromDate(now),
      'localCheckIn': Timestamp.fromDate(now),
      'status': defaultStatus,
      'photo': base64Photo,
      'latIn': lat,
      'lngIn': lng,
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> punchOut(double lat, double lng, {String? photoOut, bool? isRemote}) async {
    if (_uid == null) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final docId = '${_uid}_$today';
    
    final payload = <String, dynamic>{
      'checkOut': Timestamp.fromDate(now),
      'localCheckOut': Timestamp.fromDate(now),
      'latOut': lat,
      'lngOut': lng,
      'syncedAt': FieldValue.serverTimestamp(),
    };
    if (photoOut != null && photoOut.isNotEmpty) {
      payload['photoOut'] = photoOut;
    }
    if (isRemote != null) {
      payload['isRemoteOut'] = isRemote;
    }

    await FirebaseFirestore.instance.collection('attendance').doc(docId).set(payload, SetOptions(merge: true));
  }

  Future<void> punchHourlyLeaveOut(double lat, double lng, {String? reason}) async {
    if (_uid == null) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final docId = '${_uid}_$today';
    
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'hourlyBreakOut': Timestamp.fromDate(now),
      'hourlyBreakOutLat': lat,
      'hourlyBreakOutLng': lng,
      if (reason != null) 'hourlyLeaveReason': reason,
      'onHourlyLeave': true,
      'status': 'On Hourly Leave',
      'syncedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> punchHourlyLeaveIn(double lat, double lng) async {
    if (_uid == null) return;
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final docId = '${_uid}_$today';
    
    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
      'hourlyBreakIn': Timestamp.fromDate(now),
      'hourlyBreakInLat': lat,
      'hourlyBreakInLng': lng,
      'onHourlyLeave': false,
      'status': 'Present (Hourly Leave Taken)',
      'syncedAt': FieldValue.serverTimestamp(),
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
      final Set<String> defaultDepts = {'IT', 'Sales', 'Marketing', 'Support', 'Operations', 'HR'};
      final Set<String> depts = Set.from(defaultDepts);
      final Set<String> deletedDepts = {};
      
      // Load custom defined & deleted departments from Firestore
      try {
        final settingsDoc = await FirebaseFirestore.instance.collection('company_settings').doc('departments').get();
        if (settingsDoc.exists) {
          final data = settingsDoc.data();
          if (data?['deleted_list'] != null) {
            for (var d in (data!['deleted_list'] as List<dynamic>)) {
              deletedDepts.add(d.toString().trim().toLowerCase());
            }
          }
          if (data?['list'] != null) {
            for (var d in (data!['list'] as List<dynamic>)) {
              final val = d.toString().trim();
              if (val.isNotEmpty) {
                depts.add(val);
              }
            }
          }
        }
      } catch (_) {}

      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dept = data['department'];
        if (dept != null && dept.toString().trim().isNotEmpty && dept.toString().trim() != 'Unassigned') {
          depts.add(dept.toString().trim());
        }
      }

      // Filter out any departments marked as deleted
      final result = depts.where((d) => !deletedDepts.contains(d.toLowerCase()) && d != 'Unassigned').toList();
      return result;
    } catch (e) {
      debugPrint('Error fetching departments: $e');
      return ['IT', 'Sales', 'Marketing', 'Support', 'Operations', 'HR'];
    }
  }

  Future<bool> createDepartment(String deptName) async {
    try {
      final clean = deptName.trim();
      if (clean.isEmpty) return false;
      await FirebaseFirestore.instance.collection('company_settings').doc('departments').set({
        'list': FieldValue.arrayUnion([clean]),
        'deleted_list': FieldValue.arrayRemove([clean, clean.toLowerCase()]),
      }, SetOptions(merge: true));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating department: $e');
      return false;
    }
  }

  Future<bool> updateDepartmentName(String oldDept, String newDept) async {
    try {
      final cleanOld = oldDept.trim();
      final cleanNew = newDept.trim();
      if (cleanNew.isEmpty || cleanOld.toLowerCase() == cleanNew.toLowerCase()) {
        return false;
      }

      // Update settings doc list
      try {
        final docRef = FirebaseFirestore.instance.collection('company_settings').doc('departments');
        final snap = await docRef.get();
        if (snap.exists && snap.data() != null) {
          List<String> list = List<String>.from(snap.data()!['list'] ?? []);
          list = list.where((d) => d.toLowerCase() != cleanOld.toLowerCase()).toList();
          if (!list.contains(cleanNew)) list.add(cleanNew);

          List<String> delList = List<String>.from(snap.data()!['deleted_list'] ?? []);
          delList.add(cleanOld.toLowerCase());
          delList.remove(cleanNew.toLowerCase());

          await docRef.set({'list': list, 'deleted_list': delList}, SetOptions(merge: true));
        } else {
          await docRef.set({
            'list': [cleanNew],
            'deleted_list': [cleanOld.toLowerCase()],
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final batch = FirebaseFirestore.instance.batch();
      int updateCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userDept = (data['department'] ?? '').toString().trim();
        if (userDept.toLowerCase() == cleanOld.toLowerCase()) {
          batch.update(doc.reference, {'department': cleanNew});
          updateCount++;
        }
      }
      if (updateCount > 0) {
        await batch.commit();
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating department name: $e');
      return false;
    }
  }

  Future<bool> deleteDepartment(String deptName) async {
    try {
      final clean = deptName.trim();
      if (clean.isEmpty) return false;

      // Add to deleted_list and remove from custom list in company_settings
      try {
        await FirebaseFirestore.instance.collection('company_settings').doc('departments').set({
          'list': FieldValue.arrayRemove([clean]),
          'deleted_list': FieldValue.arrayUnion([clean.toLowerCase(), clean]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating company_settings: $e');
      }

      // Unassign users belonging to this department
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userDept = (data['department'] ?? '').toString().trim();
        if (userDept.toLowerCase() == clean.toLowerCase()) {
          batch.update(doc.reference, {'department': 'Unassigned'});
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting department: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getManagersByDepartment(String dept) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> managerList = [];
      final cleanDept = dept.trim().toLowerCase();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userDept = (data['department'] ?? '').toString().trim().toLowerCase();
        final role = (data['role'] ?? 'employee').toString().trim().toLowerCase();
        final isManager = role == 'manager' || role == 'super_admin';

        if (isManager && (userDept == cleanDept || (cleanDept == 'it' && (userDept.contains('it') || data['email'] == 'rbcitsupport@gmail.com')))) {
          data['uid'] = doc.id;
          managerList.add(data);
        }
      }
      return managerList;
    } catch (e) {
      debugPrint('Error fetching managers for department: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStaffByDepartment(String dept) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, dynamic>> staffList = [];
      final cleanDept = dept.trim().toLowerCase();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userDept = (data['department'] ?? '').toString().trim().toLowerCase();
        if (userDept == cleanDept || (cleanDept == 'it' && (userDept.contains('it') || data['email'] == 'rbcitsupport@gmail.com'))) {
          data['uid'] = doc.id;
          staffList.add(data);
        }
      }
      return staffList;
    } catch (e) {
      debugPrint('Error fetching staff for department: $e');
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
        'title': voiceNoteUrl != null ? ' Voice Task Assigned' : 'New Task Assigned',
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

      await FirebaseFirestore.instance.collection('leaves').add({
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
          'leaveStatus': 'Pending',
          'leaveReason': reason,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error applying leave: $e');
      rethrow;
    }
  }

  // ===================== PROJECT MANAGEMENT =====================
  Stream<List<Project>> getProjectsStream() {
    return FirebaseFirestore.instance
        .collection('projects')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Project.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> createProject({
    required String title,
    String description = '',
    String category = 'General',
    int colorValue = 0xFF4F46E5,
    DateTime? deadline,
    List<String>? assignedUsers,
    List<ProjectAttachment>? attachments,
    List<ProjectLink>? links,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('projects').doc();
      final project = Project(
        id: docRef.id,
        title: title,
        description: description,
        category: category,
        colorValue: colorValue,
        deadline: deadline,
        createdAt: DateTime.now(),
        createdBy: _userName.isNotEmpty ? _userName : (_userEmail.isNotEmpty ? _userEmail : 'Admin'),
        assignedUsers: assignedUsers ?? [],
        attachments: attachments ?? [],
        links: links ?? [],
        status: 'Active',
        progress: 0,
      );

      await docRef.set(project.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating project: $e');
      rethrow;
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(project.id)
          .set(project.toJson(), SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating project: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await FirebaseFirestore.instance.collection('projects').doc(projectId).delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<void> exportTasksReport() async {
    try {
      final db = FirebaseFirestore.instance;
      
      // Fetch Users for names
      final usersSnap = await db.collection('users').get();
      final Map<String, String> userNames = {};
      for (var doc in usersSnap.docs) {
        userNames[doc.id] = doc.data()['name'] ?? 'Unknown';
      }

      // Fetch Tasks
      final tasksSnap = await db.collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();

      List<List<dynamic>> rows = [];
      rows.add([
        "Created At",
        "Task Title",
        "Description",
        "Category",
        "Priority",
        "Status",
        "Due Date",
        "Created By",
        "Assigned To",
        "Subtasks Count",
        "Attachments Count"
      ]);

      for (var doc in tasksSnap.docs) {
        final data = doc.data();
        
        final createdByUid = data['createdBy'] ?? '';
        final assignedToUid = data['assignedTo'] ?? '';
        
        final createdByName = userNames[createdByUid] ?? createdByUid;
        final assignedToName = assignedToUid.isNotEmpty ? (userNames[assignedToUid] ?? assignedToUid) : 'Unassigned';

        final createdAt = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString() : '';
        final dueDate = data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate().toString() : '';

        final subtasks = data['subtasks'] as List<dynamic>? ?? [];
        final attachments = data['attachments'] as List<dynamic>? ?? [];

        rows.add([
          createdAt,
          data['title'] ?? '',
          data['description'] ?? '',
          data['category'] ?? 'All',
          data['priority'] ?? 'Low',
          (data['isCompleted'] == true) ? 'Completed' : 'Pending',
          dueDate,
          createdByName,
          assignedToName,
          subtasks.length.toString(),
          attachments.length.toString()
        ]);
      }

      String csv = const CsvEncoder().convert(rows);
      final bytes = utf8.encode(csv);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: 'tasks_report.csv',
      );
      
      await Share.shareXFiles([xFile], text: 'Tasks Report');
    } catch (e) {
      print('Error exporting tasks report: $e');
      rethrow;
    }
  }

  static Future<void> exportMonthlyReport() async {
    try {
      final db = FirebaseFirestore.instance;
      
      // 1. Fetch Users
      final usersSnap = await db.collection('users').get();
      final Map<String, String> userNames = {};
      final Map<String, String> userRoles = {};
      for (var doc in usersSnap.docs) {
        userNames[doc.id] = doc.data()['name'] ?? 'Unknown';
        userRoles[doc.id] = doc.data()['role'] ?? 'Unknown';
      }

      // 2. Fetch Attendance
      final attendanceSnap = await db.collection('attendance')
          .orderBy('date', descending: true)
          .get();

      List<List<dynamic>> rows = [];
      rows.add([
        "Date",
        "Employee Name",
        "Role",
        "In Time",
        "Out Time",
        "In Location (Lat, Lng)",
        "Out Location (Lat, Lng)",
        "Notes"
      ]);

      for (var doc in attendanceSnap.docs) {
        final data = doc.data();
        final uid = data['uid'] ?? '';
        final checkIn = data['checkIn'] ?? '';
        final checkOut = data['checkOut'] ?? 'Not Punched Out';
        final latIn = data['latIn'];
        final lngIn = data['lngIn'];
        final latOut = data['latOut'];
        final lngOut = data['lngOut'];
        
        String inLoc = (latIn != null && lngIn != null) ? "$latIn, $lngIn" : "";
        String outLoc = (latOut != null && lngOut != null) ? "$latOut, $lngOut" : "";

        rows.add([
          data['date'] ?? '',
          userNames[uid] ?? 'Unknown ($uid)',
          userRoles[uid] ?? 'Employee',
          checkIn,
          checkOut,
          inLoc,
          outLoc,
          ""
        ]);
      }

      String csv = const CsvEncoder().convert(rows);
      
      final bytes = utf8.encode(csv);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: 'monthly_attendance_report.csv',
      );
      
      await Share.shareXFiles([xFile], text: 'Monthly Attendance Report');
    } catch (e) {
      print('Error exporting report: ');
      rethrow;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/super_admin_attendance_flow.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;
  DateTime _selectedCalendarMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _selectedCalendarYear = DateTime.now().year;

  // Office Geo-Fence Coordinates (Default or Configurable)
  static const double officeLatitude = 28.6139; // Default Office Lat (e.g. Connaught Place / Head Office)
  static const double officeLongitude = 77.2090; // Default Office Lng
  static const double maxAllowedDistanceMeters = 500.0; // 500m radius allowance

  Future<void> _handlePunchIn(TaskProvider taskProvider) async {
    setState(() => _isLoading = true);
    try {
      double lat = 0.0;
      double lng = 0.0;
      double distanceInMeters = 0.0;
      bool isWithinOffice = true;

      // 1. Try to get Location (with Geofence check)
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 6),
            );
            lat = position.latitude;
            lng = position.longitude;

            if (lat != 0.0 && lng != 0.0) {
              distanceInMeters = Geolocator.distanceBetween(
                lat,
                lng,
                officeLatitude,
                officeLongitude,
              );
              // If location is outside allowed office radius, prompt user
              if (distanceInMeters > maxAllowedDistanceMeters) {
                isWithinOffice = false;
              }
            }
          }
        }
      } catch (locErr) {
        debugPrint('Location skipped or unavailable: $locErr');
      }

      // If outside geofence, confirm with employee
      if (!isWithinOffice && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.location_off_rounded, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text('Geofence Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'Aap office location se ${(distanceInMeters / 1000).toStringAsFixed(1)} km door hain (Max allowed: ${(maxAllowedDistanceMeters).toInt()}m).\n\nKya aap Field Work / Remote punch-in record karna chahte hain?',
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Proceed Anyway', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (proceed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Pick/Take Front Camera Selfie with resilient fallback
      String base64String = '';
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.front,
          imageQuality: 50,
          maxWidth: 800,
          maxHeight: 800,
        );

        if (image != null) {
          final bytes = await image.readAsBytes();
          base64String = base64Encode(bytes);
        }
      } catch (camErr) {
        debugPrint('Camera capture issue: $camErr');
      }

      // 3. Punch In
      await taskProvider.punchIn(base64String, lat, lng);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWithinOffice ? 'Punched In Successfully (Office Location)!' : 'Punched In (Remote / Field Location Recorded)!'),
            backgroundColor: isWithinOffice ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePunchOut(TaskProvider taskProvider) async {
    setState(() => _isLoading = true);
    try {
      double lat = 0.0;
      double lng = 0.0;
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {}

      await taskProvider.punchOut(lat, lng);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punched Out Successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Punch out error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportAttendanceCsv(BuildContext context, TaskProvider taskProvider) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('attendance').get();
      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No attendance data available to export.')));
        return;
      }

      List<List<dynamic>> rows = [
        ['Date', 'Employee Name', 'Role', 'Check In', 'Check Out', 'Hours Worked', 'Status', 'GPS Latitude', 'GPS Longitude']
      ];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final inTs = data['checkIn'] as Timestamp?;
        final outTs = data['checkOut'] as Timestamp?;
        final inStr = inTs != null ? DateFormat('hh:mm a').format(inTs.toDate()) : '--';
        final outStr = outTs != null ? DateFormat('hh:mm a').format(outTs.toDate()) : '--';

        String hrs = '0.0';
        if (inTs != null && outTs != null) {
          final inDt = inTs.toDate();
          final outDt = outTs.toDate();
          int sec = outDt.difference(inDt).inSeconds;
          if (sec <= 0) {
            sec = (outDt.hour * 3600 + outDt.minute * 60) - (inDt.hour * 3600 + inDt.minute * 60);
            if (sec < 0) sec += 24 * 3600;
          }
          hrs = (sec / 3600.0).toStringAsFixed(2);
        }

        rows.add([
          data['date'] ?? '',
          data['userName'] ?? '',
          data['role'] ?? '',
          inStr,
          outStr,
          hrs,
          data['status'] ?? 'Present',
          data['latIn']?.toString() ?? '',
          data['lngIn']?.toString() ?? '',
        ]);
      }

      String csvData = const CsvEncoder().convert(rows);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Attendance_Salary_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
      await file.writeAsString(csvData);

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'RBC Management Attendance & Payroll Report (.CSV / Excel)');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final role = taskProvider.userRole;

    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return DefaultTabController(
      length: (role == 'super_admin') ? 3 : (role == 'manager' ? 3 : 2),
      child: Scaffold(
        backgroundColor: isDesktop ? const Color(0xFFF8FAFC) : AppTheme.background,
        appBar: AppBar(
          title: Text(
            'Attendance',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: isDesktop ? 20 : 17,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: isDesktop ? 1 : 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
          actions: [
            if (role == 'super_admin' || role == 'manager')
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export Payroll CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _exportAttendanceCsv(context, taskProvider),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(isDesktop ? 60 : 48),
            child: Container(
              alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 0),
              child: TabBar(
                isScrollable: true,
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlue,
                indicatorWeight: isDesktop ? 4 : 3,
                labelStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: isDesktop ? 17 : 14),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 16 : 14),
                tabs: [
                  const Tab(text: 'Punch & History'),
                  const Tab(text: 'Monthly Calendar'),
                  if (role == 'super_admin') ...[
                    const Tab(text: 'All Attendance'),
                  ] else if (role == 'manager') ...[
                    const Tab(text: 'Team Attendance'),
                  ],
                ],
              ),
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          padding: isDesktop ? const EdgeInsets.fromLTRB(32, 20, 32, 20) : EdgeInsets.zero,
          child: TabBarView(
            children: [
              _buildMyAttendance(context, taskProvider),
              _buildMonthlyCalendarView(taskProvider),
              if (role == 'super_admin') ...[
                const SuperAdminAttendanceFlow(),
              ] else if (role == 'manager') ...[
                _buildAttendanceList(taskProvider.getTeamAttendanceStream()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyAttendance(BuildContext context, TaskProvider taskProvider) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(isDesktop ? 20 : 16),
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 36 : 20, vertical: isDesktop ? 32 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 22 : 18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark Today\'s Attendance',
                        style: TextStyle(fontSize: isDesktop ? 24 : 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record your presence with GPS verification & selfie punch',
                        style: TextStyle(fontSize: isDesktop ? 15 : 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (isDesktop)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 20, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF4F46E5)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: isDesktop ? 24 : 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isDesktop ? 22 : 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(Icons.camera_alt_rounded, size: isDesktop ? 26 : 20),
                            label: Text('Punch In (Selfie Camera)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: isDesktop ? 18 : 15)),
                            onPressed: () => _handlePunchIn(taskProvider),
                          ),
                        ),
                        SizedBox(width: isDesktop ? 20 : 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isDesktop ? 22 : 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(Icons.logout_rounded, size: isDesktop ? 26 : 20),
                            label: Text('Punch Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: isDesktop ? 18 : 15)),
                            onPressed: () => _handlePunchOut(taskProvider),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24.0 : 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Attendance Records',
                style: TextStyle(fontSize: isDesktop ? 20 : 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
              Text(
                'Auto-updated real time',
                style: TextStyle(fontSize: isDesktop ? 14 : 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: _buildAttendanceList(taskProvider.getMyAttendanceStream())),
      ],
    );
  }

  Widget _buildAttendanceList(Stream<List<Map<String, dynamic>>> stream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading attendance.\n${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          final isDesktop = MediaQuery.of(context).size.width >= 850;
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 650 : double.infinity),
              margin: const EdgeInsets.all(24),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 24, vertical: isDesktop ? 48 : 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fingerprint_rounded, size: 52, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Attendance Records Yet',
                    style: TextStyle(fontSize: isDesktop ? 22 : 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your check-in and check-out entries will be securely logged and calculated here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: isDesktop ? 15 : 13, color: const Color(0xFF64748B), height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        final records = snapshot.data!;

        // 1. Calculate Monthly / Overall Summary Stats
        int totalDaysPresent = records.length;
        double totalHours = 0.0;
        int completePunchOuts = 0;

        Duration computeWorkDuration(Timestamp? inTs, Timestamp? outTs) {
          if (inTs == null || outTs == null) return Duration.zero;
          final inDt = inTs.toDate();
          final outDt = outTs.toDate();
          
          // First attempt exact datetime difference
          int seconds = outDt.difference(inDt).inSeconds;
          if (seconds <= 0) {
            // If date component mismatched, calculate by time of day on same 24-hr clock
            final inSec = inDt.hour * 3600 + inDt.minute * 60 + inDt.second;
            final outSec = outDt.hour * 3600 + outDt.minute * 60 + outDt.second;
            seconds = outSec - inSec;
            if (seconds < 0) seconds += 24 * 3600; // wrapped past midnight
          }
          return Duration(seconds: seconds < 0 ? 0 : seconds);
        }

        for (var rec in records) {
          final inTs = rec['checkIn'] as Timestamp?;
          final outTs = rec['checkOut'] as Timestamp?;
          if (inTs != null && outTs != null) {
            final dur = computeWorkDuration(inTs, outTs);
            if (dur.inMinutes > 0) {
              totalHours += dur.inMinutes / 60.0;
              completePunchOuts++;
            }
          }
        }

        Widget buildCard(Map<String, dynamic> rec) {
          final checkInTs = rec['checkIn'] as Timestamp?;
          final checkOutTs = rec['checkOut'] as Timestamp?;
          
          // Format Day and Date
          final dateStr = rec['date'] ?? '';
          String dayStr = "";
          if (dateStr.isNotEmpty) {
            try {
              final d = DateFormat('yyyy-MM-dd').parse(dateStr);
              dayStr = DateFormat('EEEE, d MMM yyyy').format(d);
            } catch (_) {}
          }
          
          final name = rec['userName'] ?? 'Unknown';
          final photoBase64 = rec['photo'] as String?;
          
          final checkInStr = checkInTs != null ? DateFormat('hh:mm a').format(checkInTs.toDate()) : '--:--';
          final checkOutStr = checkOutTs != null ? DateFormat('hh:mm a').format(checkOutTs.toDate()) : '--:--';

          // Calculate daily working duration safely
          String durationStr = '';
          if (checkInTs != null && checkOutTs != null) {
            final dur = computeWorkDuration(checkInTs, checkOutTs);
            final hours = dur.inHours;
            final minutes = dur.inMinutes.remainder(60);
            durationStr = '⏱️ ${hours}h ${minutes}m worked';
          } else if (checkInTs != null) {
            durationStr = '🟡 Currently Logged In';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Selfie Thumbnail
                  if (photoBase64 != null && photoBase64.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(base64Decode(photoBase64), fit: BoxFit.contain),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(photoBase64),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayStr.isNotEmpty ? dayStr : dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.login_rounded, size: 15, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(checkInStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(width: 12),
                            const Icon(Icons.logout_rounded, size: 15, color: Color(0xFFEF4444)),
                            const SizedBox(width: 4),
                            Text(checkOutStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        if (durationStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            durationStr,
                            style: TextStyle(
                              color: checkOutTs != null ? const Color(0xFF64748B) : const Color(0xFFD97706),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (checkOutTs != null ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rec['status'] ?? (checkOutTs != null ? 'Present' : 'Punch In'),
                      style: TextStyle(
                        color: checkOutTs != null ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final summaryCard = Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total Days', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('$totalDaysPresent Days', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(height: 36, width: 1, color: Colors.white24),
              Column(
                children: [
                  const Text('Total Hours', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('${totalHours.toStringAsFixed(1)} hrs', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(height: 36, width: 1, color: Colors.white24),
              Column(
                children: [
                  const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  const Text('Active', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 850;

            if (isDesktop) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    summaryCard,
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 96,
                        ),
                        itemCount: records.length,
                        itemBuilder: (context, idx) => buildCard(records[idx]),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: records.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return summaryCard;
                return buildCard(records[index - 1]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMonthlyCalendarView(TaskProvider taskProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: taskProvider.getMyAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data ?? [];
        final Map<String, Map<String, dynamic>> dateRecordMap = {};
        for (var r in records) {
          final d = r['date'] as String?;
          if (d != null && d.isNotEmpty) {
            dateRecordMap[d] = r;
          }
        }

        final selectedMonth = _selectedCalendarMonth;
        final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
        
        int presentCount = 0;
        int offCount = 0;
        int leaveCount = 0;

        List<Map<String, dynamic>> monthDays = [];
        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(selectedMonth.year, selectedMonth.month, day);
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final isSunday = date.weekday == DateTime.sunday;
          final isFuture = date.isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));

          String status = 'Absent';
          Color badgeColor = const Color(0xFFEF4444);
          String hoursInfo = '--';

          if (dateRecordMap.containsKey(dateKey)) {
            final rec = dateRecordMap[dateKey]!;
            final inTs = rec['checkIn'] as Timestamp?;
            final outTs = rec['checkOut'] as Timestamp?;
            
            if (inTs != null && outTs != null) {
              final inDt = inTs.toDate();
              final outDt = outTs.toDate();
              int seconds = outDt.difference(inDt).inSeconds;
              if (seconds <= 0) {
                final inSec = inDt.hour * 3600 + inDt.minute * 60 + inDt.second;
                final outSec = outDt.hour * 3600 + outDt.minute * 60 + outDt.second;
                seconds = outSec - inSec;
                if (seconds < 0) seconds += 24 * 3600;
              }
              final dur = Duration(seconds: seconds < 0 ? 0 : seconds);
              hoursInfo = '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
            } else if (inTs != null) {
              hoursInfo = 'In Progress';
            }

            status = 'Present';
            badgeColor = const Color(0xFF10B981);
            presentCount++;
          } else if (isSunday) {
            status = 'Weekly Off';
            badgeColor = const Color(0xFF64748B);
            hoursInfo = 'Holiday';
            if (!isFuture) offCount++;
          } else if (isFuture) {
            status = 'Upcoming';
            badgeColor = const Color(0xFF94A3B8);
            hoursInfo = '--';
          } else {
            status = 'Absent / Leave';
            badgeColor = const Color(0xFFEF4444);
            hoursInfo = 'Off/Leave';
            leaveCount++;
          }

          monthDays.add({
            'date': date,
            'dateKey': dateKey,
            'dayName': DateFormat('EEEE').format(date),
            'formattedDate': DateFormat('d MMM yyyy').format(date),
            'status': status,
            'color': badgeColor,
            'hours': hoursInfo,
            'record': dateRecordMap[dateKey],
          });
        }

        // Show latest dates first
        monthDays = monthDays.reversed.toList();

        return Column(
          children: [
            // Month & Year Selector Navigation Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.primaryBlue),
                            onPressed: () {
                              setState(() {
                                _selectedCalendarMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month - 1, 1);
                                _selectedCalendarYear = _selectedCalendarMonth.year;
                              });
                            },
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(selectedMonth),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.primaryBlue),
                            onPressed: () {
                              setState(() {
                                _selectedCalendarMonth = DateTime(_selectedCalendarMonth.year, _selectedCalendarMonth.month + 1, 1);
                                _selectedCalendarYear = _selectedCalendarMonth.year;
                              });
                            },
                          ),
                        ],
                      ),
                      // Year Selection Quick Dropdown
                      DropdownButton<int>(
                        value: _selectedCalendarYear,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryBlue),
                        items: [2024, 2025, 2026, 2027, 2028, 2029, 2030].map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryBlue)),
                          );
                        }).toList(),
                        onChanged: (year) {
                          if (year != null) {
                            setState(() {
                              _selectedCalendarYear = year;
                              _selectedCalendarMonth = DateTime(year, _selectedCalendarMonth.month, 1);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMonthStat('Present', '$presentCount', const Color(0xFF10B981)),
                      Container(height: 30, width: 1, color: Colors.grey.shade200),
                      _buildMonthStat('Weekly Off', '$offCount', const Color(0xFF64748B)),
                      Container(height: 30, width: 1, color: Colors.grey.shade200),
                      _buildMonthStat('Leave / Absent', '$leaveCount', const Color(0xFFEF4444)),
                    ],
                  ),
                ],
              ),
            ),
            
            // Date wise breakdown (Responsive 2-column or 3-column Grid on Desktop)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 850;
                  
                  if (isDesktop) {
                    final columns = constraints.maxWidth >= 1100 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 82,
                      ),
                      itemCount: monthDays.length,
                      itemBuilder: (context, idx) => _buildDayItemCard(monthDays[idx]),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: monthDays.length,
                    itemBuilder: (context, idx) => _buildDayItemCard(monthDays[idx]),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayItemCard(Map<String, dynamic> item) {
    final status = item['status'] as String;
    final Color color = item['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                DateFormat('dd').format(item['date']),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${item['dayName']}, ${item['formattedDate']}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Hours: ${item['hours']}",
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat(String title, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

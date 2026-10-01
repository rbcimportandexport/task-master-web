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
import 'leaves_screen.dart';
import 'holiday_policy_screen.dart';

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
        String msg = e.toString().replaceAll('Exception: ', '');
        if (msg.contains('client is offline') || msg.contains('unavailable')) {
          msg = 'Attendance recorded offline! Internet aane par server se sync ho jayega.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: msg.contains('offline') ? const Color(0xFFF59E0B) : Colors.red,
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

  Future<void> _handleHourlyLeaveOut(TaskProvider taskProvider) async {
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

      await taskProvider.punchHourlyLeaveOut(lat, lng);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punched Out for Hourly Leave! Have a safe break.'),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hourly Leave Punch Out Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleHourlyLeaveIn(TaskProvider taskProvider) async {
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

      await taskProvider.punchHourlyLeaveIn(lat, lng);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punched In! Welcome back from Hourly Leave.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hourly Leave Punch In Error: $e'),
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

    final isDesktop = MediaQuery.of(context).size.width >= 950;

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
            if (role == 'super_admin')
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B)),
                  tooltip: 'Sunday & Holiday Policy',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayPolicyScreen()));
                  },
                ),
              ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: taskProvider.getTodayAttendanceStream(),
      builder: (context, todaySnap) {
        final todayData = todaySnap.data?.data();
        final hasCheckIn = todayData?['checkIn'] != null;
        final hasCheckOut = todayData?['checkOut'] != null;
        final onHourlyLeave = todayData?['onHourlyLeave'] == true;
        final durationMode = todayData?['durationMode'] as String?;
        final halfDayType = todayData?['halfDayType'] as String?;
        final hourlyHours = todayData?['hourlyHours'];
        final hourlyTimeSlot = todayData?['hourlyTimeSlot'] as String?;
        final leaveStatus = todayData?['leaveStatus'] as String?;
        final inTs = todayData?['checkIn'] as Timestamp?;
        final outTs = todayData?['checkOut'] as Timestamp?;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.all(isDesktop ? 20 : 16),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 36 : 20, vertical: isDesktop ? 30 : 20),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mark Today\'s Attendance',
                              style: TextStyle(fontSize: isDesktop ? 24 : 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Record your presence with GPS verification & selfie punch',
                              style: TextStyle(fontSize: isDesktop ? 15 : 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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

                  // Active Hourly or Half Day Leave Banner
                  if (durationMode == 'Hourly') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.timer_rounded, color: Color(0xFF4F46E5), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Hourly Leave Pass (${hourlyHours ?? 1} hr${(hourlyHours ?? 1) > 1 ? "s" : ""})',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF312E81)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (leaveStatus == 'Approved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        leaveStatus ?? 'Pending',
                                        style: TextStyle(
                                          color: leaveStatus == 'Approved' ? const Color(0xFF047857) : const Color(0xFFB45309),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hourlyTimeSlot != null && hourlyTimeSlot.isNotEmpty
                                      ? 'Time Slot: $hourlyTimeSlot • ${onHourlyLeave ? "🔴 On Hourly Leave Break Now" : "Hourly pass recorded"}'
                                      : (onHourlyLeave ? "🔴 Currently On Hourly Leave Break" : "Short Permission Pass"),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onHourlyLeave ? const Color(0xFFDC2626) : const Color(0xFF4338CA),
                                    fontWeight: onHourlyLeave ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (durationMode == 'Half Day') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.tonality_rounded, color: Color(0xFFD97706), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Half Day Leave (${halfDayType ?? "First Half"})',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF78350F)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (leaveStatus == 'Approved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        leaveStatus ?? 'Approved',
                                        style: TextStyle(
                                          color: leaveStatus == 'Approved' ? const Color(0xFF047857) : const Color(0xFFB45309),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Your punch-in will be marked as Half Day Present alongside your leave.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: isDesktop ? 22 : 18),

                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                      : Column(
                          children: [
                            // Primary Punch In & Punch Out Controls
                            LayoutBuilder(
                              builder: (context, btnConstraints) {
                                final isNarrow = btnConstraints.maxWidth < 460;

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasCheckIn ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                                        label: Text(
                                          hasCheckIn ? 'Already Punched In Today' : 'Punch In (Selfie Camera)',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                        onPressed: hasCheckIn ? null : () => _handlePunchIn(taskProvider),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasCheckOut ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        icon: const Icon(Icons.logout_rounded, size: 20),
                                        label: Text(
                                          hasCheckOut ? 'Shift Completed (Punched Out)' : 'Punch Out',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                        onPressed: (!hasCheckIn || hasCheckOut) ? null : () => _handlePunchOut(taskProvider),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasCheckIn ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: isDesktop ? 22 : 16),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        icon: Icon(Icons.camera_alt_rounded, size: isDesktop ? 26 : 20),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            hasCheckIn ? 'Already Punched In Today' : 'Punch In (Selfie Camera)',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: isDesktop ? 18 : 15),
                                          ),
                                        ),
                                        onPressed: hasCheckIn ? null : () => _handlePunchIn(taskProvider),
                                      ),
                                    ),
                                    SizedBox(width: isDesktop ? 20 : 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: hasCheckOut ? const Color(0xFF94A3B8) : const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: isDesktop ? 22 : 16),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        icon: Icon(Icons.logout_rounded, size: isDesktop ? 26 : 20),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            hasCheckOut ? 'Shift Completed' : 'Punch Out',
                                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: isDesktop ? 18 : 15),
                                          ),
                                        ),
                                        onPressed: (!hasCheckIn || hasCheckOut) ? null : () => _handlePunchOut(taskProvider),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Hourly Leave Break Controls (if checked in and haven't fully checked out)
                            if (hasCheckIn && !hasCheckOut) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: onHourlyLeave ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                                  border: Border.all(color: onHourlyLeave ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      onHourlyLeave ? Icons.timer_rounded : Icons.timer_outlined,
                                      color: onHourlyLeave ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        onHourlyLeave
                                            ? 'Currently on Hourly Leave Break'
                                            : (durationMode == 'Hourly'
                                                ? 'Hourly Pass Approved: Ready for Break?'
                                                : 'Need short break / hourly pass?'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: onHourlyLeave ? const Color(0xFF312E81) : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!onHourlyLeave)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6366F1),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.pause_circle_outline_rounded, size: 16),
                                        label: const Text('Hourly Punch Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        onPressed: () => _handleHourlyLeaveOut(taskProvider),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                                        label: const Text('Hourly Punch In (Return)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        onPressed: () => _handleHourlyLeaveIn(taskProvider),
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // Quick Link to Apply Hourly / Half Day Leave
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryBlue,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.beach_access_rounded, size: 16),
                                  label: const Text(
                                    'Apply Hourly Pass / Half Day Leave →',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LeavesScreen()),
                                    );
                                  },
                                ),
                              ],
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
                  Expanded(
                    child: Text(
                      'Recent Attendance Records',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Sync',
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(child: _buildAttendanceList(taskProvider.getMyAttendanceStream())),
          ],
        );
      },
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
          final isDesktop = MediaQuery.of(context).size.width >= 950;
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

          final durationMode = rec['durationMode'] as String?;
          final halfDayType = rec['halfDayType'] as String?;
          final hourlyHours = rec['hourlyHours'];
          final hourlyTimeSlot = rec['hourlyTimeSlot'] as String?;
          final onHourlyLeave = rec['onHourlyLeave'] == true;

          // Calculate daily working duration safely
          String durationStr = '';
          if (checkInTs != null && checkOutTs != null) {
            final dur = computeWorkDuration(checkInTs, checkOutTs);
            final hours = dur.inHours;
            final minutes = dur.inMinutes.remainder(60);
            durationStr = '⏱️ ${hours}h ${minutes}m worked';
          } else if (checkInTs != null) {
            durationStr = onHourlyLeave ? '🔴 On Hourly Leave Break' : '🟡 Currently Logged In';
          }

          String displayStatus = rec['status'] ?? (checkOutTs != null ? 'Present' : 'Punch In');
          Color statusColor = checkOutTs != null ? const Color(0xFF10B981) : const Color(0xFFD97706);
          if (onHourlyLeave) {
            displayStatus = 'On Hourly Leave';
            statusColor = const Color(0xFF6366F1);
          } else if (durationMode == 'Half Day') {
            displayStatus = 'Half Day';
            statusColor = const Color(0xFFF59E0B);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                          style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dayStr.isNotEmpty ? dayStr : dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.login_rounded, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 3),
                                Text(checkInStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFEF4444)),
                                const SizedBox(width: 3),
                                Text(checkOutStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        if (durationStr.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            durationStr,
                            style: TextStyle(
                              color: onHourlyLeave
                                  ? const Color(0xFFDC2626)
                                  : (checkOutTs != null ? const Color(0xFF64748B) : const Color(0xFFD97706)),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (durationMode == 'Hourly') ...[
                          const SizedBox(height: 2),
                          Text(
                            '⏱️ Hourly Pass: ${hourlyHours ?? 1}h${hourlyTimeSlot != null ? " ($hourlyTimeSlot)" : ""}',
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else if (durationMode == 'Half Day') ...[
                          const SizedBox(height: 2),
                          Text(
                            '🌗 Half Day: ${halfDayType ?? "First Half"}',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
            final isDesktop = constraints.maxWidth >= 950;

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
                          mainAxisExtent: 135,
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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('company_settings').doc('holiday_policy').snapshots(),
      builder: (context, policySnap) {
        final sundayPolicy = policySnap.data?.data()?['sundayPolicy'] ?? 'Full Day Off';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('public_holidays').snapshots(),
          builder: (context, holidaysSnap) {
            final holidayDocs = holidaysSnap.data?.docs ?? [];
            final Map<String, String> publicHolidayMap = {};
            for (var h in holidayDocs) {
              final hData = h.data() as Map<String, dynamic>;
              final title = hData['title'] ?? 'Holiday';
              final startStr = hData['startDate'];
              final endStr = hData['endDate'];
              if (startStr != null && endStr != null) {
                try {
                  DateTime s = DateTime.parse(startStr);
                  DateTime e = DateTime.parse(endStr);
                  for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
                    final key = DateFormat('yyyy-MM-dd').format(d);
                    publicHolidayMap[key] = title;
                  }
                } catch (_) {}
              }
            }

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
                  final hasPublicHoliday = publicHolidayMap.containsKey(dateKey);
                  final publicHolidayName = publicHolidayMap[dateKey];

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
                  } else if (hasPublicHoliday) {
                    status = publicHolidayName ?? 'Public Holiday';
                    badgeColor = const Color(0xFFEC4899);
                    hoursInfo = 'Festival Off';
                    if (!isFuture) offCount++;
                  } else if (isSunday) {
                    if (sundayPolicy == 'Half Day Working') {
                      status = 'Sunday (Half Day)';
                      badgeColor = const Color(0xFFF59E0B);
                      hoursInfo = 'Half Day Duty';
                    } else if (sundayPolicy == 'Full Day Working') {
                      status = 'Sunday (Working)';
                      badgeColor = const Color(0xFF3B82F6);
                      hoursInfo = 'Full Day Duty';
                    } else {
                      status = 'Weekly Off';
                      badgeColor = const Color(0xFF64748B);
                      hoursInfo = 'Holiday';
                    }
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
          },
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

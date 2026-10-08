import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'voice_record_sheet.dart';
import 'voice_note_player.dart';

class AssignTaskSheet extends StatefulWidget {
  final String? employeeId;
  const AssignTaskSheet({super.key, this.employeeId});

  @override
  State<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<AssignTaskSheet> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Work');
  final _estimatedTimeController = TextEditingController();
  
  DateTime? _dueDate = DateTime.now();
  int _priority = 1; // 0: None, 1: Low, 2: Medium, 3: High
  bool _isLoading = false;
  bool _isFetchingData = true;

  String? _voiceNotePath;
  int? _voiceNoteDuration;

  List<String> _departments = ['All'];
  List<Map<String, dynamic>> _allUsers = [];

  String _selectedDept = 'All';
  String? _selectedManagerId;
  String? _selectedTargetUserId;
  String? _selectedTargetUserName;

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();
  }

  Future<void> _loadHierarchyData() async {
    try {
      final provider = context.read<TaskProvider>();
      final users = await provider.getEmployees();
      final depts = await provider.getDepartments();

      Set<String> deptSet = {'All'};
      deptSet.addAll(depts);
      for (var u in users) {
        if (u['department'] != null && u['department'].toString().isNotEmpty) {
          deptSet.add(u['department'].toString());
        }
      }

      String? targetId = widget.employeeId;
      String? targetName;
      if (targetId != null) {
        final match = users.firstWhere((u) => u['uid'] == targetId, orElse: () => {});
        if (match.isNotEmpty) {
          targetName = match['name'];
        }
      }

      if (mounted) {
        setState(() {
          _allUsers = users;
          _departments = deptSet.toList();
          _selectedTargetUserId = targetId;
          _selectedTargetUserName = targetName;
          _isFetchingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_voiceNotePath != null ? 'Voice Instructions (${DateFormat('dd MMM, h:mm a').format(DateTime.now())})' : '');

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a task title or record voice instructions')));
      return;
    }

    if (_selectedTargetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a manager or team member to assign this task to')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<TaskProvider>().assignTaskToEmployee(
        _selectedTargetUserId!,
        title: title,
        category: _categoryController.text.trim().isNotEmpty ? _categoryController.text.trim() : 'Work',
        dueDate: _dueDate,
        priority: _priority,
        estimatedTime: _estimatedTimeController.text.trim().isNotEmpty ? _estimatedTimeController.text.trim() : null,
        voiceNoteUrl: _voiceNotePath,
        voiceDurationSeconds: _voiceNoteDuration,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task successfully assigned to ${_selectedTargetUserName ?? "selected person"}!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error assigning task: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter managers
    List<Map<String, dynamic>> availableManagers = _allUsers.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      final dept = (u['department'] ?? 'Unassigned').toString();
      final isMgr = role == 'manager' || role == 'super_admin';
      if (_selectedDept != 'All') {
        return isMgr && dept == _selectedDept;
      }
      return isMgr;
    }).toList();

    // Filter team members of selected manager (or dept employees)
    List<Map<String, dynamic>> teamMembers = [];
    if (_selectedManagerId != null) {
      teamMembers = _allUsers.where((u) => u['managerId'] == _selectedManagerId).toList();
    } else if (_selectedDept != 'All') {
      teamMembers = _allUsers.where((u) {
        final dept = (u['department'] ?? 'Unassigned').toString();
        final role = (u['role'] ?? '').toString().toLowerCase();
        return dept == _selectedDept && role == 'employee';
      }).toList();
    } else {
      teamMembers = _allUsers.where((u) => (u['role'] ?? '').toString().toLowerCase() == 'employee').toList();
    }

    final isDesktop = MediaQuery.of(context).size.width >= 950;

    final sheetContent = Container(
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 680 : double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isDesktop
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: isDesktop ? 28 : 20,
        right: isDesktop ? 28 : 20,
        top: isDesktop ? 24 : 20,
      ),
      child: SafeArea(
        top: false,
        child: _isFetchingData
            ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Assign Task',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // STEP 1: SELECT DEPARTMENT
                  const Text('1. Select Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDept,
                        items: _departments.map((d) {
                          return DropdownMenuItem<String>(
                            value: d,
                            child: Row(
                              children: [
                                const Icon(Icons.business_rounded, size: 18, color: AppTheme.primaryBlue),
                                const SizedBox(width: 10),
                                Text(d, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedDept = val;
                              _selectedManagerId = null;
                              if (_selectedTargetUserId != null && widget.employeeId == null) {
                                _selectedTargetUserId = null;
                                _selectedTargetUserName = null;
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // STEP 2: SELECT MANAGER (Cross-Manager / Department Lead)
                  const Text('2. Select Manager / Lead', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select a Manager (or assign directly to Manager)'),
                        value: _selectedManagerId,
                        items: availableManagers.map((m) {
                          final mName = m['name'] ?? 'Manager';
                          final mDept = m['department'] ?? '';
                          return DropdownMenuItem<String>(
                            value: m['uid'],
                            child: Row(
                              children: [
                                const Icon(Icons.admin_panel_settings_rounded, size: 18, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 10),
                                Text(mName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                if (mDept.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text('($mDept)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = availableManagers.firstWhere((m) => m['uid'] == val, orElse: () => {});
                            setState(() {
                              _selectedManagerId = val;
                              // By default, assigning to manager
                              _selectedTargetUserId = val;
                              _selectedTargetUserName = match['name'];
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  // Action: Direct Manager Assign vs Team Member Choice
                  if (_selectedManagerId != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Assign to this Manager'),
                          selected: _selectedTargetUserId == _selectedManagerId,
                          selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _selectedTargetUserId == _selectedManagerId ? AppTheme.primaryBlue : const Color(0xFF475569),
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              final match = availableManagers.firstWhere((m) => m['uid'] == _selectedManagerId, orElse: () => {});
                              setState(() {
                                _selectedTargetUserId = _selectedManagerId;
                                _selectedTargetUserName = match['name'];
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Select from Team'),
                          selected: _selectedTargetUserId != _selectedManagerId && _selectedTargetUserId != null,
                          selectedColor: const Color(0xFF10B981).withOpacity(0.15),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: (_selectedTargetUserId != _selectedManagerId && _selectedTargetUserId != null) ? const Color(0xFF10B981) : const Color(0xFF475569),
                          ),
                          onSelected: (sel) {
                            if (sel && teamMembers.isNotEmpty) {
                              setState(() {
                                _selectedTargetUserId = teamMembers.first['uid'];
                                _selectedTargetUserName = teamMembers.first['name'];
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],

                  // STEP 3: SELECT SPECIFIC TEAM MEMBER (If choice is team)
                  if (_selectedManagerId != null && _selectedTargetUserId != _selectedManagerId) ...[
                    const SizedBox(height: 16),
                    const Text('3. Select Team Member (Employee)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    teamMembers.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                                SizedBox(width: 8),
                                Text('No team members found under this manager.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedTargetUserId,
                                items: teamMembers.map((emp) {
                                  return DropdownMenuItem<String>(
                                    value: emp['uid'],
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF10B981)),
                                        const SizedBox(width: 10),
                                        Text(emp['name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(width: 8),
                                        Text('(${emp['email'] ?? ""})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final match = teamMembers.firstWhere((e) => e['uid'] == val, orElse: () => {});
                                    setState(() {
                                      _selectedTargetUserId = val;
                                      _selectedTargetUserName = match['name'];
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                  ],

                  // Selected Person Banner
                  if (_selectedTargetUserName != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Assigning to: $_selectedTargetUserName',
                              style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text('Task Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  // Task Title
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'e.g. Audit IT infrastructure & submit report',
                      prefixIcon: const Icon(Icons.title_rounded, color: AppTheme.primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _voiceNotePath != null ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _voiceNotePath != null ? AppTheme.primaryBlue : const Color(0xFF64748B),
                        ),
                        tooltip: 'Record Voice Instructions',
                        onPressed: () async {
                          final res = await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const VoiceRecordSheet(),
                          );
                          if (res != null && res['path'] != null) {
                            setState(() {
                              _voiceNotePath = res['path'] as String;
                              _voiceNoteDuration = res['duration'] as int?;
                              if (_titleController.text.trim().isEmpty) {
                                _titleController.text = 'Voice Instructions (${DateFormat('dd MMM, h:mm a').format(DateTime.now())})';
                              }
                            });
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  // Voice Instructions Player / Attachment Card
                  if (_voiceNotePath != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: VoiceNotePlayerWidget(
                              audioPathOrUrl: _voiceNotePath!,
                              durationSeconds: _voiceNoteDuration,
                              isCompact: false,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _voiceNotePath = null;
                                _voiceNoteDuration = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final res = await showModalBottomSheet<Map<String, dynamic>>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const VoiceRecordSheet(),
                        );
                        if (res != null && res['path'] != null) {
                          setState(() {
                            _voiceNotePath = res['path'] as String;
                            _voiceNoteDuration = res['duration'] as int?;
                            if (_titleController.text.trim().isEmpty) {
                              _titleController.text = 'Voice Instructions (${DateFormat('dd MMM, h:mm a').format(DateTime.now())})';
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic_rounded, size: 16, color: AppTheme.primaryBlue),
                            SizedBox(width: 6),
                            Text(
                              '+ Attach Voice Instructions (Audio)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  // Estimated Time / Duration input
                  const SizedBox(height: 12),
                  TextField(
                    controller: _estimatedTimeController,
                    decoration: InputDecoration(
                      labelText: 'Estimated Time / Duration (Kitna time lagega)',
                      hintText: 'e.g. 2 hours, 45 mins, 1 day',
                      prefixIcon: const Icon(Icons.timer_outlined, color: AppTheme.primaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['30 mins', '1 hour', '2 hours', '4 hours', '1 day', '2 days'].map((opt) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _estimatedTimeController.text = opt;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _estimatedTimeController.text == opt ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _estimatedTimeController.text == opt ? AppTheme.primaryBlue : const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _estimatedTimeController.text == opt ? AppTheme.primaryBlue : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category & Due Date Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.folder_outlined, color: AppTheme.primaryBlue),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.primaryBlue),
                          label: Text(
                            _dueDate != null ? DateFormat('dd MMM yyyy').format(_dueDate!) : 'Set Due Date',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Assign Task Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
      ),
    );

    return PopScope(
      canPop: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          alignment: isDesktop ? Alignment.center : Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Prevent taps inside the sheet from dismissing
            child: sheetContent,
          ),
        ),
      ),
    );
  }
}

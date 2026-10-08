import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../providers/task_provider.dart';

class SpreadsheetGridEditor extends StatefulWidget {
  final String title;
  final Project? project;
  final String? initialCsvData;
  final Function(String csvContent)? onSave;

  const SpreadsheetGridEditor({
    super.key,
    required this.title,
    this.project,
    this.initialCsvData,
    this.onSave,
  });

  @override
  State<SpreadsheetGridEditor> createState() => _SpreadsheetGridEditorState();
}

class _SpreadsheetGridEditorState extends State<SpreadsheetGridEditor> {
  late List<String> _headers;
  late List<List<String>> _rows;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.initialCsvData != null && widget.initialCsvData!.trim().isNotEmpty) {
      final lines = const LineSplitter().convert(widget.initialCsvData!);
      if (lines.isNotEmpty) {
        _headers = lines.first.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
        _rows = [];
        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;
          final row = lines[i].split(',').map((e) => e.trim().replaceAll('"', '')).toList();
          while (row.length < _headers.length) {
            row.add('');
          }
          _rows.add(row);
        }
      } else {
        _initDefaultGrid();
      }
    } else {
      _initDefaultGrid();
    }
  }

  void _initDefaultGrid() {
    _headers = ['A (Title / Task)', 'B (Category)', 'C (Value / Amount)', 'D (Status)', 'E (Date / Remarks)'];
    _rows = [
      ['Project Kickoff', 'Planning', '100%', 'Completed', 'Approved'],
      ['Database Setup', 'Backend', '100%', 'Completed', 'Firestore sync'],
      ['API Endpoints', 'Backend', '80%', 'In Progress', 'Testing routes'],
      ['Frontend UI', 'UI/UX', '90%', 'In Progress', 'Responsive clean'],
      ['QA Testing', 'QA', '40%', 'Pending', 'Scheduled next week'],
      ['Deployment', 'DevOps', '0%', 'Pending', 'Awaiting signoff'],
      ['Client Demo', 'Meeting', '1', 'Scheduled', 'Friday 4 PM'],
      ['Documentation', 'Docs', '70%', 'In Progress', 'User manual'],
      ['', '', '', '', ''],
      ['', '', '', '', ''],
    ];
  }

  String _exportToCsv() {
    final buffer = StringBuffer();
    buffer.writeln(_headers.map((h) => '"$h"').join(','));
    for (final row in _rows) {
      buffer.writeln(row.map((cell) => '"$cell"').join(','));
    }
    return buffer.toString();
  }

  Future<void> _saveSheet() async {
    setState(() => _isSaving = true);
    final csvData = _exportToCsv();

    if (widget.onSave != null) {
      widget.onSave!(csvData);
    }

    if (widget.project != null) {
      final base64Content = base64Encode(utf8.encode(csvData));
      final fileName = widget.title.toLowerCase().endsWith('.csv')
          ? widget.title
          : '${widget.title}.csv';

      final existingIndex = widget.project!.attachments.indexWhere(
        (a) => a.name.toLowerCase() == fileName.toLowerCase(),
      );

      final newAtt = ProjectAttachment(
        name: fileName,
        path: '',
        extension: 'csv',
        sizeBytes: csvData.length,
        base64Data: base64Content,
      );

      final updatedAtts = List<ProjectAttachment>.from(widget.project!.attachments);
      if (existingIndex >= 0) {
        updatedAtts[existingIndex] = newAtt;
      } else {
        updatedAtts.add(newAtt);
      }

      final updatedProject = widget.project!.copyWith(attachments: updatedAtts);
      await context.read<TaskProvider>().updateProject(updatedProject);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Sheet changes saved successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _editCell(int rowIndex, int colIndex) {
    final currentVal = _rows[rowIndex][colIndex];
    final controller = TextEditingController(text: currentVal);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit: ${_headers[colIndex]} (Row ${rowIndex + 1})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Cell Content / Formula',
            hintText: 'Enter text, numbers or values...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) {
            setState(() {
              _rows[rowIndex][colIndex] = controller.text;
              _hasChanges = true;
            });
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() {
                _rows[rowIndex][colIndex] = controller.text;
                _hasChanges = true;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _editHeader(int colIndex) {
    final controller = TextEditingController(text: _headers[colIndex]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Column Header', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Column Title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _headers[colIndex] = controller.text.trim();
                  _hasChanges = true;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(List.generate(_headers.length, (_) => ''));
      _hasChanges = true;
    });
  }

  void _addColumn() {
    final colLetter = String.fromCharCode(65 + (_headers.length % 26));
    final controller = TextEditingController(text: 'Column $colLetter');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Column'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _headers.add(controller.text.trim());
                  for (var row in _rows) {
                    row.add('');
                  }
                  _hasChanges = true;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteRow(int index) {
    setState(() {
      _rows.removeAt(index);
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.table_chart_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    _hasChanges ? 'Unsaved Edits' : 'All Changes Saved',
                    style: TextStyle(
                      fontSize: 11,
                      color: _hasChanges ? Colors.orange.shade800 : const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _addRow,
            icon: const Icon(Icons.add_rounded, color: Color(0xFF10B981)),
            tooltip: 'Add Row',
          ),
          IconButton(
            onPressed: _addColumn,
            icon: const Icon(Icons.view_column_rounded, color: Color(0xFF10B981)),
            tooltip: 'Add Column',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSheet,
              icon: _isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded, size: 16),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tap any cell to edit content. Click Save to store changes.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFE2E8F0)),
                      dataRowColor: WidgetStateProperty.resolveWith<Color>((states) => Colors.white),
                      dividerThickness: 1,
                      columns: [
                        const DataColumn(
                          label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                        ..._headers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final header = entry.value;
                          return DataColumn(
                            label: InkWell(
                              onTap: () => _editHeader(index),
                              child: Row(
                                children: [
                                  Text(
                                    header,
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_rounded, size: 13, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        }),
                        const DataColumn(
                          label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ),
                      ],
                      rows: _rows.asMap().entries.map((rowEntry) {
                        final rowIndex = rowEntry.key;
                        final rowData = rowEntry.value;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text('${rowIndex + 1}', style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                            ),
                            ...rowData.asMap().entries.map((cellEntry) {
                              final colIndex = cellEntry.key;
                              final cellVal = cellEntry.value;
                              return DataCell(
                                InkWell(
                                  onTap: () => _editCell(rowIndex, colIndex),
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    constraints: const BoxConstraints(minWidth: 90, minHeight: 38),
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: Text(
                                      cellVal.isEmpty ? '—' : cellVal,
                                      style: TextStyle(
                                        color: cellVal.isEmpty ? Colors.grey.shade400 : const Color(0xFF1E293B),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                tooltip: 'Delete Row',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _deleteRow(rowIndex),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

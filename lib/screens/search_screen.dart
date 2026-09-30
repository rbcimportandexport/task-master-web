import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final results = _query.isEmpty
        ? []
        : taskProvider.tasks.where((t) => t.title.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search tasks...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
          ),
          onChanged: (val) => setState(() => _query = val),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const Center(
              child: Text(
                'Type something to search tasks',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
              ),
            )
          : (results.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks found',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  ),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final task = results[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => taskProvider.toggleTaskCompletion(task.id),
                        activeColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? const Color(0xFF94A3B8) : AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(task.category, style: const TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: Icon(
                          task.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                          color: task.isStarred ? const Color(0xFFFBBF24) : const Color(0xFF94A3B8),
                        ),
                        onPressed: () => taskProvider.toggleTaskStar(task.id),
                      ),
                    );
                  },
                )),
    );
  }
}

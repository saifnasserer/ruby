import 'package:flutter/material.dart';
import '../../../core/theme/ruby_theme.dart';
import '../../task_management/controllers/task_controller.dart';
import '../../../core/models/task.dart';
import '../../../presentation/widgets/task_bubble.dart';
import '../../../presentation/screens/task_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final TaskController taskController;

  const SearchScreen({super.key, required this.taskController});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final List<Map<String, dynamic>> results = [];
    final tasks = widget.taskController.tasks;

    tasks.forEach((dateKey, dateTasks) {
      for (var task in dateTasks) {
        if (task.isDeleted) continue;

        // Check task text
        if (task.text.toLowerCase().contains(query)) {
          results.add({'task': task, 'dateKey': dateKey});
          continue;
        }

        // Check subtasks
        for (var subtask in task.subtasks) {
          if (subtask.text.toLowerCase().contains(query)) {
            results.add({'task': task, 'dateKey': dateKey});
            break; // Avoid adding same task multiple times
          }
        }

        // Check transcription if it exists (assuming it's same as text for now, keeping it simple)
        // If we add dedicated description field logic later, add it here.
      }
    });

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _openTaskDetail(Task task, String dateKey) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          taskController: widget.taskController,
          dateKey: dateKey,
          onTaskUpdated: () {
            setState(() {
              _performSearch(); // Refresh results if task changed
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyTheme.background(context),
      appBar: AppBar(
        backgroundColor: RubyTheme.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RubyTheme.textPrimary(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'بحث في التاسكات...',
            hintStyle: RubyTheme.bodyLarge(
              context,
            ).copyWith(color: RubyTheme.textSecondary(context)),
            border: InputBorder.none,
          ),
          style: RubyTheme.heading2(context),
          cursorColor: RubyTheme.primary(context),
          onChanged: (value) {
            // Logic handled by listener
          },
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isSearching && _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: RubyTheme.textSecondary(context).withOpacity(0.2),
            ),
            SizedBox(height: 16),
            Text(
              'اكتب للبحث في تاسكاتك',
              style: RubyTheme.bodyLarge(
                context,
              ).copyWith(color: RubyTheme.textSecondary(context)),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: RubyTheme.textSecondary(context).withOpacity(0.2),
            ),
            SizedBox(height: 16),
            Text(
              'مفيش نتائج',
              style: RubyTheme.bodyLarge(
                context,
              ).copyWith(color: RubyTheme.textSecondary(context)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        final Task task = item['task'];
        final String dateKey = item['dateKey'];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: TaskBubble(
            task: task,
            onTap: () => _openTaskDetail(task, dateKey),
            isToday:
                false, // Or true if dateKey matches today, but false is safer for generic search
          ),
        );
      },
    );
  }
}

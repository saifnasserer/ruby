import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../features/task_management/controllers/task_controller.dart';

class TagManagementModal extends StatefulWidget {
  final TaskController taskController;

  const TagManagementModal({super.key, required this.taskController});

  @override
  State<TagManagementModal> createState() => _TagManagementModalState();
}

class _TagManagementModalState extends State<TagManagementModal> {
  final TextEditingController _tagInputController = TextEditingController();

  @override
  void dispose() {
    _tagInputController.dispose();
    super.dispose();
  }

  void _addNewTag([String? value]) {
    final tag = value?.trim();
    if (tag != null && tag.isNotEmpty) {
      widget.taskController.addGlobalTag(tag);
      _tagInputController.clear();
    }
  }

  void _renameTag(String oldTag) async {
    final controller = TextEditingController(text: oldTag);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الوسم'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != oldTag) {
      widget.taskController.renameGlobalTag(oldTag, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: RubyTheme.textSecondary(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('إدارة الوسوم', style: RubyTheme.heading2(context)),
          const SizedBox(height: 20),
          TextField(
            controller: _tagInputController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'إضافة وسم جديد...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(100)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: BorderSide(
                  color: RubyTheme.textSecondary(context).withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(100),
                borderSide: const BorderSide(color: RubyTheme.sapphire, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addNewTag(_tagInputController.text),
              ),
            ),
            onSubmitted: (value) => _addNewTag(value),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListenableBuilder(
              listenable: widget.taskController,
              builder: (context, _) {
                final tags = widget.taskController.availableTags;
                if (tags.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'لا يوجد وسوم حالياً',
                      style: RubyTheme.bodyMedium(context),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      title: Text(
                        tag,
                        style: RubyTheme.bodyLarge(context).copyWith(
                          color: RubyTheme.textPrimary(context),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: RubyTheme.sapphire),
                            onPressed: () => _renameTag(tag),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: RubyTheme.priorityHigh),
                            onPressed: () => widget.taskController.removeGlobalTag(tag),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showTagManagementModal(BuildContext context, TaskController taskController) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => TagManagementModal(taskController: taskController),
  );
}

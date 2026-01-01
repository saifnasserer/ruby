import '../models/task.dart';

class TestDataService {
  /// Generate mock tasks for testing
  /// Call this once to populate the app with sample data
  static Map<String, List<Task>> generateMockTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate the start of the current week (Monday)
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final Map<String, List<Task>> mockTasks = {};

    // Helper function to create date key
    String getDateKey(DateTime date) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    // Helper function to create task ID
    String createTaskId(int dayOffset, int taskIndex) {
      return 'mock_${dayOffset}_$taskIndex';
    }

    // Monday - Work tasks with high priority
    final monday = weekStart;
    final mondayKey = getDateKey(monday);
    mockTasks[mondayKey] = [
      Task(
        id: createTaskId(0, 1),
        text: 'إنهاء تقرير المشروع الشهري',
        createdAt: monday.add(const Duration(hours: 9)),
        dayOfWeek: mondayKey,
        priority: TaskPriority.important,
        category: 'عمل',
        tags: ['تقارير', 'مهم'],
        isCompleted: true,
        completedAt: monday.add(const Duration(hours: 14)),
      ),
      Task(
        id: createTaskId(0, 2),
        text: 'اجتماع الفريق الأسبوعي',
        createdAt: monday.add(const Duration(hours: 10)),
        dayOfWeek: mondayKey,
        priority: TaskPriority.normal,
        category: 'عمل',
        tags: ['اجتماعات'],
        isCompleted: true,
        completedAt: monday.add(const Duration(hours: 11)),
      ),
      Task(
        id: createTaskId(0, 3),
        text: 'مراجعة الكود للمشروع الجديد',
        createdAt: monday.add(const Duration(hours: 15)),
        dayOfWeek: mondayKey,
        priority: TaskPriority.normal,
        category: 'عمل',
        tags: ['برمجة', 'مراجعة'],
        isCompleted: false,
      ),
    ];

    // Tuesday - Mixed priorities
    final tuesday = weekStart.add(const Duration(days: 1));
    final tuesdayKey = getDateKey(tuesday);
    mockTasks[tuesdayKey] = [
      Task(
        id: createTaskId(1, 1),
        text: 'شراء هدية عيد ميلاد أحمد',
        createdAt: tuesday.add(const Duration(hours: 8)),
        dayOfWeek: tuesdayKey,
        priority: TaskPriority.important,
        category: 'شخصي',
        tags: ['تسوق', 'عائلة'],
        isCompleted: true,
        completedAt: tuesday.add(const Duration(hours: 18)),
      ),
      Task(
        id: createTaskId(1, 2),
        text: 'تحديث السيرة الذاتية',
        createdAt: tuesday.add(const Duration(hours: 12)),
        dayOfWeek: tuesdayKey,
        priority: TaskPriority.normal,
        category: 'تطوير',
        tags: ['وظيفة'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(1, 3),
        text: 'قراءة فصل من كتاب البرمجة',
        createdAt: tuesday.add(const Duration(hours: 20)),
        dayOfWeek: tuesdayKey,
        priority: TaskPriority.normal,
        category: 'تعلم',
        tags: ['قراءة', 'برمجة'],
        isCompleted: true,
        completedAt: tuesday.add(const Duration(hours: 21, minutes: 30)),
      ),
    ];

    // Wednesday - Development and learning
    final wednesday = weekStart.add(const Duration(days: 2));
    final wednesdayKey = getDateKey(wednesday);
    mockTasks[wednesdayKey] = [
      Task(
        id: createTaskId(2, 1),
        text: 'إصلاح الباقات في التطبيق',
        createdAt: wednesday.add(const Duration(hours: 9)),
        dayOfWeek: wednesdayKey,
        priority: TaskPriority.important,
        category: 'عمل',
        tags: ['باقات', 'عاجل'],
        isCompleted: true,
        completedAt: wednesday.add(const Duration(hours: 16)),
      ),
      Task(
        id: createTaskId(2, 2),
        text: 'مشاهدة كورس Flutter المتقدم',
        createdAt: wednesday.add(const Duration(hours: 19)),
        dayOfWeek: wednesdayKey,
        priority: TaskPriority.normal,
        category: 'تعلم',
        tags: ['Flutter', 'كورسات'],
        isCompleted: false,
      ),
    ];

    // Thursday - Personal tasks
    final thursday = weekStart.add(const Duration(days: 3));
    final thursdayKey = getDateKey(thursday);
    mockTasks[thursdayKey] = [
      Task(
        id: createTaskId(3, 1),
        text: 'موعد الطبيب الساعة 3 مساءً',
        createdAt: thursday.add(const Duration(hours: 8)),
        dayOfWeek: thursdayKey,
        priority: TaskPriority.important,
        category: 'صحة',
        tags: ['مواعيد', 'مهم'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(3, 2),
        text: 'تنظيف المنزل',
        createdAt: thursday.add(const Duration(hours: 10)),
        dayOfWeek: thursdayKey,
        priority: TaskPriority.normal,
        category: 'شخصي',
        tags: ['منزل'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(3, 3),
        text: 'الاتصال بالعائلة',
        createdAt: thursday.add(const Duration(hours: 18)),
        dayOfWeek: thursdayKey,
        priority: TaskPriority.normal,
        category: 'شخصي',
        tags: ['عائلة'],
        isCompleted: false,
      ),
    ];

    // Friday - Weekend prep
    final friday = weekStart.add(const Duration(days: 4));
    final fridayKey = getDateKey(friday);
    mockTasks[fridayKey] = [
      Task(
        id: createTaskId(4, 1),
        text: 'صلاة الجمعة',
        createdAt: friday.add(const Duration(hours: 11)),
        dayOfWeek: fridayKey,
        priority: TaskPriority.important,
        category: 'ديني',
        tags: ['صلاة'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(4, 2),
        text: 'تحضير خطة الأسبوع القادم',
        createdAt: friday.add(const Duration(hours: 16)),
        dayOfWeek: fridayKey,
        priority: TaskPriority.normal,
        category: 'تخطيط',
        tags: ['تنظيم'],
        isCompleted: false,
      ),
    ];

    // Saturday - Leisure and hobbies
    final saturday = weekStart.add(const Duration(days: 5));
    final saturdayKey = getDateKey(saturday);
    mockTasks[saturdayKey] = [
      Task(
        id: createTaskId(5, 1),
        text: 'ممارسة الرياضة',
        createdAt: saturday.add(const Duration(hours: 7)),
        dayOfWeek: saturdayKey,
        priority: TaskPriority.normal,
        category: 'صحة',
        tags: ['رياضة', 'صحة'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(5, 2),
        text: 'العمل على المشروع الشخصي',
        createdAt: saturday.add(const Duration(hours: 14)),
        dayOfWeek: saturdayKey,
        priority: TaskPriority.normal,
        category: 'تطوير',
        tags: ['مشاريع', 'برمجة'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(5, 3),
        text: 'مشاهدة فيلم مع العائلة',
        createdAt: saturday.add(const Duration(hours: 20)),
        dayOfWeek: saturdayKey,
        priority: TaskPriority.normal,
        category: 'ترفيه',
        tags: ['عائلة', 'استرخاء'],
        isCompleted: false,
      ),
    ];

    // Sunday - Planning and preparation
    final sunday = weekStart.add(const Duration(days: 6));
    final sundayKey = getDateKey(sunday);
    mockTasks[sundayKey] = [
      Task(
        id: createTaskId(6, 1),
        text: 'مراجعة أهداف الشهر',
        createdAt: sunday.add(const Duration(hours: 10)),
        dayOfWeek: sundayKey,
        priority: TaskPriority.normal,
        category: 'تخطيط',
        tags: ['أهداف', 'مراجعة'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(6, 2),
        text: 'تحضير ملابس الأسبوع',
        createdAt: sunday.add(const Duration(hours: 15)),
        dayOfWeek: sundayKey,
        priority: TaskPriority.normal,
        category: 'شخصي',
        tags: ['تنظيم'],
        isCompleted: false,
      ),
      Task(
        id: createTaskId(6, 3),
        text: 'كتابة مقال في المدونة',
        createdAt: sunday.add(const Duration(hours: 18)),
        dayOfWeek: sundayKey,
        priority: TaskPriority.normal,
        category: 'تطوير',
        tags: ['كتابة', 'محتوى'],
        isCompleted: false,
      ),
    ];

    return mockTasks;
  }
}

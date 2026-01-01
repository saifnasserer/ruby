import 'package:flutter/material.dart';
import '../../task_management/services/task_service.dart';

class WeeklyViewController extends ChangeNotifier {
  final TaskService _taskService = TaskService.instance;

  late TabController _tabController;
  late ScrollController _tabScrollController;
  late PageController _pageController;

  int _selectedIndex = 0;
  List<DateTime> _currentWeekDates = [];
  bool _isUserNavigating = false;

  // Arabic weekdays (Saturday to Friday)
  final List<String> _weekDays = [
    'الأحد', // Sunday
    'الإثنين', // Monday
    'الثلاثاء', // Tuesday
    'الأربعاء', // Wednesday
    'الخميس', // Thursday
    'الجمعة', // Friday
    'السبت', // Saturday
  ];

  // Getters
  TabController get tabController => _tabController;
  ScrollController get tabScrollController => _tabScrollController;
  PageController get pageController => _pageController;
  int get selectedIndex => _selectedIndex;
  List<DateTime> get currentWeekDates => _currentWeekDates;
  List<String> get weekDays => _weekDays;

  /// Initialize the weekly view controller
  void initialize(TickerProvider vsync) {
    // Initialize current week dates first
    _initializeCurrentWeek();

    // Find today's index for PageController initialization
    final todayIndex = _taskService.getTodayIndex(_currentWeekDates);

    // Initialize controllers
    _tabController = TabController(length: _weekDays.length, vsync: vsync);
    _tabScrollController = ScrollController();
    _pageController = PageController(
      initialPage: todayIndex >= 0 ? todayIndex : 0,
    );

    // Set up listeners
    _setupListeners();

    // Set today's tab as default
    _setTodayTab();
  }

  /// Set up controller listeners
  void _setupListeners() {
    // Only listen to page controller for swipe gestures
    _pageController.addListener(() {
      // Don't respond if user is navigating via tab tap
      if (_isUserNavigating) return;

      if (_pageController.page != null) {
        final pageIndex = _pageController.page!.round();
        // Only update if the page has actually changed and is valid
        if (pageIndex != _selectedIndex &&
            pageIndex >= 0 &&
            pageIndex < _weekDays.length) {
          _selectedIndex = pageIndex;
          // Update tab controller to match the page
          if (_tabController.index != pageIndex) {
            _tabController.animateTo(pageIndex);
          }
          notifyListeners();
        }
      }
    });
  }

  /// Initialize current week dates (Saturday to Friday)
  void _initializeCurrentWeek() {
    _currentWeekDates = _taskService.getCurrentWeekDates();
  }

  /// Set today's tab as default
  void _setTodayTab() {
    final todayIndex = _taskService.getTodayIndex(_currentWeekDates);

    if (todayIndex != -1) {
      // Set the initial index immediately without animation
      _tabController.index = todayIndex;
      _selectedIndex = todayIndex;

      // Scroll to today's tab after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use a microtask to ensure the scroll happens after the widget is fully built
        Future.microtask(() {
          if (_tabScrollController.hasClients) {
            // Note: Context will be passed from the widget
          }
        });
      });
    }
  }

  /// Handle tab tap
  void onTabTap(int index) {
    // Prevent unnecessary updates if already at the same index
    if (_selectedIndex == index) return;

    // Set flag to prevent listener feedback
    _isUserNavigating = true;

    // Update selected index immediately
    _selectedIndex = index;

    // Animate page controller to the selected page
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }

    // Update tab controller to match the selected index
    if (_tabController.index != index) {
      _tabController.animateTo(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }

    // Reset flag after animation completes
    Future.delayed(const Duration(milliseconds: 350), () {
      _isUserNavigating = false;
    });

    // Notify listeners of the change
    notifyListeners();
  }

  /// Check if a date is today
  bool isToday(DateTime date) {
    return _taskService.isToday(date);
  }

  /// Check if an index is today
  bool isTodayIndex(int index) {
    if (index >= 0 && index < _currentWeekDates.length) {
      return isToday(_currentWeekDates[index]);
    }
    return false;
  }

  /// Get date display text
  String getDateDisplayText(DateTime date, bool showDate) {
    return _taskService.getDateDisplayText(date, showDate);
  }

  /// Get date key
  String getDateKey(DateTime date) {
    return _taskService.getDateKey(date);
  }

  /// Get current date key
  String getCurrentDateKey() {
    return getDateKey(_currentWeekDates[_selectedIndex]);
  }

  /// Dispose controllers
  @override
  void dispose() {
    _tabController.dispose();
    _tabScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

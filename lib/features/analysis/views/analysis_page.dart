import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/ruby_theme.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/chat_history_service.dart';
import '../../../core/services/analysis_service.dart';
import '../../../core/models/task.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool _isLoading = true;
  AnalysisMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasksMap = await StorageService.loadTasks();
    final List<Task> allTasks = [];
    tasksMap.forEach((_, tasks) => allTasks.addAll(tasks));

    final allMessages = await ChatHistoryService.getAllChatHistory();

    if (mounted) {
      setState(() {
        _metrics = AnalysisService.calculateMetrics(allTasks, allMessages);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RubyTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('تحليل الإنتاجية', style: RubyTheme.heading2(context)),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: RubyTheme.textPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metrics == null
          ? const Center(child: Text('لا يوجد بيانات كافية للتحليل'))
          : Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyDials(),
                    const SizedBox(height: 24),
                    _buildOverviewHero(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('تحليل التاجيل (المشورة)'),
                    _buildMigrationChart(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('أوقات الذروة'),
                    _buildHourlyActivityChart(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('توزيع المهام'),
                    _buildCategoryAndPriorityBreakdown(),
                    const SizedBox(height: 24),
                    _buildStreakSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: RubyTheme.heading2(
          context,
        ).copyWith(color: RubyTheme.textPrimary(context), fontSize: 18),
      ),
    );
  }

  Widget _buildDailyDials() {
    final completed = _metrics!.todayCompleted;
    final total = _metrics!.todayTotal;
    final remaining = total - completed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'إنجاز اليوم',
            style: RubyTheme.heading2(context).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 50,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    color: RubyTheme.emerald,
                    value: total > 0 ? completed.toDouble() : 1,
                    title: '',
                    radius: 20,
                    badgeWidget: total > 0 && completed > 0
                        ? _buildDialBadge(completed)
                        : null,
                    badgePositionPercentageOffset: 1,
                  ),
                  PieChartSectionData(
                    color: RubyTheme.surfaceVariant(context),
                    value: total > 0
                        ? (remaining > 0 ? remaining.toDouble() : 0)
                        : 0,
                    title: '',
                    radius: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('مكتمل', '$completed', RubyTheme.emerald),
              _buildStatItem(
                'المتبقي',
                '$remaining',
                RubyTheme.textSecondary(context),
              ),
              _buildStatItem('الإجمالي', '$total', RubyTheme.primary(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: RubyTheme.emerald,
        size: 20,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: RubyTheme.bodyMedium(context).copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildOverviewHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معدل الإنجاز العام',
                  style: RubyTheme.bodyLarge(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'لقد أنجزت ${_metrics!.completedTasks} من ${_metrics!.totalTasks} مهمة إجمالية.',
                  style: RubyTheme.bodyMedium(
                    context,
                  ).copyWith(color: RubyTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            width: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _metrics!.completionRate,
                  strokeWidth: 8,
                  backgroundColor: RubyTheme.surfaceVariant(context),
                  color: RubyTheme.emerald,
                ),
                Center(
                  child: Text(
                    '${(_metrics!.completionRate * 100).toInt()}%',
                    style: RubyTheme.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrationChart() {
    final dates = _metrics!.completionOverTime.keys.toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('مكتمل', RubyTheme.emerald),
              const SizedBox(width: 16),
              _buildLegendItem('مؤجل', Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxYForBarChart(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= dates.length) {
                          return const SizedBox();
                        }
                        final date = dates[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dates.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _metrics!.completionOverTime[dates[i]]!.toDouble(),
                        color: RubyTheme.emerald,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: _metrics!.migrationOverTime[dates[i]]!.toDouble(),
                        color: Colors.orange,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxYForBarChart() {
    int maxVal = 0;
    for (var v in _metrics!.completionOverTime.values) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in _metrics!.migrationOverTime.values) {
      if (v > maxVal) maxVal = v;
    }
    return (maxVal + 2).toDouble();
  }

  Widget _buildHourlyActivityChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 4,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}:00',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _metrics!.hourlyActivity.entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.toDouble());
              }).toList(),
              isCurved: true,
              color: RubyTheme.primary(context),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: RubyTheme.primary(context).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAndPriorityBreakdown() {
    return Row(
      children: [
        Expanded(child: _buildPriorityChart()),
        const SizedBox(width: 16),
        Expanded(child: _buildCategoryStats()),
      ],
    );
  }

  Widget _buildPriorityChart() {
    final important = _metrics!.tasksByPriority[TaskPriority.important] ?? 0;
    final normal = _metrics!.tasksByPriority[TaskPriority.normal] ?? 0;
    final total = important + normal;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'الأولوية',
            style: RubyTheme.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 20,
                sections: [
                  PieChartSectionData(
                    color: RubyTheme.priorityHigh,
                    value: important.toDouble(),
                    title: total > 0
                        ? '${(important / total * 100).toInt()}%'
                        : '',
                    radius: 30,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: RubyTheme.priorityMedium,
                    value: normal.toDouble(),
                    title: total > 0
                        ? '${(normal / total * 100).toInt()}%'
                        : '',
                    radius: 30,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('مهم', RubyTheme.priorityHigh, size: 8),
              const SizedBox(width: 8),
              _buildLegendItem('عادي', RubyTheme.priorityMedium, size: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats() {
    final categories = _metrics!.tasksByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RubyTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفئات الأكثر تردداً',
            style: RubyTheme.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (categories.isEmpty)
            const Expanded(
              child: Center(
                child: Text('لا توجد فئات', style: TextStyle(fontSize: 12)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: categories.take(3).length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categories[i].key,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${categories[i].value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [RubyTheme.emerald, RubyTheme.emerald.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStreakItem(
            'الرقم الحالي',
            '${_metrics!.currentStreak}',
            Icons.local_fire_department_rounded,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildStreakItem(
            'أعلى رقم',
            '${_metrics!.recordStreak}',
            Icons.emoji_events_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, {double size = 12}) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: size - 2)),
      ],
    );
  }
}

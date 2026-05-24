import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:table_calendar/table_calendar.dart';

class KidProgressScreen extends StatefulWidget {
  final UserModel kid;
  const KidProgressScreen({super.key, required this.kid});

  @override
  State<KidProgressScreen> createState() => _KidProgressScreenState();
}

enum TabItem { week, month, year }

class _KidProgressScreenState extends State<KidProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateTime _today = DateTime.now();
  DateTime _currentDate = DateTime.now();
  Stream<List<TaskModel>>? _tasksStream;
  TabItem _selectedTab = TabItem.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _updateTasksStream();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedTab = TabItem.values[_tabController.index];
      });
      _updateTasksStream();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  String _getWeekRange(DateTime date) {
    DateTime firstDayOfWeek = _startOfWeek(date);
    DateTime lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));

    if (firstDayOfWeek.month != lastDayOfWeek.month) {
      return '${DateFormat('d MMMM', 'ru').format(firstDayOfWeek)} - ${DateFormat('d MMMM yyyy', 'ru').format(lastDayOfWeek)}';
    } else {
      return '${DateFormat('d', 'ru').format(firstDayOfWeek)} - ${DateFormat('d MMMM yyyy', 'ru').format(lastDayOfWeek)}';
    }
  }

  String _getMonthRange(DateTime date) {
    return getMonthYearInNominative(date);
  }

  String _getYearRange(DateTime date) {
    return DateFormat('yyyy', 'ru').format(date);
  }

  void _goToPrevious() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentDate = _currentDate.subtract(const Duration(days: 7));
          break;
        case 1:
          _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
          break;
        case 2:
          _currentDate = DateTime(_currentDate.year - 1, _currentDate.month, _currentDate.day);
          break;
      }
    });
    _updateTasksStream();
  }

  void _goToNext() {
    setState(() {
      switch (_tabController.index) {
        case 0:
          _currentDate = _currentDate.add(const Duration(days: 7));
          break;
        case 1:
          _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, _currentDate.day);
          break;
        case 2:
          _currentDate = DateTime(_currentDate.year + 1, _currentDate.month, _currentDate.day);
          break;
      }
    });
    _updateTasksStream();
  }

  bool _canGoForward() {
    switch (_tabController.index) {
      case 0:
        final DateTime displayedStartOfWeek = _startOfWeek(_currentDate);
        final DateTime todayStartOfWeek = _startOfWeek(_today);
        return displayedStartOfWeek.isBefore(todayStartOfWeek);
      case 1:
        return _currentDate.year < _today.year ||
            (_currentDate.year == _today.year && _currentDate.month < _today.month);
      case 2:
        return _currentDate.year < _today.year;
      default:
        return false;
    }
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday == 7 ? 6 : date.weekday - 1));
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Map<String, DateTime> _getDateRange() {
    DateTime startDate;
    DateTime endDate;

    switch (_tabController.index) {
      case 0:
        startDate = _startOfWeek(_currentDate);
        endDate = _endOfDay(startDate.add(const Duration(days: 6)));
        break;
      case 1:
        startDate = DateTime(_currentDate.year, _currentDate.month, 1);
        endDate = _endOfDay(DateTime(_currentDate.year, _currentDate.month + 1, 0));
        break;
      case 2:
        startDate = DateTime(_currentDate.year, 1, 1);
        endDate = _endOfDay(DateTime(_currentDate.year, 12, 31));
        break;
      default:
        startDate = _currentDate;
        endDate = _currentDate;
    }
    return {'startDate': startDate, 'endDate': endDate};
  }

  void _updateTasksStream() {
    final dateRange = _getDateRange();
    final startDate = dateRange['startDate']!.dateOnly;
    final endDate = dateRange['endDate']!.dateOnly;

    final endDateFormatted = DateTime(endDate.year, endDate.month, endDate.day, 23, 59);

    _tasksStream = TaskModel.collection
        .where('kid', isEqualTo: widget.kid.ref)
        .where('action_date', isGreaterThanOrEqualTo: startDate)
        .where('action_date', isLessThanOrEqualTo: endDateFormatted)
        .where('status', whereIn: ['completed', 'canceled'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: greyscale100,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(text: 'taskProgress'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(111),
          child: _KidProgressHeader(
            tabController: _tabController,
            goToPrevious: _goToPrevious,
            goToNext: _goToNext,
            canGoForward: _canGoForward(),
            displayedDate: _tabController.index == 0
                ? _getWeekRange(_currentDate)
                : _tabController.index == 1
                    ? _getMonthRange(_currentDate)
                    : _getYearRange(_currentDate),
          ),
        ),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _TaskCountsInfo(tasks: tasks),
                const SizedBox(height: 24),
                _ProgressCompletePercentage(
                  tasks: tasks,
                  selectedTab: _selectedTab,
                  dates: _getDateRange(),
                ),
                const SizedBox(height: 24),
                _ProgressCompleteCount(
                  tasks: tasks,
                  selectedTab: _selectedTab,
                  dates: _getDateRange(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KidProgressHeader extends StatelessWidget {
  final TabController tabController;
  final VoidCallback goToPrevious;
  final VoidCallback goToNext;
  final String displayedDate;
  final bool canGoForward;
  const _KidProgressHeader({
    required this.tabController,
    required this.goToPrevious,
    required this.goToNext,
    required this.displayedDate,
    required this.canGoForward,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              color: greyscale100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TabBar(
              controller: tabController,
              tabs: [
                Tab(text: 'week'.tr()),
                Tab(text: 'month'.tr()),
                Tab(text: 'year'.tr()),
              ],
              dividerHeight: 0,
              dividerColor: greyscale100,
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: greyscale900,
                fontFamily: Involve,
                height: 1.6,
              ),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: white,
                fontFamily: Involve,
                height: 1.6,
              ),
              unselectedLabelColor: greyscale900,
              labelColor: white,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(borderRadius: BorderRadius.circular(6), color: primary900),
              indicatorPadding: EdgeInsets.zero,
              labelPadding: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              splashBorderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: goToPrevious,
                  child: const Icon(Icons.arrow_back_ios),
                ),
                Expanded(child: Center(child: AppText(text: displayedDate))),
                GestureDetector(
                  onTap: canGoForward ? goToNext : null,
                  child: Icon(Icons.arrow_forward_ios, color: canGoForward ? null : greyscale500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TaskCountsInfo extends StatelessWidget {
  final List<TaskModel> tasks;
  const _TaskCountsInfo({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).length;
    final canceledTasks = tasks.where((task) => task.status == TaskStatus.canceled).length;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 94,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary900, width: 2),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 38,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    color: primary900,
                  ),
                  child: Center(
                    child: AppText(
                      text: 'tasksCompleted'.tr(),
                      size: 14,
                      fw: FontWeight.w700,
                      color: white,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/progress.svg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      AppText(text: completedTasks.toString(), size: 20, fw: FontWeight.bold),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 94,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: red, width: 2),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 38,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                    color: red,
                  ),
                  child: Center(
                    child: AppText(
                      text: 'taskCanceled'.tr(),
                      size: 14,
                      fw: FontWeight.w700,
                      color: white,
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/progress_red.svg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      AppText(text: canceledTasks.toString(), size: 20, fw: FontWeight.bold),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressCompletePercentage extends StatefulWidget {
  final List<TaskModel> tasks;
  final TabItem selectedTab;
  final Map<String, DateTime> dates;
  const _ProgressCompletePercentage({required this.tasks, required this.selectedTab, required this.dates});

  @override
  State<_ProgressCompletePercentage> createState() => _ProgressCompletePercentageState();
}

class _ProgressCompletePercentageState extends State<_ProgressCompletePercentage> {
  int touchedIndex = -1;

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    double width = 34,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isTouched ? primary900 : primary900.withOpacity(0.48),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
          width: width,
          backDrawRodData: BackgroundBarChartRodData(
            color: primary900.withOpacity(0.08),
            toY: 1,
            show: true,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingWeekGroups() {
    final DateTime startDate = widget.dates['startDate']!;

    return List.generate(7, (i) {
      final addDuration = Duration(days: i);
      switch (i) {
        case 0:
          return makeGroupData(
            0,
            _getWeekCompletePercentage(widget.tasks, startDate),
            isTouched: i == touchedIndex,
          );
        case 1:
          return makeGroupData(
            1,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 2:
          return makeGroupData(
            2,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 3:
          return makeGroupData(
            3,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 4:
          return makeGroupData(
            4,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 5:
          return makeGroupData(
            5,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 6:
          return makeGroupData(
            6,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        default:
          return throw Error();
      }
    });
  }

  double _getWeekCompletePercentage(List<TaskModel> tasks, DateTime day) {
    if (tasks.isEmpty) return 0;
    final items = widget.tasks.where((task) => isSameDay(day, task.actionDate)).toList();
    if (items.isEmpty) return 0;
    final completedTasks = items.where((task) => task.status == TaskStatus.completed).toList().length;
    return completedTasks / items.length;
  }

  List<BarChartGroupData> showingMonthGroups() {
    final DateTime startDate = widget.dates['startDate']!;
    return List.generate(7, (i) {
      switch (i) {
        case 0:
          return makeGroupData(
            0,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 1:
          return makeGroupData(
            1,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 2:
          return makeGroupData(
            2,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 3:
          return makeGroupData(
            3,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 4:
          return makeGroupData(
            4,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 5:
          return makeGroupData(
            5,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 6:
          return makeGroupData(
            6,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        default:
          return throw Error();
      }
    });
  }

  double _getMonthCompletePercentage(List<TaskModel> tasks, int index, DateTime month) {
    if (tasks.isEmpty) return 0;
    final dates = _getIndexDates(index, month);
    final items = _filterTasksByDates(tasks, dates);
    if (items.isEmpty) return 0;
    final completedTasks = items.where((task) => task.status == TaskStatus.completed).toList().length;
    return completedTasks / items.length;
  }

  List<TaskModel> _filterTasksByDates(List<TaskModel> tasks, List<DateTime> dates) {
    List<TaskModel> filteredTasks = [];

    for (TaskModel task in tasks) {
      for (DateTime date in dates) {
        if (isSameDay(task.actionDate, date)) {
          filteredTasks.add(task);
          break;
        }
      }
    }
    return filteredTasks;
  }

  List<DateTime> _getIndexDates(int index, DateTime month) {
    final int monthDays = DateTime(month.year, month.month + 1, 0).day;

    switch (index) {
      case 0:
        return List.generate(4, (i) => DateTime(month.year, month.month, i + 1));
      case 1:
        return List.generate(4, (i) => DateTime(month.year, month.month, 5 + i));
      case 2:
        return List.generate(4, (i) => DateTime(month.year, month.month, 9 + i));
      case 3:
        return List.generate(4, (i) => DateTime(month.year, month.month, 13 + i));
      case 4:
        return List.generate(4, (i) => DateTime(month.year, month.month, 17 + i));
      case 5:
        return List.generate(4, (i) => DateTime(month.year, month.month, 21 + i));
      case 6:
        return List.generate((monthDays - 24), (i) => DateTime(month.year, month.month, 25 + i));
      default:
        return [];
    }
  }

  List<BarChartGroupData> showingYearGroups() {
    return List.generate(6, (i) {
      switch (i) {
        case 0:
          return makeGroupData(
            0,
            _getYearCompletePercentage(widget.tasks, 1, 2),
            isTouched: i == touchedIndex,
          );
        case 1:
          return makeGroupData(
            1,
            _getYearCompletePercentage(widget.tasks, 3, 4),
            isTouched: i == touchedIndex,
          );
        case 2:
          return makeGroupData(
            2,
            _getYearCompletePercentage(widget.tasks, 5, 6),
            isTouched: i == touchedIndex,
          );
        case 3:
          return makeGroupData(
            3,
            _getYearCompletePercentage(widget.tasks, 7, 8),
            isTouched: i == touchedIndex,
          );
        case 4:
          return makeGroupData(
            4,
            _getYearCompletePercentage(widget.tasks, 9, 10),
            isTouched: i == touchedIndex,
          );
        case 5:
          return makeGroupData(
            5,
            _getYearCompletePercentage(widget.tasks, 11, 12),
            isTouched: i == touchedIndex,
          );

        default:
          return throw Error();
      }
    });
  }

  double _getYearCompletePercentage(List<TaskModel> tasks, int month1, int month2) {
    if (tasks.isEmpty) return 0;
    final items =
        widget.tasks.where((task) => task.actionDate?.month == month1 || task.actionDate?.month == month2).toList();
    if (items.isEmpty) return 0;
    final completedTasks = items.where((task) => task.status == TaskStatus.completed).toList().length;
    return completedTasks / items.length;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = widget.dates['startDate']!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(text: 'completeProsent'.tr(), size: 20, fw: FontWeight.w700),
          const Divider(height: 32, thickness: 1, color: greyscale200),
          SizedBox(
            width: double.infinity,
            height: 255,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                gridData: const FlGridData(show: false),
                backgroundColor: white,
                borderData: FlBorderData(show: false),
                barGroups: widget.selectedTab == TabItem.week
                    ? showingWeekGroups()
                    : widget.selectedTab == TabItem.month
                        ? showingMonthGroups()
                        : showingYearGroups(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    direction: TooltipDirection.top,
                    getTooltipColor: (group) => white,
                    tooltipMargin: 10,
                    maxContentWidth: 45,
                    tooltipRoundedRadius: 300,
                    fitInsideHorizontally: false,
                    fitInsideVertically: false,
                    tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                    tooltipPadding: const EdgeInsets.fromLTRB(10, 13, 10, 9),
                    tooltipBorder: const BorderSide(color: primary900, width: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${(rod.toY * 100).toInt()}%',
                        const TextStyle(
                          color: greyscale800,
                          fontSize: 16,
                          fontFamily: Involve,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameSize: 32,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(
                              top: value == 1 ? 10 : 0, bottom: value == 0 ? 15 : 0, right: value == 1 ? 0 : 3),
                          child: AppText(
                            text: '${(value * 100).toInt()}%',
                            size: 12,
                            fw: FontWeight.w500,
                            color: greyscale700,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(axisNameSize: 0),
                  topTitles: const AxisTitles(axisNameSize: 0),
                  bottomTitles: AxisTitles(
                      axisNameSize: 22,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 27,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: widget.selectedTab == TabItem.year ? 3 : 10),
                            child: AppText(
                              text: widget.selectedTab == TabItem.week
                                  ? _gerWeekTabTitle(value.toInt())
                                  : widget.selectedTab == TabItem.month
                                      ? _gerMonthTabTitle(value.toInt(), startDate)
                                      : _gerYearTabTitle(value.toInt()),
                              size: widget.selectedTab == TabItem.week ? 12 : 10,
                              fw: FontWeight.w500,
                              color: greyscale700,
                              maxLine: 2,
                              height: 1.3,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _gerWeekTabTitle(int i) {
    final DateTime startDate = widget.dates['startDate']!;
    if (i == 0) return DateFormat('dd', 'ru').format(startDate);
    final date = startDate.add(Duration(days: i));
    return DateFormat('dd', 'ru').format(date);
  }

  String _gerMonthTabTitle(int i, DateTime month) {
    final int monthDays = DateTime(month.year, month.month + 1, 0).day;
    switch (i) {
      case 0:
        return '1-4';
      case 1:
        return '5-8';
      case 2:
        return '9-12';
      case 3:
        return '13-16';
      case 4:
        return '17-20';
      case 5:
        return '21-24';
      case 6:
        return '25-$monthDays';
      default:
        return '';
    }
  }

  String _gerYearTabTitle(int i) {
    switch (i) {
      case 0:
        return 'y1'.tr();
      case 1:
        return 'y2'.tr();
      case 2:
        return 'y3'.tr();
      case 3:
        return 'y4'.tr();
      case 4:
        return 'y5'.tr();
      case 5:
        return 'y6'.tr();
      default:
        return '';
    }
  }
}

class _ProgressCompleteCount extends StatefulWidget {
  final List<TaskModel> tasks;
  final TabItem selectedTab;
  final Map<String, DateTime> dates;
  const _ProgressCompleteCount({required this.tasks, required this.selectedTab, required this.dates});

  @override
  State<_ProgressCompleteCount> createState() => _ProgressCompleteCountState();
}

class _ProgressCompleteCountState extends State<_ProgressCompleteCount> {
  int touchedIndex = -1;

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    double width = 34,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isTouched ? blue : blue.withOpacity(0.48),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(100)),
          width: width,
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  List<BarChartGroupData> showingWeekGroups() {
    final DateTime startDate = widget.dates['startDate']!;

    return List.generate(7, (i) {
      final addDuration = Duration(days: i);
      switch (i) {
        case 0:
          return makeGroupData(
            0,
            _getWeekCompletePercentage(widget.tasks, startDate),
            isTouched: i == touchedIndex,
          );
        case 1:
          return makeGroupData(
            1,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 2:
          return makeGroupData(
            2,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 3:
          return makeGroupData(
            3,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 4:
          return makeGroupData(
            4,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 5:
          return makeGroupData(
            5,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        case 6:
          return makeGroupData(
            6,
            _getWeekCompletePercentage(widget.tasks, startDate.add(addDuration)),
            isTouched: i == touchedIndex,
          );
        default:
          return throw Error();
      }
    });
  }

  double _getWeekCompletePercentage(List<TaskModel> tasks, DateTime day) {
    if (tasks.isEmpty) return 0;
    final items = widget.tasks.where((task) => isSameDay(day, task.actionDate)).toList();
    if (items.isEmpty) return 0;
    final completedTasks = items.where((task) => task.status == TaskStatus.completed).toList().length;

    return completedTasks.toDouble();
  }

  List<BarChartGroupData> showingMonthGroups() {
    final DateTime startDate = widget.dates['startDate']!;
    return List.generate(7, (i) {
      switch (i) {
        case 0:
          return makeGroupData(
            0,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 1:
          return makeGroupData(
            1,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 2:
          return makeGroupData(
            2,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 3:
          return makeGroupData(
            3,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 4:
          return makeGroupData(
            4,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 5:
          return makeGroupData(
            5,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        case 6:
          return makeGroupData(
            6,
            _getMonthCompletePercentage(widget.tasks, i, startDate),
            isTouched: i == touchedIndex,
          );
        default:
          return throw Error();
      }
    });
  }

  double _getMonthCompletePercentage(List<TaskModel> tasks, int index, DateTime month) {
    if (tasks.isEmpty) return 0;
    final dates = _getIndexDates(index, month);
    final items = _filterTasksByDates(tasks, dates);
    if (items.isEmpty) return 0;
    final completedTasks = items.where((task) => task.status == TaskStatus.completed).toList().length;
    return completedTasks.toDouble();
  }

  List<TaskModel> _filterTasksByDates(List<TaskModel> tasks, List<DateTime> dates) {
    List<TaskModel> filteredTasks = [];

    for (TaskModel task in tasks) {
      for (DateTime date in dates) {
        if (isSameDay(task.actionDate, date)) {
          filteredTasks.add(task);
          break;
        }
      }
    }
    return filteredTasks;
  }

  List<DateTime> _getIndexDates(int index, DateTime month) {
    final int monthDays = DateTime(month.year, month.month + 1, 0).day;

    switch (index) {
      case 0:
        return List.generate(4, (i) => DateTime(month.year, month.month, i + 1));
      case 1:
        return List.generate(4, (i) => DateTime(month.year, month.month, 5 + i));
      case 2:
        return List.generate(4, (i) => DateTime(month.year, month.month, 9 + i));
      case 3:
        return List.generate(4, (i) => DateTime(month.year, month.month, 13 + i));
      case 4:
        return List.generate(4, (i) => DateTime(month.year, month.month, 17 + i));
      case 5:
        return List.generate(4, (i) => DateTime(month.year, month.month, 21 + i));
      case 6:
        return List.generate((monthDays - 24), (i) => DateTime(month.year, month.month, 25 + i));
      default:
        return [];
    }
  }

  List<BarChartGroupData> showingYearGroups() {
    return List.generate(6, (i) {
      switch (i) {
        case 0:
          return makeGroupData(
            0,
            _getYearCompletePercentage(widget.tasks, 1, 2),
            isTouched: i == touchedIndex,
          );
        case 1:
          return makeGroupData(
            1,
            _getYearCompletePercentage(widget.tasks, 3, 4),
            isTouched: i == touchedIndex,
          );
        case 2:
          return makeGroupData(
            2,
            _getYearCompletePercentage(widget.tasks, 5, 6),
            isTouched: i == touchedIndex,
          );
        case 3:
          return makeGroupData(
            3,
            _getYearCompletePercentage(widget.tasks, 7, 8),
            isTouched: i == touchedIndex,
          );
        case 4:
          return makeGroupData(
            4,
            _getYearCompletePercentage(widget.tasks, 9, 10),
            isTouched: i == touchedIndex,
          );
        case 5:
          return makeGroupData(
            5,
            _getYearCompletePercentage(widget.tasks, 11, 12),
            isTouched: i == touchedIndex,
          );

        default:
          return throw Error();
      }
    });
  }

  double _getYearCompletePercentage(List<TaskModel> tasks, int month1, int month2) {
    if (tasks.isEmpty) return 0;
    final items =
        widget.tasks.where((task) => task.actionDate?.month == month1 || task.actionDate?.month == month2).toList();
    if (items.isEmpty) return 0;
    final completedTasks = items.where((task) => task.status == TaskStatus.completed).toList().length;
    return completedTasks.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startDate = widget.dates['startDate']!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(text: 'completeProsent'.tr(), size: 20, fw: FontWeight.w700),
          const Divider(height: 32, thickness: 1, color: greyscale200),
          SizedBox(
            width: double.infinity,
            height: 255,
            child: BarChart(
              key: const ValueKey('count'),
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                gridData: const FlGridData(show: false),
                backgroundColor: white,
                borderData: FlBorderData(show: false),
                barGroups: widget.selectedTab == TabItem.week
                    ? showingWeekGroups()
                    : widget.selectedTab == TabItem.month
                        ? showingMonthGroups()
                        : showingYearGroups(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    direction: TooltipDirection.top,
                    getTooltipColor: (group) => white,
                    tooltipMargin: 10,
                    maxContentWidth: 40,
                    tooltipRoundedRadius: 300,
                    tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                    tooltipPadding: const EdgeInsets.fromLTRB(8, 11, 8, 6),
                    tooltipBorder: const BorderSide(color: blue, width: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${(rod.toY).toInt()}    ',
                        const TextStyle(
                          color: greyscale800,
                          fontSize: 20,
                          fontFamily: Involve,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameSize: 32,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: value == 0 ? 5 : 0, right: 3),
                          child: AppText(
                            text: meta.formattedValue,
                            size: 12,
                            fw: FontWeight.w500,
                            color: greyscale700,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(axisNameSize: 0),
                  topTitles: const AxisTitles(axisNameSize: 0),
                  bottomTitles: AxisTitles(
                      axisNameSize: 22,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 27,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: EdgeInsets.only(top: widget.selectedTab == TabItem.year ? 3 : 10),
                            child: AppText(
                              text: widget.selectedTab == TabItem.week
                                  ? _gerWeekTabTitle(value.toInt())
                                  : widget.selectedTab == TabItem.month
                                      ? _gerMonthTabTitle(value.toInt(), startDate)
                                      : _gerYearTabTitle(value.toInt()),
                              size: widget.selectedTab == TabItem.week ? 12 : 10,
                              fw: FontWeight.w500,
                              color: greyscale700,
                              maxLine: 2,
                              height: 1.3,
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      )),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _gerWeekTabTitle(int i) {
    final DateTime startDate = widget.dates['startDate']!;
    if (i == 0) return DateFormat('dd', 'ru').format(startDate);
    final date = startDate.add(Duration(days: i));
    return DateFormat('dd', 'ru').format(date);
  }

  String _gerMonthTabTitle(int i, DateTime month) {
    final int monthDays = DateTime(month.year, month.month + 1, 0).day;
    switch (i) {
      case 0:
        return '1-4';
      case 1:
        return '5-8';
      case 2:
        return '9-12';
      case 3:
        return '13-16';
      case 4:
        return '17-20';
      case 5:
        return '21-24';
      case 6:
        return '25-$monthDays';
      default:
        return '';
    }
  }

  String _gerYearTabTitle(int i) {
    switch (i) {
      case 0:
        return 'y1'.tr();
      case 1:
        return 'y2'.tr();
      case 2:
        return 'y3'.tr();
      case 3:
        return 'y4'.tr();
      case 4:
        return 'y5'.tr();
      case 5:
        return 'y6'.tr();
      default:
        return '';
    }
  }
}

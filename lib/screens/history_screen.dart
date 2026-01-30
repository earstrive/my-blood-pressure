import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/providers/record_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedTab = 0; // 0: 7天, 1: 30天, 2: 自定义
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _customRange = DateTimeRange(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _selectedTab == 0
        ? const HistoryQuery.days(7)
        : _selectedTab == 1
        ? const HistoryQuery.days(30)
        : HistoryQuery.range(
            HistoryRange(start: _customRange!.start, end: _customRange!.end),
          );
    final historyDataAsync = ref.watch(historyRecordsProvider(query));
    final chartDataAsync = ref.watch(historyChartProvider(query));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildTabsSection(),
                    _buildChartContainer(chartDataAsync),
                    _buildList(historyDataAsync),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '历史记录',
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildTabsSection() {
    return Column(children: [_buildTabs(), _buildCustomRangeSelector()]);
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabItem(0, '7天'),
            _buildTabItem(1, '30天'),
            _buildTabItem(2, '自定义'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String text) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleTabTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSans(
              textStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeSelector() {
    if (_selectedTab != 2) {
      return const SizedBox.shrink();
    }

    final range = _customRange;
    final text = range == null
        ? '请选择日期范围'
        : '${DateFormat('MM月dd日').format(range.start)} - ${DateFormat('MM月dd日').format(range.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: GestureDetector(
        onTap: _pickCustomRange,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.calendarDays,
                size: 14,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTabTap(int index) async {
    if (index == 2) {
      final picked = await _showCustomRangePicker();
      if (!mounted) {
        return;
      }
      if (picked != null) {
        setState(() {
          _selectedTab = index;
          _customRange = picked;
        });
      }
      return;
    }

    setState(() {
      _selectedTab = index;
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await _showCustomRangePicker();
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _customRange = picked;
    });
  }

  Future<DateTimeRange?> _showCustomRangePicker() async {
    final now = DateTime.now();
    final initialRange =
        _customRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);
    return showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: now,
    );
  }

  double _calculateInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 40) return 10;
    if (range <= 80) return 20;
    if (range <= 160) return 40;
    return 60;
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.notoSans(
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartContainer(
    AsyncValue<List<Map<String, dynamic>>> chartDataAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: chartDataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (data) {
            if (data.isEmpty || data.every((d) => !d['hasData'])) {
              return const Center(child: Text('暂无数据'));
            }

            double totalSys = 0;
            double totalDia = 0;
            int count = 0;
            int minSys = 999, maxSys = 0;
            int minDia = 999, maxDia = 0;

            for (var d in data) {
              if (d['hasData']) {
                final sysD = (d['systolic'] as double);
                final diaD = (d['diastolic'] as double);
                totalSys += sysD;
                totalDia += diaD;
                final sys = sysD.round();
                final dia = diaD.round();
                count++;

                if (sys < minSys) minSys = sys;
                if (sys > maxSys) maxSys = sys;
                if (dia < minDia) minDia = dia;
                if (dia > maxDia) maxDia = dia;
              }
            }

            final avgSys = count > 0
                ? (totalSys / count).toStringAsFixed(1)
                : '0.0';
            final avgDia = count > 0
                ? (totalDia / count).toStringAsFixed(1)
                : '0.0';
            final minValue = min(minSys, minDia);
            final maxValue = max(maxSys, maxDia);
            double minY = ((minValue - 10) / 10).floorToDouble() * 10;
            double maxY = ((maxValue + 10) / 10).ceilToDouble() * 10;
            if (minY < 0) minY = 0;
            if (maxY <= minY) maxY = minY + 10;
            final yInterval = _calculateInterval(minY, maxY);
            final sysSpots = data.asMap().entries.map((e) {
              if (!(e.value['hasData'] as bool)) {
                return FlSpot.nullSpot;
              }
              return FlSpot(e.key.toDouble(), (e.value['systolic'] as double));
            }).toList();
            final diaSpots = data.asMap().entries.map((e) {
              if (!(e.value['hasData'] as bool)) {
                return FlSpot.nullSpot;
              }
              return FlSpot(e.key.toDouble(), (e.value['diastolic'] as double));
            }).toList();

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '平均值',
                          style: GoogleFonts.notoSans(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$avgSys/$avgDia',
                          style: GoogleFonts.notoSans(
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '范围',
                          style: GoogleFonts.notoSans(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$minSys-$maxSys / $minDia-$maxDia',
                          style: GoogleFonts.notoSans(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(color: Colors.blue[500]!, label: '收缩压'),
                    const SizedBox(width: 16),
                    _buildLegendItem(color: Colors.indigo[200]!, label: '舒张压'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[100],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              );
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 6,
                                child: Text(
                                  value.toStringAsFixed(0),
                                  style: style,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              );

                              if (value < 0 || value >= data.length) {
                                return const SizedBox();
                              }

                              // Show label sparsely if many points
                              if (data.length > 7 && value.toInt() % 5 != 0) {
                                return const SizedBox();
                              }

                              final date =
                                  data[value.toInt()]['date'] as DateTime;
                              final text = DateFormat('MM-dd').format(date);

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8,
                                child: Text(text, style: style),
                              );
                            },
                            interval: 1,
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItems: (spots) {
                            return spots.map((touchedSpot) {
                              final label = touchedSpot.barIndex == 0
                                  ? '收缩压'
                                  : '舒张压';
                              final value = touchedSpot.y.toStringAsFixed(1);
                              return LineTooltipItem(
                                '$label $value',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: sysSpots,
                          isCurved: true,
                          color: Colors.blue[500],
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                        LineChartBarData(
                          spots: diaSpots,
                          isCurved: true,
                          color: Colors.indigo[200],
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(AsyncValue<List<RecordWithTags>> historyDataAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近记录',
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          historyDataAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
            data: (records) {
              if (records.isEmpty) {
                return const Center(child: Text('暂无记录'));
              }

              // Group by date
              final Map<String, List<RecordWithTags>> grouped = {};
              for (var r in records) {
                final date = DateTime.fromMillisecondsSinceEpoch(
                  r.record.measureTimeMs,
                );
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                if (!grouped.containsKey(dateStr)) {
                  grouped[dateStr] = [];
                }
                grouped[dateStr]!.add(r);
              }

              final sortedKeys = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return Column(
                children: sortedKeys.map((dateStr) {
                  final items = grouped[dateStr]!;
                  final date = DateTime.parse(dateStr);
                  final now = DateTime.now();
                  final isToday =
                      date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;
                  final yesterday = now.subtract(const Duration(days: 1));
                  final isYesterday =
                      date.day == yesterday.day &&
                      date.month == yesterday.month &&
                      date.year == yesterday.year;

                  String label = dateStr;
                  if (isToday) {
                    label = '今天';
                  } else if (isYesterday) {
                    label = '昨天';
                  } else {
                    label = DateFormat('MM月dd日').format(date);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildDateGroup(
                      label: label,
                      color: isToday ? Colors.blue[500]! : Colors.grey[300]!,
                      items: items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        final r = item.record;

                        final statusColor =
                            (r.systolic < 120 && r.diastolic < 80)
                            ? Colors.green[500]!
                            : (r.systolic < 140 && r.diastolic < 90
                                  ? Colors.yellow[400]!
                                  : Colors.red[400]!);

                        return _buildRecordItem(
                          sys: r.systolic,
                          dia: r.diastolic,
                          time: DateFormat('HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              r.measureTimeMs,
                            ),
                          ),
                          pulse: r.heartRate ?? 0,
                          statusColor: statusColor,
                          tags: item.tags.map((t) => t.name).toList(),
                          showBorder: idx < items.length - 1,
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup({
    required String label,
    required Color color,
    required List<Widget> items,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.notoSans(
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[100]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildRecordItem({
    required int sys,
    required int dia,
    required String time,
    required int pulse,
    required Color statusColor,
    List<String> tags = const [],
    required bool showBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[50]!)),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$sys/$dia',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    time,
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[600],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.heartPulse,
                    color: Colors.red,
                    size: 10,
                  ), // Reduced size to match HTML text-xs
                  const SizedBox(width: 4),
                  Text(
                    '$pulse',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

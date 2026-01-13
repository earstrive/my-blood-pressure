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

  @override
  Widget build(BuildContext context) {
    // 0 -> 7 days, 1 -> 30 days, 2 -> 0 (all/custom)
    final days = _selectedTab == 0 ? 7 : (_selectedTab == 1 ? 30 : 0);
    final historyDataAsync = ref.watch(historyRecordsProvider(days));
    final chartDataAsync = ref.watch(historyChartProvider(days));

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
                    _buildTabs(),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                FontAwesomeIcons.filter,
                size: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
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
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
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

            // Calculate overall average for display
            int totalSys = 0;
            int totalDia = 0;
            int count = 0;
            int minSys = 999, maxSys = 0;
            int minDia = 999, maxDia = 0;

            for (var d in data) {
              if (d['hasData']) {
                final sys = (d['systolic'] as double).round();
                final dia = (d['diastolic'] as double).round();
                totalSys += sys;
                totalDia += dia;
                count++;

                if (sys < minSys) minSys = sys;
                if (sys > maxSys) maxSys = sys;
                if (dia < minDia) minDia = dia;
                if (dia > maxDia) maxDia = dia;
              }
            }

            final avgSys = count > 0 ? (totalSys / count).round() : 0;
            final avgDia = count > 0 ? (totalDia / count).round() : 0;

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
                const SizedBox(height: 24),
                SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 20,
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
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const style = TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              );

                              if (value < 0 || value >= data.length)
                                return const SizedBox();

                              // Show label sparsely if many points
                              if (data.length > 7 && value.toInt() % 5 != 0)
                                return const SizedBox();

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
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (data.length - 1).toDouble(),
                      minY: 40,
                      maxY: 180, // slightly higher max
                      lineBarsData: [
                        // Systolic Line
                        LineChartBarData(
                          spots: data
                              .asMap()
                              .entries
                              .where((e) => e.value['hasData'])
                              .map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  (e.value['systolic'] as double),
                                );
                              })
                              .toList(),
                          isCurved: true,
                          color: Colors.blue[500],
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                        // Diastolic Line
                        LineChartBarData(
                          spots: data
                              .asMap()
                              .entries
                              .where((e) => e.value['hasData'])
                              .map((e) {
                                return FlSpot(
                                  e.key.toDouble(),
                                  (e.value['diastolic'] as double),
                                );
                              })
                              .toList(),
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
                  if (isToday)
                    label = '今天';
                  else if (isYesterday)
                    label = '昨天';
                  else
                    label = DateFormat('MM月dd日').format(date);

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
                          tag: item.tags.isNotEmpty
                              ? item.tags.first.name
                              : null,
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
    String? tag,
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
              Row(
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
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
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
                    ),
                  ],
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

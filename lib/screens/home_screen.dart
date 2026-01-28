import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/providers/record_provider.dart';
import 'package:my_first_app/screens/dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatLastUpdated(int lastUpdated) {
    final now = DateTime.now();
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前更新';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}小时前更新';
    }
    return '${diff.inDays}天前更新';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // Space for FAB and BottomBar
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildSummaryCard(ref),
                    const SizedBox(height: 32),
                    _buildWeeklyTrend(context, ref),
                    const SizedBox(height: 32),
                    _buildRecentRecords(ref),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '早上好，',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              Text(
                '耳朵Strive',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[100]!),
              image: const DecorationImage(
                image: AssetImage('assets/images/avatar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(WidgetRef ref) {
    final dailyDataAsync = ref.watch(dailyAverageProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[500]!, Colors.indigo[600]!],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Circles
            Positioned(
              top: -16,
              right: -16,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -16,
              left: -16,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            dailyDataAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              data: (data) {
                final systolic = data['systolic'] as int;
                final diastolic = data['diastolic'] as int;
                final heartRate = data['heartRate'] as int;
                final status = data['status'] as String;
                final lastUpdated = data['lastUpdated'] as int?;
                final hasData = data['count'] as int > 0;

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '今日平均',
                                style: GoogleFonts.notoSans(
                                  textStyle: TextStyle(
                                    color: Colors.blue[100],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              hasData
                                  ? RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '$systolic',
                                            style: GoogleFonts.notoSans(
                                              textStyle: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          TextSpan(
                                            text: '/$diastolic',
                                            style: GoogleFonts.notoSans(
                                              textStyle: TextStyle(
                                                color: Colors.blue[200],
                                                fontSize: 24,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' mmHg',
                                            style: GoogleFonts.notoSans(
                                              textStyle: TextStyle(
                                                color: Colors.blue[100],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      '--',
                                      style: GoogleFonts.notoSans(
                                        textStyle: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  FontAwesomeIcons.heartPulse,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasData ? '$heartRate' : '--',
                                  style: GoogleFonts.notoSans(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: hasData && status == '正常'
                                  ? Colors.green[400]
                                  : (hasData
                                        ? Colors.orange[400]
                                        : Colors.grey[400]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  hasData && status == '正常'
                                      ? FontAwesomeIcons.solidCircleCheck
                                      : FontAwesomeIcons.circleExclamation,
                                  color: hasData && status == '正常'
                                      ? const Color(0xFF14532D)
                                      : Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status,
                                  style: GoogleFonts.notoSans(
                                    textStyle: TextStyle(
                                      color: hasData && status == '正常'
                                          ? const Color(0xFF14532D)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (lastUpdated != null)
                            Text(
                              _formatLastUpdated(lastUpdated),
                              style: GoogleFonts.notoSans(
                                textStyle: TextStyle(
                                  color: Colors.blue[100],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrend(BuildContext context, WidgetRef ref) {
    final weeklyTrendAsync = ref.watch(weeklyTrendProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '周趋势',
                style: GoogleFonts.notoSans(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  DashboardScreen.switchToHistory(context);
                },
                child: Text(
                  '查看全部',
                  style: GoogleFonts.notoSans(
                    textStyle: TextStyle(
                      color: Colors.blue[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: weeklyTrendAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (data) {
                // Check if all data is empty
                final allEmpty = data.every((d) => d['hasData'] == false);
                if (allEmpty) {
                  return const Center(child: Text('近7天暂无数据'));
                }

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 160,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            const style = TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            );

                            // Map index to weekday string
                            // data is reversed (last 7 days), index 0 is 6 days ago, index 6 is today
                            // But our provider returns data from 6 days ago to today in order?
                            // Let's check provider logic.
                            // Provider loop: for (int i = 6; i >= 0; i--) -> 6 days ago ... today.
                            // So index 0 is 6 days ago.
                            if (value < 0 || value >= data.length) {
                              return const SizedBox();
                            }

                            final dayData = data[value.toInt()];
                            final weekday = dayData['weekday'] as int;

                            String text;
                            switch (weekday) {
                              case 1:
                                text = '周一';
                                break;
                              case 2:
                                text = '周二';
                                break;
                              case 3:
                                text = '周三';
                                break;
                              case 4:
                                text = '周四';
                                break;
                              case 5:
                                text = '周五';
                                break;
                              case 6:
                                text = '周六';
                                break;
                              case 7:
                                text = '周日';
                                break;
                              default:
                                text = '';
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(text, style: style),
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
                    barGroups: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final sys = item['systolic'] as double;
                      final hasData = item['hasData'] as bool;

                      return _makeBarGroup(
                        index,
                        hasData ? sys : 0,
                        0, // Not using diastolic for bar height yet, or maybe stacked? keeping simple for now
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double sys, double dia) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: sys,
          color: Colors.blue[500],
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 160, // Max scale
            color: Colors.blue[50],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecords(WidgetRef ref) {
    final recentRecordsAsync = ref.watch(recentRecordsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最近记录',
            style: GoogleFonts.notoSans(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          recentRecordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
            data: (records) {
              if (records.isEmpty) {
                return const Text('暂无记录');
              }
              return Column(
                children: records.map((item) {
                  final r = item.record;
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    r.measureTimeMs,
                  );
                  final isToday =
                      date.day == DateTime.now().day &&
                      date.month == DateTime.now().month &&
                      date.year == DateTime.now().year;

                  final timeStr = DateFormat('HH:mm').format(date);
                  final displayTime = isToday
                      ? '今天, $timeStr'
                      : DateFormat('MM月dd日, HH:mm', 'zh_CN').format(date);
                  final isDay = date.hour >= 6 && date.hour < 18;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecordItem(
                      sys: r.systolic,
                      dia: r.diastolic,
                      time: displayTime,
                      pulse: r.heartRate ?? 0,
                      isDay: isDay,
                      tag: item.tags.isNotEmpty ? item.tags.first.name : null,
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

  Widget _buildRecordItem({
    required int sys,
    required int dia,
    required String time,
    required int pulse,
    required bool isDay,
    String? tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDay ? Colors.blue[50] : Colors.indigo[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDay ? FontAwesomeIcons.sun : FontAwesomeIcons.moon,
                  color: isDay ? Colors.blue[500] : Colors.indigo[500],
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sys/$dia',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
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
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pulse',
                    style: GoogleFonts.notoSans(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              if (tag != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

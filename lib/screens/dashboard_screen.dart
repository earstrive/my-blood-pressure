import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                    _buildSummaryCard(),
                    const SizedBox(height: 32),
                    _buildWeeklyTrend(),
                    const SizedBox(height: 32),
                    _buildRecentRecords(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue[600],
        child: const Icon(FontAwesomeIcons.plus),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
                '张三',
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
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=100&q=80',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
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
            Padding(
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
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '118',
                                  style: GoogleFonts.notoSans(
                                    textStyle: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: '/76',
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
                              '72',
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
                          color: Colors.green[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              FontAwesomeIcons.solidCircleCheck,
                              color: Color(0xFF14532D),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '正常',
                              style: GoogleFonts.notoSans(
                                textStyle: const TextStyle(
                                  color: Color(0xFF14532D),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '10分钟前更新',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrend() {
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
                onPressed: () {},
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
            child: BarChart(
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
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = '周一';
                            break;
                          case 1:
                            text = '周二';
                            break;
                          case 2:
                            text = '周三';
                            break;
                          case 3:
                            text = '周四';
                            break;
                          case 4:
                            text = '周五';
                            break;
                          case 5:
                            text = '周六';
                            break;
                          case 6:
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
                barGroups: [
                  _makeBarGroup(0, 120, 80),
                  _makeBarGroup(1, 115, 75),
                  _makeBarGroup(2, 130, 85),
                  _makeBarGroup(3, 118, 78),
                  _makeBarGroup(4, 122, 82),
                  _makeBarGroup(5, 110, 70),
                  _makeBarGroup(6, 105, 65),
                ],
              ),
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
          fromY:
              dia, // This property is not available in all versions, wait, checking docs.
          // Actually fl_chart BarChartRodData supports 'rodStackItems' or simple 'toY'.
          // For BP range, we ideally want a floating bar (Range Bar).
          // Standard BarChart in fl_chart starts from 0 usually.
          // Let's use 'toY' as systolic and background or stacked?
          // The HTML design shows a bar from 0 to something, and a darker part.
          // "bg-blue-100" (total height?) "bg-blue-500" (actual value?)
          // The HTML says "absolute bottom-0 w-full bg-blue-500 rounded-t-sm h-12".
          // It looks like a standard bar chart.
          // Let's stick to standard bar for now, maybe just showing Systolic.
          // Or we can try to simulate range if possible, but let's keep it simple.
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

  Widget _buildRecentRecords() {
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
          _buildRecordItem(
            sys: 120,
            dia: 80,
            time: '今天, 08:30',
            pulse: 72,
            isDay: true,
            tag: '咖啡',
          ),
          const SizedBox(height: 12),
          _buildRecordItem(
            sys: 115,
            dia: 74,
            time: '昨天, 22:15',
            pulse: 68,
            isDay: false,
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.chartSimple),
            label: '历史',
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.gear),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

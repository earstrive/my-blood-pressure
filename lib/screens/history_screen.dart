import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedTab = 0; // 0: 7天, 1: 30天, 2: 自定义

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
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildTabs(),
                    _buildChartContainer(),
                    _buildList(),
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

  Widget _buildChartContainer() {
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
        child: Column(
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
                      '118/76',
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
                      '110-135 / 70-85',
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
                      return FlLine(color: Colors.grey[100], strokeWidth: 1);
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
                          String text = '';
                          switch (value.toInt()) {
                            case 0:
                              text = '一';
                              break;
                            case 1:
                              text = '二';
                              break;
                            case 2:
                              text = '三';
                              break;
                            case 3:
                              text = '四';
                              break;
                            case 4:
                              text = '五';
                              break;
                            case 5:
                              text = '六';
                              break;
                            case 6:
                              text = '日';
                              break;
                          }
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
                  maxX: 6,
                  minY: 40,
                  maxY: 140,
                  lineBarsData: [
                    // Systolic Line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 120),
                        FlSpot(1, 115),
                        FlSpot(2, 130),
                        FlSpot(3, 118),
                        FlSpot(4, 122),
                        FlSpot(5, 110),
                        FlSpot(6, 125),
                      ],
                      isCurved: true,
                      color: Colors.blue[500],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Diastolic Line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 80),
                        FlSpot(1, 75),
                        FlSpot(2, 85),
                        FlSpot(3, 78),
                        FlSpot(4, 82),
                        FlSpot(5, 70),
                        FlSpot(6, 82),
                      ],
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
        ),
      ),
    );
  }

  Widget _buildList() {
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
          _buildDateGroup(
            label: '今天',
            color: Colors.blue[500]!,
            items: [
              _buildRecordItem(
                sys: 120,
                dia: 80,
                time: '08:30',
                pulse: 72,
                statusColor: Colors.green[500]!,
                tag: '咖啡',
                showBorder: true,
              ),
              _buildRecordItem(
                sys: 125,
                dia: 82,
                time: '20:30',
                pulse: 75,
                statusColor: Colors.yellow[400]!,
                showBorder: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDateGroup(
            label: '昨天',
            color: Colors.grey[300]!,
            items: [
              _buildRecordItem(
                sys: 118,
                dia: 79,
                time: '09:15',
                pulse: 68,
                statusColor: Colors.green[500]!,
                showBorder: false,
              ),
            ],
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

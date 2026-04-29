import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminCharts {
  // Pie Chart for Role Distribution
  static Widget roleDistributionChart(Map<String, int> rolesCount) {
    if (rolesCount.isEmpty) return const Center(child: Text("No Data", style: TextStyle(color: Colors.white54)));
    
    final List<Color> colors = [
      const Color(0xFF1A4DBE),
      const Color(0xFF4CAF50),
      const Color(0xFFFFC107),
      const Color(0xFF29B6F6),
      const Color(0xFFCE93D8),
    ];
    
    int total = rolesCount.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return const Center(child: Text("No Roles", style: TextStyle(color: Colors.white54)));

    int colorIndex = 0;
    final sections = rolesCount.entries.where((e) => e.value > 0).map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final percentage = (e.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '$percentage%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                enabled: true,
              ),
              sections: sections,
              centerSpaceRadius: 35,
              sectionsSpace: 4,
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOutBack,
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rolesCount.entries.where((e) => e.value > 0).map((e) {
              final color = colors[rolesCount.keys.toList().indexOf(e.key) % colors.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, color: color),
                    const SizedBox(width: 6),
                    Text('${e.key.toUpperCase()} (${e.value})', style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Bar Chart for Daily Service Requests (Last 7 Days)
  static Widget dailyRequestsChart(List<int> dailyCounts) {
    if (dailyCounts.isEmpty || dailyCounts.length != 7) return const SizedBox();

    final maxY = dailyCounts.reduce((a, b) => a > b ? a : b).toDouble() + 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1A2640),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} Requests',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final daysAgo = 6 - value.toInt();
                if (daysAgo == 0) return const Text('Today', style: TextStyle(color: Colors.white54, fontSize: 9));
                return Text('${daysAgo}d ago', style: const TextStyle(color: Colors.white54, fontSize: 9));
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: dailyCounts[i].toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: Colors.white.withAlpha(12),
                ),
              ),
            ],
          );
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 800),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }
}

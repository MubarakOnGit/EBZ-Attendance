import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatusDistributionChart extends StatefulWidget {
  final int onTimeCount;
  final int lateCount;
  final int absentCount;

  const StatusDistributionChart({
    super.key,
    required this.onTimeCount,
    required this.lateCount,
    required this.absentCount,
  });

  @override
  State<StatusDistributionChart> createState() => _StatusDistributionChartState();
}

class _StatusDistributionChartState extends State<StatusDistributionChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.onTimeCount + widget.lateCount + widget.absentCount;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
        ),
        child: const Center(
          child: Text(
            'NO DATA AVAILABLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.black26,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: Colors.black, size: 24),
              const SizedBox(width: 16),
              const Text(
                'Status Distribution',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              touchedIndex = -1;
                              return;
                            }
                            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: _getSections(total),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('ON TIME', widget.onTimeCount, total, Colors.black),
                    const SizedBox(height: 20),
                    _buildLegendItem('LATE', widget.lateCount, total, Colors.orange),
                    const SizedBox(height: 20),
                    _buildLegendItem('ABSENT', widget.absentCount, total, Colors.redAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections(int total) {
    return [
      PieChartSectionData(
        color: Colors.black,
        value: widget.onTimeCount.toDouble(),
        title: touchedIndex == 0 ? '${widget.onTimeCount}' : '',
        radius: touchedIndex == 0 ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: widget.lateCount.toDouble(),
        title: touchedIndex == 1 ? '${widget.lateCount}' : '',
        radius: touchedIndex == 1 ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.redAccent,
        value: widget.absentCount.toDouble(),
        title: touchedIndex == 2 ? '${widget.absentCount}' : '',
        radius: touchedIndex == 2 ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

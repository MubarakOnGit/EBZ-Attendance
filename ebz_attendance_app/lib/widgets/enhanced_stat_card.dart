import 'package:flutter/material.dart';
import 'animated_count.dart';

class EnhancedStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final String? trend;
  final bool isPositive;
  final String? percentageChange;

  const EnhancedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.trend,
    this.isPositive = true,
    this.percentageChange,
  });

  @override
  State<EnhancedStatCard> createState() => _EnhancedStatCardState();
}

class _EnhancedStatCardState extends State<EnhancedStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    int? numericValue = int.tryParse(widget.value);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        transform: _isHovered 
          ? (Matrix4.identity()..scale(1.02, 1.02)) 
          : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? Colors.black.withOpacity(0.1) : Colors.black.withOpacity(0.04),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(widget.icon, color: Colors.black, size: 28),
                ),
                const Spacer(),
                if (widget.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (widget.isPositive ? Colors.green : Colors.redAccent).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 12,
                          color: widget.isPositive ? Colors.green : Colors.redAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.trend!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: widget.isPositive ? Colors.green : widget.isPositive ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (numericValue != null)
                        AnimatedCount(
                          count: numericValue,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        )
                      else
                        Text(
                          widget.value,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black26,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.percentageChange != null)
                  Text(
                    widget.percentageChange!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: (widget.isPositive ? Colors.green : Colors.redAccent).withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Donut chart for Genre Distribution matching Stitch Profile Bento specification
/// (Sci-Fi 38%, Drama 29%, Crime 21%, Comedy 12%)
class GenreDonutChart extends StatelessWidget {
  final Map<String, double> genreData;

  static const List<Color> _palette = [
    AppColors.primaryAccent, // Sci-Fi (Yellow)
    AppColors.infoBlue, // Drama (Blue)
    AppColors.functionalSuccess, // Crime (Green)
    AppColors.warningOrange, // Comedy (Orange)
  ];

  const GenreDonutChart({
    super.key,
    required this.genreData,
  });

  @override
  Widget build(BuildContext context) {
    final entries = genreData.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GENRE DISTRIBUTION',
            style: AppTypography.labelCode,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Custom Donut Painter
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    entries: entries,
                    colors: _palette,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  children: List.generate(entries.length, (index) {
                    final entry = entries[index];
                    final color = _palette[index % _palette.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${entry.value.toStringAsFixed(0)}%',
                            style: AppTypography.labelCodeSmall.copyWith(
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final List<Color> colors;

  _DonutChartPainter({required this.entries, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final total = entries.fold<double>(0.0, (sum, e) => sum + e.value);
    if (total == 0) return;

    double startAngle = -pi / 2;
    for (int i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * pi;
      paint.color = colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + 0.05,
        sweepAngle - 0.1,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

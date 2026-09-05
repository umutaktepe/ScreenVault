import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';

/// 7-day horizontal calendar timeline strip (Monday - Sunday)
class CalendarDayStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarDayStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start of current week (Monday)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((date) {
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryAccent
                    : (isToday
                        ? AppColors.surfaceHighlight
                        : AppColors.cardSurface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryAccent
                      : (isToday ? AppColors.primaryAccent.withValues(alpha: 0.5) : AppColors.borderStroke),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormatter.getDayOfWeek(date).toUpperCase(),
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.textOnAccent
                          : AppColors.secondarySlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.getDayOfMonth(date),
                    style: AppTypography.headline3.copyWith(
                      fontSize: 16,
                      color: isSelected
                          ? AppColors.textOnAccent
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Dot indicator for episode release
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.textOnAccent
                          : (isToday ? AppColors.functionalSuccess : Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

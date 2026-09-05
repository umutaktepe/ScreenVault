import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// 5-Emotion Meter matching Stitch Episode Detail specification
/// (🤯 Shocked, 😢 Sad, 😂 Funny, 🔥 Fire, 😡 Angry)
class EmotionMeter extends StatefulWidget {
  final String? initialSelectedEmotion;
  final ValueChanged<String>? onEmotionSelected;

  const EmotionMeter({
    super.key,
    this.initialSelectedEmotion,
    this.onEmotionSelected,
  });

  @override
  State<EmotionMeter> createState() => _EmotionMeterState();
}

class _EmotionMeterState extends State<EmotionMeter> {
  String? _selectedEmotion;

  final Map<String, int> _voteCounts = {
    '🤯': 142,
    '😢': 28,
    '😂': 19,
    '🔥': 389,
    '😡': 12,
  };

  @override
  void initState() {
    super.initState();
    _selectedEmotion = widget.initialSelectedEmotion ?? '🔥';
  }

  void _selectEmotion(String emoji) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedEmotion != emoji) {
        if (_selectedEmotion != null) {
          _voteCounts[_selectedEmotion!] = (_voteCounts[_selectedEmotion!]! - 1).clamp(0, 99999);
        }
        _selectedEmotion = emoji;
        _voteCounts[emoji] = (_voteCounts[emoji] ?? 0) + 1;
      }
    });
    widget.onEmotionSelected?.call(emoji);
  }

  @override
  Widget build(BuildContext context) {
    final int totalVotes = _voteCounts.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EPISODE VIBE / EMOTION',
                style: AppTypography.labelCode.copyWith(fontSize: 11),
              ),
              Text(
                '$totalVotes votes',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _voteCounts.entries.map((entry) {
              final emoji = entry.key;
              final count = entry.value;
              final isSelected = _selectedEmotion == emoji;
              final pct = totalVotes > 0 ? (count / totalVotes * 100).toStringAsFixed(0) : '0';

              return GestureDetector(
                onTap: () => _selectEmotion(emoji),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryAccent.withValues(alpha: 0.15)
                        : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryAccent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pct%',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryAccent : AppColors.secondarySlate,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

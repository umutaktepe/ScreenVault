import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/services/pocketbase_auth_service.dart';
import '../../../../data/sync/pocketbase_sync_engine.dart';
import '../../profile/widgets/auth_bottom_sheet.dart';

class PostCommentSheet extends StatefulWidget {
  final String? defaultShowTitle;
  final String? defaultEpisodeCode;
  final int? defaultShowId;

  const PostCommentSheet({
    super.key,
    this.defaultShowTitle,
    this.defaultEpisodeCode,
    this.defaultShowId,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? defaultShowTitle,
    String? defaultEpisodeCode,
    int? defaultShowId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCommentSheet(
        defaultShowTitle: defaultShowTitle,
        defaultEpisodeCode: defaultEpisodeCode,
        defaultShowId: defaultShowId,
      ),
    );
  }

  @override
  State<PostCommentSheet> createState() => _PostCommentSheetState();
}

class _PostCommentSheetState extends State<PostCommentSheet> {
  final PocketBaseAuthService _auth = PocketBaseAuthService();
  final PocketBaseSyncEngine _syncEngine = PocketBaseSyncEngine();

  late final TextEditingController _showController;
  late final TextEditingController _episodeController;
  late final TextEditingController _commentController;

  String _selectedEmotion = '🔥';
  bool _isSpoiler = false;
  bool _isSubmitting = false;

  final List<String> _emotions = ['🔥', '🤯', '😢', '😂', '😡'];

  @override
  void initState() {
    super.initState();
    _showController = TextEditingController(text: widget.defaultShowTitle ?? 'Behzat Ç.');
    _episodeController = TextEditingController(text: widget.defaultEpisodeCode ?? 'S01 · E01');
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _showController.dispose();
    _episodeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_auth.isLoggedIn) {
      final res = await AuthBottomSheet.show(context);
      if (res != true) return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _syncEngine.postComment(
        showTitle: _showController.text.trim(),
        episodeCode: _episodeController.text.trim(),
        showId: widget.defaultShowId ?? 36474,
        content: comment,
        isSpoiler: _isSpoiler,
        emotion: _selectedEmotion,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.functionalSuccess,
            content: Text('Yorumunuz PocketBase topluluk akışında paylaşıldı!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorRed,
            content: Text('Gönderilemedi: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: RepaintBoundary(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.borderStroke, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'TOPLULUKLA YORUM PAYLAŞ',
              style: AppTypography.labelCode.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Show & Episode Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _showController,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Dizi / Film',
                      labelStyle: AppTypography.labelCodeSmall,
                      filled: true,
                      fillColor: AppColors.surfaceHighlight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _episodeController,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Bölüm',
                      labelStyle: AppTypography.labelCodeSmall,
                      filled: true,
                      fillColor: AppColors.surfaceHighlight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Emotion picker
            Text(
              'BÖLÜM DUYGU DURUMU',
              style: AppTypography.labelCodeSmall.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _emotions.map((emoji) {
                final isSelected = _selectedEmotion == emoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmotion = emoji),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryAccent.withValues(alpha: 0.2) : AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryAccent : AppColors.borderStroke,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Comment text
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Bölüm hakkında düşünceleriniz...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceHighlight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderStroke),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Spoiler toggle
            Row(
              children: [
                Checkbox(
                  value: _isSpoiler,
                  activeColor: AppColors.primaryAccent,
                  checkColor: Colors.black,
                  onChanged: (v) => setState(() => _isSpoiler = v ?? false),
                ),
                GestureDetector(
                  onTap: () => setState(() => _isSpoiler = !_isSpoiler),
                  child: Text(
                    'Spoiler içeriyor (Buzlu koruma)',
                    style: AppTypography.bodySmall.copyWith(
                      color: _isSpoiler ? AppColors.primaryAccent : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  foregroundColor: AppColors.textOnAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.black),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Paylaşılıyor...' : 'Toplulukta Paylaş',
                  style: AppTypography.buttonPrimary.copyWith(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
);
  }
}

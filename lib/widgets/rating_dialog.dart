import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/rating_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class RatingDialog extends StatefulWidget {
  final Order order;
  final VoidCallback onRated;

  const RatingDialog({
    super.key,
    required this.order,
    required this.onRated,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedStars = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStars == 0) return;
    setState(() => _submitting = true);
    await RatingService.saveRating(
      widget.order.id,
      _selectedStars,
      _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
    );
    if (mounted) {
      Navigator.of(context).pop();
      widget.onRated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      title: Column(
        children: [
          const Icon(Icons.star_rounded, size: 44, color: Colors.amber),
          const SizedBox(height: 8),
          const Text(
            'Évaluer votre commande',
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          Text(
            'Commande #${widget.order.id}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedStars = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    star <= _selectedStars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          if (_selectedStars > 0) ...[
            const SizedBox(height: 6),
            Text(
              _starLabel(_selectedStars),
              style: AppTextStyles.caption.copyWith(color: Colors.amber),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Laissez un commentaire (optionnel)…',
              hintStyle: AppTextStyles.caption,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: (_selectedStars == 0 || _submitting) ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Mauvais';
      case 2:
        return 'Passable';
      case 3:
        return 'Bien';
      case 4:
        return 'Très bien';
      case 5:
        return 'Excellent !';
      default:
        return '';
    }
  }
}

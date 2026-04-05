import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/community_controller.dart';
import '../../core/theme/app_theme.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentCtrl = TextEditingController();
  String _type = 'post';
  bool _loading = false;

  static const _types = [
    {
      'id': 'post',
      'label': '📝 Post',
      'hint': 'Share your travel experience...',
    },
    {'id': 'tip', 'label': '💡 Tip', 'hint': 'Share a travel tip...'},
    {'id': 'question', 'label': '❓ Question', 'hint': 'Ask the community...'},
    {'id': 'review', 'label': '⭐ Review', 'hint': 'Review a spot...'},
  ];

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final error = await ref
        .read(postsControllerProvider.notifier)
        .createPost(content: _contentCtrl.text.trim(), type: _type);

    if (mounted) {
      setState(() => _loading = false);
      if (error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post shared! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hint = _types.firstWhere((t) => t['id'] == _type)['hint']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: (_loading || _contentCtrl.text.trim().isEmpty)
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(70, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _loading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.col.bg,
                      ),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text('Post Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = _type == t['id'];
                return GestureDetector(
                  onTap: () => setState(() => _type = t['id']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : context.col.border,
                      ),
                    ),
                    child: Text(
                      t['label']!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.primary
                            : context.col.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Content input
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

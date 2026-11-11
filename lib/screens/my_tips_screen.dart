import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

/// Every tip the signed-in student submitted, with its moderation status and
/// the Admin rejection reason when there is one.
class MyTipsScreen extends StatefulWidget {
  const MyTipsScreen({super.key, required this.store, required this.uid});

  final FinalFirestore store;
  final String uid;

  @override
  State<MyTipsScreen> createState() => _MyTipsScreenState();
}

class _MyTipsScreenState extends State<MyTipsScreen> {
  int _reload = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Bí kíp của tôi',
        onBack: () => Navigator.pop(context),
      ),
      body: StreamBuilder<List<ExperienceNote>>(
        key: ValueKey(_reload),
        stream: widget.store.watchMyNotes(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorState(
              message: 'Không tải được bí kíp của bạn: ${snapshot.error}',
              onRetry: () => setState(() => _reload++),
            );
          }
          if (!snapshot.hasData) {
            return const AppLoadingState(message: 'Đang tải bí kíp...');
          }
          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return const AppEmptyState(
              message:
                  'Bạn chưa gửi bí kíp nào.\nMở môn học → tab "Bí kíp cộng đồng" '
                  'để chia sẻ kinh nghiệm của mình.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: notes.length,
            separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _MyTipCard(note: notes[index]),
          );
        },
      ),
    );
  }
}

class _MyTipCard extends StatelessWidget {
  const _MyTipCard({required this.note});

  final ExperienceNote note;

  @override
  Widget build(BuildContext context) {
    final (label, color, background, icon) = switch (note.status) {
      'approved' => (
        'Đã được duyệt',
        AppColors.success,
        AppColors.successContainer,
        Icons.check_circle_outline,
      ),
      'rejected' => (
        'Bị từ chối',
        AppColors.error,
        AppColors.errorContainer,
        Icons.highlight_off,
      ),
      _ => (
        'Đang chờ duyệt',
        AppColors.warning,
        AppColors.warningContainer,
        Icons.hourglass_top_outlined,
      ),
    };
    return AppCard(
      onTap: note.status == 'approved'
          ? () => Navigator.pushNamed(
              context,
              '/course-tips',
              arguments: note.courseDocId,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${note.courseCode} · ${note.courseName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            note.displayTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(note.content, maxLines: 4, overflow: TextOverflow.ellipsis),
          if (note.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                'Lý do từ Admin: ${note.reason}',
                style: const TextStyle(
                  fontSize: AppFontSize.dense,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
          if (note.createdAt != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Gửi lúc ${DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt!)}',
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (note.status == 'approved') ...[
            const SizedBox(height: AppSpacing.xxs),
            const Row(
              children: [
                Icon(Icons.star, size: 14, color: AppColors.warning),
                SizedBox(width: 2),
                Text(
                  'Đánh giá và bình luận nằm trong môn học',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

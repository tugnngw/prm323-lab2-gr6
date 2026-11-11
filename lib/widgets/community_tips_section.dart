import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';
import 'app_components.dart';

/// Community tips for one course.
///
/// * Students submit only a title + content; Admin moderation decides visibility.
/// * Ratings come from other students (one per student per tip) and drive the
///   average shown on approved tips.
/// * Comments are unmoderated and collapse under each tip.
class CommunityTipsSection extends StatefulWidget {
  const CommunityTipsSection({
    super.key,
    required this.course,
    required this.store,
    required this.currentUid,
    required this.viewerName,
    this.onSubmitted,
  });

  final CourseModel course;
  final FinalFirestore? store;
  final String? currentUid;
  final String viewerName;
  final VoidCallback? onSubmitted;

  @override
  State<CommunityTipsSection> createState() => _CommunityTipsSectionState();
}

class _CommunityTipsSectionState extends State<CommunityTipsSection> {
  String? _streamKey;
  Stream<List<ExperienceNote>>? _notesStream;
  Stream<List<TipRating>>? _ratingsStream;
  Stream<List<TipComment>>? _commentsStream;

  String get _courseDocId => widget.course.id.isNotEmpty
      ? widget.course.id
      : '${widget.course.major}__${widget.course.code}';

  void _bindStreams() {
    final store = widget.store;
    final uid = widget.currentUid;
    final key = '$_courseDocId::${uid ?? ''}';
    if (store == null || uid == null || uid.isEmpty) {
      _streamKey = key;
      _notesStream = null;
      _ratingsStream = null;
      _commentsStream = null;
      return;
    }
    if (_streamKey == key) return;
    _streamKey = key;
    _notesStream = store.watchCourseNotes(_courseDocId, uid: uid);
    _ratingsStream = store.watchCourseRatings(_courseDocId);
    _commentsStream = store.watchCourseComments(_courseDocId);
  }

  @override
  Widget build(BuildContext context) {
    _bindStreams();
    final stream = _notesStream;
    if (stream == null) {
      return _layout(context, notes: const [], ratings: const [], comments: const []);
    }
    return StreamBuilder<List<ExperienceNote>>(
      stream: stream,
      builder: (context, notesSnap) {
        return StreamBuilder<List<TipRating>>(
          stream: _ratingsStream,
          builder: (context, ratingsSnap) {
            return StreamBuilder<List<TipComment>>(
              stream: _commentsStream,
              builder: (context, commentsSnap) {
                return _layout(
                  context,
                  notes: notesSnap.data ?? const [],
                  ratings: ratingsSnap.data ?? const [],
                  comments: commentsSnap.data ?? const [],
                  error: notesSnap.hasError
                      ? 'Không tải được bí kíp từ Firestore: ${notesSnap.error}'
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _layout(
    BuildContext context, {
    required List<ExperienceNote> notes,
    required List<TipRating> ratings,
    required List<TipComment> comments,
    String? error,
  }) {
    final currentUid = widget.currentUid;
    final myNotes = currentUid == null
        ? const <ExperienceNote>[]
        : notes.where((note) => note.uid == currentUid).toList();
    final approved = notes.where((note) => note.status == 'approved').toList();
    final hasPending = myNotes.any((note) => note.status == 'pending');
    final canSubmit =
        widget.store != null && currentUid != null && currentUid.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Kinh nghiệm & Bí kíp từ Tiền bối',
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/my-tips'),
              icon: const Icon(Icons.fact_check_outlined, size: 18),
              label: const Text('Bí kíp của tôi'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openSubmitSheet(
                context,
                existingPending: hasPending,
              ),
              icon: Icon(
                hasPending
                    ? Icons.hourglass_top_outlined
                    : Icons.add_comment_outlined,
                size: 18,
              ),
              label: Text(hasPending ? 'Đang chờ duyệt' : 'Gửi bí kíp'),
            ),
          ],
        ),
        if (!canSubmit) ...[
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Đăng nhập để gửi bí kíp và đánh giá.',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (myNotes.isNotEmpty) ...[
          for (final note in myNotes) ...[
            _MyTipStatusCard(note: note, ratings: ratings),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
        if (error != null) ...[
          AppCard(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (approved.isEmpty)
          AppCard(
            child: Column(
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 36,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Chưa có bí kíp nào được duyệt cho môn này',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Hãy là người đầu tiên chia sẻ kinh nghiệm học tập, mẹo thi PE/FE '
                  'để giúp đỡ các bạn sinh viên khác!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          for (final note in approved)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _CommunityTipCard(
                note: note,
                ratings: ratings.where((r) => r.tipId == note.id).toList(),
                comments: comments.where((c) => c.tipId == note.id).toList(),
                currentUid: currentUid,
                viewerName: widget.viewerName,
                courseDocId: _courseDocId,
                courseCode: widget.course.code,
                store: widget.store,
              ),
            ),
      ],
    );
  }

  void _openSubmitSheet(
    BuildContext context, {
    required bool existingPending,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _SubmitTipSheet(
        courseDocId: _courseDocId,
        course: widget.course,
        store: widget.store,
        currentUid: widget.currentUid,
        viewerName: widget.viewerName,
        existingPending: existingPending,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}

/// Owns its text controllers so they outlive the route's exit animation.
class _SubmitTipSheet extends StatefulWidget {
  const _SubmitTipSheet({
    required this.courseDocId,
    required this.course,
    required this.store,
    required this.currentUid,
    required this.viewerName,
    required this.existingPending,
    required this.onSubmitted,
  });

  final String courseDocId;
  final CourseModel course;
  final FinalFirestore? store;
  final String? currentUid;
  final String viewerName;
  final bool existingPending;
  final VoidCallback? onSubmitted;

  @override
  State<_SubmitTipSheet> createState() => _SubmitTipSheetState();
}

class _SubmitTipSheetState extends State<_SubmitTipSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _snack(String message, {bool failed = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failed ? AppColors.error : null,
        ),
      );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.length < 3) {
      _snack('Tiêu đề cần tối thiểu 3 ký tự.');
      return;
    }
    if (content.length < 20) {
      _snack('Nội dung bí kíp cần tối thiểu 20 ký tự.');
      return;
    }
    final store = widget.store;
    final uid = widget.currentUid;
    if (store == null || uid == null || uid.isEmpty) {
      _snack(
        'Cần đăng nhập tài khoản sinh viên và kết nối '
        'Firestore để gửi bí kíp.',
      );
      return;
    }
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.submitExperienceNote(
        courseDocId: widget.courseDocId,
        courseCode: widget.course.code,
        courseName: widget.course.name,
        major: widget.course.major,
        uid: uid,
        authorName: widget.viewerName,
        title: title,
        content: content,
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Đã gửi bí kíp! Đang chờ Admin duyệt.'),
            backgroundColor: AppColors.success,
          ),
        );
    } catch (e) {
      if (mounted) _snack('Gửi thất bại: $e', failed: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.existingPending;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Chia sẻ bí kíp môn ${widget.course.code}',
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Chỉ cần tiêu đề và nội dung. Admin duyệt trước khi công khai; '
              'bạn theo dõi trạng thái tại "Bí kíp của tôi".',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (pending) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.hourglass_top_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Bạn đang có một bí kíp chờ Admin phê duyệt. '
                        'Không thể gửi thêm cho môn này đến khi được xử lý.',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _titleController,
              maxLength: 120,
              enabled: !pending,
              decoration: InputDecoration(
                labelText: 'Tiêu đề bí kíp *',
                hintText: 'VD: Mẹo qua PE PRM323 trong 1 tuần',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 2000,
              enabled: !pending,
              decoration: InputDecoration(
                labelText: 'Nội dung bí kíp * (tối thiểu 20 ký tự)',
                hintText:
                    'VD: Ôn kỹ SQLite và Provider cho bài PE; hỏi thầy '
                    'trước buổi lab để kịp sửa...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton(
                  label: _submitting ? 'Đang gửi...' : 'Gửi duyệt',
                  icon: Icons.send,
                  isLoading: _submitting,
                  onPressed: (_submitting || pending) ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTipStatusCard extends StatelessWidget {
  const _MyTipStatusCard({required this.note, required this.ratings});

  final ExperienceNote note;
  final List<TipRating> ratings;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color color;
    IconData icon;
    String label;
    switch (note.status) {
      case 'approved':
        background = AppColors.successContainer;
        color = AppColors.success;
        icon = Icons.check_circle_outline;
        label = 'Đã được duyệt';
        break;
      case 'rejected':
        background = AppColors.errorContainer;
        color = AppColors.error;
        icon = Icons.highlight_off;
        label = 'Bị từ chối';
        break;
      default:
        background = AppColors.warningContainer;
        color = AppColors.warning;
        icon = Icons.hourglass_top_outlined;
        label = 'Đang chờ duyệt';
    }
    final tipRatings = ratings.where((r) => r.tipId == note.id).toList();
    final average = _average(tipRatings);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Bí kíp của bạn · $label',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: AppFontSize.label,
                  ),
                ),
              ),
              if (note.status == 'approved')
                _RatingSummary(average: average, count: tipRatings.length),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            note.displayTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.hairline),
          Text(note.content, style: Theme.of(context).textTheme.bodySmall),
          if (note.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Lý do từ Admin: "${note.reason}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: AppFontSize.caption,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommunityTipCard extends StatefulWidget {
  const _CommunityTipCard({
    required this.note,
    required this.ratings,
    required this.comments,
    required this.currentUid,
    required this.viewerName,
    required this.courseDocId,
    required this.courseCode,
    required this.store,
  });

  final ExperienceNote note;
  final List<TipRating> ratings;
  final List<TipComment> comments;
  final String? currentUid;
  final String viewerName;
  final String courseDocId;
  final String courseCode;
  final FinalFirestore? store;

  @override
  State<_CommunityTipCard> createState() => _CommunityTipCardState();
}

class _CommunityTipCardState extends State<_CommunityTipCard> {
  bool _rating = false;

  Future<void> _rate(int stars) async {
    final store = widget.store;
    final uid = widget.currentUid;
    if (store == null || uid == null || uid.isEmpty || _rating) return;
    if (uid == widget.note.uid) return;
    setState(() => _rating = true);
    try {
      await store.rateTip(
        tipId: widget.note.id,
        courseDocId: widget.courseDocId,
        courseCode: widget.courseCode,
        authorUid: widget.note.uid,
        uid: uid,
        displayName: widget.viewerName,
        stars: stars,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi đánh giá $stars sao.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không gửi được đánh giá: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _rating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final myRating = widget.ratings
        .where((r) => r.uid == widget.currentUid)
        .firstOrNull
        ?.stars ??
        0;
    final isAuthor = widget.currentUid == note.uid;
    final average = _average(widget.ratings);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Đã duyệt',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _RatingSummary(average: average, count: widget.ratings.length),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            note.displayTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            note.authorName.isEmpty ? 'Sinh viên' : note.authorName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            note.content,
            softWrap: true,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          if (note.lecturerTip.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _tipLine(
              context,
              Icons.person_outline,
              'Giảng viên',
              note.lecturerTip,
            ),
          ],
          if (note.examTip.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            _tipLine(
              context,
              Icons.fact_check_outlined,
              'Lưu ý thi / PE',
              note.examTip,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (isAuthor)
            const Text(
              'Đây là bí kíp của bạn.',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                const Text(
                  'Đánh giá của bạn:',
                  style: TextStyle(fontSize: AppFontSize.label),
                ),
                const SizedBox(width: AppSpacing.xxs),
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: '$star sao',
                    onPressed: _rating ? null : () => _rate(star),
                    icon: Icon(
                      star <= myRating ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                      size: 22,
                    ),
                  ),
                if (_rating)
                  const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.xxs),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xxs),
          _TipComments(
            tipId: note.id,
            courseDocId: widget.courseDocId,
            courseCode: widget.courseCode,
            currentUid: widget.currentUid,
            viewerName: widget.viewerName,
            store: widget.store,
            comments: widget.comments,
          ),
        ],
      ),
    );
  }

}

double _average(List<TipRating> ratings) {
  if (ratings.isEmpty) return 0;
  final total = ratings.fold<int>(0, (sum, r) => sum + r.stars);
  return total / ratings.length;
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.average, required this.count});

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text(
        'Chưa có đánh giá',
        style: TextStyle(
          fontSize: AppFontSize.caption,
          color: AppColors.onSurfaceVariant,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 15, color: AppColors.warning),
        const SizedBox(width: 2),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: AppFontSize.label,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '($count)',
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TipComments extends StatefulWidget {
  const _TipComments({
    required this.tipId,
    required this.courseDocId,
    required this.courseCode,
    required this.currentUid,
    required this.viewerName,
    required this.store,
    required this.comments,
  });

  final String tipId;
  final String courseDocId;
  final String courseCode;
  final String? currentUid;
  final String viewerName;
  final FinalFirestore? store;
  final List<TipComment> comments;

  @override
  State<_TipComments> createState() => _TipCommentsState();
}

class _TipCommentsState extends State<_TipComments> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final uid = widget.currentUid;
    final store = widget.store;
    if (text.isEmpty || _sending || uid == null || uid.isEmpty || store == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await store.addTipComment(
        tipId: widget.tipId,
        courseDocId: widget.courseDocId,
        courseCode: widget.courseCode,
        uid: uid,
        authorName: widget.viewerName,
        content: text,
      );
      if (!mounted) return;
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không gửi được bình luận: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<TipComment>.from(widget.comments)
      ..sort((a, b) {
        final left = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final right = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return left.compareTo(right);
      });
    final canComment =
        widget.store != null && (widget.currentUid ?? '').isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          sorted.isEmpty
              ? 'Bình luận'
              : 'Bình luận (${sorted.length})',
          style: const TextStyle(
            fontSize: AppFontSize.label,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          if (sorted.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'Chưa có bình luận. Hỏi thêm bạn học ngay bên dưới.',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final comment in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.skeleton,
                      child: Text(
                        comment.authorName.isEmpty
                            ? 'S'
                            : comment.authorName
                                  .characters
                                  .first
                                  .toUpperCase(),
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.authorName.isEmpty
                                ? 'Sinh viên'
                                : comment.authorName,
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            comment.content,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: AppFontSize.dense,
                            ),
                          ),
                          if (comment.createdAt != null)
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(comment.createdAt!),
                              style: const TextStyle(
                                fontSize: AppFontSize.caption,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          if (canComment)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Viết bình luận…',
                      isDense: true,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  tooltip: 'Gửi bình luận',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

Widget _tipLine(
  BuildContext context,
  IconData icon,
  String label,
  String value,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 15, color: AppColors.secondary),
      const SizedBox(width: 4),
      Expanded(
        child: Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodySmall,
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              TextSpan(text: value),
            ],
          ),
          softWrap: true,
        ),
      ),
    ],
  );
}

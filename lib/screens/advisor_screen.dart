import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../models/note_draft.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../widgets/app_components.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _contextLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contextLoaded) return;
    _contextLoaded = true;
    final course = ModalRoute.of(context)?.settings.arguments;
    if (course is String && course.isNotEmpty) {
      _inputController.text = 'Tư vấn môn $course';
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Share consent (rubric §6.4): shown before the first question that may
  /// reach Gemini. Local-only questions never need it.
  Future<bool> _askConsent() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chia sẻ dữ liệu hỏi đáp'),
        content: const Text(
          'Gemini nhận câu hỏi bạn nhập, cấp tư vấn và thông tin đề cương môn '
          'học (tín chỉ, đầu điểm, slot, chuẩn đầu ra).\n\n'
          'Bảng điểm, điểm thành phần và ghi chú của bạn được xử lý trên thiết '
          'bị và không gửi đi.\n\n'
          'Vui lòng tránh nhập tên, email, mã sinh viên hoặc thông tin riêng '
          'vào câu hỏi. Firebase Analytics chỉ ghi cấp tư vấn, không ghi nội '
          'dung câu hỏi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không gửi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý và gửi'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _sendMessage(AdvisorViewModel vm, String text) async {
    if (text.trim().isEmpty || vm.isLoading) return;

    if (!vm.hasConsent && vm.usesGemini && !vm.aiUnavailable) {
      final ok = await _askConsent();
      if (!mounted || !ok || vm.isLoading) return;
      vm.grantConsent();
    }
    if (!vm.hasConsent) vm.grantConsent();

    final reply = vm.askQuestion(text.trim(), level: vm.selectedLevel);
    _inputController.clear();
    _scrollToEnd();
    await reply;
    if (!mounted) return;
    _scrollToEnd();
  }

  Future<void> _openLocalPrompts(AdvisorViewModel vm) async {
    final kind = await showModalBottomSheet<LocalQuestionKind>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _LocalPromptSheet(vm: vm),
    );
    if (kind == null || !mounted) return;
    _scrollToEnd();
    await vm.askLocalPrompt(kind);
    if (!mounted) return;
    _scrollToEnd();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showHelp(AdvisorViewModel vm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cố vấn học tập làm được gì?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '1. Hai lớp trả lời. Lớp trên thiết bị luôn chạy và không gửi '
                'dữ liệu cá nhân đi đâu. Lớp Gemini chỉ bổ sung gợi ý từ đề '
                'cương khi kết nối được.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '2. Hỏi nhanh trên thiết bị trả lời được: tóm tắt môn (tín '
                'chỉ, giảng viên, tiên quyết, số slot, đầu điểm, chuẩn đầu '
                'ra), danh sách bài kiểm tra và trọng số, nội dung từng slot, '
                'điểm và điểm thành phần, bí kíp đã duyệt, chiến lược ôn môn, '
                'tổng quan kỳ (số môn, tín chỉ, môn đủ điều kiện), môn vướng '
                'tiên quyết, môn cần học lại, môn có thể đăng ký, GPA từng kỳ '
                'và tích lũy, tín chỉ đã qua.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '3. Gemini trả lời tự do theo 4 cấp: môn học, kỳ học, chương '
                'trình, điểm số — dựa trên đề cương và bí kíp đã duyệt. Ví dụ: '
                '"Nên ôn gì cho bài PE của môn X?", "So sánh độ khó hai môn '
                'trong kỳ 5", "Lập kế hoạch ôn thi 2 tuần", "Môn nào nên học '
                'trước nếu muốn ra trường đúng hạn?". Câu trả lời Gemini luôn '
                'kèm phần đối chiếu trên thiết bị.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '4. "Mốc Sinh viên Giỏi: GPA tích lũy ≥ 8.0" là mốc tham '
                'chiếu để bạn tự đối chiếu; app không kết luận danh hiệu hay '
                'xét tốt nghiệp.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '5. Vì sao Gemini lỗi? Thường gặp: máy không có mạng; Firebase '
                'AI Logic chưa bật; App Check/Play Integrity không qua (APK '
                'cài tay ký debug thường báo lỗi -14 "Play Store needs to be '
                'updated"); hoặc hết hạn mức.',
                style: TextStyle(height: 1.4),
              ),
              if (vm.aiFailure != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Lỗi AI gần nhất\n${vm.aiFailure}',
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                '6. Trạng thái kỹ thuật\n${vm.diagnostics}',
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
              if (vm.usesDebugAppCheck) ...[
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Bản build này dùng App Check debug provider với token cố '
                  'định đã đăng ký sẵn. Cài lại app hoặc chuyển giữa bản '
                  'debug và bản release không cần thêm token mới.',
                  style: TextStyle(fontSize: AppFontSize.caption),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final advisorVm = context.watch<AdvisorViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cố vấn học tập',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Dữ liệu học tập',
            onPressed: () => Navigator.pushNamed(context, '/academic-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Cố vấn làm được gì?',
            onPressed: () => _showHelp(advisorVm),
          ),
        ],
      ),
      body: Column(
        children: [
          _AiStatusBanner(vm: advisorVm, onOpenHelp: () => _showHelp(advisorVm)),

          // Consultation level selector (rubric §6.4 — 4 levels)
          Semantics(
            label: 'Chọn cấp tư vấn',
            container: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final level in AdvisorLevel.values)
                    ChoiceChip(
                      label: Text(level.label),
                      selected: advisorVm.selectedLevel == level,
                      onSelected: advisorVm.isLoading
                          ? null
                          : (_) => advisorVm.selectLevel(level),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: advisorVm.messages.length,
              itemBuilder: (context, index) {
                final msg = advisorVm.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _MessageBubble(message: msg),
                );
              },
            ),
          ),

          if (advisorVm.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Đang tổng hợp câu trả lời...',
                    style: TextStyle(fontSize: AppFontSize.label),
                  ),
                ],
              ),
            ),

          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: advisorVm.isLoading
                    ? null
                    : () => _openLocalPrompts(advisorVm),
                icon: const Icon(Icons.touch_app_outlined, size: 18),
                label: const Text('Hỏi nhanh trên thiết bị · không cần mạng'),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Hỏi tự do về môn, kỳ, chương trình, GPA...',
                      isDense: true,
                      counterText: '',
                    ),
                    onSubmitted: (val) => _sendMessage(advisorVm, val),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  tooltip: 'Gửi câu hỏi',
                  onPressed: advisorVm.isLoading
                      ? null
                      : () => _sendMessage(advisorVm, _inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusBanner extends StatelessWidget {
  const _AiStatusBanner({required this.vm, required this.onOpenHelp});

  final AdvisorViewModel vm;
  final VoidCallback onOpenHelp;

  @override
  Widget build(BuildContext context) {
    final failed = vm.isAiEnabled && vm.aiStatus == AiStatus.unavailable;
    final available = vm.isAiEnabled && vm.aiStatus == AiStatus.available;
    final background = failed
        ? AppColors.warningContainer
        : available
        ? AppColors.successContainer
        : AppColors.primaryContainer;
    final foreground = failed
        ? AppColors.warning
        : available
        ? AppColors.success
        : AppColors.primary;
    final icon = failed
        ? Icons.cloud_off_outlined
        : available
        ? Icons.cloud_done_outlined
        : !vm.isAiEnabled || !vm.usesGemini
        ? Icons.phone_android
        : Icons.cloud_queue;
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: foreground),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vm.aiStatusTitle,
                  style: TextStyle(
                    fontSize: AppFontSize.label,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  vm.aiStatusDetail,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSize.caption,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (failed)
            TextButton(
              onPressed: vm.retryLastQuestion,
              child: const Text('Thử lại AI'),
            )
          else
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Chi tiết AI',
              onPressed: onOpenHelp,
              icon: const Icon(Icons.info_outline, size: 18),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AdvisorMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    if (isUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                message.text,
                style: const TextStyle(color: AppColors.onPrimary, height: 1.4),
              ),
            ),
          ),
        ],
      );
    }

    final isError = message.isError;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isError
                ? AppColors.warningContainer
                : AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isError ? Icons.cloud_off_outlined : Icons.school,
            size: 16,
            color: isError ? AppColors.warning : AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isError ? AppColors.warningContainer : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isError ? AppColors.warning : AppColors.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _sourceBackground(message.source),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          message.source.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppFontSize.label,
                            fontWeight: FontWeight.bold,
                            color: _sourceForeground(message.source),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Sao chép',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép phản hồi cố vấn!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_outlined, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 30,
                        minHeight: 30,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Tạo ghi chú từ tư vấn này',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/note-editor',
                          arguments: NoteDraft(
                            title: 'Tư vấn: ${message.level.label}',
                            content: message.text,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                MarkdownBody(
                  data: message.text,
                  selectable: true,
                  styleSheet: _markdownStyle(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Color _sourceBackground(AdvisorSource source) => switch (source) {
    AdvisorSource.hybrid => AppColors.primaryContainer,
    AdvisorSource.aiUnavailable => AppColors.warningContainer,
    AdvisorSource.local => AppColors.skeleton,
  };

  static Color _sourceForeground(AdvisorSource source) => switch (source) {
    AdvisorSource.hybrid => AppColors.primary,
    AdvisorSource.aiUnavailable => AppColors.warning,
    AdvisorSource.local => AppColors.onSurfaceVariant,
  };

  static MarkdownStyleSheet _markdownStyle(BuildContext context) =>
      MarkdownStyleSheet(
        p: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 14,
          height: 1.45,
        ),
        h3: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        strong: const TextStyle(
          color: AppColors.onSurface,
          fontWeight: FontWeight.bold,
        ),
        em: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        listBullet: const TextStyle(color: AppColors.onSurface, fontSize: 14),
        blockquote: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 13,
          height: 1.4,
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.skeleton,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
      );
}

class _LocalPromptSheet extends StatefulWidget {
  const _LocalPromptSheet({required this.vm});

  final AdvisorViewModel vm;

  @override
  State<_LocalPromptSheet> createState() => _LocalPromptSheetState();
}

class _LocalPromptSheetState extends State<_LocalPromptSheet> {
  String? _course;
  int? _semester;

  @override
  void initState() {
    super.initState();
    final vm = widget.vm;
    _course = vm.selectedLocalCourse ?? vm.defaultLocalCourse?.code;
    _semester = vm.defaultLocalSemester;
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final courses = vm.catalogCourses;
    final semesters = vm.catalogSemesters;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỏi nhanh trên thiết bị',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                const Text(
                  'Chọn câu hỏi — trả lời ngay, không cần mạng và không gửi '
                  'dữ liệu cá nhân đi đâu.',
                  style: TextStyle(
                    fontSize: AppFontSize.label,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              children: [
                if (courses.isNotEmpty) ...[
                  Text(
                    'Môn học',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  DropdownButtonFormField<String>(
                    initialValue: _course,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn môn',
                      isDense: true,
                    ),
                    items: courses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course.code,
                            child: Text(
                              '${course.code} — ${course.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _course = value);
                      vm.selectLocalCourse(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final kind in LocalQuestionKind.forLevel(
                    AdvisorLevel.course,
                  ))
                    _promptTile(kind, enabled: _course != null),
                ] else
                  const AppCard(
                    child: Text(
                      'Chưa có danh mục môn. Chọn chuyên ngành và đăng nhập '
                      'để xem câu hỏi theo từng môn.',
                    ),
                  ),
                if (semesters.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Kỳ học',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  DropdownButtonFormField<int>(
                    initialValue: _semester,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn kỳ',
                      isDense: true,
                    ),
                    items: semesters
                        .map(
                          (semester) => DropdownMenuItem(
                            value: semester,
                            child: Text('Kỳ $semester'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _semester = value);
                      vm.selectLocalSemester(value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final kind in LocalQuestionKind.forLevel(
                    AdvisorLevel.semester,
                  ))
                    _promptTile(kind, enabled: _semester != null),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Chương trình',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                for (final kind in LocalQuestionKind.forLevel(
                  AdvisorLevel.program,
                ))
                  _promptTile(kind, enabled: true),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Điểm số',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                for (final kind in LocalQuestionKind.forLevel(
                  AdvisorLevel.score,
                ))
                  _promptTile(kind, enabled: true),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _promptTile(LocalQuestionKind kind, {required bool enabled}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      enabled: enabled,
      leading: Icon(_iconFor(kind), color: AppColors.primary),
      title: Text(kind.label),
      subtitle: Text(kind.description),
      trailing: const Icon(Icons.chevron_right),
      onTap: enabled
          ? () {
              widget.vm.selectLocalCourse(
                kind.needsCourse ? _course : widget.vm.selectedLocalCourse,
              );
              widget.vm.selectLocalSemester(
                kind.needsSemester
                    ? _semester
                    : widget.vm.selectedLocalSemester,
              );
              Navigator.pop(context, kind);
            }
          : null,
    );
  }

  static IconData _iconFor(LocalQuestionKind kind) => switch (kind) {
    LocalQuestionKind.courseOverview => Icons.menu_book_outlined,
    LocalQuestionKind.courseAssessments => Icons.assignment_outlined,
    LocalQuestionKind.courseSlots => Icons.view_list_outlined,
    LocalQuestionKind.coursePrerequisites => Icons.account_tree_outlined,
    LocalQuestionKind.courseGrade => Icons.grading_outlined,
    LocalQuestionKind.courseTips => Icons.lightbulb_outline,
    LocalQuestionKind.courseStudyPlan => Icons.route_outlined,
    LocalQuestionKind.semesterOverview => Icons.calendar_view_month_outlined,
    LocalQuestionKind.semesterAssessments => Icons.fact_check_outlined,
    LocalQuestionKind.blockedPrerequisites => Icons.block_outlined,
    LocalQuestionKind.retakes => Icons.replay_outlined,
    LocalQuestionKind.eligibleCourses => Icons.playlist_add_check_outlined,
    LocalQuestionKind.gpaSummary => Icons.insights_outlined,
    LocalQuestionKind.completedCredits => Icons.verified_outlined,
  };
}

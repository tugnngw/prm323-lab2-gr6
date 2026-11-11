import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../services/study_plan_ai.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key, required this.store, required this.uid});

  final FinalFirestore store;
  final String uid;

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _summary = TextEditingController();
  late Stream<List<StudyPlanSubmission>> _submissions;
  int _semester = 1;
  bool _generating = false;
  bool _sending = false;
  StudyPlanDraft? _draft;

  @override
  void initState() {
    super.initState();
    _submissions = widget.store.watchSubmissions(widget.uid);
  }

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _suggest(RemoteConfigService config) async {
    final analytics = context.read<AnalyticsService>();
    setState(() {
      _generating = true;
      _draft = null;
    });
    unawaited(
      analytics.logAiRequest(feature: 'study_plan', model: config.studyPlanModel),
    );
    try {
      String? curriculumContext;
      try {
        final academic = context.read<AcademicViewModel>();
        final courses = academic.courses.where((c) => c.semester == _semester).toList();
        if (courses.isNotEmpty) {
          curriculumContext = courses
              .map((c) =>
                  '${c.code} (${c.name}, ${c.credits} tín chỉ, ${c.slots.length} slots${c.lecturer.isNotEmpty ? ', GV: ${c.lecturer}' : ''})')
              .join('; ');
        }
      } catch (_) {}

      final draft = await generateStudyPlan(
        semester: _semester,
        model: config.studyPlanModel,
        prompt: config.studyPlanPrompt,
        curriculumContext: curriculumContext,
      );
      if (mounted && config.isStudyPlanAiEnabled) {
        setState(() => _draft = draft);
      }
    } catch (_) {
      unawaited(
        analytics.logAiError(feature: 'study_plan', errorType: 'generation_failed'),
      );
      if (mounted) {
        _message('AI chưa khả dụng. Bạn vẫn có thể nhập kế hoạch trực tiếp.');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _submit() async {
    final summary = _summary.text.trim();
    if (summary.isEmpty || summary.length > 600) {
      _message('Nhập kế hoạch từ 1 đến 600 ký tự.');
      return;
    }
    setState(() => _sending = true);
    try {
      if (await widget.store.ensureRole(widget.uid) != 'user') {
        if (mounted) _message('Tài khoản Staff/Admin dùng cổng web.');
        return;
      }
      await widget.store.submit(widget.uid, _semester, summary);
      if (mounted) {
        _summary.clear();
        _message('Đã gửi kế hoạch để duyệt.');
      }
    } catch (_) {
      if (mounted) {
        _message(
          'Chưa gửi được. Kiểm tra kết nối và kế hoạch đã gửi của kỳ này.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<RemoteConfigService>();
    final busy = _sending || _generating;
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt kế hoạch học tập')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text(
            'Staff sẽ thấy kỳ học và nội dung kế hoạch bạn gửi. Tránh nhập thông tin cá nhân.',
          ),
          DropdownButton<int>(
            value: _semester,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(value: i + 1, child: Text('Kỳ ${i + 1}')),
            ),
            onChanged: busy
                ? null
                : (value) => setState(() {
                    _semester = value!;
                    _draft = null;
                  }),
          ),
          if (config.isStudyPlanAiEnabled)
            OutlinedButton(
              onPressed: busy ? null : () => _suggest(config),
              child: Text(_generating ? 'Đang tạo gợi ý...' : 'Gợi ý bằng AI'),
            ),
          if (config.isStudyPlanAiEnabled && draft != null)
            Card(
              child: ListTile(
                title: const Text('Bản nháp do AI tạo'),
                subtitle: Text(draft.editableText),
                trailing: TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          _summary.text = draft.editableText;
                          setState(() => _draft = null);
                          unawaited(
                            context
                                .read<AnalyticsService>()
                                .logAiResultAccepted(feature: 'study_plan'),
                          );
                        },
                  child: const Text('Dùng'),
                ),
              ),
            ),
          TextField(
            controller: _summary,
            enabled: !busy,
            maxLength: 600,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Nội dung kế hoạch'),
          ),
          FilledButton(
            onPressed: busy ? null : _submit,
            child: Text(_sending ? 'Đang gửi...' : 'Gửi để duyệt'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kế hoạch đã gửi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          StreamBuilder<List<StudyPlanSubmission>>(
            stream: _submissions,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: () => setState(() {
                    _submissions = widget.store.watchSubmissions(widget.uid);
                  }),
                  child: const Text('Tải lại danh sách kế hoạch'),
                );
              }
              final records = snapshot.data;
              if (records == null) return const LinearProgressIndicator();
              if (records.isEmpty) {
                return const Text('Chưa có kế hoạch gửi duyệt.');
              }
              return Column(
                children: [
                  for (final item in records)
                    ListTile(
                      title: Text(
                        'Kỳ ${item.semester} · ${switch (item.status) {
                          'approved' => 'Đã duyệt',
                          'rejected' => 'Từ chối',
                          _ => 'Chờ duyệt',
                        }}',
                      ),
                      subtitle: Text(
                        item.reason.isEmpty
                            ? item.summary
                            : '${item.summary}\nPhản hồi: ${item.reason}',
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

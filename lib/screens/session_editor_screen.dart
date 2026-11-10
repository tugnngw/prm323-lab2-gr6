import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/academic_profile.dart';
import '../models/schedule_rules.dart';
import '../models/slot_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_text_field.dart';

/// Create / edit one weekly session. Opening it with an [entry] edits that
/// session in place; [copyOf] pre-fills the form for a duplicate.
class SessionEditorScreen extends StatefulWidget {
  const SessionEditorScreen({super.key, this.entry, this.copyOf});

  final TimetableEntry? entry;
  final TimetableEntry? copyOf;

  @override
  State<SessionEditorScreen> createState() => _SessionEditorScreenState();
}

class _SessionEditorScreenState extends State<SessionEditorScreen> {
  late final _code = TextEditingController();
  late final _name = TextEditingController();
  late final _room = TextEditingController();
  late final _campus = TextEditingController();
  late final _lecturer = TextEditingController();
  late final _sectionGroup = TextEditingController();
  late final _notes = TextEditingController();
  late final _startTime = TextEditingController();
  late final _endTime = TextEditingController();

  int? _weekday;
  int? _slotNumber;
  int? _semester;
  String? _effectiveStart;
  String? _effectiveEnd;
  bool _customTimes = false;
  bool _saving = false;
  Map<String, String> _errors = const {};

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final source = widget.entry ?? widget.copyOf;
    _code.text = source?.courseCode ?? '';
    _name.text = source?.courseName ?? '';
    _room.text = source?.room ?? '';
    _campus.text = source?.campus ?? '';
    _lecturer.text = source?.lecturer ?? '';
    _sectionGroup.text = source?.section ?? '';
    _notes.text = source?.notes ?? '';
    _weekday = source?.weekday;
    _slotNumber = source?.slotNumber;
    _semester = source?.semester;
    _effectiveStart = source?.effectiveStart;
    _effectiveEnd = source?.effectiveEnd;
    _startTime.text = source?.startTime ?? '';
    _endTime.text = source?.endTime ?? '';
    _customTimes = source != null && source.slotNumber == null;
  }

  @override
  void dispose() {
    for (final c in [
      _code,
      _name,
      _room,
      _campus,
      _lecturer,
      _sectionGroup,
      _notes,
      _startTime,
      _endTime,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  SlotCatalog get _catalog => context.read<AcademicViewModel>().slotCatalog;

  void _applySlot(SlotDefinition slot) {
    setState(() {
      _slotNumber = slot.number;
      // Choosing a slot again replaces custom times, so the saved session is
      // not labelled "Giờ tự chọn" while showing slot times.
      _customTimes = false;
      _startTime.text = slot.start;
      _endTime.text = slot.end;
      _errors = {..._errors}
        ..remove('startTime')
        ..remove('endTime')
        ..remove('slotNumber');
    });
  }

  TimetableEntry _buildEntry() {
    final base = widget.entry;
    return TimetableEntry(
      // A copied session keeps no id, so it is stored as a new record.
      id: base?.id ?? '',
      courseCode: _code.text.trim().toUpperCase(),
      courseName: _name.text.trim(),
      weekday: _weekday ?? 1,
      slotNumber: _customTimes ? null : _slotNumber,
      startTime: _startTime.text.trim(),
      endTime: _endTime.text.trim(),
      room: _room.text.trim(),
      campus: _campus.text.trim(),
      lecturer: _lecturer.text.trim(),
      section: _sectionGroup.text.trim(),
      notes: _notes.text.trim(),
      semester: _semester,
      effectiveStart: _effectiveStart,
      effectiveEnd: _effectiveEnd,
    );
  }

  Future<void> _save(AcademicViewModel vm) async {
    final entry = _buildEntry();
    final errors = ScheduleRules.validate(
      courseCode: entry.courseCode,
      courseName: entry.courseName,
      weekday: _weekday,
      slotNumber: _slotNumber,
      startTime: entry.startTime,
      endTime: entry.endTime,
      catalog: _catalog,
      effectiveStart: entry.effectiveStart,
      effectiveEnd: entry.effectiveEnd,
    );
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    setState(() => _errors = const {});
    if (ScheduleRules.isDuplicate(
      entry,
      vm.timetable,
      ignoreId: widget.entry?.id,
    )) {
      setState(
        () => _errors = {
          'duplicate': 'Buổi học này đã có trong thời khóa biểu của bạn.',
        },
      );
      return;
    }
    final conflicts = ScheduleRules.conflictsWith(
      entry,
      vm.timetable,
      ignoreId: widget.entry?.id,
    );
    if (conflicts.isNotEmpty && !await _confirmConflicts(conflicts)) return;
    if (!mounted) return;

    setState(() => _saving = true);
    final ok = _isEditing
        ? await vm.updateSession(entry)
        : await vm.addSession(entry);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.lastError ?? 'Không lưu được buổi học.')),
      );
      return;
    }
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Đã cập nhật buổi học.' : 'Đã thêm buổi học vào lịch.',
        ),
      ),
    );
  }

  Future<bool> _confirmConflicts(List<ScheduleConflict> conflicts) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Có buổi học bị trùng giờ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Xem lại các buổi bị trùng trước khi lưu:'),
              const SizedBox(height: AppSpacing.sm),
              for (final conflict in conflicts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text('• ${conflict.description}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vẫn lưu'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _effectiveStart : _effectiveEnd;
    final initial = current == null ? DateTime.now() : DateTime.parse(current);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Ngày bắt đầu hiệu lực' : 'Ngày kết thúc hiệu lực',
    );
    if (picked == null) return;
    final value =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _effectiveStart = value;
      } else {
        _effectiveEnd = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    final preview = _buildEntry();
    final conflicts = ScheduleRules.conflictsWith(
      preview,
      vm.timetable,
      ignoreId: widget.entry?.id,
    ).length;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isEditing ? 'Sửa buổi học' : 'Thêm buổi học',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _block(
            context,
            '1. Thông tin môn học',
            children: [
              _coursePicker(vm),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _code,
                label: 'Mã môn *',
                hint: 'PRM323',
                errorText: _errors['courseCode'],
                onChanged: (value) => setState(() {
                  _errors = {..._errors}..remove('courseCode');
                  final match = vm.courses.where(
                    (c) => c.code.toUpperCase() == value.trim().toUpperCase(),
                  );
                  if (match.isNotEmpty && _name.text.isEmpty) {
                    _name.text = match.first.name;
                  }
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _name,
                label: 'Tên môn học *',
                hint: 'Lập trình di động đa nền tảng',
                errorText: _errors['courseName'],
                onChanged: (_) => setState(
                  () => _errors = {..._errors}..remove('courseName'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _block(
            context,
            '2. Buổi học trong tuần',
            children: [
              _weekdayField(),
              const SizedBox(height: AppSpacing.sm),
              _slotField(),
              if (!_catalog.verified) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _catalog.sourceNote,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: AppFontSize.label,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tự chỉnh giờ'),
                subtitle: const Text(
                  'Bật khi buổi học không theo slot chuẩn.',
                ),
                value: _customTimes,
                onChanged: (value) => setState(() {
                  _customTimes = value;
                  if (!value && _slotNumber != null) {
                    final slot = _catalog.byNumber(_slotNumber!);
                    if (slot != null) {
                      _startTime.text = slot.start;
                      _endTime.text = slot.end;
                    }
                  }
                }),
              ),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _startTime,
                      label: 'Giờ bắt đầu *',
                      hint: '07:30',
                      keyboardType: TextInputType.datetime,
                      errorText: _errors['startTime'],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _endTime,
                      label: 'Giờ kết thúc *',
                      hint: '09:00',
                      keyboardType: TextInputType.datetime,
                      errorText: _errors['endTime'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _block(
            context,
            '3. Thời gian học kỳ',
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _semester,
                decoration: const InputDecoration(labelText: 'Kỳ học'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Không chọn'),
                  ),
                  for (var i = 1; i <= 9; i++)
                    DropdownMenuItem<int?>(value: i, child: Text('Kỳ $i')),
                ],
                onChanged: (value) => setState(() => _semester = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      label: 'Bắt đầu hiệu lực',
                      value: _effectiveStart,
                      error: _errors['effectiveStart'],
                      onTap: () => _pickDate(isStart: true),
                      onClear: () => setState(() => _effectiveStart = null),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _dateField(
                      label: 'Kết thúc hiệu lực',
                      value: _effectiveEnd,
                      error: _errors['effectiveEnd'],
                      onTap: () => _pickDate(isStart: false),
                      onClear: () => setState(() => _effectiveEnd = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Buổi học lặp lại mỗi tuần trong khoảng ngày này. '
                'Để trống nếu môn học kéo dài cả kỳ.',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _block(
            context,
            '4. Thông tin bổ sung (không bắt buộc)',
            children: [
              AppTextField(
                controller: _room,
                label: 'Phòng học',
                hint: 'AL-R302',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _campus,
                label: 'Cơ sở',
                hint: 'Hòa Lạc',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _lecturer,
                label: 'Giảng viên',
                hint: 'Nguyễn Văn A',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _sectionGroup,
                label: 'Lớp / Nhóm',
                hint: 'SE1810',
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _notes,
                label: 'Ghi chú',
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _block(
            context,
            '5. Xem lại',
            children: [
              if (_errors['duplicate'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _errors['duplicate']!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              Text(_previewLine(preview)),
              if (conflicts > 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Trùng giờ với $conflicts buổi khác trong lịch.',
                    style: const TextStyle(color: AppColors.warning),
                  ),
                )
              else
                const Text('Không thấy trùng giờ với lịch hiện có.'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _isEditing ? 'Lưu thay đổi' : 'Thêm buổi học',
            icon: Icons.save_outlined,
            isExpanded: true,
            isLoading: _saving,
            onPressed: () => _save(vm),
          ),
        ],
      ),
    );
  }

  String _previewLine(TimetableEntry entry) {
    final parts = [
      '${entry.courseCode} — ${entry.courseName}',
      ScheduleConflict.weekdayLabel(entry.weekday),
      entry.slotNumber == null ? 'Giờ tự chọn' : 'Slot ${entry.slotNumber}',
      '${entry.startTime}–${entry.endTime}',
      if (entry.room.isNotEmpty) 'Phòng ${entry.room}',
      if (entry.campus.isNotEmpty) entry.campus,
      if (entry.lecturer.isNotEmpty) entry.lecturer,
    ];
    return parts.join(' · ');
  }

  Widget _coursePicker(AcademicViewModel vm) {
    if (vm.courses.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final course in vm.courses.take(12))
          ActionChip(
            label: Text(course.code),
            onPressed: () => setState(() {
              _code.text = course.code;
              _name.text = course.name;
              _errors = {..._errors}..remove('courseCode');
            }),
          ),
      ],
    );
  }

  Widget _weekdayField() => DropdownButtonFormField<int>(
    initialValue: _weekday,
    decoration: const InputDecoration(labelText: 'Thứ *'),
    items: [
      for (var day = 1; day <= 7; day++)
        DropdownMenuItem(
          value: day,
          child: Text(ScheduleConflict.weekdayLabel(day)),
        ),
    ],
    onChanged: (value) => setState(() {
      _weekday = value;
      _errors = {..._errors}..remove('weekday');
    }),
    validator: (_) => _errors['weekday'],
  );

  Widget _slotField() => DropdownButtonFormField<int>(
    initialValue: _slotNumber,
    decoration: const InputDecoration(labelText: 'Slot'),
    items: [
      for (final slot in _catalog.slots)
        DropdownMenuItem(
          value: slot.number,
          child: Text('${slot.label} (${slot.range})'),
        ),
    ],
    onChanged: (value) {
      final slot = value == null ? null : _catalog.byNumber(value);
      if (slot != null) _applySlot(slot);
    },
    validator: (_) => _errors['slotNumber'],
  );

  Widget _dateField({
    required String label,
    required String? value,
    required String? error,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: AppSpacing.xxs),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InputDecorator(
          decoration: InputDecoration(
            errorText: error,
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined)
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Xóa ngày',
                    onPressed: onClear,
                  ),
          ),
          child: Text(value ?? 'Chưa chọn'),
        ),
      ),
    ],
  );

  Widget _block(
    BuildContext context,
    String title, {
    required List<Widget> children,
  }) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        ...children,
      ],
    ),
  );
}

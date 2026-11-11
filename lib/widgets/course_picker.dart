import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/roadmap_viewmodel.dart';

/// Opens a two-step picker (major → searchable course list). Returns the chosen
/// course, or null when dismissed. Catalog reads are per-major so a student can
/// target a subject outside the curriculum they are currently viewing.
Future<CourseModel?> showCoursePicker(
  BuildContext context, {
  String? initialCourseCode,
  String? initialMajor,
}) {
  final roadmap = context.read<RoadmapViewModel>();
  return showDialog<CourseModel>(
    context: context,
    builder: (_) => _CoursePickerDialog(
      roadmap: roadmap,
      initialCourseCode: initialCourseCode,
      initialMajor: initialMajor,
    ),
  );
}

class _CoursePickerDialog extends StatefulWidget {
  const _CoursePickerDialog({
    required this.roadmap,
    this.initialCourseCode,
    this.initialMajor,
  });

  final RoadmapViewModel roadmap;
  final String? initialCourseCode;
  final String? initialMajor;

  @override
  State<_CoursePickerDialog> createState() => _CoursePickerDialogState();
}

class _CoursePickerDialogState extends State<_CoursePickerDialog> {
  final _search = TextEditingController();
  List<CourseModel> _courses = const [];
  String _major = '';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final majors = _majorOptions();
    final preferred = widget.initialMajor?.trim() ?? '';
    if (preferred.isNotEmpty) {
      _major = preferred;
    } else if (widget.roadmap.selectedMajor.isNotEmpty) {
      _major = widget.roadmap.selectedMajor;
    } else if (majors.isNotEmpty) {
      _major = majors.first.code;
    }
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MajorModel> _majorOptions() {
    final majors = widget.roadmap.availableMajors.toList();
    if (majors.isNotEmpty) return majors;
    // Catalog fallback: derive codes when the majors collection is unreadable.
    final codes = <String>{
      for (final course in widget.roadmap.allCourses)
        if (course.major.trim().isNotEmpty) course.major.trim(),
    };
    return codes
        .map((code) => MajorModel(code: code, name: code))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  Future<void> _load() async {
    if (_major.isEmpty) {
      setState(() {
        _courses = const [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final courses = await widget.roadmap.coursesForMajor(_major);
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
      if (courses.isEmpty) {
        _error = 'Không tìm thấy môn nào cho ngành $_major.';
      }
    });
  }

  List<CourseModel> get _filtered {
    final query = _search.text.trim().toLowerCase();
    final list = _courses.where((course) {
      if (query.isEmpty) return true;
      return course.code.toLowerCase().contains(query) ||
          course.name.toLowerCase().contains(query);
    }).toList();
    list.sort((a, b) {
      if (a.semester != b.semester) return a.semester.compareTo(b.semester);
      return a.code.compareTo(b.code);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final majors = _majorOptions();
    return AlertDialog(
      title: const Text('Chọn môn học'),
      content: SizedBox(
        width: double.maxFinite,
        height: 460,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue:
                  majors.any((m) => m.code == _major) ? _major : null,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Ngành học',
                isDense: true,
              ),
              items: majors
                  .map(
                    (major) => DropdownMenuItem(
                      value: major.code,
                      child: Text(
                        major.name.isEmpty
                            ? major.code
                            : '${major.code} · ${major.name}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null || value == _major) return;
                setState(() => _major = value);
                _search.clear();
                _load();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Tìm mã hoặc tên môn...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? Center(
                      child: Text(
                        _error ??
                            'Không có môn nào khớp "${_search.text.trim()}".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.outline),
                      itemBuilder: (context, index) {
                        final course = _filtered[index];
                        final selected =
                            course.code.toUpperCase() ==
                            (widget.initialCourseCode ?? '').toUpperCase();
                        return ListTile(
                          dense: true,
                          selected: selected,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              course.semester.toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            course.code,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            course.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, course),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}

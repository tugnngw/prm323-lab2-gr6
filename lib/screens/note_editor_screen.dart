import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_text_field.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _courseController = TextEditingController(text: 'PRM323');
  final _contentController = TextEditingController();
  bool _isInitialized = false;
  String? _existingNoteId;
  String? _attachmentName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final notesVm = context.read<NotesViewModel>();
      final arg = widget.noteId ?? ModalRoute.of(context)?.settings.arguments as String?;

      if (arg != null) {
        final existing = notesVm.findNoteById(arg);
        if (existing != null) {
          _existingNoteId = existing.id;
          _titleController.text = existing.title;
          _courseController.text = existing.courseCode;
          _contentController.text = existing.content;
          if (existing.attachmentUrl != null) {
            _attachmentName = 'Tệp đính kèm đã tải lên';
          }
        } else if (arg.startsWith('PRM') || arg.startsWith('SWP') || arg.startsWith('SWR')) {
          // Argument is a course code
          _courseController.text = arg;
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final course = _courseController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề ghi chú')),
      );
      return;
    }

    final notesVm = context.read<NotesViewModel>();
    notesVm.saveNote(
      id: _existingNoteId,
      title: title,
      content: content,
      courseCode: course.isEmpty ? 'Chung' : course,
      attachmentUrl: _attachmentName != null ? 'https://storage/sample.pdf' : null,
      tags: [course.toLowerCase()],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu ghi chú vào Vault thành công!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  void _simulateAttachFile() {
    setState(() {
      _attachmentName = 'baitap_lab3_flutter_mvvm.pdf (2.4 MB)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chọn tệp đính kèm')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingNoteId != null;

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Chỉnh sửa ghi chú' : 'Soạn ghi chú mới',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: 'Đính kèm tệp tin',
            onPressed: _simulateAttachFile,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu ghi chú',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: AppTextField(
                    controller: _titleController,
                    hint: 'Tiêu đề ghi chú...',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 1,
                  child: AppTextField(
                    controller: _courseController,
                    hint: 'Môn học',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Attachment indicator if attached
            if (_attachmentName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _attachmentName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _attachmentName = null),
                      child: const Icon(Icons.close, size: 16, color: AppColors.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Content text area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.outline),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: 'Bắt đầu viết nội dung ghi chú...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Bottom Save Button
            AppButton(
              label: isEditing ? 'Cập nhật ghi chú' : 'Lưu vào Notes Vault',
              icon: Icons.save_outlined,
              isExpanded: true,
              onPressed: _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}

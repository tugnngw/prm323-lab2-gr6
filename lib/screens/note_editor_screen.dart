import 'package:file_picker/file_picker.dart';
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
  String? _attachmentUrl;
  bool _uploading = false;

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
            _attachmentUrl = existing.attachmentUrl;
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

  Future<void> _saveNote() async {
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
    final ok = await notesVm.saveNote(
      id: _existingNoteId,
      title: title,
      content: content,
      courseCode: course.isEmpty ? 'Chung' : course,
      attachmentUrl: _attachmentUrl,
      tags: [course.toLowerCase()],
    );

    if (!mounted) return;
    if (!ok) {
      // Failed persistence is never reported as success. The ViewModel has
      // already reverted its optimistic change; stay in the editor.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notesVm.lastError ?? 'Không thể lưu ghi chú.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu ghi chú vào Vault thành công!'),
        backgroundColor: AppColors.success,
      ),
    );
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Real attachment flow (no mockdata): pick a file, upload its bytes to
  /// Cloud Storage via NotesViewModel, keep the returned download URL. The
  /// note only references the file after the upload actually succeeded.
  Future<void> _attachFile() async {
    if (_uploading) return;
    final notesVm = context.read<NotesViewModel>();
    // file_picker 13: static API, returns empty list on cancel.
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tệp rỗng — không thể tải lên.')),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    final url = await notesVm.uploadAttachment(
      fileName: file.name,
      bytes: bytes,
    );
    if (!mounted) return;
    setState(() => _uploading = false);

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notesVm.lastError ?? 'Tải tệp lên thất bại.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      _attachmentUrl = url;
      _attachmentName = '${file.name} (${(bytes.length / 1024).ceil()} KB)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tải tệp lên Cloud Storage')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingNoteId != null;
    final isSaving = context.watch<NotesViewModel>().isSaving;

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Chỉnh sửa ghi chú' : 'Soạn ghi chú mới',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: _uploading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.attach_file),
            tooltip: 'Đính kèm tệp tin (tải lên Cloud Storage)',
            onPressed: _uploading ? null : _attachFile,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu ghi chú',
            onPressed: isSaving ? null : _saveNote,
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
                      onTap: () => setState(() {
                        _attachmentName = null;
                        _attachmentUrl = null;
                      }),
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
              isLoading: isSaving,
              onPressed: _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}

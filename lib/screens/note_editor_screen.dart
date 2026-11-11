import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/note_attachment.dart';
import '../models/note_draft.dart';
import '../models/note_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_text_field.dart';
import '../widgets/course_picker.dart';
import 'note_ai_screen.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.noteId, this.showLegacyMedia = true});

  final bool showLegacyMedia;

  final String? noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _courseController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isInitialized = false;
  String? _existingNoteId;
  NoteModel? _savedNote;
  bool _preview = false;
  String? _attachmentName;
  String? _attachmentUrl;
  String? _attachmentPath;
  (String?, String?)? _originalAttachment;
  String? _stagedAttachment;
  NotesViewModel? _notesVm;
  bool _saving = false;
  bool _uploading = false;
  bool _downloading = false;
  double? _uploadProgress;
  bool get _transferring => _uploading || _downloading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final notesVm = context.read<NotesViewModel>();
      _notesVm = notesVm;
      final arg = widget.noteId ?? ModalRoute.of(context)?.settings.arguments;

      if (arg is NoteDraft) {
        _titleController.text = arg.title;
        _courseController.text = arg.courseCode;
        if (arg.courseName.isNotEmpty) {
          _courseNameController.text = arg.courseName;
        }
        _contentController.text = arg.content;
        if (arg.pickAttachment && widget.showLegacyMedia) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_attachFile());
          });
        }
      } else if (arg is String) {
        final existing = notesVm.findNoteById(arg);
        if (existing != null) {
          _existingNoteId = existing.id;
          _savedNote = existing;
          _titleController.text = existing.title;
          _courseController.text = existing.courseCode;
          _contentController.text = existing.content;
          _attachmentUrl = existing.attachmentUrl;
          _attachmentPath = existing.attachmentPath;
          _originalAttachment = (_attachmentPath, _attachmentUrl);
          if (_attachmentPath != null || _attachmentUrl != null) {
            _attachmentName = existing.attachmentName ?? 'Tệp đính kèm';
          }
        } else {
          // Deep links may pass a course code directly.
          _courseController.text = arg;
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    if (!_saving) _discardStagedAttachment();
    _titleController.dispose();
    _courseController.dispose();
    _courseNameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickCourse() async {
    final course = await showCoursePicker(
      context,
      initialCourseCode: _courseController.text.trim().isEmpty
          ? null
          : _courseController.text.trim(),
    );
    if (course == null || !mounted) return;
    setState(() {
      _courseController.text = course.code;
      _courseNameController.text = course.name;
    });
  }

  void _discardStagedAttachment() {
    final path = _stagedAttachment;
    _stagedAttachment = null;
    if (path != null) {
      unawaited(_notesVm?.removeObsoleteAttachment(path));
    }
  }

  Future<void> _saveNote() async {
    if (_transferring || _saving) return;
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
    final attachmentChanged =
        (_attachmentPath, _attachmentUrl) != _originalAttachment;
    _saving = true;
    final ok = await notesVm.saveNote(
      id: _existingNoteId,
      title: title,
      content: content,
      courseCode: course.isEmpty ? 'Chung' : course,
      attachmentUrl: _attachmentUrl,
      attachmentPath: _attachmentPath,
      attachmentName: _attachmentName,
      attachmentBefore: attachmentChanged ? _originalAttachment : null,
      preserveAttachment: !attachmentChanged && _existingNoteId != null,
      tags: {
        ...?_savedNote?.tags.where(
          (tag) => tag != _savedNote?.courseCode.toLowerCase(),
        ),
        if (course.isNotEmpty) course.toLowerCase(),
      }.toList(),
    );
    _saving = false;
    if (ok) _stagedAttachment = null;

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
      SnackBar(
        content: Text(
          notesVm.lastError ?? 'Đã lưu ghi chú vào Vault thành công!',
        ),
        backgroundColor: notesVm.lastError == null ? AppColors.success : null,
      ),
    );
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _attachFile() async {
    final notesVm = context.read<NotesViewModel>();
    if (_transferring || notesVm.isSaving) return;
    final uid = notesVm.currentUserId;
    setState(() {
      _uploading = true;
      _uploadProgress = null;
    });
    try {
      // Some Android providers don't advertise a MIME type for Markdown.
      // Accept their selection and validate its extension before reading it.
      final file = await FilePicker.pickFile(
        dialogTitle: 'Chọn tài liệu đính kèm',
      );
      if (file == null || !mounted || uid != notesVm.currentUserId) return;
      final name = NoteAttachment.safeFileName(file.name);
      final error = NoteAttachment.validationError(name, file.lengthSync());
      if (!mounted || uid != notesVm.currentUserId) return;
      if (error != null) {
        _showAttachmentMessage(error, failed: true);
        return;
      }
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in file.readAsByteStream()) {
        if (!mounted || uid != notesVm.currentUserId) return;
        if (buffer.length + chunk.length >= NoteAttachment.maxBytesExclusive) {
          _showAttachmentMessage('Tệp phải nhỏ hơn 10 MB.', failed: true);
          return;
        }
        buffer.add(chunk);
      }
      if (!mounted || uid != notesVm.currentUserId) return;
      final bytes = buffer.takeBytes();
      final mime = NoteAttachment.contentTypeFor(name);
      String? importedText;
      if ((mime == 'text/markdown' || mime == 'text/plain') &&
          bytes.length <= 400 * 1024) {
        try {
          importedText = utf8.decode(bytes);
        } on FormatException {
          // Keep the original file attached even when its text is not UTF-8.
        }
      }
      final path = await notesVm.uploadAttachment(
        fileName: name,
        bytes: bytes,
        onProgress: (progress) {
          if (mounted && _uploading) {
            setState(() => _uploadProgress = progress);
          }
        },
      );
      if (!mounted || uid != notesVm.currentUserId) {
        if (path != null) unawaited(notesVm.removeObsoleteAttachment(path));
        return;
      }
      if (path == null) {
        _showAttachmentMessage(
          notesVm.lastError ?? 'Tải tệp lên thất bại.',
          failed: true,
        );
        return;
      }
      _discardStagedAttachment();
      setState(() {
        _stagedAttachment = path;
        _attachmentUrl = null;
        _attachmentPath = path;
        _attachmentName = name;
        if (_titleController.text.trim().isEmpty) {
          _titleController.text = name.substring(0, name.lastIndexOf('.'));
        }
        if (_contentController.text.trim().isEmpty && importedText != null) {
          _contentController.text = importedText;
        }
      });
      _showAttachmentMessage(
        'Đã tải tệp lên. Lưu ghi chú để giữ tệp đính kèm.',
      );
    } catch (_) {
      if (mounted) _showAttachmentMessage('Không đọc được tệp.', failed: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _downloadAttachment() async {
    final path = _attachmentPath;
    if (path == null || _transferring) return;
    final notesVm = context.read<NotesViewModel>();
    final uid = notesVm.currentUserId;
    setState(() => _downloading = true);
    try {
      final bytes = await notesVm.downloadAttachment(path);
      if (!mounted || uid != notesVm.currentUserId) return;
      final name = NoteAttachment.safeFileName(
        _attachmentName ?? path.split('/').last,
      );
      final location = await FilePicker.saveFile(
        fileName: name.isEmpty ? 'attachment' : name,
        bytes: Uint8List.fromList(bytes),
        mimeType:
            NoteAttachment.contentTypeFor(name) ?? 'application/octet-stream',
      );
      if (mounted && location != null) {
        _showAttachmentMessage('Đã lưu tệp trên thiết bị.');
      }
    } catch (_) {
      if (mounted) {
        _showAttachmentMessage('Không tải được tệp đính kèm.', failed: true);
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showAttachmentMessage(String message, {bool failed = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: failed ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _existingNoteId != null;
    final isSaving = context.watch<NotesViewModel>().isSaving;
    final saved = _savedNote;

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? 'Chỉnh sửa ghi chú' : 'Soạn ghi chú mới',
        onBack: () {
          if (!_saving) Navigator.pop(context);
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu ghi chú',
            onPressed: isSaving || _transferring ? null : _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppTextField(
              controller: _titleController,
              hint: 'Tiêu đề ghi chú...',
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: _pickCourse,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Môn học (tùy chọn)',
                  suffixIcon: Icon(Icons.search),
                ),
                child: Text(
                  _courseController.text.isEmpty
                      ? 'Chọn ngành rồi tìm môn — hoặc để trống cho ghi chú chung'
                      : _courseNameController.text.isEmpty
                      ? _courseController.text
                      : '${_courseController.text} · ${_courseNameController.text}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _courseController.text.isEmpty
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  label: Text(
                    _attachmentName == null ? 'Tải tệp lên' : 'Thay tệp',
                  ),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  onPressed:
                      !widget.showLegacyMedia || _transferring || isSaving
                      ? null
                      : _attachFile,
                ),
                TextButton.icon(
                  label: Text(_preview ? 'Chỉnh sửa' : 'Xem nội dung'),
                  icon: Icon(
                    _preview ? Icons.edit_outlined : Icons.article_outlined,
                  ),
                  onPressed: () => setState(() => _preview = !_preview),
                ),
                if (saved != null &&
                    (saved.content.trim().isNotEmpty ||
                        NoteAiScreen.attachmentType(saved) != null))
                  TextButton.icon(
                    label: const Text('Hỏi AI'),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    onPressed: _transferring || isSaving
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NoteAiScreen(note: saved),
                            ),
                          ),
                  ),
              ],
            ),
            if (!widget.showLegacyMedia)
              const Text('Bản này chưa cấu hình máy chủ lưu tài liệu.'),
            const SizedBox(height: AppSpacing.sm),

            if (_uploading) ...[
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _uploadProgress == null
                    ? 'Đang chuẩn bị tệp…'
                    : 'Đang tải lên ${(_uploadProgress! * 100).round()}%',
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

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
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _attachmentName!,
                        style: const TextStyle(
                          fontSize: AppFontSize.label,
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.showLegacyMedia && _attachmentPath != null)
                      IconButton(
                        tooltip: 'Tải tệp đính kèm',
                        onPressed: _transferring || isSaving
                            ? null
                            : _downloadAttachment,
                        icon: _downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_outlined),
                      ),
                    if (widget.showLegacyMedia)
                      IconButton(
                        tooltip: 'Gỡ tệp khỏi ghi chú',
                        onPressed: _transferring || isSaving
                            ? null
                            : () {
                                _discardStagedAttachment();
                                setState(() {
                                  _attachmentName = null;
                                  _attachmentPath = null;
                                  _attachmentUrl = null;
                                });
                              },
                        icon: const Icon(Icons.close, size: 18),
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
                child: _preview
                    ? Markdown(
                        data: _contentController.text.isEmpty
                            ? 'Ghi chú chưa có nội dung văn bản.'
                            : _contentController.text,
                        padding: EdgeInsets.zero,
                        selectable: true,
                        onTapLink: (_, href, _) async {
                          final url = Uri.tryParse(href ?? '');
                          if (url?.scheme == 'https' &&
                              url?.host == 'flm.fpt.edu.vn') {
                            await launchUrl(
                              url!,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        imageBuilder: (_, title, alt) =>
                            Text(alt ?? title ?? 'Ảnh'),
                      )
                    : TextField(
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
              onPressed: _transferring ? null : _saveNote,
            ),
          ],
        ),
      ),
    );
  }
}

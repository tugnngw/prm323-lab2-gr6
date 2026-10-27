import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/note_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';
import '../widgets/app_text_field.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesVm = context.watch<NotesViewModel>();
    final state = notesVm.state;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Ghi chú học tập'),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: AppSearchBar(
              controller: _searchController,
              hint: 'Tìm kiếm tiêu đề hoặc nội dung ghi chú...',
              onChanged: (val) => notesVm.setSearchQuery(val),
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),

          // Content
          Expanded(
            child: switch (state.state) {
              ViewState.loading => const AppLoadingState(message: 'Đang tải ghi chú...'),
              ViewState.error => AppErrorState(
                  message: state.message ?? 'Lỗi tải ghi chú',
                  onRetry: () => notesVm.loadData(),
                ),
              ViewState.empty => AppEmptyState(
                  message: 'Chưa có ghi chú nào trong Vault.',
                  actionLabel: 'Tạo ghi chú đầu tiên',
                  onAction: () => Navigator.pushNamed(context, '/note-editor'),
                ),
              ViewState.data => _buildNoteList(context, notesVm, notesVm.filteredNotes),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/note-editor'),
        icon: const Icon(Icons.add),
        label: const Text('Tạo ghi chú'),
      ),
    );
  }

  Widget _buildNoteList(
    BuildContext context,
    NotesViewModel vm,
    List<NoteModel> notes,
  ) {
    if (notes.isEmpty) {
      return AppEmptyState(
        message: 'Không tìm thấy ghi chú nào phù hợp.',
        actionLabel: 'Xem tất cả',
        onAction: () {
          _searchController.clear();
          vm.setSearchQuery('');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Dismissible(
            key: Key(note.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.errorContainer,
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            onDismissed: (_) => vm.deleteNote(note.id),
            child: AppCard(
              onTap: () => Navigator.pushNamed(
                context,
                '/note-editor',
                arguments: note.id,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          note.courseCode,
                          style: const TextStyle(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          note.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.onSurfaceVariant),
                        onPressed: () => vm.deleteNote(note.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note.updatedAt,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      if (note.tags.isNotEmpty)
                        Row(
                          children: note.tags.map((tag) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

import '../models/app_state.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/announcements_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key, required this.store});

  final FinalFirestore store;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => AnnouncementsViewModel(
      watchAnnouncements: store.watchAnnouncements,
    )..loadData(),
    child: Scaffold(
      appBar: CustomAppBar(
        title: 'Thông báo hệ thống',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Consumer<AnnouncementsViewModel>(
        builder: (context, vm, _) {
          switch (vm.state.state) {
            case ViewState.loading:
              return const AppLoadingState(message: 'Đang tải thông báo...');
            case ViewState.error:
              return AppErrorState(
                message: vm.state.message ?? 'Không tải được thông báo.',
                onRetry: vm.loadData,
              );
            case ViewState.empty:
              return const AppEmptyState(
                message: 'Chưa có thông báo nào từ nhà trường.',
              );
            case ViewState.data:
              final items = vm.state.data!;
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.body,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              );
          }
        },
      ),
    ),
  );
}

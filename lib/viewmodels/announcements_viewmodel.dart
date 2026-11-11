import 'dart:async';

import 'package:study_pilot_core/study_pilot_core.dart';

import '../models/app_state.dart';
import 'base_viewmodel.dart';

/// School announcements written by staff in the web admin. The stream is
/// long-lived so a new announcement reaches the in-app notification center
/// without a manual refresh.
class AnnouncementsViewModel extends BaseViewModel<List<Announcement>> {
  AnnouncementsViewModel({required this.watchAnnouncements});

  final Stream<List<Announcement>> Function() watchAnnouncements;
  StreamSubscription<List<Announcement>>? _subscription;

  @override
  Future<void> loadData() async {
    setState(const AsyncViewState.loading());
    await _subscription?.cancel();
    _subscription = watchAnnouncements().listen(
      (items) => setState(
        items.isEmpty
            ? const AsyncViewState.empty()
            : AsyncViewState.data(items),
      ),
      onError: (Object error) => setState(
        AsyncViewState.error('Không tải được thông báo: $error'),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

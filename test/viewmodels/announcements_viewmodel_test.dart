import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/app_state.dart';
import 'package:prm393_final_gr6/viewmodels/announcements_viewmodel.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

void main() {
  group('AnnouncementsViewModel', () {
    test('streams empty, data and error states and retries', () async {
      final controller = StreamController<List<Announcement>>.broadcast();
      final vm = AnnouncementsViewModel(
        watchAnnouncements: () => controller.stream,
      );
      addTearDown(() async {
        vm.dispose();
        await controller.close();
      });

      await vm.loadData();
      expect(vm.state.state, ViewState.loading);

      controller.add(const []);
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.state, ViewState.empty);

      const announcement = Announcement(
        id: 'a1',
        title: 'Lịch thi HK5',
        body: 'Xem chi tiết trên portal.',
      );
      controller.add([announcement]);
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.state, ViewState.data);
      expect(vm.state.data!.single.title, 'Lịch thi HK5');

      controller.addError(StateError('offline'));
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.state, ViewState.error);
      expect(vm.state.message, contains('offline'));

      await vm.loadData();
      expect(vm.state.state, ViewState.loading);
      controller.add([announcement]);
      await Future<void>.delayed(Duration.zero);
      expect(vm.state.state, ViewState.data);
    });
  });
}

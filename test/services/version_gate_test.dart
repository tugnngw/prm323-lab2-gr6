import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:prm393_final_gr6/main.dart';
import 'package:prm393_final_gr6/services/remote_config_service.dart';

import '../helpers/mock_auth_service.dart';
import '../helpers/mock_firestore_service.dart';

/// Regression coverage for audit M-09: Remote Config `min_app_version` must
/// change behaviour (block an outdated build), not just be displayed.
///
/// No Firebase app and no Console deploy is involved: the service is built with
/// in-memory [RemoteConfigService.overrides], so these are hermetic.
void main() {
  group('compareVersions', () {
    test('orders dotted numeric versions', () {
      expect(compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('treats missing segments and build metadata as equal', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.0.0', '1.0.0+7'), 0);
      expect(compareVersions('1.0.0+7', '1.0.0'), 0);
      expect(compareVersions('1.0.0-beta', '1.0.0'), 0);
    });
  });

  group('isOutdatedVersion', () {
    test('below minimum is outdated', () {
      expect(isOutdatedVersion('1.0.0', '1.0.1'), isTrue);
      expect(isOutdatedVersion('0.9.9', '1.0.0'), isTrue);
    });

    test('exactly at minimum is allowed', () {
      expect(isOutdatedVersion('1.0.0', '1.0.0'), isFalse);
      expect(isOutdatedVersion('1.0', '1.0.0'), isFalse);
    });

    test('above minimum is allowed', () {
      expect(isOutdatedVersion('1.0.1', '1.0.0'), isFalse);
      expect(isOutdatedVersion('2.0.0', '1.0.0'), isFalse);
    });

    test('fails open on a malformed or empty minimum', () {
      expect(isOutdatedVersion('1.0.0', ''), isFalse);
      expect(isOutdatedVersion('1.0.0', 'latest'), isFalse);
    });
  });

  group('RemoteConfigService min_app_version', () {
    test('below / equal / above minimum', () {
      expect(
        RemoteConfigService(overrides: {'min_app_version': '1.0.1'})
            .isVersionBelowMinimum,
        isTrue,
      );
      expect(
        RemoteConfigService(overrides: {'min_app_version': '1.0.0'})
            .isVersionBelowMinimum,
        isFalse,
      );
      expect(
        RemoteConfigService(overrides: {'min_app_version': '0.9.0'})
            .isVersionBelowMinimum,
        isFalse,
      );
    });

    test('defaults match the committed remote-config-defaults.json', () {
      // M-09 acceptance: defaults are externalized and must not drift.
      final committed = jsonDecode(
        File('firebase/remote-config-defaults.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final service = RemoteConfigService(); // no Firebase app → in-code defaults

      expect(service.minAppVersion, committed['min_app_version']);
      expect(service.isMaintenanceMode, committed['maintenance_mode']);
      expect(service.isAiAdvisorEnabled, committed['feature_ai_advisor_enabled']);
      expect(service.vaultSyncIntervalMins, committed['vault_sync_interval_mins']);
    });

    test('kAppVersion matches pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final version =
          RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
              .firstMatch(pubspec)!
              .group(1);
      expect(kAppVersion, version);
    });
  });

  group('AuthGate version block', () {
    Future<void> pumpApp(WidgetTester tester, Map<String, dynamic> overrides,
        {bool signedIn = true}) async {
      await tester.pumpWidget(
        StudyPilotApp(
          authService: MockAuthService(
            initialUserId: signedIn ? 'user_123' : null,
            initialEmail: signedIn ? 'ducnmse180000@fpt.edu.vn' : null,
          ),
          firestoreService: MockFirestoreService(),
          remoteConfigService: RemoteConfigService(overrides: overrides),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    }

    testWidgets('older build than minimum is blocked', (tester) async {
      await pumpApp(tester, {'min_app_version': '1.0.1'});

      expect(find.text('Cần cập nhật ứng dụng'), findsOneWidget);
      expect(
        find.textContaining('Phiên bản hiện tại $kAppVersion'),
        findsOneWidget,
      );
      expect(find.textContaining('1.0.1'), findsOneWidget);
      // Shell and sign-in are both unreachable while blocked.
      expect(find.text('Trang chủ'), findsNothing);
      expect(find.text('Đăng nhập với Google'), findsNothing);
    });

    testWidgets('exactly at minimum reaches the shell', (tester) async {
      await pumpApp(tester, {'min_app_version': '1.0.0'});

      expect(find.text('Cần cập nhật ứng dụng'), findsNothing);
      expect(find.text('Trang chủ'), findsOneWidget);
    });

    testWidgets('newer build than minimum reaches the shell', (tester) async {
      await pumpApp(tester, {'min_app_version': '0.9.0'});

      expect(find.text('Cần cập nhật ứng dụng'), findsNothing);
      expect(find.text('Trang chủ'), findsOneWidget);
    });

    testWidgets('blocked gate does not break sign-in for a signed-out user',
        (tester) async {
      await pumpApp(tester, {'min_app_version': '9.9.9'}, signedIn: false);

      expect(find.text('Cần cập nhật ứng dụng'), findsOneWidget);
      expect(find.text('Đăng nhập với Google'), findsNothing);
    });

    testWidgets('sign-in still renders when no version block applies',
        (tester) async {
      await pumpApp(tester, {'min_app_version': '1.0.0'}, signedIn: false);

      expect(find.text('Cần cập nhật ứng dụng'), findsNothing);
      expect(find.text('Đăng nhập với Google'), findsOneWidget);
    });

    testWidgets('maintenance_mode still gates after the version check',
        (tester) async {
      await pumpApp(tester,
          {'min_app_version': '1.0.0', 'maintenance_mode': true});

      expect(find.text('Ứng dụng đang bảo trì'), findsOneWidget);
      expect(find.byType(MaintenanceScreen), findsOneWidget);
      expect(find.text('Trang chủ'), findsNothing);
    });

    testWidgets('version block wins over maintenance mode', (tester) async {
      await pumpApp(tester,
          {'min_app_version': '2.0.0', 'maintenance_mode': true});

      expect(find.byType(VersionBlockedScreen), findsOneWidget);
      expect(find.text('Ứng dụng đang bảo trì'), findsNothing);
    });
  });
}

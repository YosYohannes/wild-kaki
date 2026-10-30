import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildkaki/ui/theme.dart';
import 'package:wildkaki/ui/update_banner.dart';
import 'package:wildkaki/update/update_service.dart';

const _base = 'https://github.com/x/y/releases/download/v1.2.0';

String release(
  String tag, {
  List<String> files = const [
    'wildkaki-1.2.0.apk',
    'wildkaki-1.2.0-arm64-v8a.apk',
    'wildkaki-1.2.0-armeabi-v7a.apk',
    'notes.md',
  ],
}) => jsonEncode({
  'tag_name': tag,
  'html_url': 'https://github.com/x/y/releases/tag/$tag',
  'assets': [
    for (final f in files) {'browser_download_url': '$_base/$f'},
  ],
});

class FakePlatform implements AppPlatform {
  FakePlatform(this.version, [this.abiList = const ['arm64-v8a']]);

  final String? version;
  final List<String> abiList;
  final opened = <String>[];

  @override
  Future<String?> installedVersion() async => version;

  @override
  Future<List<String>> abis() async => abiList;

  @override
  Future<void> openUrl(String url) async => opened.add(url);
}

class Net {
  Net(this.body);

  String body;
  bool fail = false;
  final calls = <Uri>[];

  Future<String> call(Uri url) async {
    calls.add(url);
    if (fail) throw Exception('offline');
    return body;
  }
}

class Clock {
  DateTime now = DateTime(2026, 10, 30, 9);
  DateTime call() => now;
}

UpdateService service(
  Net net, {
  String? installed = '1.0.1',
  List<String> abis = const ['arm64-v8a'],
  bool Function()? enabled,
  Clock? clock,
  FakePlatform? platform,
}) => UpdateService(
  enabled: enabled ?? () => true,
  repo: 'x/y',
  platform: platform ?? FakePlatform(installed, abis),
  fetch: net.call,
  clock: (clock ?? Clock()).call,
);

void main() {
  test('versions compare number by number', () {
    expect(isNewerVersion('v1.0.2', '1.0.1'), isTrue);
    expect(isNewerVersion('1.10.0', '1.9.9'), isTrue);
    expect(isNewerVersion('v2.0.0', '1.99.99'), isTrue);
    expect(isNewerVersion('v1.0.1', '1.0.1'), isFalse);
    expect(isNewerVersion('v1.0.0', '1.0.1'), isFalse);
    expect(isNewerVersion('nightly', '1.0.1'), isFalse);
    expect(isNewerVersion('v1.1.0', '1.1.0-beta.1'), isTrue);
    expect(isNewerVersion('v1.1.0-beta.2', '1.1.0-beta.1'), isFalse);
  });

  test('the repository is asked for its latest release', () {
    expect(
      latestReleaseUrl('YosYohannes/wild-kaki').toString(),
      'https://api.github.com/repos/YosYohannes/wild-kaki/releases/latest',
    );
  });

  group('which APK', () {
    final urls = [
      '$_base/wildkaki-1.2.0.apk',
      '$_base/wildkaki-1.2.0-arm64-v8a.apk',
      '$_base/wildkaki-1.2.0-armeabi-v7a.apk',
      '$_base/notes.md',
    ];

    test('the phone\'s own architecture comes first', () {
      expect(
        pickApk(urls, ['armeabi-v7a', 'armeabi']),
        '$_base/wildkaki-1.2.0-armeabi-v7a.apk',
      );
      expect(
        pickApk(urls, ['arm64-v8a', 'armeabi-v7a']),
        '$_base/wildkaki-1.2.0-arm64-v8a.apk',
      );
    });

    test('an unknown architecture gets the universal APK', () {
      expect(pickApk(urls, ['riscv64']), '$_base/wildkaki-1.2.0.apk');
      expect(pickApk(urls, const []), '$_base/wildkaki-1.2.0.apk');
    });

    test('no universal APK and no match means none', () {
      expect(pickApk([urls[1]], ['x86_64']), isNull);
      expect(pickApk([urls[3]], ['arm64-v8a']), isNull);
    });
  });

  test('a newer release offers the APK for this phone', () async {
    final s = service(Net(release('v1.2.0')));
    await s.refresh();
    expect(s.available.value!.version, '1.2.0');
    expect(s.available.value!.url, '$_base/wildkaki-1.2.0-arm64-v8a.apk');
  });

  test('without an APK the release page is offered', () async {
    final s = service(Net(release('v1.2.0', files: ['notes.md'])));
    await s.refresh();
    expect(
      s.available.value!.url,
      'https://github.com/x/y/releases/tag/v1.2.0',
    );
  });

  test('same version, junk and failures offer nothing', () async {
    for (final body in [
      release('v1.0.1'),
      release('v1.0.0'),
      '{}',
      '[]',
      'not json',
      jsonEncode({'tag_name': 5}),
    ]) {
      final s = service(Net(body));
      await s.refresh();
      expect(s.available.value, isNull, reason: body);
    }
    final offline = Net(release('v1.2.0'))..fail = true;
    final s = service(offline);
    await s.refresh();
    expect(s.available.value, isNull);
    final unknown = service(Net(release('v9.0.0')), installed: null);
    await unknown.refresh();
    expect(unknown.available.value, isNull);
  });

  test('switched off, the network is never asked', () async {
    final net = Net(release('v1.2.0'));
    final s = service(net, enabled: () => false);
    await s.refresh();
    expect(net.calls, isEmpty);
    expect(s.available.value, isNull);
  });

  test('it asks again only after six hours', () async {
    final net = Net(release('v1.2.0'));
    final clock = Clock();
    final s = service(net, clock: clock);
    await s.refresh();
    clock.now = clock.now.add(const Duration(hours: 5));
    await s.refresh();
    expect(net.calls, hasLength(1));
    clock.now = clock.now.add(const Duration(hours: 2));
    await s.refresh();
    expect(net.calls, hasLength(2));
  });

  test('a failed check is tried again on the next open', () async {
    final net = Net(release('v1.2.0'))..fail = true;
    final s = service(net);
    await s.refresh();
    net.fail = false;
    await s.refresh();
    expect(s.available.value!.version, '1.2.0');
  });

  test('Later hides that version, a newer one shows again', () async {
    final net = Net(release('v1.2.0'));
    final clock = Clock();
    final s = service(net, clock: clock);
    await s.refresh();
    s.dismiss();
    expect(s.available.value, isNull);

    clock.now = clock.now.add(const Duration(hours: 7));
    await s.refresh();
    expect(s.available.value, isNull);

    net.body = release('v1.3.0');
    clock.now = clock.now.add(const Duration(hours: 7));
    await s.refresh();
    expect(s.available.value!.version, '1.3.0');
  });

  test('Update opens the link', () async {
    final platform = FakePlatform('1.0.1');
    final s = service(Net(release('v1.2.0')), platform: platform);
    await s.openUpdate();
    expect(platform.opened, isEmpty);
    await s.refresh();
    await s.openUpdate();
    expect(platform.opened, ['$_base/wildkaki-1.2.0-arm64-v8a.apk']);
  });

  testWidgets('the banner names the version and offers both buttons', (
    tester,
  ) async {
    var later = 0;
    var update = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: wildTheme(),
        home: Scaffold(
          body: UpdateBanner(
            info: const UpdateInfo(version: '1.2.0', url: 'u'),
            onLater: () => later++,
            onUpdate: () => update++,
          ),
        ),
      ),
    );
    expect(find.text('Version 1.2.0 is ready'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.tap(find.text('Update'));
    expect([later, update], [1, 1]);
  });
}

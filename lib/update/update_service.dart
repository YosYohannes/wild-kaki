import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef UpdateFetch = Future<String> Function(Uri url);

const kUpdateRepo = String.fromEnvironment(
  'UPDATE_REPO',
  defaultValue: 'YosYohannes/wild-kaki',
);

const _recheckAfter = Duration(hours: 6);
const _timeout = Duration(seconds: 10);

Future<String> _httpGet(Uri url) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.getUrl(url).timeout(_timeout);
    request.headers.set('Accept', 'application/vnd.github+json');
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != 200) {
      throw HttpException('status ${response.statusCode}', uri: url);
    }
    return await response.transform(utf8.decoder).join().timeout(_timeout);
  } finally {
    client.close(force: true);
  }
}

class UpdateInfo {
  const UpdateInfo({required this.version, required this.url});

  final String version;
  final String url;

  @override
  bool operator ==(Object other) =>
      other is UpdateInfo && other.version == version && other.url == url;

  @override
  int get hashCode => Object.hash(version, url);
}

({List<int> numbers, bool pre})? _parse(String version) {
  final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(-[0-9A-Za-z.]+)?')
      .firstMatch(version.trim());
  if (m == null) return null;
  return (
    numbers: [for (var i = 1; i <= 3; i++) int.parse(m[i]!)],
    pre: m[4] != null,
  );
}

bool isNewerVersion(String latest, String installed) {
  final a = _parse(latest);
  final b = _parse(installed);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a.numbers[i] != b.numbers[i]) return a.numbers[i] > b.numbers[i];
  }
  return b.pre && !a.pre;
}

Uri latestReleaseUrl(String repo) =>
    Uri.https('api.github.com', '/repos/$repo/releases/latest');

const _abiNames = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];

String? pickApk(List<String> urls, List<String> abis) {
  final apks = [
    for (final u in urls)
      if (u.endsWith('.apk')) u,
  ];
  for (final abi in abis) {
    for (final u in apks) {
      if (u.endsWith('-$abi.apk')) return u;
    }
  }
  for (final u in apks) {
    if (!_abiNames.any((a) => u.endsWith('-$a.apk'))) return u;
  }
  return null;
}

UpdateInfo? parseRelease(String body, String installed, List<String> abis) {
  final json = jsonDecode(body);
  if (json is! Map || json['tag_name'] is! String) return null;
  final tag = json['tag_name'] as String;
  if (!isNewerVersion(tag, installed)) return null;
  final assets = json['assets'];
  final apk = assets is List
      ? pickApk([
          for (final a in assets.whereType<Map>())
            if (a['browser_download_url'] is String)
              a['browser_download_url'] as String,
        ], abis)
      : null;
  final page = json['html_url'];
  final url = apk ?? (page is String ? page : null);
  if (url == null) return null;
  return UpdateInfo(version: tag.replaceFirst(RegExp(r'^v'), ''), url: url);
}

abstract class AppPlatform {
  Future<String?> installedVersion();
  Future<List<String>> abis();
  Future<void> openUrl(String url);
}

class PlatformApp implements AppPlatform {
  static const _channel = MethodChannel('app.wildkaki/app');

  @override
  Future<String?> installedVersion() async {
    try {
      return await _channel.invokeMethod<String>('version');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<List<String>> abis() async {
    try {
      return await _channel.invokeListMethod<String>('abis') ?? const [];
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod<void>('open', url);
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }
}

class UpdateService {
  UpdateService({
    required this.enabled,
    this.repo = kUpdateRepo,
    AppPlatform? platform,
    UpdateFetch? fetch,
    DateTime Function()? clock,
  }) : platform = platform ?? PlatformApp(),
       _fetch = fetch ?? _httpGet,
       _clock = clock ?? DateTime.now;

  final bool Function() enabled;
  final String repo;
  final AppPlatform platform;
  final UpdateFetch _fetch;
  final DateTime Function() _clock;

  final ValueNotifier<UpdateInfo?> available = ValueNotifier(null);

  DateTime? _checkedAt;
  bool _checking = false;
  String? _dismissed;

  Future<void> refresh() async {
    if (!enabled() || _checking) return;
    final last = _checkedAt;
    if (last != null && _clock().difference(last) < _recheckAfter) return;
    _checking = true;
    try {
      final installed = await platform.installedVersion();
      if (installed == null) return;
      final body = await _fetch(latestReleaseUrl(repo));
      _checkedAt = _clock();
      final found = parseRelease(body, installed, await platform.abis());
      available.value = found?.version == _dismissed ? null : found;
    } on Object {
      return;
    } finally {
      _checking = false;
    }
  }

  void dismiss() {
    _dismissed = available.value?.version;
    available.value = null;
  }

  Future<void> openUpdate() async {
    final info = available.value;
    if (info != null) await platform.openUrl(info.url);
  }
}

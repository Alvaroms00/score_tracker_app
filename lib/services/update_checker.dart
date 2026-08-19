import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final String version;
  final String releaseUrl;

  const UpdateInfo({required this.version, required this.releaseUrl});
}

const String _repo = 'Alvaroms00/score_tracker_app';

/// Checks the latest GitHub release for this repo and returns its info if
/// it's newer than the currently installed version. Returns null on any
/// failure (offline, no releases yet, rate limited) or if already up to date.
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
      headers: const {'Accept': 'application/vnd.github+json'},
    ).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final tagName = json['tag_name'] as String?;
    final releaseUrl = json['html_url'] as String?;
    if (tagName == null || releaseUrl == null) return null;

    final latestVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '');
    final currentVersion = (await PackageInfo.fromPlatform()).version;

    if (_isNewer(latestVersion, currentVersion)) {
      return UpdateInfo(version: latestVersion, releaseUrl: releaseUrl);
    }
    return null;
  } catch (_) {
    return null;
  }
}

bool _isNewer(String remote, String local) {
  final remoteParts = _versionParts(remote);
  final localParts = _versionParts(local);
  final length = remoteParts.length > localParts.length
      ? remoteParts.length
      : localParts.length;
  for (var i = 0; i < length; i++) {
    final r = i < remoteParts.length ? remoteParts[i] : 0;
    final l = i < localParts.length ? localParts[i] : 0;
    if (r != l) return r > l;
  }
  return false;
}

List<int> _versionParts(String version) {
  return version.split('.').map((part) {
    final match = RegExp(r'^\d+').firstMatch(part);
    return match == null ? 0 : int.parse(match.group(0)!);
  }).toList();
}

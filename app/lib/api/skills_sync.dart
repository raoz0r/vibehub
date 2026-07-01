import 'dart:io';
import 'paths.dart';

/// Result details returned by the [SkillsSyncApi.sync] operation.
class SkillsSyncResult {
  final bool success;
  final bool downloaded;
  final String path;
  final String reason;
  final String? errorMessage;

  SkillsSyncResult({
    required this.success,
    required this.downloaded,
    required this.path,
    required this.reason,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'SkillsSyncResult(success: $success, downloaded: $downloaded, path: $path, reason: $reason, errorMessage: $errorMessage)';
  }
}

/// Current check status details of the skills file.
class SkillsSyncStatus {
  final bool exists;
  final String path;
  final DateTime? lastModified;
  final double? ageDays;
  final bool needsUpdate;

  SkillsSyncStatus({
    required this.exists,
    required this.path,
    this.lastModified,
    this.ageDays,
    required this.needsUpdate,
  });

  @override
  String toString() {
    return 'SkillsSyncStatus(exists: $exists, path: $path, lastModified: $lastModified, ageDays: $ageDays, needsUpdate: $needsUpdate)';
  }
}

/// An isolated programmatic API for managing the workspace skills catalog synchronization.
/// This checks if the local `skills.json` file exists or is older than 7 days,
/// and automatically downloads the latest version if needed.
class SkillsSyncApi {
  static const String skillsUrl =
      'https://raw.githubusercontent.com/raoz0r/agent-skills-list/refs/heads/main/skills.json';

  /// Resolves the local file path to the catalog's skills.json.
  static String getLocalFilePath() {
    // Using simple concatenation to avoid external dependency on package:path
    return '${VibeHubPaths.dataDir.replaceAll(RegExp(r'[/\\]+'), '/')}/catalog/skills.json';
  }

  /// Evaluates whether the file requires sync update.
  static SkillsSyncStatus checkStatus() {
    final filePath = getLocalFilePath();
    final file = File(filePath);

    if (!file.existsSync()) {
      return SkillsSyncStatus(
        exists: false,
        path: filePath,
        needsUpdate: true,
      );
    }

    final lastModified = file.lastModifiedSync();
    final difference = DateTime.now().difference(lastModified);
    final ageDays = difference.inSeconds / (24 * 3600);
    final needsUpdate = ageDays >= 7;

    return SkillsSyncStatus(
      exists: true,
      path: filePath,
      lastModified: lastModified,
      ageDays: ageDays,
      needsUpdate: needsUpdate,
    );
  }

  /// Triggers the synchronization.
  /// Downloads the latest catalog if the file is missing or older than 7 days (or if [force] is true).
  static Future<SkillsSyncResult> sync({bool force = false}) async {
    final status = checkStatus();
    final file = File(status.path);

    if (!status.needsUpdate && !force) {
      return SkillsSyncResult(
        success: true,
        downloaded: false,
        path: status.path,
        reason: 'File is up to date (age: ${status.ageDays?.toStringAsFixed(2)} days, limit: 7 days).',
      );
    }

    final reason = !status.exists
        ? 'File does not exist.'
        : force
            ? 'Forced update requested.'
            : 'File is older than 7 days (age: ${status.ageDays?.toStringAsFixed(2)} days).';

    final client = HttpClient();
    try {
      // Ensure directory exists
      await file.parent.create(recursive: true);

      // Download the catalog JSON
      final request = await client.getUrl(Uri.parse(skillsUrl));
      // Set a generic User-Agent
      request.headers.set(HttpHeaders.userAgentHeader, 'VibeHub-Sync-Agent/1.0');
      
      final response = await request.close();

      if (response.statusCode == 200) {
        // Pipes response stream directly into the file stream
        await response.pipe(file.openWrite());
        return SkillsSyncResult(
          success: true,
          downloaded: true,
          path: status.path,
          reason: 'File downloaded successfully because: $reason',
        );
      } else {
        return SkillsSyncResult(
          success: false,
          downloaded: false,
          path: status.path,
          reason: 'Failed to download due to HTTP status: ${response.statusCode}',
          errorMessage: 'Server returned HTTP status code ${response.statusCode}',
        );
      }
    } catch (e) {
      return SkillsSyncResult(
        success: false,
        downloaded: false,
        path: status.path,
        reason: 'Failed to download due to an unexpected error.',
        errorMessage: e.toString(),
      );
    } finally {
      client.close();
    }
  }
}

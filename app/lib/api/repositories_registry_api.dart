import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'paths.dart';

class RepositoriesRegistryApi {
  RepositoriesRegistryApi({String? registryFilePath}) : _customRegistryFilePath = registryFilePath;

  final String? _customRegistryFilePath;

  String get _registryFilePath => _customRegistryFilePath ?? p.join(VibeHubPaths.configDir, 'registered_repositories.json');

  /// Fetches the list of all registered repository directories.
  Future<List<Map<String, String>>> getRegisteredRepositories() async {
    final file = File(_registryFilePath);
    if (!await file.exists()) {
      return [];
    }
    try {
      final content = await file.readAsString();
      final decoded = json.decode(content);
      if (decoded is Map && decoded['repositories'] is List) {
        return (decoded['repositories'] as List).map((item) {
          final map = item as Map;
          return {
            'id': map['id'] as String,
            'name': map['name'] as String,
            'path': map['path'] as String,
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Registers a new repository directory path.
  Future<void> registerRepository({
    required String id,
    required String name,
    required String path,
  }) async {
    final file = File(_registryFilePath);
    await file.parent.create(recursive: true);
    final current = await getRegisteredRepositories();
    // Normalise path separators
    final normalizedPath = path.replaceAll('\\', '/');
    if (!current.any((repo) => repo['path'] == normalizedPath || repo['id'] == id)) {
      current.add({'id': id, 'name': name, 'path': normalizedPath});
      await file.writeAsString(json.encode({'repositories': current}));
    }
  }

  /// Unregisters a repository directory path by its ID.
  Future<void> unregisterRepository(String id) async {
    final file = File(_registryFilePath);
    final current = await getRegisteredRepositories();
    final lengthBefore = current.length;
    current.removeWhere((repo) => repo['id'] == id);
    if (current.length < lengthBefore) {
      await file.parent.create(recursive: true);
      await file.writeAsString(json.encode({'repositories': current}));
    }
  }
}

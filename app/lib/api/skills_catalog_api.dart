import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

part '../src/skills_catalog_memory_database.dart';

class CatalogSkill {
  const CatalogSkill({
    required this.name,
    required this.owner,
    required this.repo,
    required this.version,
    required this.sha,
    required this.repoUrl,
    required this.installCommand,
    this.metadata = const {},
  });

  final String name;
  final String owner;
  final String repo;
  final String version;
  final String sha;
  final String repoUrl;
  final String installCommand;
  final Map<String, dynamic> metadata;

  factory CatalogSkill.fromJson(Map<String, dynamic> json) {
    return CatalogSkill(
      name: (json['name'] as String?)?.trim() ?? '',
      owner: (json['owner'] as String?)?.trim() ?? '',
      repo: (json['repo'] as String?)?.trim() ?? '',
      version: (json['version'] as String?)?.trim() ?? '',
      sha: (json['sha'] as String?)?.trim() ?? '',
      repoUrl: (json['repoUrl'] as String?)?.trim() ?? '',
      installCommand: (json['installCommand'] as String?)?.trim() ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }

  factory CatalogSkill.fromRow(Row row) {
    return CatalogSkill(
      name: row['name'] as String,
      owner: row['owner'] as String,
      repo: row['repo'] as String,
      version: row['version'] as String,
      sha: row['sha'] as String,
      repoUrl: row['repo_url'] as String,
      installCommand: row['install_command'] as String,
      metadata: _decodeCatalogMetadata(row['metadata'] as String?),
    );
  }
}

class SkillsCatalogApi {
  SkillsCatalogApi() : _db = _SkillsCatalogMemoryDatabase();

  final _SkillsCatalogMemoryDatabase _db;
  String? _hydrationError;

  Future<void> hydrateFromFile(String catalogPath) async {
    try {
      final catalogSkills = await loadCatalogSkills(catalogPath);
      replaceCatalogSkills(catalogSkills);
    } catch (error) {
      _hydrationError = error.toString();
    }
  }

  void replaceCatalogSkills(List<CatalogSkill> skills) {
    final conn = _db._connection;
    _hydrationError = null;
    conn.execute('BEGIN TRANSACTION');
    final statement = conn.prepare('''
      INSERT OR REPLACE INTO catalog_skills (
        id,
        comparison_key,
        name,
        owner,
        repo,
        version,
        sha,
        repo_url,
        install_command,
        metadata
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''');

    try {
      conn.execute('DELETE FROM catalog_skills');
      for (final skill in skills) {
        statement.execute([
          skillIdFor(skill.owner, skill.repo, skill.name, skill.version),
          skillComparisonKey(
            owner: skill.owner,
            repo: skill.repo,
            name: skill.name,
          ),
          skill.name,
          skill.owner,
          skill.repo,
          skill.version,
          skill.sha,
          skill.repoUrl,
          skill.installCommand,
          json.encode(skill.metadata),
        ]);
      }
      conn.execute('COMMIT');
    } catch (_) {
      conn.execute('ROLLBACK');
      rethrow;
    } finally {
      statement.close();
    }
  }

  List<CatalogSkill> readAllCatalogSkills() {
    final hydrationError = _hydrationError;
    if (hydrationError != null) {
      throw StateError(hydrationError);
    }

    final results = _db._connection.select(
      'SELECT * FROM catalog_skills ORDER BY owner, repo, id',
    );
    return results.map(CatalogSkill.fromRow).toList();
  }

  void close() {
    _db.close();
  }
}

Map<String, dynamic> _decodeCatalogMetadata(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) {
    return const {};
  }
  final decoded = json.decode(rawJson);
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  return const {};
}

Future<List<CatalogSkill>> loadCatalogSkills(String catalogPath) async {
  final file = File(catalogPath);
  if (!await file.exists()) {
    throw FileSystemException('Skills catalog file was not found', catalogPath);
  }

  final rawJson = await file.readAsString();
  return parseCatalogSkills(rawJson);
}

List<CatalogSkill> parseCatalogSkills(String rawJson) {
  final decoded = json.decode(rawJson);
  final rawSkills = decoded is Map<String, dynamic>
      ? decoded['skills']
      : decoded is List
      ? decoded
      : null;

  if (rawSkills is! List) {
    return const [];
  }

  return rawSkills
      .whereType<Map>()
      .map((item) => CatalogSkill.fromJson(Map<String, dynamic>.from(item)))
      .where(
        (skill) =>
            skill.name.isNotEmpty &&
            skill.owner.isNotEmpty &&
            skill.repo.isNotEmpty &&
            skill.version.isNotEmpty,
      )
      .toList();
}

String skillIdFor(String owner, String repo, String name, String version) {
  return '$owner/$repo/$name@$version';
}

String skillComparisonKey({
  required String owner,
  required String repo,
  required String name,
}) {
  return '$owner/$repo/$name';
}

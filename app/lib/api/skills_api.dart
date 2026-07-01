import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'paths.dart';

part '../src/database.dart';

/// Represents a Skill entry in the database.
class Skill {
  final String id;
  final String owner;
  final String repo;
  final String version;
  final String installCommand;
  final bool updateAvailable;
  final String inJsonProjects;
  final Map<String, dynamic> metadata;
  final String description;

  Skill({
    required this.id,
    required this.owner,
    required this.repo,
    required this.version,
    required this.installCommand,
    required this.updateAvailable,
    required this.inJsonProjects,
    this.metadata = const {},
    this.description = '',
  });

  /// Decodes and returns the list of projects from the [inJsonProjects] field.
  List<Map<String, dynamic>> get projects {
    try {
      final decoded = json.decode(inJsonProjects);
      if (decoded is Map && decoded['projects'] is List) {
        return List<Map<String, dynamic>>.from(
          (decoded['projects'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      }
    } catch (_) {}
    return const [];
  }

  /// Converts this [Skill] to a Map of column names and values for database use.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner': owner,
      'repo': repo,
      'version': version,
      'install_command': installCommand,
      'update_available': updateAvailable ? 1 : 0,
      'in_json_projects': inJsonProjects,
      'metadata': json.encode(metadata),
      'description': description,
    };
  }

  /// Creates a [Skill] from a database [Row].
  factory Skill.fromRow(Row row) {
    return Skill(
      id: row['id'] as String,
      owner: row['owner'] as String,
      repo: row['repo'] as String,
      version: row['version'] as String,
      installCommand: row['install_command'] as String,
      updateAvailable: (row['update_available'] as int) != 0,
      inJsonProjects: row['in_json_projects'] as String,
      metadata:
          json.decode((row['metadata'] as String?) ?? '{}')
              as Map<String, dynamic>,
      description: row['description'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'Skill(id: $id, owner: $owner, repo: $repo, version: $version, installCommand: $installCommand, updateAvailable: $updateAvailable, inJsonProjects: $inJsonProjects, metadata: $metadata, description: $description)';
  }
}

/// A Dart service API for writing, reading, and deleting skills from the database.
class SkillsApi {
  final VibeHubDatabase _db;

  SkillsApi([VibeHubDatabase? db]) : _db = db ?? VibeHubDatabase();

  String _getSkillName(String id) {
    final separator = id.lastIndexOf('@');
    return separator > 0 ? id.substring(0, separator) : id;
  }

  /// Writes (inserts or updates via REPLACE) a [Skill] in the database.
  void writeSkill(Skill skill) {
    final conn = _db._connection;
    final parentId = _getSkillName(skill.id);
    final lastSlash = parentId.lastIndexOf('/');
    final shortName = lastSlash > 0
        ? parentId.substring(lastSlash + 1)
        : parentId;

    conn.execute('BEGIN TRANSACTION');
    try {
      // 1. Write skills metadata using UPSERT to avoid DELETE CASCADE
      conn.execute(
        '''
        INSERT INTO skills (id, name, owner, repo) VALUES (?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET name = excluded.name, owner = excluded.owner, repo = excluded.repo
        ''',
        [parentId, shortName, skill.owner, skill.repo],
      );

      // 2. Write skill version details using UPSERT to avoid DELETE CASCADE
      conn.execute(
        '''
        INSERT INTO skill_versions (id, skill_id, version, install_command, update_available, metadata, description) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET 
          version = excluded.version,
          install_command = excluded.install_command, 
          update_available = excluded.update_available,
          metadata = excluded.metadata,
          description = excluded.description
        ''',
        [
          skill.id,
          parentId,
          skill.version,
          skill.installCommand,
          skill.updateAvailable ? 1 : 0,
          json.encode(skill.metadata),
          skill.description,
        ],
      );

      // 3. Sync projects associated with this skill version
      final projectsList = skill.projects;
      final newProjectIds = projectsList.map((p) => p['id'] as String).toList();

      // Delete projects no longer associated with this specific version
      if (newProjectIds.isEmpty) {
        conn.execute('DELETE FROM project_skills WHERE skill_version_id = ?', [
          skill.id,
        ]);
      } else {
        final placeholders = List.filled(newProjectIds.length, '?').join(', ');
        conn.execute(
          'DELETE FROM project_skills WHERE skill_version_id = ? AND project_id NOT IN ($placeholders)',
          [skill.id, ...newProjectIds],
        );
      }

      // Insert/update currently associated projects using UPSERT
      for (final project in projectsList) {
        conn.execute(
          '''
          INSERT INTO project_skills (project_id, project_name, project_path, skill_version_id)
          VALUES (?, ?, ?, ?)
          ON CONFLICT(project_id, skill_version_id) DO UPDATE SET
            project_name = excluded.project_name,
            project_path = excluded.project_path
          ''',
          [
            project['id'] as String,
            project['name'] as String,
            project['path'] as String,
            skill.id,
          ],
        );
      }
      conn.execute('COMMIT');
    } catch (_) {
      conn.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Reads a [Skill] by its unique [id] (e.g. brand-guidelines@2026.26). Returns null if not found.
  Skill? readSkill(String id) {
    final conn = _db._connection;

    final results = conn.select(
      '''
      SELECT sv.id, s.owner, s.repo, sv.version, sv.install_command, sv.update_available, sv.metadata, sv.description
      FROM skill_versions sv
      JOIN skills s ON sv.skill_id = s.id
      WHERE sv.id = ?
      ''',
      [id],
    );

    if (results.isEmpty) {
      return null;
    }

    final row = results.first;
    final projectRows = conn.select(
      'SELECT project_id, project_name, project_path FROM project_skills WHERE skill_version_id = ?',
      [id],
    );

    final projectsJson = json.encode({
      'projects': projectRows
          .map(
            (pRow) => {
              'id': pRow['project_id'] as String,
              'name': pRow['project_name'] as String,
              'path': pRow['project_path'] as String,
            },
          )
          .toList(),
    });

    return Skill(
      id: id,
      owner: row['owner'] as String,
      repo: row['repo'] as String,
      version: row['version'] as String,
      installCommand: row['install_command'] as String,
      updateAvailable: (row['update_available'] as int) != 0,
      inJsonProjects: projectsJson,
      metadata: _decodeMetadata(row['metadata'] as String?),
      description: row['description'] as String? ?? '',
    );
  }

  /// Reads all skills currently stored in the database.
  List<Skill> readAllSkills() {
    final conn = _db._connection;
    final results = conn.select('''
      SELECT sv.id, s.owner, s.repo, sv.version, sv.install_command, sv.update_available, sv.metadata, sv.description
      FROM skill_versions sv
      JOIN skills s ON sv.skill_id = s.id
      ''');

    if (results.isEmpty) {
      return const [];
    }

    final projectResults = conn.select(
      'SELECT project_id, project_name, project_path, skill_version_id FROM project_skills',
    );

    final projectsMap = <String, List<Map<String, dynamic>>>{};
    for (final row in projectResults) {
      final key = row['skill_version_id'] as String;
      projectsMap.putIfAbsent(key, () => []).add({
        'id': row['project_id'] as String,
        'name': row['project_name'] as String,
        'path': row['project_path'] as String,
      });
    }

    return results.map((row) {
      final id = row['id'] as String;
      final projects = projectsMap[id] ?? const [];
      final projectsJson = json.encode({'projects': projects});

      return Skill(
        id: id,
        owner: row['owner'] as String,
        repo: row['repo'] as String,
        version: row['version'] as String,
        installCommand: row['install_command'] as String,
        updateAvailable: (row['update_available'] as int) != 0,
        inJsonProjects: projectsJson,
        metadata: _decodeMetadata(row['metadata'] as String?),
        description: row['description'] as String? ?? '',
      );
    }).toList();
  }

  /// Reads all skills owned by the specified [owner].
  List<Skill> readSkillsByOwner(String owner) {
    final conn = _db._connection;
    final results = conn.select(
      '''
      SELECT sv.id, s.owner, s.repo, sv.version, sv.install_command, sv.update_available, sv.metadata, sv.description
      FROM skill_versions sv
      JOIN skills s ON sv.skill_id = s.id
      WHERE s.owner = ?
      ''',
      [owner],
    );

    if (results.isEmpty) {
      return const [];
    }

    final projectResults = conn.select(
      '''
      SELECT ps.project_id, ps.project_name, ps.project_path, ps.skill_version_id 
      FROM project_skills ps
      JOIN skill_versions sv ON ps.skill_version_id = sv.id
      JOIN skills s ON sv.skill_id = s.id
      WHERE s.owner = ?
      ''',
      [owner],
    );

    final projectsMap = <String, List<Map<String, dynamic>>>{};
    for (final row in projectResults) {
      final key = row['skill_version_id'] as String;
      projectsMap.putIfAbsent(key, () => []).add({
        'id': row['project_id'] as String,
        'name': row['project_name'] as String,
        'path': row['project_path'] as String,
      });
    }

    return results.map((row) {
      final id = row['id'] as String;
      final projects = projectsMap[id] ?? const [];
      final projectsJson = json.encode({'projects': projects});

      return Skill(
        id: id,
        owner: row['owner'] as String,
        repo: row['repo'] as String,
        version: row['version'] as String,
        installCommand: row['install_command'] as String,
        updateAvailable: (row['update_available'] as int) != 0,
        inJsonProjects: projectsJson,
        metadata: _decodeMetadata(row['metadata'] as String?),
        description: row['description'] as String? ?? '',
      );
    }).toList();
  }

  /// Reads all skills originating from the specified [repo] repository.
  List<Skill> readSkillsByRepo(String repo) {
    final conn = _db._connection;
    final results = conn.select(
      '''
      SELECT sv.id, s.owner, s.repo, sv.version, sv.install_command, sv.update_available, sv.metadata, sv.description
      FROM skill_versions sv
      JOIN skills s ON sv.skill_id = s.id
      WHERE s.repo = ?
      ''',
      [repo],
    );

    if (results.isEmpty) {
      return const [];
    }

    final projectResults = conn.select(
      '''
      SELECT ps.project_id, ps.project_name, ps.project_path, ps.skill_version_id 
      FROM project_skills ps
      JOIN skill_versions sv ON ps.skill_version_id = sv.id
      JOIN skills s ON sv.skill_id = s.id
      WHERE s.repo = ?
      ''',
      [repo],
    );

    final projectsMap = <String, List<Map<String, dynamic>>>{};
    for (final row in projectResults) {
      final key = row['skill_version_id'] as String;
      projectsMap.putIfAbsent(key, () => []).add({
        'id': row['project_id'] as String,
        'name': row['project_name'] as String,
        'path': row['project_path'] as String,
      });
    }

    return results.map((row) {
      final id = row['id'] as String;
      final projects = projectsMap[id] ?? const [];
      final projectsJson = json.encode({'projects': projects});

      return Skill(
        id: id,
        owner: row['owner'] as String,
        repo: row['repo'] as String,
        version: row['version'] as String,
        installCommand: row['install_command'] as String,
        updateAvailable: (row['update_available'] as int) != 0,
        inJsonProjects: projectsJson,
        metadata: _decodeMetadata(row['metadata'] as String?),
        description: row['description'] as String? ?? '',
      );
    }).toList();
  }

  /// Reads all skills that are associated with the specified [projectId].
  List<Skill> readSkillsByProject(String projectId) {
    final conn = _db._connection;
    final results = conn.select(
      '''
      SELECT sv.id, s.owner, s.repo, sv.version, sv.install_command, sv.update_available, sv.metadata, sv.description
      FROM project_skills ps
      JOIN skill_versions sv ON ps.skill_version_id = sv.id
      JOIN skills s ON sv.skill_id = s.id
      WHERE ps.project_id = ?
      ''',
      [projectId],
    );

    if (results.isEmpty) {
      return const [];
    }

    final projectResults = conn.select(
      'SELECT project_id, project_name, project_path, skill_version_id FROM project_skills',
    );

    final projectsMap = <String, List<Map<String, dynamic>>>{};
    for (final row in projectResults) {
      final key = row['skill_version_id'] as String;
      projectsMap.putIfAbsent(key, () => []).add({
        'id': row['project_id'] as String,
        'name': row['project_name'] as String,
        'path': row['project_path'] as String,
      });
    }

    return results.map((row) {
      final id = row['id'] as String;
      final projects = projectsMap[id] ?? const [];
      final projectsJson = json.encode({'projects': projects});

      return Skill(
        id: id,
        owner: row['owner'] as String,
        repo: row['repo'] as String,
        version: row['version'] as String,
        installCommand: row['install_command'] as String,
        updateAvailable: (row['update_available'] as int) != 0,
        inJsonProjects: projectsJson,
        metadata: _decodeMetadata(row['metadata'] as String?),
        description: row['description'] as String? ?? '',
      );
    }).toList();
  }

  /// Deletes a [Skill] by its [id].
  /// Returns `true` if a record was deleted, `false` otherwise.
  bool deleteSkill(String id) {
    final conn = _db._connection;

    conn.execute('BEGIN TRANSACTION');
    try {
      conn.execute('DELETE FROM skill_versions WHERE id = ?', [id]);
      final affected = conn.updatedRows;

      // Clean up parent skill metadata if no versions remain
      final parentId = _getSkillName(id);
      conn.execute(
        '''
        DELETE FROM skills 
        WHERE id = ? AND NOT EXISTS (
          SELECT 1 FROM skill_versions WHERE skill_id = ?
        )
        ''',
        [parentId, parentId],
      );

      conn.execute('COMMIT');
      return affected > 0;
    } catch (_) {
      conn.execute('ROLLBACK');
      rethrow;
    }
  }

  /// Placeholder install action for the Skills catalog UI.
  String installSkill(Skill skill) {
    return 'ok';
  }

  /// Placeholder update action for the Skills catalog UI.
  String updateSkill(Skill skill) {
    return 'ok';
  }
}

Map<String, dynamic> _decodeMetadata(String? rawJson) {
  if (rawJson == null || rawJson.isEmpty) {
    return const {};
  }
  final decoded = json.decode(rawJson);
  if (decoded is Map) {
    return Map<String, dynamic>.from(decoded);
  }
  return const {};
}

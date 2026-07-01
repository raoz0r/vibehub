part of 'package:vibehub/api/skills_api.dart';

class VibeHubDatabase {
  VibeHubDatabase({String? databasePath})
    : databasePath = databasePath ?? defaultDatabasePath;

  final String databasePath;
  Database? _database;

  static String get defaultDatabasePath {
    return p.join(VibeHubPaths.dataDir, 'database');
  }

  /// Internal connection getter to ensure direct raw SQL/CRUD operations cannot
  /// be executed outside of this library.
  Database get _connection {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final file = File(databasePath);
    file.parent.createSync(recursive: true);

    final database = sqlite3.open(databasePath);
    database.execute('PRAGMA foreign_keys = ON;');

    // Check if the database needs schema updates
    final skillsInfo = database.select("PRAGMA table_info(skills)");
    final hasVersionInSkills =
        skillsInfo.isNotEmpty &&
        skillsInfo.any((row) => row['name'] == 'version');

    final versionInfo = database.select("PRAGMA table_info(skill_versions)");
    final hasSkillNameInVersions =
        versionInfo.isNotEmpty &&
        versionInfo.any((row) => row['name'] == 'skill_name');

    if (hasVersionInSkills || hasSkillNameInVersions) {
      database.execute('DROP TABLE IF EXISTS project_skills;');
      database.execute('DROP TABLE IF EXISTS skill_versions;');
      database.execute('DROP TABLE IF EXISTS skills;');
    }

    database.execute('''
      CREATE TABLE IF NOT EXISTS skills (
        id TEXT PRIMARY KEY,
        name TEXT,
        owner TEXT,
        repo TEXT
      );
    ''');

    database.execute('''
      CREATE TABLE IF NOT EXISTS skill_versions (
        id TEXT PRIMARY KEY,
        skill_id TEXT,
        version TEXT,
        install_command TEXT,
        update_available BOOLEAN,
        metadata TEXT DEFAULT '{}',
        description TEXT DEFAULT '',
        FOREIGN KEY (skill_id) REFERENCES skills(id) ON DELETE CASCADE
      );
    ''');

    final skillVersionInfo = database.select(
      "PRAGMA table_info(skill_versions)",
    );
    final hasMetadataInVersions = skillVersionInfo.any(
      (row) => row['name'] == 'metadata',
    );
    if (!hasMetadataInVersions) {
      database.execute(
        "ALTER TABLE skill_versions ADD COLUMN metadata TEXT DEFAULT '{}';",
      );
    }
    final hasDescriptionInVersions = skillVersionInfo.any(
      (row) => row['name'] == 'description',
    );
    if (!hasDescriptionInVersions) {
      database.execute(
        "ALTER TABLE skill_versions ADD COLUMN description TEXT DEFAULT '';",
      );
    }

    database.execute('''
      CREATE TABLE IF NOT EXISTS project_skills (
        project_id TEXT,
        project_name TEXT,
        project_path TEXT,
        skill_version_id TEXT,
        PRIMARY KEY (project_id, skill_version_id),
        FOREIGN KEY (skill_version_id) REFERENCES skill_versions(id) ON DELETE CASCADE
      );
    ''');

    _database = database;
    return database;
  }

  void close() {
    _database?.close();
    _database = null;
  }
}

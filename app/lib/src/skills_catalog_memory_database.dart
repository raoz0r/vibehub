part of 'package:vibehub/api/skills_catalog_api.dart';

class _SkillsCatalogMemoryDatabase {
  Database? _database;

  Database get _connection {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final database = sqlite3.openInMemory();
    database.execute('''
      CREATE TABLE IF NOT EXISTS catalog_skills (
        id TEXT PRIMARY KEY,
        comparison_key TEXT,
        name TEXT,
        owner TEXT,
        repo TEXT,
        version TEXT,
        sha TEXT,
        repo_url TEXT,
        install_command TEXT,
        metadata TEXT DEFAULT '{}'
      );
    ''');
    database.execute(
      'CREATE INDEX IF NOT EXISTS idx_catalog_skills_owner_repo ON catalog_skills(owner, repo);',
    );

    _database = database;
    return database;
  }

  void close() {
    _database?.close();
    _database = null;
  }
}

import 'dart:io';
import 'package:path/path.dart' as p;

class VibeHubPaths {
  static const String _appName = 'vibehub';

  /// Path to user's home directory.
  static String get homeDir {
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE']
        : Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      throw StateError('Could not resolve user home directory.');
    }
    return home;
  }

  /// Data Directory (for database, catalog files, long-term state).
  ///
  /// Windows: %LOCALAPPDATA%\vibehub\Data
  /// macOS: ~/Library/Application Support/vibehub
  /// Linux: ~/.local/share/vibehub
  static String get dataDir {
    final env = Platform.environment;
    if (Platform.isWindows) {
      final localAppData = env['LOCALAPPDATA'] ?? p.join(homeDir, 'AppData', 'Local');
      return p.join(localAppData, _appName, 'Data');
    }
    if (Platform.isMacOS) {
      return p.join(homeDir, 'Library', 'Application Support', _appName);
    }
    // Linux / Default
    final xdgData = env['XDG_DATA_HOME'];
    if (xdgData != null && xdgData.isNotEmpty) {
      return p.join(xdgData, _appName);
    }
    return p.join(homeDir, '.local', 'share', _appName);
  }

  /// Config Directory (for configuration files, preferences).
  ///
  /// Windows: %APPDATA%\vibehub\Config
  /// macOS: ~/Library/Preferences/vibehub
  /// Linux: ~/.config/vibehub
  static String get configDir {
    final env = Platform.environment;
    if (Platform.isWindows) {
      final appData = env['APPDATA'] ?? p.join(homeDir, 'AppData', 'Roaming');
      return p.join(appData, _appName, 'Config');
    }
    if (Platform.isMacOS) {
      return p.join(homeDir, 'Library', 'Preferences', _appName);
    }
    // Linux / Default
    final xdgConfig = env['XDG_CONFIG_HOME'];
    if (xdgConfig != null && xdgConfig.isNotEmpty) {
      return p.join(xdgConfig, _appName);
    }
    return p.join(homeDir, '.config', _appName);
  }

  /// Cache Directory (for downloaded/sync catalogs and volatile files).
  ///
  /// Windows: %LOCALAPPDATA%\vibehub\Cache
  /// macOS: ~/Library/Caches/vibehub
  /// Linux: ~/.cache/vibehub
  static String get cacheDir {
    final env = Platform.environment;
    if (Platform.isWindows) {
      final localAppData = env['LOCALAPPDATA'] ?? p.join(homeDir, 'AppData', 'Local');
      return p.join(localAppData, _appName, 'Cache');
    }
    if (Platform.isMacOS) {
      return p.join(homeDir, 'Library', 'Caches', _appName);
    }
    // Linux / Default
    final xdgCache = env['XDG_CACHE_HOME'];
    if (xdgCache != null && xdgCache.isNotEmpty) {
      return p.join(xdgCache, _appName);
    }
    return p.join(homeDir, '.cache', _appName);
  }

  /// Log Directory (for execution and installation logs).
  ///
  /// Windows: %LOCALAPPDATA%\vibehub\Log
  /// macOS: ~/Library/Logs/vibehub
  /// Linux: ~/.local/state/vibehub
  static String get logDir {
    final env = Platform.environment;
    if (Platform.isWindows) {
      final localAppData = env['LOCALAPPDATA'] ?? p.join(homeDir, 'AppData', 'Local');
      return p.join(localAppData, _appName, 'Log');
    }
    if (Platform.isMacOS) {
      return p.join(homeDir, 'Library', 'Logs', _appName);
    }
    // Linux / Default
    final xdgState = env['XDG_STATE_HOME'];
    if (xdgState != null && xdgState.isNotEmpty) {
      return p.join(xdgState, _appName);
    }
    return p.join(homeDir, '.local', 'state', _appName);
  }

  /// Temp Directory (for temporary extractions).
  ///
  /// Windows: %TEMP%\vibehub
  /// macOS: System Temp + /vibehub
  /// Linux: /tmp/vibehub
  static String get tempDir {
    if (Platform.isWindows) {
      final temp = Platform.environment['TEMP'] ?? p.join(homeDir, 'AppData', 'Local', 'Temp');
      return p.join(temp, _appName);
    }
    // For macOS/Linux, use Directory.systemTemp
    return p.join(Directory.systemTemp.path, _appName);
  }
}

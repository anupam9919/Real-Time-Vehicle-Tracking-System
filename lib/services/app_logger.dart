import 'package:logging/logging.dart';

/// Centralized logging service for the Vehicle Tracking App.
///
/// Usage:
/// ```dart
/// final _log = AppLogger.getLogger('ClassName');
/// _log.info('Something happened');
/// _log.warning('Something suspicious');
/// _log.severe('Something went wrong', error, stackTrace);
/// _log.fine('Debug-level detail');
/// ```
class AppLogger {
  static bool _initialized = false;

  /// Initialize the root logger. Call once at app startup.
  static void init({Level level = Level.ALL}) {
    if (_initialized) return;
    _initialized = true;

    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      final time = record.time.toIso8601String().substring(11, 23);
      final level = record.level.name.padRight(7);
      final logger = record.loggerName;
      final message = record.message;

      // ignore: avoid_print
      print('[$time] $level $logger: $message');

      if (record.error != null) {
        // ignore: avoid_print
        print('  Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('  StackTrace: ${record.stackTrace}');
      }
    });
  }

  /// Get a named logger for a specific class or module.
  static Logger getLogger(String name) => Logger(name);
}

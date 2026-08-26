/// Unified save-directory selector, independent of the target platform.
///
/// If a value is not natively supported on the current platform, the
/// implementation falls back to [downloads] and emits a debug-mode warning.
enum SaveDirectory {
  /// The user's Downloads folder (supported on all platforms).
  downloads,

  /// The Pictures / Photos library.
  pictures,

  /// The Movies / Videos folder.
  movies,

  /// The DIM (camera roll) folder.
  dim,

  /// The Documents folder.
  documents,

  /// The Music folder.
  music,

  /// The Podcasts folder (falls back to Music on Android; sub-folder on iOS).
  podcasts,

  /// The Ringtones folder (falls back to Music on Android; sub-folder on iOS).
  ringtones,

  /// The Alarms folder (falls back to Music on Android; sub-folder on iOS).
  alarms,

  /// The Notifications folder (falls back to Music on Android; sub-folder on iOS).
  notifications,

  /// The Screenshots folder (falls back to Pictures on Android; sub-folder on iOS).
  screenshots,

  /// The Audiobooks folder (falls back to Music on Android; sub-folder on iOS).
  audiobooks,
}

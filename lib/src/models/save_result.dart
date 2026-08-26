/// Represents the result of a file save or download operation.
class SaveResult {
  /// Whether the operation completed successfully.
  final bool success;

  /// The absolute path of the saved file on disk.
  /// `null` on Web (file is downloaded via the browser).
  final String? filePath;

  /// Error message if [success] is `false`.
  final String? error;

  /// Creates a [SaveResult] with explicit values for each field.
  ///
  /// Prefer [SaveResult.ok] or [SaveResult.fail] for the common cases.
  const SaveResult({required this.success, this.filePath, this.error});

  /// Convenience constructor for a successful result.
  const SaveResult.ok(this.filePath) : success = true, error = null;

  /// Convenience constructor for a failed result.
  const SaveResult.fail(this.error) : success = false, filePath = null;

  @override
  String toString() =>
      'SaveResult(success: $success, filePath: $filePath, error: $error)';
}

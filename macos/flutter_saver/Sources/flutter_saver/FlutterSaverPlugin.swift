import Cocoa
import FlutterMacOS

/// macOS implementation of flutter_saver.
///
/// Uses real system directories via FileManager.SearchPathDirectory.
/// Directories not natively available on macOS fall back to Downloads.
public class FlutterSaverPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_saver",
            binaryMessenger: registrar.messenger
        )
        let instance = FlutterSaverPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "saveFile":
            guard
                let args = call.arguments as? [String: Any],
                let bytes = args["bytes"] as? FlutterStandardTypedData,
                let fileName = args["fileName"] as? String
            else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "bytes and fileName are required",
                    details: nil
                ))
                return
            }
            let directoryKey = (args["directory"] as? String) ?? "downloads"
            saveFile(
                data: bytes.data,
                fileName: fileName,
                directoryKey: directoryKey,
                result: result
            )

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: – Private

    private func saveFile(
        data: Data,
        fileName: String,
        directoryKey: String,
        result: @escaping FlutterResult
    ) {
        do {
            let dirURL = try resolveDirectory(for: directoryKey)
            try FileManager.default.createDirectory(
                at: dirURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let fileURL = resolveUniqueURL(in: dirURL, fileName: fileName)
            try data.write(to: fileURL, options: .atomic)
            result(fileURL.path)
        } catch {
            result(FlutterError(
                code: "WRITE_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }

    /// Maps [directoryKey] to a real macOS system directory.
    ///
    /// macOS system folder support:
    ///  - downloads  → ~/Downloads
    ///  - pictures   → ~/Pictures
    ///  - movies     → ~/Movies
    ///  - documents  → ~/Documents
    ///  - music      → ~/Music
    ///  - dcim       → ~/Pictures  (fallback — macOS has no DCIM)
    ///  - all others → ~/Downloads (fallback with debug note in Dart layer)
    private func resolveDirectory(for key: String) throws -> URL {
        let fm = FileManager.default
        let searchPath: FileManager.SearchPathDirectory
        switch key.lowercased() {
        case "downloads":
            searchPath = .downloadsDirectory
        case "pictures":
            searchPath = .picturesDirectory
        case "movies":
            searchPath = .moviesDirectory
        case "documents":
            searchPath = .documentDirectory
        case "music":
            searchPath = .musicDirectory
        case "dcim":
            // macOS has no DCIM; fall back to Pictures.
            searchPath = .picturesDirectory
        default:
            // All other enum values (podcasts, audiobooks, etc.) fall back to Downloads.
            searchPath = .downloadsDirectory
        }
        guard let url = fm.urls(for: searchPath, in: .userDomainMask).first else {
            throw NSError(
                domain: "FlutterSaver",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not resolve directory for key: \(key)"]
            )
        }
        return url
    }

    /// Returns a unique file URL, appending `_1`, `_2`, … if the file already exists.
    private func resolveUniqueURL(in directory: URL, fileName: String) -> URL {
        let ext  = (fileName as NSString).pathExtension
        let stem = (fileName as NSString).deletingPathExtension
        var candidate = directory.appendingPathComponent(fileName)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(stem)_\(counter)" : "\(stem)_\(counter).\(ext)"
            candidate = directory.appendingPathComponent(newName)
            counter += 1
        }
        return candidate
    }
}

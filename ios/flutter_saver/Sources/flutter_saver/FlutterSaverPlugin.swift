import Flutter
import UIKit

/// iOS implementation of flutter_saver.
///
/// Since iOS does not expose system-wide public directories (like Android or macOS),
/// all save locations are sub-folders inside the app's sandbox Documents directory.
/// Directory names match the keys sent from the Dart layer.
public class FlutterSaverPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_saver",
            binaryMessenger: registrar.messenger()
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

    /// Resolves a sandbox sub-folder path for [directoryKey] and saves [data] there.
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

    /// Returns a URL for the requested directory inside the app sandbox.
    ///
    /// iOS directory mapping (sub-folders of Documents):
    ///  downloads, pictures, movies, dcim, documents, music,
    ///  podcasts, ringtones, alarms, notifications, screenshots, audiobooks
    private func resolveDirectory(for key: String) throws -> URL {
        let docs = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folderName: String
        switch key.lowercased() {
        case "downloads":      folderName = "Downloads"
        case "pictures":       folderName = "Pictures"
        case "movies":         folderName = "Movies"
        case "dcim":           folderName = "DCIM"
        case "documents":      folderName = "Documents"
        case "music":          folderName = "Music"
        case "podcasts":       folderName = "Podcasts"
        case "ringtones":      folderName = "Ringtones"
        case "alarms":         folderName = "Alarms"
        case "notifications":  folderName = "Notifications"
        case "screenshots":    folderName = "Screenshots"
        case "audiobooks":     folderName = "Audiobooks"
        default:               folderName = "Downloads"
        }
        return docs.appendingPathComponent(folderName, isDirectory: true)
    }

    /// Returns a unique file URL, appending `_1`, `_2`, … if the file exists.
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

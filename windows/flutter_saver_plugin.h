#ifndef FLUTTER_PLUGIN_FLUTTER_SAVER_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_SAVER_PLUGIN_H_

// Prevent Windows.h min/max macros from conflicting with std::min / std::max
#define NOMINMAX

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>
#include <windows.h>

namespace flutter_saver {

class FlutterSaverPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  FlutterSaverPlugin();
  virtual ~FlutterSaverPlugin();

  // Disallow copy and assign.
  FlutterSaverPlugin(const FlutterSaverPlugin&) = delete;
  FlutterSaverPlugin& operator=(const FlutterSaverPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Thread marshalling — used by background threads to post work back to
  // the platform (UI) thread. See FLUTTER_PLUGIN_FIXES.md Fix 6.
  void PostToMainThread(std::function<void()> fn);

  // Accessible from the dispatch window procedure.
  std::mutex pending_mutex_;
  std::vector<std::function<void()>> pending_callbacks_;

 private:
  // Message-only window for platform-thread dispatch from background threads.
  HWND dispatch_hwnd_ = nullptr;

  // Resolves the Windows Downloads folder path.
  std::wstring GetDownloadsPath() const;

  // Returns a unique file path, appending _1, _2, … to avoid overwrites.
  std::wstring ResolveUniqueFilePath(const std::wstring& dir,
                                     const std::wstring& filename) const;
};

}  // namespace flutter_saver

#endif  // FLUTTER_PLUGIN_FLUTTER_SAVER_PLUGIN_H_

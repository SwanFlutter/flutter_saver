#define NOMINMAX
#include "flutter_saver_plugin.h"

#include <windows.h>
#include <ShlObj.h>          // SHGetKnownFolderPath, FOLDERID_Downloads
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

namespace fs = std::filesystem;

namespace flutter_saver {

// ── Dispatch window class name ───────────────────────────────────────────────
static const wchar_t* kDispatchWindowClass = L"FlutterSaverDispatchWindow";

// ── Window procedure for the message-only dispatch window ───────────────────
static LRESULT CALLBACK DispatchWndProc(HWND hwnd, UINT msg,
                                         WPARAM wp, LPARAM lp) {
  if (msg == WM_APP + 1) {
    auto* plugin = reinterpret_cast<FlutterSaverPlugin*>(
        GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    if (plugin) {
      std::vector<std::function<void()>> cbs;
      {
        std::lock_guard<std::mutex> lk(plugin->pending_mutex_);
        cbs.swap(plugin->pending_callbacks_);
      }
      for (auto& fn : cbs) fn();
    }
    return 0;
  }
  return DefWindowProcW(hwnd, msg, wp, lp);
}

// ── RegisterWithRegistrar ────────────────────────────────────────────────────
// static
void FlutterSaverPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_saver",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterSaverPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

// ── Constructor / Destructor ─────────────────────────────────────────────────
FlutterSaverPlugin::FlutterSaverPlugin() {
  // Register the message-only window class.
  WNDCLASSW wc = {};
  wc.lpfnWndProc   = DispatchWndProc;
  wc.hInstance     = GetModuleHandleW(nullptr);
  wc.lpszClassName = kDispatchWindowClass;
  RegisterClassW(&wc);  // Ignore duplicate-registration error on re-init.

  dispatch_hwnd_ = CreateWindowExW(
      0, kDispatchWindowClass, nullptr, 0,
      0, 0, 0, 0, HWND_MESSAGE, nullptr,
      GetModuleHandleW(nullptr), nullptr);

  if (dispatch_hwnd_) {
    SetWindowLongPtrW(dispatch_hwnd_, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(this));
  }
}

FlutterSaverPlugin::~FlutterSaverPlugin() {
  if (dispatch_hwnd_) {
    DestroyWindow(dispatch_hwnd_);
    dispatch_hwnd_ = nullptr;
  }
  {
    std::lock_guard<std::mutex> lk(pending_mutex_);
    pending_callbacks_.clear();
  }
}

// ── PostToMainThread ─────────────────────────────────────────────────────────
void FlutterSaverPlugin::PostToMainThread(std::function<void()> fn) {
  if (!dispatch_hwnd_) {
    fn();  // Fallback: call directly if no dispatch window.
    return;
  }
  {
    std::lock_guard<std::mutex> lk(pending_mutex_);
    pending_callbacks_.push_back(std::move(fn));
  }
  PostMessageW(dispatch_hwnd_, WM_APP + 1, 0, 0);
}

// ── HandleMethodCall ─────────────────────────────────────────────────────────
void FlutterSaverPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  const std::string& method = method_call.method_name();

  // ── saveFile ──────────────────────────────────────────────────────────────
  if (method == "saveFile") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("INVALID_ARGS", "Expected a map of arguments");
      return;
    }

    // Extract bytes
    auto bytes_it = args->find(flutter::EncodableValue("bytes"));
    if (bytes_it == args->end()) {
      result->Error("INVALID_ARGS", "Missing 'bytes'");
      return;
    }
    const auto* byte_vec =
        std::get_if<std::vector<uint8_t>>(&bytes_it->second);
    if (!byte_vec) {
      result->Error("INVALID_ARGS", "'bytes' must be a Uint8List");
      return;
    }

    // Extract fileName
    auto name_it = args->find(flutter::EncodableValue("fileName"));
    if (name_it == args->end()) {
      result->Error("INVALID_ARGS", "Missing 'fileName'");
      return;
    }
    const auto* file_name = std::get_if<std::string>(&name_it->second);
    if (!file_name) {
      result->Error("INVALID_ARGS", "'fileName' must be a string");
      return;
    }

    // 'directory' is informational on Windows — always Downloads.
    // (All other SaveDirectory values fall back to Downloads.)

    // Copy data and name so we can move them into the thread.
    auto bytes_copy = std::make_shared<std::vector<uint8_t>>(*byte_vec);
    auto name_copy  = std::make_shared<std::string>(*file_name);

    // Shared ownership of result so the thread can call it after this scope.
    auto shared_result =
        std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>>(
            std::move(result));

    std::thread([this, bytes_copy, name_copy, shared_result]() {
      try {
        std::wstring dir = GetDownloadsPath();
        if (dir.empty()) {
          PostToMainThread([shared_result]() {
            shared_result->Error("DIR_NOT_FOUND",
                                 "Could not resolve Downloads directory");
          });
          return;
        }

        // Convert UTF-8 fileName to wide string.
        int sz = MultiByteToWideChar(CP_UTF8, 0,
                                     name_copy->c_str(), -1, nullptr, 0);
        std::wstring wide_name(sz, 0);
        MultiByteToWideChar(CP_UTF8, 0,
                            name_copy->c_str(), -1, wide_name.data(), sz);
        // Remove trailing null character added by MultiByteToWideChar.
        if (!wide_name.empty() && wide_name.back() == L'\0')
          wide_name.pop_back();

        // Ensure directory exists.
        fs::create_directories(fs::path(dir));

        std::wstring file_path = ResolveUniqueFilePath(dir, wide_name);

        // Write bytes.
        std::ofstream ofs(file_path, std::ios::binary);
        if (!ofs.is_open()) {
          PostToMainThread([shared_result]() {
            shared_result->Error("WRITE_ERROR", "Could not open file for writing");
          });
          return;
        }
        ofs.write(reinterpret_cast<const char*>(bytes_copy->data()),
                  static_cast<std::streamsize>(bytes_copy->size()));
        ofs.close();

        // Convert the wide path back to UTF-8 for Dart.
        int utf8_sz = WideCharToMultiByte(CP_UTF8, 0,
                                          file_path.c_str(), -1,
                                          nullptr, 0, nullptr, nullptr);
        std::string utf8_path(utf8_sz, 0);
        WideCharToMultiByte(CP_UTF8, 0,
                            file_path.c_str(), -1,
                            utf8_path.data(), utf8_sz, nullptr, nullptr);
        if (!utf8_path.empty() && utf8_path.back() == '\0')
          utf8_path.pop_back();

        PostToMainThread([shared_result, utf8_path]() {
          shared_result->Success(flutter::EncodableValue(utf8_path));
        });

      } catch (const std::exception& e) {
        std::string msg = e.what();
        PostToMainThread([shared_result, msg]() {
          shared_result->Error("WRITE_ERROR", msg);
        });
      }
    }).detach();

    return;  // Result is sent asynchronously from the thread.
  }

  result->NotImplemented();
}

// ── GetDownloadsPath ─────────────────────────────────────────────────────────
std::wstring FlutterSaverPlugin::GetDownloadsPath() const {
  PWSTR path_ptr = nullptr;
  HRESULT hr = SHGetKnownFolderPath(FOLDERID_Downloads, 0, nullptr, &path_ptr);
  if (SUCCEEDED(hr) && path_ptr) {
    std::wstring path(path_ptr);
    CoTaskMemFree(path_ptr);
    return path;
  }
  // Fallback: %USERPROFILE%\Downloads
  wchar_t buf[MAX_PATH];
  if (GetEnvironmentVariableW(L"USERPROFILE", buf, MAX_PATH) > 0) {
    return std::wstring(buf) + L"\\Downloads";
  }
  return L"";
}

// ── ResolveUniqueFilePath ────────────────────────────────────────────────────
std::wstring FlutterSaverPlugin::ResolveUniqueFilePath(
    const std::wstring& dir, const std::wstring& filename) const {
  fs::path base_path = fs::path(dir) / fs::path(filename);
  if (!fs::exists(base_path)) return base_path.wstring();

  fs::path stem = base_path.stem();
  fs::path ext  = base_path.extension();
  int counter = 1;
  while (true) {
    std::wstring new_name =
        stem.wstring() + L"_" + std::to_wstring(counter) + ext.wstring();
    fs::path candidate = fs::path(dir) / new_name;
    if (!fs::exists(candidate)) return candidate.wstring();
    ++counter;
  }
}

}  // namespace flutter_saver

#include "include/flutter_saver/flutter_saver_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <glib.h>
#include <sys/utsname.h>

#include <cerrno>
#include <cstring>
#include <string>

#include "flutter_saver_plugin_private.h"

#define FLUTTER_SAVER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_saver_plugin_get_type(), \
                              FlutterSaverPlugin))

struct _FlutterSaverPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterSaverPlugin, flutter_saver_plugin, g_object_get_type())

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Returns the user's Downloads directory, falling back to $HOME/Downloads
 * if XDG is not available.
 */
static std::string get_downloads_dir() {
  const char* xdg = g_get_user_special_dir(G_USER_DIRECTORY_DOWNLOAD);
  if (xdg && xdg[0] != '\0') return std::string(xdg);

  const char* home = g_get_home_dir();
  if (home) return std::string(home) + "/Downloads";

  return "/tmp";
}

/**
 * Returns a unique file path inside @dir for @filename.
 * Appends _1, _2, … before the extension if the file already exists.
 */
static std::string resolve_unique_path(const std::string& dir,
                                       const std::string& filename) {
  std::string candidate = dir + "/" + filename;
  if (!g_file_test(candidate.c_str(), G_FILE_TEST_EXISTS)) return candidate;

  // Split stem and extension.
  std::string stem = filename;
  std::string ext;
  auto dot = filename.rfind('.');
  if (dot != std::string::npos) {
    stem = filename.substr(0, dot);
    ext  = filename.substr(dot);      // includes the dot
  }

  int counter = 1;
  while (true) {
    std::string new_name = stem + "_" + std::to_string(counter) + ext;
    candidate = dir + "/" + new_name;
    if (!g_file_test(candidate.c_str(), G_FILE_TEST_EXISTS)) return candidate;
    ++counter;
  }
}

// ── Method implementations ───────────────────────────────────────────────────

FlMethodResponse* flutter_saver_save_file(FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Expected a map of arguments", nullptr));
  }

  // -- bytes
  FlValue* bytes_val = fl_value_lookup_string(args, "bytes");
  if (!bytes_val || fl_value_get_type(bytes_val) != FL_VALUE_TYPE_UINT8_LIST) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Missing or invalid 'bytes'", nullptr));
  }
  const uint8_t* bytes  = fl_value_get_uint8_list(bytes_val);
  size_t         n_bytes = static_cast<size_t>(fl_value_get_length(bytes_val));

  // -- fileName
  FlValue* name_val = fl_value_lookup_string(args, "fileName");
  if (!name_val || fl_value_get_type(name_val) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Missing or invalid 'fileName'", nullptr));
  }
  std::string file_name(fl_value_get_string(name_val));

  // -- directory key (informational on Linux — we map common values)
  std::string dir_key = "downloads";
  FlValue* dir_val = fl_value_lookup_string(args, "directory");
  if (dir_val && fl_value_get_type(dir_val) == FL_VALUE_TYPE_STRING) {
    dir_key = fl_value_get_string(dir_val);
  }

  // Resolve target directory.
  std::string target_dir;
  if (dir_key == "pictures") {
    const char* xdg = g_get_user_special_dir(G_USER_DIRECTORY_PICTURES);
    target_dir = (xdg && xdg[0]) ? xdg : get_downloads_dir();
  } else if (dir_key == "videos" || dir_key == "movies") {
    const char* xdg = g_get_user_special_dir(G_USER_DIRECTORY_VIDEOS);
    target_dir = (xdg && xdg[0]) ? xdg : get_downloads_dir();
  } else if (dir_key == "documents") {
    const char* xdg = g_get_user_special_dir(G_USER_DIRECTORY_DOCUMENTS);
    target_dir = (xdg && xdg[0]) ? xdg : get_downloads_dir();
  } else if (dir_key == "music") {
    const char* xdg = g_get_user_special_dir(G_USER_DIRECTORY_MUSIC);
    target_dir = (xdg && xdg[0]) ? xdg : get_downloads_dir();
  } else {
    // downloads, dcim, podcasts, ringtones, alarms, notifications,
    // screenshots, audiobooks → XDG Downloads
    target_dir = get_downloads_dir();
  }

  // Create directory if needed.
  if (g_mkdir_with_parents(target_dir.c_str(), 0755) != 0) {
    g_autofree gchar* msg =
        g_strdup_printf("Could not create directory: %s", target_dir.c_str());
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("DIR_ERROR", msg, nullptr));
  }

  // Resolve a unique file path.
  std::string file_path = resolve_unique_path(target_dir, file_name);

  // Write bytes.
  GError* error = nullptr;
  gboolean ok = g_file_set_contents(
      file_path.c_str(),
      reinterpret_cast<const gchar*>(bytes),
      static_cast<gssize>(n_bytes),
      &error);

  if (!ok) {
    g_autofree gchar* msg =
        g_strdup_printf("Write failed: %s",
                        error ? error->message : "unknown error");
    if (error) g_error_free(error);
    return FL_METHOD_RESPONSE(
        fl_method_error_response_new("WRITE_ERROR", msg, nullptr));
  }

  g_autoptr(FlValue) result = fl_value_new_string(file_path.c_str());
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// ── Method call dispatcher ───────────────────────────────────────────────────

static void flutter_saver_plugin_handle_method_call(
    FlutterSaverPlugin* self, FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue*     args   = fl_method_call_get_args(method_call);

  if (strcmp(method, "saveFile") == 0) {
    response = flutter_saver_save_file(args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// ── GObject boilerplate ──────────────────────────────────────────────────────

static void flutter_saver_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_saver_plugin_parent_class)->dispose(object);
}

static void flutter_saver_plugin_class_init(FlutterSaverPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_saver_plugin_dispose;
}

static void flutter_saver_plugin_init(FlutterSaverPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel,
                            FlMethodCall*   method_call,
                            gpointer        user_data) {
  FlutterSaverPlugin* plugin = FLUTTER_SAVER_PLUGIN(user_data);
  flutter_saver_plugin_handle_method_call(plugin, method_call);
}

void flutter_saver_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  FlutterSaverPlugin* plugin = FLUTTER_SAVER_PLUGIN(
      g_object_new(flutter_saver_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel     = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "flutter_saver",
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);
  g_object_unref(plugin);
}

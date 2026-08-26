#ifndef FLUTTER_SAVER_PLUGIN_PRIVATE_H_
#define FLUTTER_SAVER_PLUGIN_PRIVATE_H_

#include <flutter_linux/flutter_linux.h>
#include "include/flutter_saver/flutter_saver_plugin.h"

// Exposed for unit testing — see https://github.com/flutter/flutter/issues/88724

/// Handles the saveFile method call.
/// Returns a new FlMethodResponse* (caller takes ownership).
FlMethodResponse* flutter_saver_save_file(FlValue* args);

#endif  // FLUTTER_SAVER_PLUGIN_PRIVATE_H_

#include "include/flutter_saver/flutter_saver_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_saver_plugin.h"

void FlutterSaverPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_saver::FlutterSaverPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

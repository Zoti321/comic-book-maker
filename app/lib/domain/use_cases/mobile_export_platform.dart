import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

bool Function()? mobileExportSaveFileOverride;

/// Android/iOS 导出时在系统保存对话框中选择目标文件，而非预设目录。
bool usesMobileExportSaveFile() {
  final override = mobileExportSaveFileOverride;
  if (override != null) {
    return override();
  }
  if (kIsWeb) {
    return false;
  }
  return Platform.isAndroid || Platform.isIOS;
}

@visibleForTesting
void resetMobileExportSaveFileOverride() {
  mobileExportSaveFileOverride = null;
}

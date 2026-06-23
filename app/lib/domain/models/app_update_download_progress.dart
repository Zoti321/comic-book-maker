class AppUpdateDownloadProgress {
  const AppUpdateDownloadProgress({
    required this.receivedBytes,
    this.totalBytes,
  });

  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return receivedBytes / total;
  }

  String? get label {
    final total = totalBytes;
    if (total == null || total <= 0) {
      return null;
    }
    return '已下载 ${_formatMegabytes(receivedBytes)} / ${_formatMegabytes(total)}';
  }

  static String _formatMegabytes(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1)} MB';
  }
}

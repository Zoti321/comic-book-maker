import 'dart:io';
import 'dart:math' as math;

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 全屏查看单页原图；支持点留白关闭、左右翻页与键盘导航。
Future<void> showPageImageViewer(
  BuildContext context, {
  required List<PageSummary> pages,
  required PageSummary initialPage,
}) {
  return showAppOverlayDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: _PageImageViewer(
        pages: pages,
        initialPage: initialPage,
      ),
    ),
  );
}

class _PageImageViewer extends StatefulWidget {
  const _PageImageViewer({
    required this.pages,
    required this.initialPage,
  });

  final List<PageSummary> pages;
  final PageSummary initialPage;

  @override
  State<_PageImageViewer> createState() => _PageImageViewerState();
}

class _PageImageViewerState extends State<_PageImageViewer> {
  late final List<PageSummary> _sortedPages;
  late int _currentIndex;
  Size? _imageSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  final _transformationController = TransformationController();

  PageSummary get _currentPage => _sortedPages[_currentIndex];

  bool get _canGoPrevious => _currentIndex > 0;

  bool get _canGoNext => _currentIndex < _sortedPages.length - 1;

  @override
  void initState() {
    super.initState();
    _sortedPages = List<PageSummary>.from(widget.pages)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    _currentIndex = _sortedPages.indexWhere(
      (page) => page.id == widget.initialPage.id,
    );
    if (_currentIndex < 0) _currentIndex = 0;
    _loadImageSize(_currentPage);
  }

  @override
  void dispose() {
    _removeImageListener();
    _transformationController.dispose();
    super.dispose();
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  void _loadImageSize(PageSummary page) {
    _removeImageListener();
    setState(() => _imageSize = null);

    final stream = FileImage(File(page.absolutePath)).resolve(
      ImageConfiguration.empty,
    );
    _imageListener = ImageStreamListener((info, _) {
      if (!mounted) return;
      setState(() {
        _imageSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
      });
    });
    _imageStream = stream;
    stream.addListener(_imageListener!);
  }

  void _close() => Navigator.of(context).pop();

  void _goPrevious() {
    if (!_canGoPrevious) return;
    _goToIndex(_currentIndex - 1);
  }

  void _goNext() {
    if (!_canGoNext) return;
    _goToIndex(_currentIndex + 1);
  }

  void _goToIndex(int index) {
    setState(() => _currentIndex = index);
    _transformationController.value = Matrix4.identity();
    _loadImageSize(_sortedPages[index]);
  }

  Rect _imageDisplayRect(Size containerSize, Size imageSize) {
    final scale = math.min(
      containerSize.width / imageSize.width,
      containerSize.height / imageSize.height,
    );
    final width = imageSize.width * scale;
    final height = imageSize.height * scale;
    return Rect.fromLTWH(
      (containerSize.width - width) / 2,
      (containerSize.height - height) / 2,
      width,
      height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _goPrevious,
        const SingleActivator(LogicalKeyboardKey.arrowRight): _goNext,
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerSize = constraints.biggest;
            final displayRect = _imageSize != null
                ? _imageDisplayRect(containerSize, _imageSize!)
                : null;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    behavior: HitTestBehavior.opaque,
                    child: const ColoredBox(color: Colors.black),
                  ),
                ),
                if (displayRect != null)
                  Positioned.fromRect(
                    rect: displayRect,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 5,
                      child: Image.file(
                        File(_currentPage.absolutePath),
                        fit: BoxFit.fill,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Colors.black26,
                          child: Center(
                            child: Icon(
                              LucideIcons.imageOff,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Image.file(
                      File(_currentPage.absolutePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        LucideIcons.imageOff,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                if (_canGoPrevious)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: Center(
                        child: _ViewerNavButton(
                          icon: LucideIcons.chevronLeft,
                          onPressed: _goPrevious,
                        ),
                      ),
                    ),
                  ),
                if (_canGoNext)
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: SafeArea(
                      child: Center(
                        child: _ViewerNavButton(
                          icon: LucideIcons.chevronRight,
                          onPressed: _goNext,
                        ),
                      ),
                    ),
                  ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '第 ${_currentPage.sortIndex + 1} 页',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 全屏查看器专用翻页按钮：44px 圆形半透明黑底 + 白色 chevron（常见 lightbox 样式）。
class _ViewerNavButton extends StatefulWidget {
  const _ViewerNavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  static const _size = 44.0;
  static const _iconSize = 24.0;

  @override
  State<_ViewerNavButton> createState() => _ViewerNavButtonState();
}

class _ViewerNavButtonState extends State<_ViewerNavButton> {
  var _hovered = false;
  var _pressed = false;

  Color get _backgroundColor {
    if (_pressed) return const Color(0xBF000000);
    if (_hovered) return const Color(0xA6000000);
    return const Color(0x8A000000);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: _ViewerNavButton._size,
          height: _ViewerNavButton._size,
          decoration: BoxDecoration(
            color: _backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.icon,
            size: _ViewerNavButton._iconSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

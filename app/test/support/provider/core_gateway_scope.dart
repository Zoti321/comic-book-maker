import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget / 集成测试：用 [InMemoryCoreGateway] 替代 [FrbCoreGateway]。
ProviderScope coreGatewayScope({
  required CoreGateway gateway,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      coreGatewayProvider.overrideWithValue(gateway),
    ],
    child: child,
  );
}

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [ProjectWorkspace] 单元测试：注入 [InMemoryCoreGateway]。
ProviderContainer projectWorkspaceContainer({required CoreGateway gateway}) {
  return ProviderContainer(
    overrides: [
      coreGatewayProvider.overrideWithValue(gateway),
    ],
  );
}

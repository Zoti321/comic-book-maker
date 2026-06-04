import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'core_gateway_provider.g.dart';

@Riverpod(keepAlive: true)
CoreGateway coreGateway(Ref ref) => const FrbCoreGateway();

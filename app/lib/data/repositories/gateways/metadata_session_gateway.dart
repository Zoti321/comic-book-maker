import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';

import 'metadata_editing_gateway.dart';
import 'metadata_persistence_gateway.dart';

/// Metadata 编辑会话接缝：表单变换 + 持久化 + 加载上下文。
abstract class MetadataSessionGateway
    implements MetadataEditingGateway, MetadataPersistenceGateway {
  MetadataEditingContext loadMetadataEditingContext({
    required String projectId,
  });
}

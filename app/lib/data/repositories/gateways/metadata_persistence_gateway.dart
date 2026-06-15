import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';

/// Metadata 持久化（读写数据库）。
abstract class MetadataPersistenceGateway {
  Metadata getProjectMetadata({required String projectId});

  Metadata updateProjectMetadata({
    required String projectId,
    required Metadata metadata,
  });
}

import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateProjectWizardSessionData {
  const CreateProjectWizardSessionData({
    required this.draft,
    required this.tabIndex,
    required this.titleController,
  });

  final CreateProjectDraft draft;
  final int tabIndex;
  final TextEditingController titleController;
}

class CreateProjectWizardSessionNotifier
    extends Notifier<CreateProjectWizardSessionData> {
  ValueNotifier<CreateProjectDraft>? _draftListenable;
  TextEditingController? _titleController;
  var _tabIndex = 0;

  ValueNotifier<CreateProjectDraft> get draftListenable => _draftListenable!;

  @override
  CreateProjectWizardSessionData build() {
    _draftListenable ??= ValueNotifier(CreateProjectDraft());
    _titleController ??= TextEditingController();

    ref.onDispose(() {
      _draftListenable?.dispose();
      _titleController?.dispose();
      _draftListenable = null;
      _titleController = null;
    });

    return _snapshot();
  }

  CreateProjectWizardSessionData _snapshot() => CreateProjectWizardSessionData(
        draft: _draftListenable!.value,
        tabIndex: _tabIndex,
        titleController: _titleController!,
      );

  void reset() {
    _draftListenable!.value = CreateProjectDraft();
    _titleController!.clear();
    _tabIndex = 0;
    state = _snapshot();
  }

  void setTabIndex(int index) {
    if (_tabIndex == index) return;
    _tabIndex = index;
    state = _snapshot();
  }

  void setDraft(CreateProjectDraft next) {
    _draftListenable!.value = next;
    state = _snapshot();
  }

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg', 'jpeg', 'png', 'webp', 'gif', 'avif', 'bmp',
      ],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final paths = result.files
        .map((f) => f.path)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();
    if (paths.isEmpty) return;

    final next = state.draft.copyWith();
    next.applyImportSource(CreateProjectImageImport(paths));
    setDraft(next);
  }

  Future<void> pickComicArchive() async {
    final picked = await ArchiveImportRunner().pickComicArchivePath();
    if (picked == null) return;

    final next = state.draft.copyWith();
    next.applyImportSource(
      CreateProjectArchiveImport(
        format: picked.format,
        sourcePath: picked.path,
      ),
    );
    setDraft(next);
  }

  Future<void> pickEpub() => pickArchive(ArchiveFormatFrb.epub);

  Future<void> pickArchive(ArchiveFormatFrb format) async {
    final path = await ArchiveImportRunner().pickSourcePath(format);
    if (path == null) return;

    final next = state.draft.copyWith();
    next.applyImportSource(
      CreateProjectArchiveImport(format: format, sourcePath: path),
    );
    setDraft(next);
  }
}

final createProjectWizardSessionProvider = NotifierProvider<
    CreateProjectWizardSessionNotifier,
    CreateProjectWizardSessionData>(
  CreateProjectWizardSessionNotifier.new,
);

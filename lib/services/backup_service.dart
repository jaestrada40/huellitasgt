import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../domain/backup_data.dart';
import '../domain/repositories.dart';
import 'backup_codec.dart';

export 'backup_codec.dart' show kBackupSchemaVersion;

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BackupSummary {
  const BackupSummary({required this.pets, required this.events, required this.attachments});
  final int pets;
  final int events;
  final int attachments;
}

class PreparedBackup {
  const PreparedBackup({required this.data, required this.tempDir, required this.summary});
  final BackupData data;
  final Directory tempDir;
  final BackupSummary summary;
}

class BackupService {
  BackupService({
    required BackupStore store,
    required Directory root,
    required DateTime Function() now,
    int appSchemaVersion = kBackupSchemaVersion,
  })  : _store = store,
        _root = root,
        _now = now,
        _appSchemaVersion = appSchemaVersion;

  final BackupStore _store;
  final Directory _root;
  final DateTime Function() _now;
  final int _appSchemaVersion;

  Directory get _tmp => Directory(p.join(_root.path, '.import_tmp'));

  static bool _isSafe(String path) {
    final n = p.posix.normalize(path);
    return !p.posix.isAbsolute(n) &&
        n.startsWith('attachments/') &&
        !n.split('/').contains('..');
  }

  Set<String> _referencedPaths(BackupData d) => {
        for (final a in d.attachments) a.relativePath,
        for (final pet in d.pets)
          if (pet.photoPath != null) pet.photoPath!,
      };

  Future<File> export(Directory outDir) async {
    final data = await _store.readAll();
    final now = _now();
    final archive = Archive();

    final jsonBytes = utf8.encode(jsonEncode(
      backupToJson(data, schemaVersion: _appSchemaVersion, exportedAt: now),
    ));
    archive.addFile(ArchiveFile('backup.json', jsonBytes.length, jsonBytes));

    for (final rel in _referencedPaths(data)) {
      final f = File(p.join(_root.path, rel));
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        archive.addFile(ArchiveFile(rel, bytes.length, bytes));
      }
    }

    String two(int n) => n.toString().padLeft(2, '0');
    final name = 'huellitas-${now.year}-${two(now.month)}-${two(now.day)}.zip';
    await outDir.create(recursive: true);
    final file = File(p.join(outDir.path, name));
    await file.writeAsBytes(ZipEncoder().encode(archive));
    return file;
  }

  Future<PreparedBackup> prepare(File zip) async {
    const invalid = BackupException('El archivo no es un respaldo válido de Huellitas.');
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    } catch (_) {
      throw invalid;
    }

    final jsonFile = archive.findFile('backup.json');
    if (jsonFile == null) throw invalid;

    final BackupData data;
    try {
      final map = jsonDecode(utf8.decode(jsonFile.content as List<int>)) as Map<String, dynamic>;
      final version = map['schemaVersion'];
      if (version is! int) throw invalid;
      if (version > _appSchemaVersion) {
        throw const BackupException(
          'Este respaldo es de una versión más nueva de Huellitas. Actualiza la app e inténtalo de nuevo.',
        );
      }
      data = backupFromJson(map);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw invalid;
    }

    final paths = _referencedPaths(data);
    for (final rel in paths) {
      if (!_isSafe(rel)) throw invalid;
      final f = archive.findFile(rel);
      if (f == null || !f.isFile) {
        throw BackupException('Al respaldo le falta un archivo ($rel).');
      }
    }

    final tmp = _tmp;
    if (await tmp.exists()) await tmp.delete(recursive: true);
    await tmp.create(recursive: true);
    try {
      for (final rel in paths) {
        final out = File(p.join(tmp.path, rel));
        await out.parent.create(recursive: true);
        await out.writeAsBytes(archive.findFile(rel)!.content as List<int>);
      }
    } catch (_) {
      await tmp.delete(recursive: true);
      throw const BackupException('No se pudo leer el respaldo.');
    }

    return PreparedBackup(
      data: data,
      tempDir: tmp,
      summary: BackupSummary(
        pets: data.pets.length,
        events: data.events.length,
        attachments: data.attachments.length,
      ),
    );
  }

  Future<void> commit(PreparedBackup prepared) async {
    final live = Directory(p.join(_root.path, 'attachments'));
    final old = Directory(p.join(_root.path, 'attachments.old'));
    final incoming = Directory(p.join(prepared.tempDir.path, 'attachments'));

    if (await old.exists()) await old.delete(recursive: true);
    final hadLive = await live.exists();
    if (hadLive) await live.rename(old.path);

    try {
      if (await incoming.exists()) {
        await incoming.rename(live.path);
      } else {
        await live.create(recursive: true);
      }
      await _store.replaceAll(prepared.data);
    } catch (_) {
      if (await live.exists()) await live.delete(recursive: true);
      if (hadLive) await old.rename(live.path);
      await discard(prepared);
      throw const BackupException('No se pudo restaurar el respaldo. Tus datos no cambiaron.');
    }

    if (await old.exists()) await old.delete(recursive: true);
    await discard(prepared);
  }

  Future<void> discard(PreparedBackup prepared) async {
    if (await prepared.tempDir.exists()) await prepared.tempDir.delete(recursive: true);
  }
}

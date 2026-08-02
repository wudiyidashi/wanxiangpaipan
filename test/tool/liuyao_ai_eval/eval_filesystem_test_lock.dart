import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../tool/liuyao_ai_eval/canonical_json.dart';

class EvalFilesystemTestLock {
  RandomAccessFile? _handle;

  Future<void> acquire(String repositoryRoot) async {
    if (_handle != null) {
      throw StateError('Evaluator test filesystem lock is already held.');
    }
    final String identity = sha256Text(p.normalize(repositoryRoot));
    final File file = File(
      p.join(
        Directory.systemTemp.path,
        'liuyao-ai-eval-${identity.substring(0, 16)}.lock',
      ),
    );
    final RandomAccessFile handle = await file.open(mode: FileMode.append);
    try {
      final DateTime deadline = DateTime.now().add(const Duration(seconds: 30));
      while (true) {
        try {
          await handle.lock(FileLock.exclusive);
          break;
        } on FileSystemException catch (error) {
          if (!Platform.isWindows ||
              error.osError?.errorCode != 33 ||
              DateTime.now().isAfter(deadline)) {
            rethrow;
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      _handle = handle;
    } on Object {
      await handle.close();
      rethrow;
    }
  }

  Future<void> release() async {
    final RandomAccessFile? handle = _handle;
    if (handle == null) {
      return;
    }
    _handle = null;
    await handle.unlock();
    await handle.close();
  }
}

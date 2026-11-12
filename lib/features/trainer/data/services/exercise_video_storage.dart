import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Upload do vídeo de demonstração gravado pelo personal.
/// Limites combinados: até 30 segundos e 20 MB por vídeo.
class ExerciseVideoStorage {
  ExerciseVideoStorage({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const maxSeconds = 30;
  static const maxBytes = 20 * 1024 * 1024;

  /// Confere duração e tamanho; devolve a mensagem de erro ou `null`.
  Future<String?> validate(XFile file) async {
    final size = await file.length();
    if (size > maxBytes) {
      return 'O vídeo tem ${(size / 1024 / 1024).toStringAsFixed(1)} MB. '
          'O limite é 20 MB — grave mais curto ou use um link do YouTube.';
    }
    final controller = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(file.path))
        : VideoPlayerController.networkUrl(Uri.file(file.path));
    try {
      await controller.initialize();
      final seconds = controller.value.duration.inMilliseconds / 1000;
      if (seconds > maxSeconds + 0.5) {
        return 'O vídeo tem ${seconds.round()} s. O limite é $maxSeconds s.';
      }
    } on Exception {
      // Se não der para ler a duração, segue só com o limite de tamanho.
    } finally {
      await controller.dispose();
    }
    return null;
  }

  /// Envia o vídeo e devolve a URL pública de download.
  Future<String> upload({
    required String trainerId,
    required String exerciseId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('trainers/$trainerId/exercise-videos/$exerciseId.mp4');
    final task = ref.putData(
      await file.readAsBytes(),
      SettableMetadata(contentType: file.mimeType ?? 'video/mp4'),
    );
    task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    await task;
    return ref.getDownloadURL();
  }
}

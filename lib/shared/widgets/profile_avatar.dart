import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'avatar_crop_dialog.dart';

/// Mesma "chave" de imagem em todo o app, para o cache servir a foto
/// já baixada (menu, configurações, perfil) sem buscar de novo.
ImageProvider avatarImage(String url) => NetworkImage(url,
    // Cai para <img> quando o CORS do Storage bloqueia o download.
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback);

/// Baixa a foto em segundo plano logo ao entrar, para o menu abrir com ela.
void precacheAvatar(BuildContext context, String? url) {
  if (url == null || url.isEmpty) return;
  precacheImage(avatarImage(url), context, onError: (_, __) {});
}

/// Foto de perfil do usuário logado (personal ou aluno).
/// Com [editable], tocar abre "Escolher foto" / "Remover foto".
/// [onChanged] recebe a nova URL (ou null) depois de salvar no perfil —
/// o aluno usa para copiar a foto para o vínculo, que o personal enxerga.
class ProfileAvatar extends ConsumerStatefulWidget {
  const ProfileAvatar({
    super.key,
    this.radius = 36,
    this.editable = true,
    this.onChanged,
    this.borderColor,
  });

  final double radius;
  final bool editable;
  final Future<void> Function(String? url)? onChanged;
  final Color? borderColor;

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  bool _busy = false;

  static const _maxBytes = 5 * 1024 * 1024;

  void _snack(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: error ? AppColors.error : AppColors.success,
        content: Text(text),
      ));

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Grande o bastante para dar zoom no rosto; o recorte final é 512 px.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 92,
    );
    if (file == null || !mounted) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final picked = await file.readAsBytes();
    if (!mounted) return;
    final bytes = await showAvatarCropDialog(context, picked);
    if (bytes == null || !mounted) return;
    if (bytes.length > _maxBytes) {
      _snack('Foto maior que 5 MB. Escolha outra.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      // Nome novo a cada troca: evita o navegador mostrar a foto antiga.
      final ref0 = FirebaseStorage.instance.ref(
          'users/${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref0.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            // O nome muda a cada troca, então o navegador pode guardar
            // a foto por muito tempo sem risco de mostrar a antiga.
            cacheControl: 'public, max-age=31536000, immutable',
          ));
      final url = await ref0.getDownloadURL();
      await ref.read(authProvider.notifier).updatePhoto(url);
      await widget.onChanged?.call(url);
      _snack('Foto atualizada.');
    } catch (e) {
      _snack('Não foi possível enviar a foto: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).updatePhoto(null);
      await widget.onChanged?.call(null);
      _snack('Foto removida.');
    } catch (e) {
      _snack('Não foi possível remover: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMenu(bool hasPhoto) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.textPrimary),
              title: Text(hasPhoto ? 'Trocar foto' : 'Escolher foto',
                  style: AppTextStyles.bodyLarge),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            if (hasPhoto)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remover foto',
                    style: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'pick') await _pick();
    if (action == 'remove') await _remove();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final photo = user?.photoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    final initial = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()[0].toUpperCase()
        : '?';
    final r = widget.radius;

    final avatar = Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal.withValues(alpha: 0.25),
        border: widget.borderColor == null
            ? null
            : Border.all(color: widget.borderColor!, width: 3),
      ),
      alignment: Alignment.center,
      child: _busy
          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
          : hasPhoto
              // Image (e não DecorationImage): só o widget Image aceita cair
              // para <img> quando o CORS do Storage bloqueia o download.
              ? ClipOval(
                  child: Image(
                    image: avatarImage(photo),
                    width: r * 2,
                    height: r * 2,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => Text(initial,
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white, fontSize: r * 0.9)),
                  ),
                )
              : Text(initial,
                  style: AppTextStyles.displaySmall
                      .copyWith(color: Colors.white, fontSize: r * 0.9)),
    );

    if (!widget.editable) return avatar;
    return Tooltip(
      message: hasPhoto ? 'Trocar foto' : 'Adicionar foto',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _busy ? null : () => _openMenu(hasPhoto),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_camera,
                    size: r * 0.38, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

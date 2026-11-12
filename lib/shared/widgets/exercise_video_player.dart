import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Abre o vídeo de demonstração de um exercício dentro do app.
/// Aceita link do YouTube (tocado embutido) ou vídeo enviado ao Storage.
Future<void> showExerciseVideo(
  BuildContext context, {
  required String title,
  required String videoUrl,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: AppTextStyles.headlineSmall),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExerciseVideoPlayer(videoUrl: videoUrl),
          ],
        ),
      ),
    ),
  );
}

/// `true` se o link é de um vídeo do YouTube.
bool isYoutubeUrl(String url) =>
    YoutubePlayerController.convertUrlToId(url) != null;

class ExerciseVideoPlayer extends StatelessWidget {
  const ExerciseVideoPlayer({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    final youtubeId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (youtubeId != null) return _YoutubeVideo(videoId: youtubeId);
    if (videoUrl.startsWith('http')) return _NetworkVideo(url: videoUrl);
    return _UnsupportedLink(url: videoUrl);
  }
}

class _YoutubeVideo extends StatefulWidget {
  const _YoutubeVideo({required this.videoId});
  final String videoId;

  @override
  State<_YoutubeVideo> createState() => _YoutubeVideoState();
}

class _YoutubeVideoState extends State<_YoutubeVideo> {
  late final YoutubePlayerController _controller =
      YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showFullscreenButton: true,
      strictRelatedVideos: true,
    ),
  );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      YoutubePlayer(controller: _controller, aspectRatio: 16 / 9);
}

/// Vídeo enviado pelo personal (Firebase Storage), em loop.
class _NetworkVideo extends StatefulWidget {
  const _NetworkVideo({required this.url});
  final String url;

  @override
  State<_NetworkVideo> createState() => _NetworkVideoState();
}

class _NetworkVideoState extends State<_NetworkVideo> {
  late final VideoPlayerController _video =
      VideoPlayerController.networkUrl(Uri.parse(widget.url));
  ChewieController? _chewie;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _video.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewie = ChewieController(
          videoPlayerController: _video,
          autoPlay: true,
          looping: true,
          aspectRatio: _video.value.aspectRatio,
        );
      });
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _UnsupportedLink(url: widget.url);
    final chewie = _chewie;
    if (chewie == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: AspectRatio(
        aspectRatio: _video.value.aspectRatio,
        child: Chewie(controller: chewie),
      ),
    );
  }
}

/// Link que não dá para tocar aqui (ex.: Google Drive): abre fora do app.
class _UnsupportedLink extends StatelessWidget {
  const _UnsupportedLink({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Não foi possível tocar este vídeo dentro do app.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir o link'),
            onPressed: () => launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
    );
  }
}

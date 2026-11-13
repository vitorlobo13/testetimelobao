import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Tela para posicionar a foto no círculo antes de enviar.
/// Arrastar move, pinçar (ou a barra) aproxima. Devolve um JPEG quadrado
/// de [outputSize] px já recortado, ou null se a pessoa cancelar.
Future<Uint8List?> showAvatarCropDialog(
  BuildContext context,
  Uint8List bytes, {
  int outputSize = 512,
}) {
  return Navigator.of(context).push<Uint8List>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _AvatarCropPage(bytes: bytes, outputSize: outputSize),
  ));
}

/// Recorta e reduz a foto. Separado da tela para poder ser testado.
/// [viewport] é o lado do quadrado visível; [matrix] é a transformação do
/// InteractiveViewer (escala + deslocamento) sobre a foto em "cover".
Uint8List cropAvatar({
  required img.Image source,
  required double viewport,
  required Matrix4 matrix,
  int outputSize = 512,
}) {
  final w = source.width.toDouble();
  final h = source.height.toDouble();
  final cover = viewport / (w < h ? w : h);
  final ox = (viewport - w * cover) / 2;
  final oy = (viewport - h * cover) / 2;

  final s = matrix.getMaxScaleOnAxis();
  final t = matrix.getTranslation();
  // Área visível em coordenadas do quadro (antes do zoom)...
  final vx = -t.x / s;
  final vy = -t.y / s;
  final vSize = viewport / s;
  // ...e em pixels da foto.
  var x = ((vx - ox) / cover).round();
  var y = ((vy - oy) / cover).round();
  var side = (vSize / cover).round();
  side = side.clamp(
      1, source.width < source.height ? source.width : source.height);
  x = x.clamp(0, source.width - side);
  y = y.clamp(0, source.height - side);

  final cropped = img.copyCrop(source, x: x, y: y, width: side, height: side);
  final resized = side > outputSize
      ? img.copyResize(cropped,
          width: outputSize,
          height: outputSize,
          interpolation: img.Interpolation.average)
      : cropped;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

class _AvatarCropPage extends StatefulWidget {
  const _AvatarCropPage({required this.bytes, required this.outputSize});

  final Uint8List bytes;
  final int outputSize;

  @override
  State<_AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<_AvatarCropPage> {
  static const _maxScale = 4.0;
  final _controller = TransformationController();
  double _viewport = 0;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _scale => _controller.value.getMaxScaleOnAxis();

  /// Zoom pela barra, mantendo o centro do círculo no lugar.
  void _setScale(double next) {
    final m = _controller.value;
    final s = _scale;
    final t = m.getTranslation();
    final c = _viewport / 2;
    // Ponto do quadro que está no centro do círculo agora.
    final px = (c - t.x) / s;
    final py = (c - t.y) / s;
    var tx = c - px * next;
    var ty = c - py * next;
    final min = _viewport - _viewport * next;
    tx = tx.clamp(min, 0.0);
    ty = ty.clamp(min, 0.0);
    _controller.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0, 1)
      ..scaleByDouble(next, next, 1, 1);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    // Deixa o indicador aparecer antes do trabalho pesado.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final decoded = img.decodeImage(widget.bytes);
      if (decoded == null) throw const FormatException('Imagem inválida');
      final source = img.bakeOrientation(decoded);
      final out = cropAvatar(
        source: source,
        viewport: _viewport,
        matrix: _controller.value,
        outputSize: widget.outputSize,
      );
      if (mounted) Navigator.of(context).pop(out);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text('Não foi possível usar esta foto: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajustar foto'),
        leading: IconButton(
          tooltip: 'Cancelar',
          icon: const Icon(Icons.close),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text('Arraste para posicionar e aproxime com dois dedos.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: LayoutBuilder(builder: (context, c) {
                    final side =
                        (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight)
                            .clamp(120.0, 420.0);
                    _viewport = side;
                    return SizedBox.square(
                      dimension: side,
                      child: Stack(
                        children: [
                          ClipRect(
                            child: InteractiveViewer(
                              transformationController: _controller,
                              minScale: 1,
                              maxScale: _maxScale,
                              boundaryMargin: EdgeInsets.zero,
                              onInteractionUpdate: (_) => setState(() {}),
                              child: SizedBox.square(
                                dimension: side,
                                child: Image.memory(widget.bytes,
                                    fit: BoxFit.cover, gaplessPlayback: true),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size.square(side),
                              painter: _CircleMaskPainter(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.zoom_out, color: AppColors.textSecondary),
                  Expanded(
                    child: Slider(
                      value: _scale.clamp(1.0, _maxScale),
                      min: 1,
                      max: _maxScale,
                      onChanged:
                          _saving ? null : (v) => setState(() => _setScale(v)),
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _confirm,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Usar foto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Escurece tudo fora do círculo e desenha a borda dele.
class _CircleMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect.deflate(1));
    final outside =
        Path.combine(PathOperation.difference, Path()..addRect(rect), circle);
    canvas.drawPath(
        outside, Paint()..color = AppColors.background.withValues(alpha: 0.7));
    canvas.drawPath(
        circle,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

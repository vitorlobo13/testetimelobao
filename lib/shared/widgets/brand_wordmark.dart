import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Marca tipográfica "TIME LOBO LOPES" no estilo do logotipo do Instagram
/// (condensada, itálica; LOBO no azul-gelo do Time Lobão, LOPES no rosa do
/// Time Thaísa Lopes). Provisória até chegar o arquivo original do logo.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 44, this.center = true});

  /// Altura da linha "LOBO LOPES".
  final double size;
  final bool center;

  @override
  Widget build(BuildContext context) {
    TextStyle style(Color c, double s, {double spacing = 0.5}) =>
        GoogleFonts.barlowCondensed(
          fontSize: s,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
          color: c,
          letterSpacing: spacing,
          height: 1,
        );

    return Semantics(
      label: 'Time Lobo Lopes',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text('TIME',
              style: style(AppColors.textSecondary, size * 0.34,
                  spacing: size * 0.12)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'LOBO ', style: style(AppColors.textPrimary, size)),
              TextSpan(text: 'LOPES', style: style(AppColors.pink, size)),
            ]),
          ),
          SizedBox(height: size * 0.12),
          // Traço azul → rosa: a fusão dos dois times.
          Container(
            width: size * 3.6,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                  colors: [AppColors.blue, AppColors.pink]),
            ),
          ),
        ],
      ),
    );
  }
}

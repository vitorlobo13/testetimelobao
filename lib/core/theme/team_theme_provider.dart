import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'browser_theme_color.dart';

const _prefsKey = 'team_theme';

/// Lê o visual salvo neste aparelho. Chamado no main(), antes do runApp,
/// para o app já abrir com as cores certas.
Future<void> loadSavedTeamTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    AppColors.use(
        saved == TeamTheme.lopes.name ? TeamTheme.lopes : TeamTheme.lobo);
  } catch (_) {
    AppColors.use(TeamTheme.lobo);
  }
  setBrowserThemeColor(AppColors.background);
}

class TeamThemeNotifier extends Notifier<TeamTheme> {
  @override
  TeamTheme build() => AppColors.team;

  Future<void> set(TeamTheme team) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, team.name);
    } catch (_) {}
    // No iPhone a faixa do topo (hora, bateria) só pega a cor nova quando o
    // app carrega: recarrega já com o visual salvo (continua logado).
    if (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      reloadPage();
      return;
    }
    AppColors.use(team);
    setBrowserThemeColor(AppColors.background);
    state = team;
  }

  Future<void> toggle() => set(state.other);
}

final teamThemeProvider =
    NotifierProvider<TeamThemeNotifier, TeamTheme>(TeamThemeNotifier.new);

/// Botão da barra do topo que alterna entre Time Lobo (azul) e Time Lopes
/// (rosa). Mostra uma bolinha com a cor do outro time.
class TeamThemeButton extends ConsumerWidget {
  const TeamThemeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamThemeProvider);
    final next = team.other;
    final nextColor =
        next == TeamTheme.lopes ? AppColors.lopesPink : AppColors.loboBlue;
    return IconButton(
      tooltip: 'Mudar para o visual ${next.label}',
      // O app inteiro é redesenhado com as novas cores.
      onPressed: () => ref.read(teamThemeProvider.notifier).toggle(),
      icon: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: nextColor,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/physical_measurement_entity.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/physical_measurement_provider.dart';
import '../widgets/new_assessment_sheet.dart';
import '../providers/trainer_provider.dart';

/// Tela de Evolução Física do Aluno (visão do professor)
///
/// O professor NÃO edita medidas aqui.
/// Esta tela exibe o histórico de medidas que o próprio aluno registrou,
/// mostrando gráficos e comparativos de evolução.
class PhysicalAssessmentPage extends ConsumerStatefulWidget {
  final StudentEntity? initialStudent;

  const PhysicalAssessmentPage({super.key, this.initialStudent});

  @override
  ConsumerState<PhysicalAssessmentPage> createState() =>
      _PhysicalAssessmentPageState();
}

class _PhysicalAssessmentPageState
    extends ConsumerState<PhysicalAssessmentPage>
    with SingleTickerProviderStateMixin {
  StudentEntity? _selectedStudent;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(trainerDashboardProvider);
    final students = dashboardState.students;
    final history = _selectedStudent != null
        ? (ref.watch(assessmentsProvider(_selectedStudent!.id)).value ??
            const <PhysicalMeasurementEntity>[])
        : const <PhysicalMeasurementEntity>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('EVOLUÇÃO FÍSICA', style: AppTextStyles.displaySmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Seletor de aluno
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: _buildStudentSelector(students),
          ),

          if (_selectedStudent != null) ...[
            // Summary cards
            if (history.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildSummaryCards(history),
              ),
            ],

            // Tabs
            Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.teal,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.teal,
                labelStyle: AppTextStyles.buttonMedium,
                tabs: const [
                  Tab(text: 'Peso & IMC'),
                  Tab(text: 'Perímetros'),
                  Tab(text: 'Histórico'),
                ],
              ),
            ),

            Expanded(
              child: history.isEmpty
                  ? _buildEmptyState()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildWeightTab(history),
                        _buildPerimetersTab(history),
                        _buildHistoryTab(history),
                      ],
                    ),
            ),
          ] else
            Expanded(child: _buildSelectStudentPrompt()),
        ],
      ),
      floatingActionButton: _selectedStudent == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.teal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nova avaliação',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => showNewAssessmentSheet(
                context,
                linkId: _selectedStudent!.id,
                studentName: _selectedStudent!.name,
              ),
            ),
    );
  }

  // ─── Seletor de aluno ─────────────────────────────────────────────────────

  Widget _buildStudentSelector(List<StudentEntity> students) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StudentEntity>(
          hint: Text('Escolha um aluno...', style: AppTextStyles.bodyMedium),
          value: _selectedStudent != null &&
                  students.any((s) => s.id == _selectedStudent!.id)
              ? students.firstWhere((s) => s.id == _selectedStudent!.id)
              : null,
          dropdownColor: AppColors.surface,
          isExpanded: true,
          style: AppTextStyles.bodyLarge,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          items: students.map((student) {
            return DropdownMenuItem(
              value: student,
              child: Text(student.name),
            );
          }).toList(),
          onChanged: (student) {
            if (student != null) {
              setState(() => _selectedStudent = student);
            }
          },
        ),
      ),
    );
  }

  // ─── Cards de resumo ──────────────────────────────────────────────────────

  Widget _buildSummaryCards(List<PhysicalMeasurementEntity> history) {
    final latest = history.first;
    final oldest = history.last;

    final weightDiff = latest.weight != null && oldest.weight != null
        ? latest.weight! - oldest.weight!
        : null;
    final fatDiff = latest.fatPercentage != null && oldest.fatPercentage != null
        ? latest.fatPercentage! - oldest.fatPercentage!
        : null;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.monitor_weight,
            label: 'Peso atual',
            value: latest.weight != null
                ? '${latest.weight!.toStringAsFixed(1)} kg'
                : '—',
            delta: weightDiff,
            deltaUnit: 'kg',
            lowerIsBetter: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.assessment,
            label: 'IMC atual',
            value: latest.bmi?.toStringAsFixed(1) ?? '—',
            delta: (latest.bmi != null && oldest.bmi != null)
                ? latest.bmi! - oldest.bmi!
                : null,
            deltaUnit: '',
            lowerIsBetter: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.percent,
            label: 'Gordura',
            value: latest.fatPercentage != null
                ? '${latest.fatPercentage!.toStringAsFixed(1)}%'
                : '—',
            delta: fatDiff,
            deltaUnit: '%',
            lowerIsBetter: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required double? delta,
    required String deltaUnit,
    required bool lowerIsBetter,
  }) {
    Color? deltaColor;
    String? deltaText;
    IconData? deltaIcon;

    if (delta != null) {
      final isImprovement = lowerIsBetter ? delta < 0 : delta > 0;
      deltaColor = isImprovement ? AppColors.success : AppColors.error;
      deltaIcon = isImprovement ? Icons.trending_down : Icons.trending_up;
      final sign = delta > 0 ? '+' : '';
      deltaText = '$sign${delta.toStringAsFixed(1)}$deltaUnit';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.lightTeal, size: 20),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(deltaIcon!, size: 14, color: deltaColor),
                const SizedBox(width: 2),
                Text(
                  deltaText!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Aba: Peso & IMC ──────────────────────────────────────────────────────

  Widget _buildWeightTab(List<PhysicalMeasurementEntity> history) {
    // Histórico em ordem cronológica para o gráfico
    final sorted = [...history]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Evolução do Peso (kg)'),
          const SizedBox(height: 12),
          _buildLineChart(
            data: sorted
                .map((m) => _DataPoint(m.recordedAt, m.weight))
                .toList(),
            unit: 'kg',
            color: AppColors.lightTeal,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Evolução do IMC'),
          const SizedBox(height: 12),
          _buildLineChart(
            data:
                sorted.map((m) => _DataPoint(m.recordedAt, m.bmi)).toList(),
            unit: '',
            color: AppColors.info,
            referenceLines: [
              _ReferenceLine(18.5, 'Abaixo do peso', AppColors.warning),
              _ReferenceLine(25.0, 'Sobrepeso', AppColors.warning),
              _ReferenceLine(30.0, 'Obesidade', AppColors.error),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Gordura Corporal (%)'),
          const SizedBox(height: 12),
          _buildLineChart(
            data: sorted
                .map((m) => _DataPoint(m.recordedAt, m.fatPercentage))
                .toList(),
            unit: '%',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  // ─── Aba: Perímetros ──────────────────────────────────────────────────────

  Widget _buildPerimetersTab(List<PhysicalMeasurementEntity> history) {
    final sorted = [...history]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Cintura (cm)'),
          const SizedBox(height: 12),
          _buildLineChart(
            data:
                sorted.map((m) => _DataPoint(m.recordedAt, m.waist)).toList(),
            unit: 'cm',
            color: AppColors.error,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Quadril (cm)'),
          const SizedBox(height: 12),
          _buildLineChart(
            data:
                sorted.map((m) => _DataPoint(m.recordedAt, m.hip)).toList(),
            unit: 'cm',
            color: AppColors.warning,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Tórax (cm)'),
          const SizedBox(height: 12),
          _buildLineChart(
            data:
                sorted.map((m) => _DataPoint(m.recordedAt, m.chest)).toList(),
            unit: 'cm',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  // ─── Aba: Histórico ───────────────────────────────────────────────────────

  Widget _buildHistoryTab(List<PhysicalMeasurementEntity> history) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final m = history[index];
        final isLatest = index == 0;
        return _buildMeasurementCard(m, isLatest: isLatest);
      },
    );
  }

  Widget _buildMeasurementCard(
    PhysicalMeasurementEntity m, {
    required bool isLatest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLatest
              ? AppColors.teal.withValues(alpha: 0.6)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(m.recordedAt),
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 15),
              ),
              if (isLatest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.teal),
                  ),
                  child: Text(
                    'Mais recente',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.lightTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (m.weight != null)
                _buildMeasureChip(
                  Icons.monitor_weight,
                  '${m.weight!.toStringAsFixed(1)} kg',
                ),
              if (m.bmi != null)
                _buildMeasureChip(
                  Icons.assessment,
                  'IMC ${m.bmi!.toStringAsFixed(1)}',
                  color: _getBmiColor(m.bmi!),
                ),
              if (m.fatPercentage != null)
                _buildMeasureChip(
                  Icons.percent,
                  '${m.fatPercentage!.toStringAsFixed(1)}% gord.',
                ),
              if (m.waist != null)
                _buildMeasureChip(
                  Icons.straighten,
                  'Cin ${m.waist!.toStringAsFixed(1)}cm',
                ),
              if (m.hip != null)
                _buildMeasureChip(
                  Icons.straighten,
                  'Quad ${m.hip!.toStringAsFixed(1)}cm',
                ),
              if (m.chest != null)
                _buildMeasureChip(
                  Icons.straighten,
                  'Tórax ${m.chest!.toStringAsFixed(1)}cm',
                ),
            ],
          ),
          if (m.recordedBy == 'student') ...[
            const SizedBox(height: 8),
            Text('Registrado pelo aluno',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          ],
          if ((m.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(m.notes!, style: AppTextStyles.bodyMedium),
          ],
          if (m.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: m.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(m.photoUrls[i],
                            webHtmlElementStrategy: WebHtmlElementStrategy.fallback),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(m.photoUrls[i],
                        width: 72, height: 96, fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.fallback),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasureChip(IconData icon, String label, {Color? color}) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: c),
          ),
        ],
      ),
    );
  }

  // ─── Gráfico de linha customizado ─────────────────────────────────────────

  Widget _buildLineChart({
    required List<_DataPoint> data,
    required String unit,
    required Color color,
    List<_ReferenceLine> referenceLines = const [],
  }) {
    final validData = data.where((d) => d.value != null).toList();

    if (validData.isEmpty) {
      return Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Center(
          child: Text(
            'Sem dados disponíveis',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    if (validData.length == 1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                '${validData.first.value!.toStringAsFixed(1)} $unit',
                style: AppTextStyles.displaySmall.copyWith(color: color),
              ),
              const SizedBox(height: 4),
              Text(
                'Apenas um registro — registre mais para ver evolução',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: CustomPaint(
        painter: _LineChartPainter(
          data: validData,
          color: color,
          referenceLines: referenceLines,
          unit: unit,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: const Icon(
                Icons.monitor_weight_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sem registros ainda',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O aluno ainda não atualizou\nsuas medidas no aplicativo.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectStudentPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search,
              size: 72,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 20),
            Text(
              'Selecione um aluno',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha um aluno acima para\nvisualizar sua evolução física.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.warning;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── Modelo interno para pontos do gráfico ────────────────────────────────

class _DataPoint {
  final DateTime date;
  final double? value;

  _DataPoint(this.date, this.value);
}

class _ReferenceLine {
  final double value;
  final String label;
  final Color color;

  _ReferenceLine(this.value, this.label, this.color);
}

// ─── CustomPainter para o gráfico de linha ────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<_DataPoint> data;
  final Color color;
  final List<_ReferenceLine> referenceLines;
  final String unit;

  _LineChartPainter({
    required this.data,
    required this.color,
    required this.referenceLines,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final values = data.map((d) => d.value!).toList();
    double minVal = values.reduce((a, b) => a < b ? a : b);
    double maxVal = values.reduce((a, b) => a > b ? a : b);

    // Inclui linhas de referência no range
    for (final ref in referenceLines) {
      if (ref.value < minVal) minVal = ref.value;
      if (ref.value > maxVal) maxVal = ref.value;
    }

    final padding = (maxVal - minVal) * 0.15;
    final yMin = minVal - padding;
    final yMax = maxVal + padding;
    final yRange = yMax - yMin;

    const leftPad = 40.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 24.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    double toX(int index) =>
        leftPad + (index / (data.length - 1)) * chartW;

    double toY(double value) =>
        topPad + (1 - (value - yMin) / yRange) * chartH;

    // Linhas de referência
    for (final ref in referenceLines) {
      final refPaint = Paint()
        ..color = ref.color.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final ry = toY(ref.value);
      canvas.drawLine(
        Offset(leftPad, ry),
        Offset(size.width - rightPad, ry),
        refPaint,
      );
    }

    // Linhas de grade horizontais
    final gridPaint = Paint()
      ..color = AppColors.surfaceLight.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = topPad + (i / 4) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      // Label do eixo Y
      final yVal = yMax - (i / 4) * yRange;
      final tp = TextPainter(
        text: TextSpan(
          text: yVal.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 9,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Área sob a curva
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(leftPad, topPad, chartW, chartH),
      )
      ..style = PaintingStyle.fill;

    final areaPath = Path()
      ..moveTo(toX(0), toY(data[0].value!));
    for (int i = 1; i < data.length; i++) {
      final prev = data[i - 1];
      final curr = data[i];
      final cpX = (toX(i - 1) + toX(i)) / 2;
      areaPath.cubicTo(
        cpX, toY(prev.value!),
        cpX, toY(curr.value!),
        toX(i), toY(curr.value!),
      );
    }
    areaPath
      ..lineTo(toX(data.length - 1), topPad + chartH)
      ..lineTo(toX(0), topPad + chartH)
      ..close();
    canvas.drawPath(areaPath, areaPaint);

    // Linha da curva
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(toX(0), toY(data[0].value!));
    for (int i = 1; i < data.length; i++) {
      final prev = data[i - 1];
      final curr = data[i];
      final cpX = (toX(i - 1) + toX(i)) / 2;
      linePath.cubicTo(
        cpX, toY(prev.value!),
        cpX, toY(curr.value!),
        toX(i), toY(curr.value!),
      );
    }
    canvas.drawPath(linePath, linePaint);

    // Pontos e labels de data
    for (int i = 0; i < data.length; i++) {
      final x = toX(i);
      final y = toY(data[i].value!);

      // Ponto externo (halo)
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = color.withValues(alpha: 0.25),
      );
      // Ponto interno
      canvas.drawCircle(
        Offset(x, y),
        3.5,
        Paint()..color = color,
      );

      // Label com valor
      final valueTp = TextPainter(
        text: TextSpan(
          text: '${data[i].value!.toStringAsFixed(1)}$unit',
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      valueTp.paint(canvas, Offset(x - valueTp.width / 2, y - 18));

      // Label de data (apenas primeiro e último)
      if (i == 0 || i == data.length - 1) {
        final dateTp = TextPainter(
          text: TextSpan(
            text: DateFormat('dd/MM').format(data[i].date),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 9,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        dateTp.paint(
          canvas,
          Offset(x - dateTp.width / 2, size.height - bottomPad + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.color != color;
}

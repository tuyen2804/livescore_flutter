import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/app_image.dart';
import '../../providers/sofascore_providers.dart';
import 'widgets/motorsport_header.dart';

/// Port `MotorsportStageActivity.kt` + `activity_motorsport_stage.xml`:
/// nền sáng `#EEF2F6`, header hero 300dp có lớp phủ `#990A1708`,
/// cờ quốc gia 72dp, tên chặng 17sp + tên giải 28sp, tab 54dp.
class MotorsportStageScreen extends StatelessWidget {
  const MotorsportStageScreen({
    super.key,
    required this.stageId,
    required this.name,
    required this.sportSlug,
  });

  final int stageId;
  final String name;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MotorsportStageProvider(sl())..load(stageId),
        child: _View(name: name),
      );
}

class _View extends StatefulWidget {
  const _View({required this.name});

  final String name;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MotorsportStageProvider>();
    final stage = provider.stage;

    final tabs = <String>[s.result, s.tabEvents, s.sectionInfo];
    final flag = stage?.country?.alpha2;

    return Scaffold(
      backgroundColor: MotorsportPalette.background,
      body: Column(
        children: [
          MotorsportHeroHeader(
            backgroundColor: MotorsportPalette.stageHeaderFallback,
            showScrim: true,
            title: stage?.description ?? stage?.name ?? widget.name,
            bigTitle: stage?.uniqueStage?.name ?? stage?.year ?? '',
            tabs: tabs,
            selectedTab: _tab,
            tabInactiveColor: MotorsportPalette.stageTabInactive,
            onSelectTab: (i) => setState(() => _tab = i),
            logo: flag == null
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      source: stage!.country!.flagUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.sofaBlue),
                  )
                : switch (_tab) {
                    0 => _Results(rows: provider.standingRows),
                    1 => _Sessions(sessions: provider.sessions),
                    _ => _Info(provider: provider),
                  },
          ),
        ],
      ),
    );
  }
}

class _LightCard extends StatelessWidget {
  const _LightCard({required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.sofaCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.sofaDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Text(
                  title!,
                  style: AppTextStyles.semiBold(
                    size: 14,
                    color: AppColors.sofaTextPrimary,
                  ),
                ),
              ),
            ...children,
          ],
        ),
      );
}

/// Port `view_motorsport_dynamic_result_table.xml` (bản sáng).
class _Results extends StatelessWidget {
  const _Results({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (rows.isEmpty) return _empty(s.noData);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 108),
      children: [
        _LightCard(
          title: s.result,
          children: [
            for (final row in rows) _ResultRow(row: row),
          ],
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final competitor = row['team'] ?? row['competitor'];
    final name = competitor is Map ? '${competitor['name'] ?? ''}' : '';
    final flag = competitor is Map
        ? (competitor['country']?['alpha2'] as String?)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${row['position'] ?? ''}',
              style: AppTextStyles.semiBold(
                size: 12,
                color: AppColors.sofaBlue,
              ),
            ),
          ),
          if (flag != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AppImage(
                source: 'https://img.sofascore.com/api/v1/country/'
                    '${flag.toLowerCase()}/flag',
                width: 20,
                height: 14,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.medium(
                size: 13,
                color: AppColors.sofaTextPrimary,
              ),
            ),
          ),
          Text(
            '${row['time'] ?? row['gap'] ?? row['points'] ?? ''}',
            style: AppTextStyles.regular(
              size: 12,
              color: AppColors.sofaTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Port `card_motorsport_stage_session.xml`.
class _Sessions extends StatelessWidget {
  const _Sessions({required this.sessions});

  final List<Map<String, dynamic>> sessions;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (sessions.isEmpty) return _empty(s.noData);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 108),
      children: [
        _LightCard(
          title: s.tabEvents,
          children: [
            for (final session in sessions)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${session['description'] ?? session['name'] ?? ''}',
                        style: AppTextStyles.medium(
                          size: 13,
                          color: AppColors.sofaTextPrimary,
                        ),
                      ),
                    ),
                    if (session['startDateTimestamp'] != null)
                      Text(
                        DateTimeUtils.formatEpochToLocalTime(
                          (session['startDateTimestamp'] as num).toInt(),
                        ),
                        style: AppTextStyles.regular(
                          size: 12,
                          color: AppColors.sofaTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.provider});

  final MotorsportStageProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final stage = provider.stage;
    if (stage == null) return _empty(s.noData);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 108),
      children: [
        _LightCard(
          title: s.sectionInfo,
          children: [
            _InfoRow(label: s.infoCountry, value: stage.country?.name),
            _InfoRow(
              label: s.infoTime,
              value: stage.startDateTimestamp == null
                  ? null
                  : DateTimeUtils.formatEpochToLocalDateFull(
                      stage.startDateTimestamp!,
                    ),
            ),
            _InfoRow(label: s.infoRound, value: stage.year),
            _InfoRow(label: s.infoLeague, value: stage.uniqueStage?.name),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.regular(
                size: 12,
                color: AppColors.sofaTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: AppTextStyles.medium(
                size: 12,
                color: AppColors.sofaTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _empty(String message) => Center(
      child: Text(
        message,
        style: AppTextStyles.regular(
          size: 14,
          color: AppColors.sofaTextSecondary,
        ),
      ),
    );

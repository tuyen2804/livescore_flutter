import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/sofascore/sofascore_models.dart';
import '../../providers/sofascore_providers.dart';
import 'widgets/motorsport_header.dart';

/// Port `MotorsportSeriesActivity.kt` + `activity_motorsport_series.xml`.
/// Màn này dùng **giao diện sáng** riêng: nền `#EEF2F6`, header hero 300dp có
/// ảnh nền, ô logo 72dp, tên mùa 28sp và TabLayout 54dp gạch chỉ báo trắng.
class MotorsportSeriesScreen extends StatelessWidget {
  const MotorsportSeriesScreen({
    super.key,
    required this.uniqueStageId,
    required this.name,
    required this.sportSlug,
  });

  final int uniqueStageId;
  final String name;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MotorsportSeriesProvider(sl())..load(uniqueStageId),
        child: _View(
          uniqueStageId: uniqueStageId,
          name: name,
          sportSlug: sportSlug,
        ),
      );
}

class _View extends StatefulWidget {
  const _View({
    required this.uniqueStageId,
    required this.name,
    required this.sportSlug,
  });

  final int uniqueStageId;
  final String name;
  final String sportSlug;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MotorsportSeriesProvider>();
    final season = provider.selectedSeason;

    // Tab = danh sách mùa giải, đúng như `seriesTabs` của bản gốc.
    final seasonLabels = provider.seasons
        .map((e) => e.year ?? e.name ?? '')
        .toList(growable: false);
    final tabs = seasonLabels.isEmpty ? [s.seeAll] : seasonLabels;
    final selected = _tab.clamp(0, tabs.length - 1);

    return Scaffold(
      backgroundColor: MotorsportPalette.background,
      body: Column(
        children: [
          MotorsportHeroHeader(
            backgroundColor: MotorsportPalette.seriesHeaderFallback,
            title: widget.name,
            bigTitle: season?.year ?? season?.name ?? '',
            tabs: tabs,
            selectedTab: selected,
            tabInactiveColor: MotorsportPalette.seriesTabInactive,
            onSelectTab: (i) {
              setState(() => _tab = i);
              if (i < provider.seasons.length) {
                provider.selectSeason(provider.seasons[i]);
              }
            },
            logo: Card(
              color: Colors.white,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppImage(
                  source: ApiConstants.uniqueStageLogo(widget.uniqueStageId),
                  width: 62,
                  height: 42,
                ),
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.sofaBlue,
                    ),
                  )
                : provider.races.isEmpty
                    ? Center(
                        child: Text(
                          s.noData,
                          style: AppTextStyles.regular(
                            size: 14,
                            color: AppColors.sofaTextSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 92),
                        itemCount: provider.races.length,
                        itemBuilder: (context, index) => _RaceCard(
                          stage: provider.races[index],
                          sportSlug: widget.sportSlug,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ chặng đua trên nền sáng — port `card_motorsport_dark_results` ở dạng
/// hàng danh sách: cờ quốc gia, tên chặng, quốc gia và ngày.
class _RaceCard extends StatelessWidget {
  const _RaceCard({required this.stage, required this.sportSlug});

  final SofascoreStage stage;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.motorsportStage,
          arguments: {
            'stageId': stage.id,
            'name': stage.description ?? stage.name ?? '',
            'sportSlug': sportSlug,
          },
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.sofaCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sofaDivider),
          ),
          child: Row(
            children: [
              if (stage.country?.alpha2 != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: AppImage(
                    source: stage.country!.flagUrl,
                    width: 28,
                    height: 20,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.description ?? stage.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.semiBold(
                        size: 14,
                        color: AppColors.sofaTextPrimary,
                      ),
                    ),
                    if (stage.country?.name != null)
                      Text(
                        stage.country!.name!,
                        style: AppTextStyles.regular(
                          size: 12,
                          color: AppColors.sofaTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (stage.startDateTimestamp != null)
                Text(
                  DateTimeUtils.formatEpochToLocalDate(
                    stage.startDateTimestamp!,
                  ),
                  style: AppTextStyles.medium(
                    size: 12,
                    color: AppColors.sofaBlue,
                  ),
                ),
            ],
          ),
        ),
      );
}

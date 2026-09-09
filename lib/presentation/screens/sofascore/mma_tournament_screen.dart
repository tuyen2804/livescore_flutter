import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/sofascore/sofascore_models.dart';
import '../../providers/sofascore_providers.dart';
import '../../widgets/detail_widgets.dart';
import 'widgets/sofa_detail_header.dart';
import 'widgets/sofa_widgets.dart';

/// Port `MmaTournamentActivity.kt` + `activity_mma_tournament.xml`:
/// header 74sdp → 2 tab viên thuốc (Trận chính thức / Prelims) →
/// thẻ địa điểm + danh sách trận đấu, có nhãn "Main Event" / "Co-Main Event".
class MmaTournamentScreen extends StatelessWidget {
  const MmaTournamentScreen({
    super.key,
    required this.uniqueTournamentId,
    required this.name,
    this.tournamentId = 0,
  });

  final int uniqueTournamentId;
  final String name;
  final int tournamentId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MmaTournamentProvider(sl())
          ..load(uniqueTournamentId, tournamentId: tournamentId),
        child: _View(uniqueTournamentId: uniqueTournamentId, name: name),
      );
}

class _View extends StatelessWidget {
  const _View({required this.uniqueTournamentId, required this.name});

  final int uniqueTournamentId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MmaTournamentProvider>();
    final detail = provider.detail;
    final tournament = provider.tournament;

    // `bindTournamentHeader`: phụ đề là phần tên giải bỏ đi tên tổ chức,
    // không có thì lấy `location`, cuối cùng rơi về "Mixed Martial Arts".
    final orgName = detail?.name ?? tournament?.name ?? name;
    var subtitle =
        (tournament?.name ?? '').replaceAll(orgName, '').trim();
    subtitle = subtitle.replaceAll(RegExp(r'^[:\s]+'), '');
    if (subtitle.isEmpty) subtitle = tournament?.location ?? '';
    if (subtitle.isEmpty) subtitle = 'Mixed Martial Arts';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SofaDetailHeader(
            logoUrl: ApiConstants.uniqueTournamentLogo(uniqueTournamentId),
            title: orgName,
            subtitle: subtitle,
            logoSize: 28,
          ),
          SizedBox(height: AppDimens.sdp(14)),
          SegmentedTabs(
            tabs: [s.statusMainCard, 'Prelims'],
            selected: provider.tab == 'maincard' ? 0 : 1,
            onSelect: (i) =>
                provider.selectTab(i == 0 ? 'maincard' : 'prelims'),
          ),
          Expanded(
            child: provider.isLoading
                ? const AppLoading()
                : provider.fights.isEmpty
                    ? AppEmptyView(
                        message: s.noRecentMatches,
                        icon: Icons.sports_mma,
                      )
                    : ListView(
                        padding: EdgeInsets.only(
                          left: AppDimens.sdp(14),
                          right: AppDimens.sdp(14),
                          top: AppDimens.sdp(10),
                          bottom: AppDimens.sdp(24),
                        ),
                        children: [
                          if (tournament?.location?.isNotEmpty ?? false)
                            _VenueCard(
                              logoUrl: ApiConstants.uniqueTournamentLogo(
                                uniqueTournamentId,
                              ),
                              date: tournament!.startTimestamp > 0
                                  ? DateFormat('EEE dd.MM.yyyy | HH:mm').format(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        tournament.startTimestamp * 1000,
                                      ),
                                    )
                                  : '',
                              location: tournament.location!,
                            ),
                          for (var i = 0; i < provider.fights.length; i++) ...[
                            if (provider.sectionHeaderFor(i) != null)
                              Padding(
                                padding: EdgeInsets.only(
                                  top: AppDimens.sdp(4),
                                  bottom: AppDimens.sdp(6),
                                ),
                                child: Text(
                                  provider.sectionHeaderFor(i)!,
                                  style: AppTextStyles.semiBold(
                                    size: AppDimens.ssp(12),
                                    color: AppColors.brandAccent,
                                  ),
                                ),
                              ),
                            _FightRow(
                              event: provider.fights[i],
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

/// Port `venueCard`: nền `bg_border_radius_16_dark`, padding 14sdp,
/// logo 28sdp + ngày 13ssp + (cờ 16x12sdp · địa điểm 11ssp).
class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.logoUrl,
    required this.date,
    required this.location,
  });

  final String logoUrl;
  final String date;
  final String location;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: AppDimens.sdp(12)),
        padding: EdgeInsets.all(AppDimens.sdp(14)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
        ),
        child: Row(
          children: [
            AppImage(
              source: logoUrl,
              width: AppDimens.sdp(28),
              height: AppDimens.sdp(28),
              placeholderAsset: 'assets/icons/ic_league.svg',
            ),
            SizedBox(width: AppDimens.sdp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(13),
                        color: AppColors.text500,
                      ),
                    ),
                  SizedBox(height: AppDimens.sdp(2)),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.regular(
                      size: AppDimens.ssp(11),
                      color: AppColors.text100,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Hàng trận MMA: hạng cân + kiểu trận ở trên, rồi thẻ trận chuẩn.
class _FightRow extends StatelessWidget {
  const _FightRow({required this.event});

  final SofascoreEvent event;

  @override
  Widget build(BuildContext context) {
    final meta = [event.weightClass, event.fightType]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (meta.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              left: AppDimens.sdp(4),
              bottom: AppDimens.sdp(4),
            ),
            child: Text(
              meta,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        SofaEventRow(
          event: event,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.sofascoreMatchDetail,
            arguments: {'eventId': event.id, 'sportSlug': 'mma'},
          ),
        ),
      ],
    );
  }
}

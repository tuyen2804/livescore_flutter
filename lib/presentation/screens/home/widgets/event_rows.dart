import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/sport_presentation.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/sofascore/sofascore_models.dart';

/// Các dòng trận của `EventAdapter`, mỗi môn một layout riêng:
/// `item_event_card.xml` (chung/bóng chày), `item_event_period_card.xml`
/// (tennis, bóng rổ), `item_event_cricket.xml` và thẻ MMA dựng bằng code.

// ---- Helper port từ companion object của EventAdapter ----

final DateFormat _hhmm = DateFormat('HH:mm');
final DateFormat _mmaDateTime = DateFormat('dd.MM.yyyy. HH:mm');

String formatStartTime(int timestamp) => timestamp <= 0
    ? '--:--'
    : _hhmm.format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

/// Port `statusLabel(event)`.
String statusLabel(SofascoreEvent event) {
  final type = event.status?.type ?? '';
  final description = event.status?.description ?? '';
  return switch (type) {
    'inprogress' => description.isEmpty ? 'LIVE' : description,
    'ended' || 'finished' => 'FT',
    'canceled' => 'Canceled',
    _ => description.isEmpty ? 'NS' : description,
  };
}

Color statusColor(SofascoreEvent event) => event.status?.type == 'inprogress'
    ? AppColors.sofaLiveRed
    : AppColors.text200;

bool _isNotStarted(SofascoreEvent event) {
  final type = (event.status?.type ?? 'notstarted').toLowerCase();
  return type == 'notstarted' || type == 'scheduled';
}

/// Port `competitorImageUrl` — vài môn dùng cờ quốc gia thay logo đội.
String? competitorImageUrl(SofascoreEvent event, Team? team) {
  if (team == null) return null;
  if (SportPresentation.homeCompetitorImage(event.sportSlug) ==
      HomeCompetitorImage.countryFlag) {
    final alpha2 = team.country?.alpha2;
    if (alpha2 != null && alpha2.trim().isNotEmpty) {
      return ApiConstants.countryFlag(alpha2.toUpperCase());
    }
  }
  return team.logoUrl;
}

List<int> _periods(Score? score) => [
      score?.period1,
      score?.period2,
      score?.period3,
      score?.period4,
      score?.period5,
      score?.period6,
      score?.period7,
      score?.period8,
      score?.period9,
    ].whereType<int>().toList(growable: false);

/// Port `periodLine(score, limit)`.
String periodLine(Score? score, int limit) =>
    _periods(score).take(limit).join(' ');

/// Port `lastPeriodValue(score)`.
int? lastPeriodValue(Score? score) {
  final values = _periods(score);
  return values.isEmpty ? null : values.last;
}

String scoreValue(Score? score) =>
    (score?.display ?? score?.current)?.toString() ?? '-';

/// Chuông theo dõi, chỉ hiện khi trận chưa bắt đầu — đúng như `btnBell`.
class _Bell extends StatelessWidget {
  const _Bell({
    required this.size,
    required this.padding,
    required this.isNotified,
    required this.onTap,
    this.tint = AppColors.text200,
  });

  final double size;
  final double padding;
  final bool isNotified;
  final VoidCallback? onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: SvgPicture.asset(
              'assets/icons/ic_bell_outline.svg',
              colorFilter: ColorFilter.mode(
                isNotified ? AppColors.brandAccent : tint,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      );
}

/// Port `item_event_card.xml` + `MatchViewHolder.bind` — dùng cho bóng đá,
/// bóng chày và mọi môn hai đội không có cột set.
class GenericEventRow extends StatelessWidget {
  const GenericEventRow({
    super.key,
    required this.event,
    required this.borderRadius,
    required this.isNotified,
    this.onTap,
    this.onNoti,
  });

  final SofascoreEvent event;
  final BorderRadius borderRadius;
  final bool isNotified;
  final VoidCallback? onTap;
  final VoidCallback? onNoti;

  @override
  Widget build(BuildContext context) {
    final type = event.status?.type ?? 'notstarted';
    final live = type == 'inprogress';
    final homeScore = event.homeScore?.display ?? event.homeScore?.current ?? 0;
    final awayScore = event.awayScore?.display ?? event.awayScore?.current ?? 0;

    // Chỉ vài môn tính điểm theo set mới hiện cột điểm phụ đang chạy.
    int? homePoint;
    int? awayPoint;
    if (live && SportPresentation.usesSetPointSecondaryScore(event.sportSlug)) {
      homePoint = lastPeriodValue(event.homeScore);
      awayPoint = lastPeriodValue(event.awayScore);
      if (homePoint == null || awayPoint == null) {
        homePoint = null;
        awayPoint = null;
      }
    }

    final statusText = switch (type) {
      'inprogress' => statusLabel(event),
      'ended' || 'finished' => 'FT',
      'canceled' => 'Canceled',
      _ => (event.status?.description ?? '').isEmpty
          ? 'NS'
          : event.status!.description!,
    };
    final statusTint =
        live ? AppColors.sofaLiveRed : AppColors.sofaFinishedGrey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(height: 1, color: AppColors.divider),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formatStartTime(event.startTimestamp),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.regular(
                              size: 12,
                              color: AppColors.text200,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.regular(
                              size: 11,
                              color: statusTint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 6),
                          _CompetitorLine(
                            event: event,
                            team: event.homeTeam,
                            fallback: 'Home',
                            score: '$homeScore',
                            livePoint: homePoint,
                            live: live,
                            winner: event.winnerCode == 1,
                            loser: event.winnerCode == 2,
                          ),
                          const SizedBox(height: 4),
                          _CompetitorLine(
                            event: event,
                            team: event.awayTeam,
                            fallback: 'Away',
                            score: '$awayScore',
                            livePoint: awayPoint,
                            live: live,
                            winner: event.winnerCode == 2,
                            loser: event.winnerCode == 1,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    if (_isNotStarted(event))
                      _Bell(
                        size: 40,
                        padding: 10,
                        isNotified: isNotified,
                        onTap: onNoti,
                      )
                    else
                      const SizedBox(width: 40),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompetitorLine extends StatelessWidget {
  const _CompetitorLine({
    required this.event,
    required this.team,
    required this.fallback,
    required this.score,
    required this.livePoint,
    required this.live,
    required this.winner,
    required this.loser,
  });

  final SofascoreEvent event;
  final Team? team;
  final String fallback;
  final String score;
  final int? livePoint;
  final bool live;
  final bool winner;
  final bool loser;

  @override
  Widget build(BuildContext context) {
    // Port applyWinnerStyle: bên thắng trắng + đậm, bên thua xám.
    final nameColor = loser ? AppColors.text200 : AppColors.text500;
    final scoreColor = live
        ? AppColors.sofaLiveRed
        : (loser ? AppColors.text200 : AppColors.text500);

    return Row(
      children: [
        const SizedBox(width: 8),
        AppImage(
          source: competitorImageUrl(event, team),
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team?.name ?? fallback,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: winner
                ? AppTextStyles.bold(size: 14, color: nameColor)
                : AppTextStyles.regular(size: 14, color: nameColor),
          ),
        ),
        if (livePoint != null)
          SizedBox(
            width: 32,
            child: Text(
              '$livePoint',
              textAlign: TextAlign.end,
              style: AppTextStyles.regular(size: 13, color: AppColors.text200),
            ),
          ),
        SizedBox(
          width: 32,
          child: Text(
            score,
            textAlign: TextAlign.center,
            style: winner
                ? AppTextStyles.bold(size: 14, color: scoreColor)
                : AppTextStyles.regular(size: 14, color: scoreColor),
          ),
        ),
      ],
    );
  }
}

/// Port `item_event_period_card.xml` + `PeriodMatchViewHolder.bind` —
/// tennis và bóng rổ, có thêm cột điểm từng set/hiệp.
class PeriodEventRow extends StatelessWidget {
  const PeriodEventRow({
    super.key,
    required this.event,
    required this.family,
    required this.borderRadius,
    required this.isNotified,
    this.onTap,
    this.onNoti,
  });

  final SofascoreEvent event;
  final HomeEventFamily family;
  final BorderRadius borderRadius;
  final bool isNotified;
  final VoidCallback? onTap;
  final VoidCallback? onNoti;

  @override
  Widget build(BuildContext context) {
    final live = event.status?.type == 'inprogress';
    final limit = switch (family) {
      HomeEventFamily.tennis => 5,
      HomeEventFamily.basketball => 6,
      HomeEventFamily.cricket => 2,
      _ => 9,
    };
    final showClock = family != HomeEventFamily.cricket;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(height: 1, color: AppColors.divider),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Opacity(
                      opacity: showClock ? 1 : 0,
                      child: SizedBox(
                        width: 58,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatStartTime(event.startTimestamp),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.regular(
                                size: 12,
                                color: AppColors.text200,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusLabel(event),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.regular(
                                size: 11,
                                color: statusColor(event),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PeriodLine(
                            event: event,
                            team: event.homeTeam,
                            fallback: event.homeTeam?.name ?? event.name,
                            periods: periodLine(event.homeScore, limit),
                            score: scoreValue(event.homeScore),
                            live: live,
                            winner: event.winnerCode == 1,
                            loser: event.winnerCode == 2,
                          ),
                          const SizedBox(height: 5),
                          _PeriodLine(
                            event: event,
                            team: event.awayTeam,
                            fallback: 'Away',
                            periods: periodLine(event.awayScore, limit),
                            score: scoreValue(event.awayScore),
                            live: live,
                            winner: event.winnerCode == 2,
                            loser: event.winnerCode == 1,
                          ),
                        ],
                      ),
                    ),
                    if (_isNotStarted(event))
                      _Bell(
                        size: 36,
                        padding: 9,
                        isNotified: isNotified,
                        onTap: onNoti,
                      )
                    else
                      const SizedBox(width: 36),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodLine extends StatelessWidget {
  const _PeriodLine({
    required this.event,
    required this.team,
    required this.fallback,
    required this.periods,
    required this.score,
    required this.live,
    required this.winner,
    required this.loser,
  });

  final SofascoreEvent event;
  final Team? team;
  final String? fallback;
  final String periods;
  final String score;
  final bool live;
  final bool winner;
  final bool loser;

  @override
  Widget build(BuildContext context) {
    final nameColor =
        live ? AppColors.text500 : (loser ? AppColors.text200 : AppColors.text500);
    final scoreColor = live
        ? AppColors.sofaLiveRed
        : (loser ? AppColors.text200 : AppColors.text500);

    return Row(
      children: [
        const SizedBox(width: 6),
        AppImage(
          source: competitorImageUrl(event, team),
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team?.name ?? fallback ?? 'Home',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: winner
                ? AppTextStyles.bold(size: 13, color: nameColor)
                : AppTextStyles.regular(size: 13, color: nameColor),
          ),
        ),
        SizedBox(
          width: 86,
          child: Text(
            periods,
            maxLines: 1,
            textAlign: TextAlign.end,
            style: AppTextStyles.regular(size: 12, color: AppColors.text200),
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            score,
            textAlign: TextAlign.center,
            style: winner
                ? AppTextStyles.bold(size: 14, color: scoreColor)
                : AppTextStyles.regular(size: 14, color: scoreColor),
          ),
        ),
      ],
    );
  }
}

/// Port `item_event_cricket.xml` + `CricketMatchViewHolder.bind` —
/// thẻ này dùng nền sáng `surface_1` khác hẳn các môn còn lại.
class CricketEventRow extends StatelessWidget {
  const CricketEventRow({
    super.key,
    required this.event,
    required this.borderRadius,
    required this.isNotified,
    this.onTap,
    this.onNoti,
  });

  final SofascoreEvent event;
  final BorderRadius borderRadius;
  final bool isNotified;
  final VoidCallback? onTap;
  final VoidCallback? onNoti;

  @override
  Widget build(BuildContext context) {
    final live = (event.status?.type ?? '').toLowerCase() == 'inprogress';
    final homeBatting = live && event.currentBattingTeamId == event.homeTeam?.id;
    final awayBatting = live && event.currentBattingTeamId == event.awayTeam?.id;

    final description = live
        ? ((event.status?.description ?? '').isNotEmpty
            ? event.status!.description!
            : _capitalize(event.lastPeriod ?? ''))
        : const {'ended', 'finished'}.contains(event.status?.type)
            ? ((event.status?.description ?? '').isNotEmpty
                ? event.status!.description!
                : 'Finished')
            : event.status?.type == 'canceled'
                ? 'Canceled'
                : formatStartTime(event.startTimestamp);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: borderRadius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CricketLine(
                    team: event.homeTeam,
                    fallback: 'Home',
                    score: _cricketScore(event.homeScore),
                    batting: homeBatting,
                  ),
                  const SizedBox(height: 5),
                  _CricketLine(
                    team: event.awayTeam,
                    fallback: 'Away',
                    score: _cricketScore(event.awayScore),
                    batting: awayBatting,
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.regular(
                        size: 12,
                        color: live
                            ? AppColors.cricketLive
                            : AppColors.cricketDescription,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isNotStarted(event))
              _Bell(
                size: 48,
                padding: 13,
                isNotified: isNotified,
                onTap: onNoti,
                tint: AppColors.nLv3,
              )
            else
              const SizedBox(width: 48),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _CricketLine extends StatelessWidget {
  const _CricketLine({
    required this.team,
    required this.fallback,
    required this.score,
    required this.batting,
  });

  final Team? team;
  final String fallback;
  final String score;
  final bool batting;

  @override
  Widget build(BuildContext context) {
    final name = (team?.shortName ?? '').trim().isNotEmpty
        ? team!.shortName!
        : (team?.name ?? fallback);

    return Row(
      children: [
        const SizedBox(width: 16),
        AppImage(source: team?.logoUrl, width: 18, height: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.regular(size: 16, color: AppColors.nLv1),
          ),
        ),
        if (batting)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: SvgPicture.asset(
              'assets/icons/ic_cricket_bat.svg',
              width: 16,
              height: 18,
            ),
          ),
        SizedBox(
          width: 116,
          child: Text(
            score,
            maxLines: 1,
            textAlign: TextAlign.end,
            style: AppTextStyles.bold(
              size: 16,
              color: batting ? AppColors.cricketLive : AppColors.cricketNormal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Port `cricketScore(score)`: ghép các hiệp "runs-wickets (overs)".
String _cricketScore(Score? score) {
  if (score == null) return '-';
  final entries = (score.innings ?? const <String, CricketInningScore>{})
      .entries
      .toList()
    ..sort((a, b) {
      final ka = int.tryParse(a.key.replaceAll(RegExp(r'\D'), '')) ?? 1 << 31;
      final kb = int.tryParse(b.key.replaceAll(RegExp(r'\D'), '')) ?? 1 << 31;
      return ka.compareTo(kb);
    });

  final innings = <String>[];
  for (final entry in entries) {
    final runs = entry.value.score ?? entry.value.run;
    if (runs == null) continue;
    final buffer = StringBuffer('$runs');
    final wickets = entry.value.wickets;
    if (wickets != null) buffer.write('-$wickets');
    final overs = entry.value.overs;
    if (overs != null) buffer.write(' (${_formatOvers(overs)})');
    innings.add(buffer.toString());
  }

  if (innings.isNotEmpty) return innings.join(' & ');
  final display = score.currentCricketDisplay;
  if (display != null && display.trim().isNotEmpty) return display;
  final current = score.display ?? score.current ?? 0;
  return current > 0 ? '$current' : '-';
}

String _formatOvers(num value) =>
    value % 1 == 0 ? '${value.toInt()}' : '$value';

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

/// Port `createMmaCardView` + `MmaViewHolder.bind`: khối giải phía trên,
/// gạch ngăn, rồi băng hai võ sĩ với ảnh 48dp và cờ 16dp ở góc.
class MmaEventRow extends StatelessWidget {
  const MmaEventRow({
    super.key,
    required this.event,
    required this.isNotified,
    this.onTap,
    this.onNoti,
  });

  final SofascoreEvent event;
  final bool isNotified;
  final VoidCallback? onTap;
  final VoidCallback? onNoti;

  @override
  Widget build(BuildContext context) {
    final tournament = event.tournament;
    final unique = tournament?.uniqueTournament;

    final tournamentName = (unique?.name ?? '').trim().isNotEmpty
        ? unique!.name
        : (tournament?.name ?? 'MMA');
    final eventTitle = tournament?.name ??
        '${event.homeTeam?.name} vs ${event.awayTeam?.name}';

    final venue = event.venue;
    final venueText = venue?.name != null
        ? [
            venue!.name!,
            ?venue.city?.name,
            ?(venue.city?.country?.name ?? venue.country?.name),
          ].join(', ')
        : (tournament?.location ?? '');

    final date = event.startTimestamp > 0
        ? _mmaDateTime.format(
            DateTime.fromMillisecondsSinceEpoch(event.startTimestamp * 1000),
          )
        : '--.--.----. --:--';
    final rawFightType = event.fightType?.replaceAll('maincard', 'Main card');
    final fightType = (rawFightType ?? '').trim().isEmpty
        ? 'Main card'
        : rawFightType!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: AppColors.itemBg,
        child: Column(
          children: [
            Container(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(14).copyWith(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppImage(
                        source: unique?.logoUrl,
                        width: 24,
                        height: 24,
                        placeholderAsset: 'assets/icons/ic_league.svg',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tournamentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bold(
                            size: 13,
                            color: AppColors.text500,
                          ),
                        ),
                      ),
                      _Bell(
                        size: 20,
                        padding: 0,
                        isNotified: isNotified,
                        onTap: onNoti,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    eventTitle,
                    style: AppTextStyles.bold(
                      size: 14,
                      color: AppColors.text500,
                    ),
                  ),
                  if (venueText.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      venueText,
                      style: AppTextStyles.regular(
                        size: 12,
                        color: AppColors.text200,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          date,
                          style: AppTextStyles.regular(
                            size: 12,
                            color: AppColors.text200,
                          ),
                        ),
                      ),
                      Text(
                        fightType,
                        style: AppTextStyles.regular(
                          size: 12,
                          color: AppColors.text200,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Row(
                      children: [
                        _FighterAvatar(team: event.homeTeam, alignStart: true),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 6),
                            child: Text(
                              _fighterName(event.homeTeam, 'Fighter 1'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bold(
                                size: 13,
                                color: AppColors.text500,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'VS',
                            style: AppTextStyles.bold(
                              size: 13,
                              color: AppColors.text200,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6, right: 8),
                            child: Text(
                              _fighterName(event.awayTeam, 'Fighter 2'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppTextStyles.bold(
                                size: 13,
                                color: AppColors.text500,
                              ),
                            ),
                          ),
                        ),
                        _FighterAvatar(team: event.awayTeam, alignStart: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fighterName(Team? team, String fallback) {
  final short = (team?.shortName ?? '').trim();
  if (short.isNotEmpty) return short;
  return team?.name ?? fallback;
}

class _FighterAvatar extends StatelessWidget {
  const _FighterAvatar({required this.team, required this.alignStart});

  final Team? team;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final alpha2 = team?.country?.alpha2;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        children: [
          Positioned.fill(
            child: AppImage(
              source: (team?.id ?? 0) > 0 ? team!.logoUrl : null,
              fit: BoxFit.cover,
            ),
          ),
          if (alpha2 != null && alpha2.trim().isNotEmpty)
            Positioned(
              bottom: 0,
              left: alignStart ? 0 : null,
              right: alignStart ? null : 0,
              child: AppImage(
                source: ApiConstants.countryFlag(alpha2),
                width: 16,
                height: 16,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}

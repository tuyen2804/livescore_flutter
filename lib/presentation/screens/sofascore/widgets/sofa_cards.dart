import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/sofascore/sofascore_models.dart';
import '../../../providers/sofascore_match_detail_provider.dart';
import 'sofa_widgets.dart';

/// Port `newCard()` + `addCard()`: nền `bg_border_radius_16_dark`,
/// padding dưới 16, cách thẻ sau 24.
class SofaCardBox extends StatelessWidget {
  const SofaCardBox({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) SofaSectionTitle(title!),
            ...children,
          ],
        ),
      );
}

/// `sectionTitle()` — 14sp.
class SofaSectionTitle extends StatelessWidget {
  const SofaSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.sdp(12),
          AppDimens.sdp(12),
          AppDimens.sdp(12),
          AppDimens.sdp(8),
        ),
        child: Text(
          title,
          style: AppTextStyles.semiBold(size: 14, color: AppColors.text500),
        ),
      );
}

/// `renderTournamentHeaderCard()` — logo giải + tên giải + hạng mục.
class SofaTournamentHeaderCard extends StatelessWidget {
  const SofaTournamentHeaderCard({super.key, required this.event});

  final SofascoreEvent event;

  @override
  Widget build(BuildContext context) {
    final tournament = event.tournament;
    if (tournament == null) return const SizedBox.shrink();

    return SofaCardBox(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
          child: Row(
            children: [
              AppImage(
                source: tournament.logoUrl,
                width: AppDimens.sdp(28),
                height: AppDimens.sdp(28),
                placeholderAsset: 'assets/icons/ic_league.svg',
              ),
              SizedBox(width: AppDimens.sdp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.semiBold(
                        size: AppDimens.ssp(13),
                        color: AppColors.text500,
                      ),
                    ),
                    if (tournament.category?.name.isNotEmpty ?? false)
                      Text(
                        tournament.category!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.regular(
                          size: AppDimens.ssp(11),
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `renderPeriodScoresCard()` — bảng điểm từng hiệp/set.
class SofaPeriodScoresCard extends StatelessWidget {
  const SofaPeriodScoresCard({
    super.key,
    required this.rows,
    required this.homeName,
    required this.awayName,
  });

  final List<(String, String, String)> rows;
  final String homeName;
  final String awayName;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);

    return SofaCardBox(
      title: s.titlePeriodScores,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: SizedBox.shrink()),
                  for (final row in rows)
                    SizedBox(
                      width: AppDimens.sdp(34),
                      child: Text(
                        row.$1,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.regular(
                          size: AppDimens.ssp(10),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppDimens.sdp(6)),
              _ScoreLine(name: homeName, values: [for (final r in rows) r.$2]),
              SizedBox(height: AppDimens.sdp(6)),
              _ScoreLine(name: awayName, values: [for (final r in rows) r.$3]),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({required this.name, required this.values});

  final String name;
  final List<String> values;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.medium(
                size: AppDimens.ssp(11),
                color: AppColors.text500,
              ),
            ),
          ),
          for (final v in values)
            SizedBox(
              width: AppDimens.sdp(34),
              child: Text(
                v,
                textAlign: TextAlign.center,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(11),
                  color: AppColors.text500,
                ),
              ),
            ),
        ],
      );
}

/// `renderIncidentsCard()` — dòng thời gian sự kiện, chia hai bên theo đội.
class SofaIncidentsCard extends StatelessWidget {
  const SofaIncidentsCard({
    super.key,
    required this.incidents,
    this.homeTeamId,
  });

  final List<Map<String, dynamic>> incidents;
  final int? homeTeamId;

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);

    return SofaCardBox(
      title: s.titleMatchIncidents,
      children: [
        for (final item in incidents)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.sdp(12),
              vertical: AppDimens.sdp(5),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: AppDimens.sdp(34),
                  child: Text(
                    item['time'] == null ? '' : "${item['time']}'",
                    style: AppTextStyles.semiBold(
                      size: AppDimens.ssp(11),
                      color: AppColors.brandAccent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _describe(item),
                    style: AppTextStyles.regular(
                      size: AppDimens.ssp(12),
                      color: AppColors.text500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _describe(Map<String, dynamic> item) {
    final player = item['player'];
    final name = player is Map ? '${player['name'] ?? ''}' : '';
    final text = item['text'] ??
        item['incidentClass'] ??
        item['incidentType'] ??
        '';
    return name.isEmpty ? '$text' : '$text · $name';
  }
}

/// `renderVotesCard()` — 1 / X / 2.
class SofaVotesCard extends StatelessWidget {
  const SofaVotesCard({
    super.key,
    required this.vote,
    required this.homeName,
    required this.awayName,
  });

  final Map<String, dynamic> vote;
  final String homeName;
  final String awayName;

  @override
  Widget build(BuildContext context) {
    final v1 = (vote['vote1'] as num?)?.toInt() ?? 0;
    final vx = (vote['voteX'] as num?)?.toInt() ?? 0;
    final v2 = (vote['vote2'] as num?)?.toInt() ?? 0;
    final total = v1 + vx + v2;
    if (total == 0) return const SizedBox.shrink();

    final s = S.of(context);
    String pct(int v) => '${(v * 100 / total).round()}%';

    return SofaCardBox(
      title: s.whoWillWins,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
          child: Row(
            children: [
              _VoteSlot(
                label: homeName,
                value: pct(v1),
                ratio: v1 / total,
                color: AppColors.homeColor,
              ),
              if (vx > 0)
                _VoteSlot(
                  label: s.drawText,
                  value: pct(vx),
                  ratio: vx / total,
                  color: AppColors.drawColor,
                ),
              _VoteSlot(
                label: awayName,
                value: pct(v2),
                ratio: v2 / total,
                color: AppColors.awayColor,
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimens.sdp(8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
          child: Text(
            s.totalVotesFormat(total),
            style: AppTextStyles.regular(
              size: AppDimens.ssp(10),
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _VoteSlot extends StatelessWidget {
  const _VoteSlot({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String value;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(4)),
          child: Column(
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(11),
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bold(size: AppDimens.ssp(15), color: color),
              ),
              SizedBox(height: AppDimens.sdp(5)),
              LinearProgressIndicator(
                value: ratio,
                minHeight: 4,
                backgroundColor: AppColors.divider,
                color: color,
              ),
            ],
          ),
        ),
      );
}

/// `renderMatchInfoCard()` — giải / hạng mục / sân / ngày giờ.
class SofaMatchInfoCard extends StatelessWidget {
  const SofaMatchInfoCard({super.key, required this.event});

  final SofascoreEvent event;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SofaCardBox(
      title: s.matchInfoTitle,
      children: [
        SofaInfoRow(label: s.infoLeague, value: event.tournament?.name),
        SofaInfoRow(
          label: s.infoCountry,
          value: event.tournament?.category?.name,
        ),
        SofaInfoRow(label: s.infoVenue, value: event.venue?.name),
        SofaInfoRow(
          label: s.infoTime,
          value: DateTimeUtils.formatEpochToLocalTime(event.startTimestamp),
        ),
        if (event.weightClass != null)
          SofaInfoRow(label: s.infoWeightDivisions, value: event.weightClass),
      ],
    );
  }
}

/// `renderTvChannelsCard()`.
class SofaTvChannelsCard extends StatelessWidget {
  const SofaTvChannelsCard({super.key, required this.channels});

  final List<Map<String, dynamic>> channels;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    return SofaCardBox(
      title: s.titleTvChannels,
      children: [
        for (final ch in channels.take(20))
          SofaInfoRow(
            label: '${ch['country'] ?? ''}'.toUpperCase(),
            value: '${ch['name'] ?? ''}',
          ),
      ],
    );
  }
}

/// `renderPointByPointCard()` — tennis: điểm từng game trong mỗi set.
class SofaPointByPointCard extends StatelessWidget {
  const SofaPointByPointCard({super.key, required this.sets});

  final List<Map<String, dynamic>> sets;

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);

    return SofaCardBox(
      title: s.titlePointByPoint,
      children: [
        for (final set in sets.take(5))
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.sdp(12),
              vertical: AppDimens.sdp(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set ${set['set'] ?? ''}',
                  style: AppTextStyles.semiBold(
                    size: AppDimens.ssp(11),
                    color: AppColors.brandAccent,
                  ),
                ),
                SizedBox(height: AppDimens.sdp(4)),
                Wrap(
                  spacing: AppDimens.sdp(6),
                  runSpacing: AppDimens.sdp(4),
                  children: [
                    for (final game in _games(set))
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimens.sdp(6),
                          vertical: AppDimens.sdp(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgApp,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${game['homeScore'] ?? '-'}:${game['awayScore'] ?? '-'}',
                          style: AppTextStyles.regular(
                            size: AppDimens.ssp(10),
                            color: AppColors.text500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _games(Map<String, dynamic> set) {
    final games = set['games'];
    if (games is! List) return const [];
    return games
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
  }
}

/// `renderEsportsGamesCard()`.
class SofaEsportsGamesCard extends StatelessWidget {
  const SofaEsportsGamesCard({super.key, required this.games});

  final List<Map<String, dynamic>> games;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) return const SizedBox.shrink();
    final s = S.of(context);
    return SofaCardBox(
      title: s.titleEsportsGames,
      children: [
        for (var i = 0; i < games.length; i++)
          SofaInfoRow(
            label: 'Map ${i + 1}',
            value: '${games[i]['homeScore']?['display'] ?? '-'}'
                ' - ${games[i]['awayScore']?['display'] ?? '-'}',
          ),
      ],
    );
  }
}

/// `showStandings()` — bảng xếp hạng của Sofascore.
class SofaStandingsCard extends StatelessWidget {
  const SofaStandingsCard({
    super.key,
    required this.rows,
    this.compact = false,
  });

  final List<Map<String, dynamic>> rows;

  /// Ở tab Info bản gốc chỉ hiện bảng rút gọn (`renderPrematchStandingsCard`).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (rows.isEmpty) {
      return compact
          ? const SizedBox.shrink()
          : AppEmptyView(message: s.noData, icon: Icons.table_chart_outlined);
    }

    final visible = compact ? rows.take(6).toList(growable: false) : rows;
    final content = SofaCardBox(
      title: s.tabStandings,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: AppDimens.sdp(22)),
                  Expanded(
                    child: Text(
                      s.team,
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(10),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _Cell(text: s.tableMatchesPlayed, header: true),
                  const _Cell(text: 'W', header: true),
                  const _Cell(text: 'L', header: true),
                  _Cell(text: s.tablePoints, header: true),
                ],
              ),
              SizedBox(height: AppDimens.sdp(6)),
              for (final row in visible) _StandingRow(row: row),
            ],
          ),
        ),
      ],
    );

    return compact
        ? content
        : ListView(
            padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
            children: [content],
          );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final team = row['team'];
    final teamId = team is Map ? (team['id'] as num?)?.toInt() : null;
    final teamName = team is Map ? '${team['name'] ?? ''}' : '';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(5)),
      child: Row(
        children: [
          SizedBox(
            width: AppDimens.sdp(22),
            child: Text(
              '${row['position'] ?? ''}',
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          AppImage(
            source: teamId == null ? null : ApiConstants.teamLogo(teamId),
            width: AppDimens.sdp(16),
            height: AppDimens.sdp(16),
            placeholderAsset: 'assets/icons/ic_ball.svg',
          ),
          SizedBox(width: AppDimens.sdp(6)),
          Expanded(
            child: Text(
              teamName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.medium(
                size: AppDimens.ssp(11),
                color: AppColors.text500,
              ),
            ),
          ),
          _Cell(text: '${row['matches'] ?? 0}'),
          _Cell(text: '${row['wins'] ?? 0}'),
          _Cell(text: '${row['losses'] ?? 0}'),
          _Cell(text: '${row['points'] ?? 0}', bold: true),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, this.header = false, this.bold = false});

  final String text;
  final bool header;
  final bool bold;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: AppDimens.sdp(26),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: bold
              ? AppTextStyles.bold(
                  size: AppDimens.ssp(11),
                  color: AppColors.brandAccent,
                )
              : AppTextStyles.regular(
                  size: AppDimens.ssp(10),
                  color: header ? AppColors.textSecondary : AppColors.text500,
                ),
        ),
      );
}

/// `showStatistics()` — nhóm theo `groupName`.
class SofaStatisticsList extends StatelessWidget {
  const SofaStatisticsList({super.key, required this.rows});

  final List<(String, String, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (rows.isEmpty) {
      return AppEmptyView(message: s.noData, icon: Icons.bar_chart_outlined);
    }

    final grouped = <String, List<(String, String, String, String)>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.$1, () => []).add(row);
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        for (final entry in grouped.entries)
          SofaCardBox(
            title: entry.key,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
                child: Column(
                  children: [
                    for (final row in entry.value)
                      SofaStatRow(label: row.$2, home: row.$3, away: row.$4),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// `showLineups()` — hai đội, mỗi đội một thẻ.
class SofaLineupsCard extends StatelessWidget {
  const SofaLineupsCard({super.key, required this.provider});

  final SofascoreMatchDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final home = provider.lineupPlayers(home: true);
    final away = provider.lineupPlayers(home: false);
    if (home.isEmpty && away.isEmpty) {
      return AppEmptyView(message: s.noData, icon: Icons.groups_outlined);
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        _TeamLineup(
          title: provider.event?.homeTeam?.name ?? s.homeText,
          formation: provider.lineupFormation(home: true),
          players: home,
        ),
        _TeamLineup(
          title: provider.event?.awayTeam?.name ?? s.awayText,
          formation: provider.lineupFormation(home: false),
          players: away,
        ),
      ],
    );
  }
}

class _TeamLineup extends StatelessWidget {
  const _TeamLineup({
    required this.title,
    required this.formation,
    required this.players,
  });

  final String title;
  final String? formation;
  final List<Map<String, dynamic>> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();
    return SofaCardBox(
      title: formation == null || formation!.isEmpty
          ? title
          : '$title · $formation',
      children: [
        for (final entry in players)
          Builder(
            builder: (context) {
              final player = entry['player'];
              final p = player is Map
                  ? Map<String, dynamic>.from(player)
                  : entry;
              final id = (p['id'] as num?)?.toInt();
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.sdp(12),
                  vertical: AppDimens.sdp(4),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: AppDimens.sdp(24),
                      child: Text(
                        '${entry['shirtNumber'] ?? p['jerseyNumber'] ?? ''}',
                        style: AppTextStyles.semiBold(
                          size: AppDimens.ssp(11),
                          color: AppColors.brandAccent,
                        ),
                      ),
                    ),
                    AppImage(
                      source: id == null ? null : ApiConstants.playerImage(id),
                      width: AppDimens.sdp(24),
                      height: AppDimens.sdp(24),
                      borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
                    ),
                    SizedBox(width: AppDimens.sdp(8)),
                    Expanded(
                      child: Text(
                        '${p['name'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.medium(
                          size: AppDimens.ssp(12),
                          color: AppColors.text500,
                        ),
                      ),
                    ),
                    Text(
                      '${p['position'] ?? ''}',
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(10),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// `showMatches()` — các trận đối đầu.
class SofaMatchesCard extends StatelessWidget {
  const SofaMatchesCard({super.key, required this.events});

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (events.isEmpty) {
      return AppEmptyView(message: s.noData, icon: Icons.compare_arrows);
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        SofaCardBox(
          title: s.h2h,
          children: [
            for (final json in events)
              SofaEventRow(event: SofascoreEvent.fromJson(json)),
          ],
        ),
      ],
    );
  }
}

/// Hàng nhãn — giá trị dùng chung trong các thẻ.
class SofaInfoRow extends StatelessWidget {
  const SofaInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(12),
        vertical: AppDimens.sdp(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppDimens.sdp(90),
            child: Text(
              label,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(11),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: AppTextStyles.medium(
                size: AppDimens.ssp(11),
                color: AppColors.text500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Port `item_match_stat.xml`: hai ô giá trị nền `bg_item_stats` cao 28dp,
/// tên chỉ số ở giữa, và một chấm 7dp màu accent đánh dấu bên trội hơn.
/// Bản gốc so sánh bằng `toIntOrNull()` sau khi bỏ `%`, nên chuỗi kiểu
/// "9/14 (64%)" không parse được và cả hai bên đều được đánh dấu.
class SofaStatRow extends StatelessWidget {
  const SofaStatRow({
    super.key,
    required this.label,
    required this.home,
    required this.away,
  });

  final String label;
  final String home;
  final String away;

  static int? _num(String v) => int.tryParse(v.replaceAll('%', '').trim());

  @override
  Widget build(BuildContext context) {
    final h = _num(home) ?? 0;
    final a = _num(away) ?? 0;
    final homeDot = h >= a;
    final awayDot = a >= h;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          _ValueChip(text: home, showDot: homeDot, dotOnRight: true),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(
                size: 12,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
          _ValueChip(text: away, showDot: awayDot, dotOnRight: false),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.text,
    required this.showDot,
    required this.dotOnRight,
  });

  final String text;
  final bool showDot;
  final bool dotOnRight;

  @override
  Widget build(BuildContext context) {
    final dot = Opacity(
      opacity: showDot ? 1 : 0,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.brandAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
    final value = Text(
      text,
      style: AppTextStyles.regular(size: 11, color: const Color(0xFFF8FAFC)),
    );

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // `bg_item_stats.xml`: nền #283240, viền 1dp #3B495E, bo 16dp.
      decoration: BoxDecoration(
        color: const Color(0xFF283240),
        border: Border.all(color: const Color(0xFF3B495E)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: dotOnRight
            ? [value, const SizedBox(width: 6), dot]
            : [dot, const SizedBox(width: 6), value],
      ),
    );
  }
}

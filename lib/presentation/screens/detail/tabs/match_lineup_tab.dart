import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/football/football_models.dart';
import '../../../providers/match_detail_provider.dart';

/// Port `MatchLineupFragment.kt` + `fragment_match_lineup.xml`: khối sân
/// `bg_team_pick` cao 680dp chứa hai `TeamPitchView` 300dp, rồi tới khối
/// "Substitutions" chia đôi Home / Away.
class MatchLineupTab extends StatelessWidget {
  const MatchLineupTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchDetailProvider>();
    final match = provider.match;
    final lineups = provider.lineups;

    if (lineups.isEmpty || match == null) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.theFieldIsQuiteEmpty),
        ],
      );
    }

    final home = lineups
        .where((l) =>
            l.teamId == match.homeId && (l.positionField ?? '').isNotEmpty)
        .toList(growable: false);
    final away = lineups
        .where((l) =>
            l.teamId == match.awayId && (l.positionField ?? '').isNotEmpty)
        .toList(growable: false);

    final subs = provider.events
        .where((e) => e.typeName == 'Substitution')
        .toList(growable: false);

    return ListView(
      children: [
        Container(
          height: 680,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.sdp(12),
            vertical: AppDimens.sdp(12),
          ),
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg_team_pick.webp'),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 300,
                child: TeamPitch(
                  players: home,
                  events: provider.events,
                  isHome: true,
                ),
              ),
              SizedBox(
                height: 300,
                child: TeamPitch(
                  players: away,
                  events: provider.events,
                  isHome: false,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppDimens.sdp(24)),
        Padding(
          padding: EdgeInsets.only(
            left: AppDimens.sdp(16),
            right: AppDimens.sdp(16),
            top: AppDimens.sdp(16),
            bottom: AppDimens.sdp(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Substitutions',
                style: AppTextStyles.semiBold(
                  size: AppDimens.ssp(14),
                  color: AppColors.text500,
                ),
              ),
              SizedBox(height: AppDimens.sdp(12)),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SubsColumn(
                        title: 'Home',
                        alignEnd: false,
                        events: subs
                            .where((e) => e.teamId == match.homeId)
                            .toList(growable: false),
                      ),
                    ),
                    Container(
                      width: AppDimens.sdp(1),
                      margin: EdgeInsets.symmetric(
                        horizontal: AppDimens.sdp(12),
                      ),
                      color: const Color(0x33FFFFFF),
                    ),
                    Expanded(
                      child: _SubsColumn(
                        title: 'Away',
                        alignEnd: true,
                        events: subs
                            .where((e) => e.teamId == match.awayId)
                            .toList(growable: false),
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

class _SubsColumn extends StatelessWidget {
  const _SubsColumn({
    required this.title,
    required this.alignEnd,
    required this.events,
  });

  final String title;
  final bool alignEnd;
  final List<MatchEventDto> events;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.semiBold(
              size: AppDimens.ssp(12),
              color: AppColors.text500,
            ),
          ),
          SizedBox(height: AppDimens.sdp(8)),
          for (final event in events)
            _SubstitutionEvent(event: event, alignEnd: alignEnd),
        ],
      );
}

/// Port `item_substitution_event.xml`: phút 10ssp `text200`, dòng ra
/// `ic_sub_out` đỏ `#FF4B4B`, dòng vào `ic_sub_in` xanh `#00FF00`.
class _SubstitutionEvent extends StatelessWidget {
  const _SubstitutionEvent({required this.event, required this.alignEnd});

  final MatchEventDto event;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: AppDimens.sdp(4)),
              child: Text(
                "${event.minute}'",
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(10),
                  color: AppColors.text200,
                ),
              ),
            ),
            _SubLine(
              asset: 'assets/icons/ic_sub_out.svg',
              tint: const Color(0xFFFF4B4B),
              text: event.playerName ?? '',
              textColor: const Color(0xFFFF4B4B),
              alignEnd: alignEnd,
            ),
            SizedBox(height: AppDimens.sdp(4)),
            _SubLine(
              asset: 'assets/icons/ic_sub_in.svg',
              tint: const Color(0xFF00FF00),
              text: event.relatedPlayerName ?? '',
              textColor: AppColors.text500,
              alignEnd: alignEnd,
            ),
          ],
        ),
      );
}

class _SubLine extends StatelessWidget {
  const _SubLine({
    required this.asset,
    required this.tint,
    required this.text,
    required this.textColor,
    required this.alignEnd,
  });

  final String asset;
  final Color tint;
  final String text;
  final Color textColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      asset,
      width: AppDimens.sdp(14),
      height: AppDimens.sdp(14),
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
    );
    final label = Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: AppTextStyles.regular(
          size: AppDimens.ssp(11),
          color: textColor,
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignEnd
          ? [label, SizedBox(width: AppDimens.sdp(8)), icon]
          : [icon, SizedBox(width: AppDimens.sdp(8)), label],
    );
  }
}

/// Port `TeamPitchView.kt` + `view_team_pitch.xml`: 5 hàng chia đều, mỗi cầu
/// thủ chiếm một phần bằng nhau. Đội khách vẽ ngược hàng (5→1) để hai đội
/// quay mặt vào nhau.
class TeamPitch extends StatelessWidget {
  const TeamPitch({
    super.key,
    required this.players,
    required this.events,
    required this.isHome,
  });

  final List<MatchLineupDto> players;
  final List<MatchEventDto> events;
  final bool isHome;

  static int _row(MatchLineupDto p) =>
      int.tryParse((p.positionField ?? '').split(':').first) ?? 0;

  static int _col(MatchLineupDto p) {
    final parts = (p.positionField ?? '').split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final byRow = <int, List<MatchLineupDto>>{};
    for (final player in players) {
      final row = _row(player);
      if (row == 0) continue;
      byRow.putIfAbsent(row, () => []).add(player);
    }
    for (final list in byRow.values) {
      list.sort((a, b) => _col(a).compareTo(_col(b)));
    }

    final maxRow = byRow.keys.isEmpty
        ? 0
        : byRow.keys.reduce((a, b) => a > b ? a : b);
    final rowCount = maxRow >= 5 ? 5 : 4;
    final order = isHome
        ? [for (var i = 1; i <= rowCount; i++) i]
        : [for (var i = rowCount; i >= 1; i--) i];

    return Column(
      children: [
        for (final row in order)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final player in byRow[row] ?? const <MatchLineupDto>[])
                  Expanded(
                    child: _PitchPlayer(player: player, events: events),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Port `item_player_on_pitch.xml`: ảnh 26sdp bo tròn nền trắng, số áo + tên
/// 6ssp, các huy hiệu bàn thắng / thẻ / vào-ra sân dán quanh ảnh.
class _PitchPlayer extends StatelessWidget {
  const _PitchPlayer({required this.player, required this.events});

  final MatchLineupDto player;
  final List<MatchEventDto> events;

  @override
  Widget build(BuildContext context) {
    var goal = false;
    var yellow = false;
    var red = false;
    var subIn = false;
    var subOut = false;

    for (final event in events) {
      final samePlayer = event.playerId == player.playerId;
      final relatedIsPlayer = event.relatedPlayerName != null &&
          event.relatedPlayerName == player.playerName;
      if (!samePlayer && !relatedIsPlayer) continue;

      switch (event.typeName) {
        case 'Goal' || 'Penalty':
          if (samePlayer) goal = true;
        case 'Yellowcard':
          if (samePlayer) yellow = true;
        case 'Redcard' || 'Yellowred':
          if (samePlayer) red = true;
        case 'Substitution':
          if (samePlayer) {
            subOut = true;
          } else if (relatedIsPlayer) {
            subIn = true;
          }
      }
    }

    final avatar = AppDimens.sdp(26);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: AppDimens.sdp(5)),
        SizedBox(
          width: avatar + AppDimens.sdp(6),
          height: avatar + AppDimens.sdp(4),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: avatar,
                height: avatar,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: AppImage(
                  source: player.playerImageUrl,
                  fit: BoxFit.cover,
                  errorWidget: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF757575),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (goal)
                Positioned(
                  left: -AppDimens.sdp(2),
                  top: -AppDimens.sdp(2),
                  child: SvgPicture.asset(
                    'assets/icons/ic_ball.svg',
                    width: AppDimens.sdp(12),
                    height: AppDimens.sdp(12),
                  ),
                ),
              if (yellow)
                Positioned(
                  right: -AppDimens.sdp(2),
                  top: -AppDimens.sdp(2),
                  child: SvgPicture.asset(
                    'assets/icons/ic_yellow_card.svg',
                    width: AppDimens.sdp(10),
                    height: AppDimens.sdp(13),
                  ),
                ),
              if (red)
                Positioned(
                  right: -AppDimens.sdp(2),
                  top: AppDimens.sdp(11),
                  child: SvgPicture.asset(
                    'assets/icons/ic_red_card.svg',
                    width: AppDimens.sdp(10),
                    height: AppDimens.sdp(13),
                  ),
                ),
              if (subIn)
                Positioned(
                  right: -AppDimens.sdp(2),
                  bottom: -AppDimens.sdp(2),
                  child: SvgPicture.asset(
                    'assets/icons/ic_sub_in.svg',
                    width: AppDimens.sdp(12),
                    height: AppDimens.sdp(12),
                  ),
                ),
              if (subOut)
                Positioned(
                  left: -AppDimens.sdp(2),
                  bottom: -AppDimens.sdp(2),
                  child: SvgPicture.asset(
                    'assets/icons/ic_sub_out.svg',
                    width: AppDimens.sdp(12),
                    height: AppDimens.sdp(12),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: AppDimens.sdp(5)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.jerseyNumber != null) ...[
              Text(
                '${player.jerseyNumber}',
                maxLines: 1,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(6),
                  color: AppColors.text100,
                ),
              ),
              SizedBox(width: AppDimens.sdp(2)),
            ],
            Flexible(
              child: Text(
                player.playerName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(6),
                  color: AppColors.text500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

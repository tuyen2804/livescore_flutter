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
import '../../../widgets/detail_widgets.dart';

/// Port `presentation/detail/MatchInfoFragment.kt` + `fragment_match_info.xml`:
/// khối bình chọn (hai trạng thái) rồi tới dải "Match timeline" và danh sách
/// sự kiện. Bản gốc **không có** thẻ thông tin trận ở tab này.
class MatchInfoTab extends StatelessWidget {
  const MatchInfoTab({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchDetailProvider>();
    final match = provider.match;
    if (match == null) return AppEmptyView(message: s.theFieldIsQuiteEmpty);

    final events = provider.events.toList()
      ..sort((a, b) => a.minute.compareTo(b.minute));
    final vote = provider.vote;

    if (vote == null && events.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.theFieldIsQuiteEmpty),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(20)),
      children: [
        if (vote != null)
          Padding(
            padding: EdgeInsets.only(
              left: AppDimens.sdp(12),
              right: AppDimens.sdp(12),
              top: AppDimens.sdp(12),
            ),
            child: provider.isVoted
                ? _VotedCard(
                    vote: vote,
                    homeName: match.homeName ?? '',
                    awayName: match.awayName ?? '',
                    homeLogo: match.homeTeamLogoUrl,
                    awayLogo: match.awayTeamLogoUrl,
                  )
                : _VotePickCard(
                    homeName: match.homeName ?? '',
                    awayName: match.awayName ?? '',
                    homeLogo: match.homeTeamLogoUrl,
                    awayLogo: match.awayTeamLogoUrl,
                    enabled: provider.isPredictionAvailable,
                    onVote: (choice) => provider.voteTeam(matchId, choice),
                  ),
          ),
        if (events.isNotEmpty) ...[
          SizedBox(height: AppDimens.sdp(12)),
          _TimelineHeader(title: s.matchTimeline),
          SizedBox(height: AppDimens.sdp(12)),
          for (final event in events)
            _TimelineRow(event: event, homeId: match.homeId),
        ],
      ],
    );
  }
}

/// `ctrInfor`: hai vạch gradient `divider_gradient_timeline` kẹp tiêu đề
/// 14ssp bold, tiêu đề cách hai bên 12sdp.
class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: TimelineGradientLine(fadeFromStart: true)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
            child: Text(
              title,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(14),
                color: AppColors.text500,
              ),
            ),
          ),
          const Expanded(child: TimelineGradientLine(fadeFromStart: false)),
        ],
      );
}

/// Port `ctrVoteTeam`: tiêu đề 16ssp bold accent, mô tả 11ssp text100,
/// rồi 3 ô `bg_vote_unselected` (#2A2A30, bo 24sdp) chia đều.
class _VotePickCard extends StatelessWidget {
  const _VotePickCard({
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
    required this.enabled,
    required this.onVote,
  });

  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;
  final bool enabled;
  final void Function(int choice) onVote;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(12),
        vertical: AppDimens.sdp(16),
      ),
      child: Column(
        children: [
          Text(
            s.whoWillWins,
            textAlign: TextAlign.center,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(16),
              color: AppColors.brandAccent,
            ),
          ),
          SizedBox(height: AppDimens.sdp(4)),
          Text(
            s.cheerForYourSideWillTheyConquerCrumbleOrHoldTheLine,
            textAlign: TextAlign.center,
            style: AppTextStyles.regular(
              size: AppDimens.ssp(11),
              color: AppColors.text100,
            ),
          ),
          SizedBox(height: AppDimens.sdp(20)),
          Row(
            children: [
              Expanded(
                child: _VoteOption(
                  label: homeName,
                  logo: homeLogo,
                  onTap: enabled ? () => onVote(1) : null,
                ),
              ),
              SizedBox(width: AppDimens.sdp(8)),
              Expanded(
                child: _VoteOption(
                  label: s.drawText,
                  asset: 'assets/icons/ic_draw.svg',
                  onTap: enabled ? () => onVote(2) : null,
                ),
              ),
              SizedBox(width: AppDimens.sdp(8)),
              Expanded(
                child: _VoteOption(
                  label: awayName,
                  logo: awayLogo,
                  onTap: enabled ? () => onVote(3) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteOption extends StatelessWidget {
  const _VoteOption({
    required this.label,
    required this.onTap,
    this.logo,
    this.asset,
  });

  final String label;
  final VoidCallback? onTap;
  final String? logo;
  final String? asset;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(
            top: AppDimens.sdp(18),
            bottom: AppDimens.sdp(16),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A30),
            borderRadius: BorderRadius.circular(AppDimens.sdp(24)),
          ),
          child: Column(
            children: [
              asset != null
                  ? SvgPicture.asset(
                      asset!,
                      width: AppDimens.sdp(29),
                      height: AppDimens.sdp(29),
                    )
                  : AppImage(
                      source: logo,
                      width: AppDimens.sdp(32),
                      height: AppDimens.sdp(32),
                      placeholderAsset: 'assets/icons/ic_ball.svg',
                    ),
              SizedBox(height: AppDimens.sdp(8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(4)),
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: AppColors.text100,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Port `ctrVoted`: hai đội hai bên với "VS" ở giữa, thanh
/// `MatchStatBarView` rồi dòng tổng số phiếu.
class _VotedCard extends StatelessWidget {
  const _VotedCard({
    required this.vote,
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
  });

  final MatchVoteDto vote;
  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
      ),
      padding: EdgeInsets.all(AppDimens.sdp(16)),
      child: Column(
        children: [
          Row(
            children: [
              AppImage(
                source: homeLogo,
                width: AppDimens.sdp(32),
                height: AppDimens.sdp(32),
                placeholderAsset: 'assets/icons/ic_ball.svg',
              ),
              SizedBox(width: AppDimens.sdp(8)),
              Expanded(
                child: Text(
                  homeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.semiBold(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  ),
                ),
              ),
              Text(
                'VS',
                style: AppTextStyles.bold(
                  size: AppDimens.ssp(10),
                  color: AppColors.text200,
                ),
              ),
              Expanded(
                child: Text(
                  awayName,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.semiBold(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  ),
                ),
              ),
              SizedBox(width: AppDimens.sdp(8)),
              AppImage(
                source: awayLogo,
                width: AppDimens.sdp(32),
                height: AppDimens.sdp(32),
                placeholderAsset: 'assets/icons/ic_ball.svg',
              ),
            ],
          ),
          SizedBox(height: AppDimens.sdp(20)),
          MatchStatBar(
            home: vote.countTeam1Win,
            draw: vote.countDraws,
            away: vote.countTeam2Win,
          ),
          SizedBox(height: AppDimens.sdp(12)),
          Text(
            s.totalVotesFormat(vote.total),
            style: AppTextStyles.regular(
              size: AppDimens.ssp(10),
              color: AppColors.text200,
            ),
          ),
        ],
      ),
    );
  }
}

/// Port `item_match_timeline.xml`: phút nằm giữa trong viên `#8ADB83`,
/// bên có sự kiện hiện tên + icon + vạch gradient, bên kia để trống.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.homeId});

  final MatchEventDto event;
  final int homeId;

  static const Map<String, String> _icons = {
    'yellowcard': 'assets/icons/ic_yellow_card.svg',
    'redcard': 'assets/icons/ic_red_card.svg',
    'substitution': 'assets/icons/ic_substitution.svg',
    'goal': 'assets/icons/ic_ball.svg',
    'penalty': 'assets/icons/ic_ball.svg',
  };

  @override
  Widget build(BuildContext context) {
    final isHome = event.teamId == homeId;
    final type = (event.typeName ?? '').toLowerCase();
    final icon = _icons[type] ?? 'assets/icons/ic_ball.svg';
    final isSub = type == 'substitution';
    final extra = (event.extraMinute ?? 0) > 0 ? '+${event.extraMinute}' : '';

    final name = _NameBlock(
      isSub: isSub,
      alignEnd: isHome,
      playerName: event.playerName ?? '',
      relatedName: event.relatedPlayerName,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(10),
        vertical: AppDimens.ssp(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: isHome ? 1 : 0,
              child: Padding(
                padding: EdgeInsets.only(right: AppDimens.sdp(10)),
                child: Row(
                  children: [
                    Expanded(flex: 7, child: name),
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDimens.sdp(6),
                        right: AppDimens.sdp(4),
                      ),
                      child: SvgPicture.asset(
                        icon,
                        height: AppDimens.sdp(20),
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: TimelineGradientLine(fadeFromStart: false),
                    ),
                    SizedBox(width: AppDimens.sdp(4)),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.sdp(10),
              vertical: AppDimens.sdp(2),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF8ADB83),
              borderRadius: BorderRadius.circular(AppDimens.sdp(30)),
            ),
            child: Text(
              "${event.minute}$extra'",
              style: AppTextStyles.medium(
                size: AppDimens.ssp(10),
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: isHome ? 0 : 1,
              child: Padding(
                padding: EdgeInsets.only(left: AppDimens.sdp(10)),
                child: Row(
                  children: [
                    SizedBox(width: AppDimens.sdp(4)),
                    const Expanded(
                      flex: 2,
                      child: TimelineGradientLine(fadeFromStart: true),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: AppDimens.sdp(6),
                        right: AppDimens.sdp(4),
                      ),
                      child: SvgPicture.asset(
                        icon,
                        height: AppDimens.sdp(20),
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(flex: 7, child: name),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thay người thì hiện hai dòng (vào 10ssp `text500`, ra 8ssp `#aaaaaa`),
/// còn lại chỉ một dòng 10ssp `text100`.
class _NameBlock extends StatelessWidget {
  const _NameBlock({
    required this.isSub,
    required this.alignEnd,
    required this.playerName,
    required this.relatedName,
  });

  final bool isSub;
  final bool alignEnd;
  final String playerName;
  final String? relatedName;

  @override
  Widget build(BuildContext context) {
    if (!isSub) {
      return Text(
        playerName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: AppTextStyles.medium(
          size: AppDimens.ssp(10),
          color: AppColors.text100,
        ),
      );
    }
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          playerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(10),
            color: AppColors.text500,
          ),
        ),
        Text(
          relatedName ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(8),
            color: const Color(0xFFAAAAAA),
          ),
        ),
      ],
    );
  }
}

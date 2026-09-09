import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'widgets/sofa_detail_header.dart';
import 'widgets/sofa_widgets.dart';

/// Port `presentation/SofascoreTeamDetailActivity.kt` +
/// `activity_sofascore_team_detail.xml`: header 74sdp (logo 32sdp · tên 15ssp ·
/// hạng mục 10ssp · chuông 26sdp) → tab cố định 36sdp → danh sách có kéo làm mới.
class SofascoreTeamDetailScreen extends StatelessWidget {
  const SofascoreTeamDetailScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.sportSlug,
  });

  final int teamId;
  final String teamName;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SofascoreTeamDetailProvider(sl())..load(teamId),
        child: _View(
          teamId: teamId,
          teamName: teamName,
          sportSlug: sportSlug,
        ),
      );
}

class _View extends StatefulWidget {
  const _View({
    required this.teamId,
    required this.teamName,
    required this.sportSlug,
  });

  final int teamId;
  final String teamName;
  final String sportSlug;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<SofascoreTeamDetailProvider>();

    final team = provider.team['team'];
    final name = team is Map ? '${team['name'] ?? widget.teamName}' : widget.teamName;
    final category = team is Map
        ? '${team['category']?['name'] ?? team['country']?['name'] ?? ''}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SofaDetailHeader(
            logoUrl: ApiConstants.teamLogo(widget.teamId),
            title: name,
            subtitle: category,
            trailing: SizedBox(
              width: AppDimens.sdp(26),
              height: AppDimens.sdp(26),
              child: Padding(
                padding: EdgeInsets.all(AppDimens.sdp(4)),
                child: SvgPicture.asset(
                  'assets/icons/ic_notihome.svg',
                  colorFilter: const ColorFilter.mode(
                    AppColors.text200,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          SofaFixedTabs(
            labels: [s.subtabUpcoming, s.subtabFinished, s.squad],
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: provider.isLoading
                ? const AppLoading()
                : RefreshIndicator(
                    color: AppColors.brandAccent,
                    backgroundColor: AppColors.itemBg,
                    onRefresh: () => provider.load(widget.teamId),
                    child: switch (_tab) {
                      0 => _EventList(
                          events: provider.nextEvents,
                          sportSlug: widget.sportSlug,
                        ),
                      1 => _EventList(
                          events: provider.lastEvents,
                          sportSlug: widget.sportSlug,
                        ),
                      _ => _Squad(players: provider.squad),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({required this.events, required this.sportSlug});

  final List<SofascoreEvent> events;
  final String sportSlug;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (events.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.noData, icon: Icons.event_busy),
        ],
      );
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(14),
        right: AppDimens.sdp(14),
        top: AppDimens.sdp(10),
        bottom: 16,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return SofaEventRow(
          event: event,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.sofascoreMatchDetail,
            arguments: {
              'eventId': event.id,
              'sportSlug':
                  event.sportSlug.isNotEmpty ? event.sportSlug : sportSlug,
            },
          ),
        );
      },
    );
  }
}

class _Squad extends StatelessWidget {
  const _Squad({required this.players});

  final List<Map<String, dynamic>> players;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (players.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.noData, icon: Icons.groups_outlined),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(14),
        right: AppDimens.sdp(14),
        top: AppDimens.sdp(10),
        bottom: 16,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final id = (player['id'] as num?)?.toInt();
        return GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.playerDetail,
            arguments: {
              'playerName': '${player['name'] ?? ''}',
              'playerPos': '${player['position'] ?? ''}',
              'playerImg': id == null ? null : ApiConstants.playerImage(id),
              'teamName': '${player['team']?['name'] ?? ''}',
            },
          ),
          child: Container(
            margin: EdgeInsets.only(bottom: AppDimens.sdp(8)),
            padding: EdgeInsets.all(AppDimens.sdp(10)),
            decoration: BoxDecoration(
              color: AppColors.itemBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AppImage(
                  source: id == null ? null : ApiConstants.playerImage(id),
                  width: AppDimens.sdp(30),
                  height: AppDimens.sdp(30),
                  borderRadius: BorderRadius.circular(AppDimens.sdp(15)),
                ),
                SizedBox(width: AppDimens.sdp(10)),
                Expanded(
                  child: Text(
                    '${player['name'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(12),
                      color: AppColors.text500,
                    ),
                  ),
                ),
                if (player['jerseyNumber'] != null)
                  Text(
                    '#${player['jerseyNumber']}',
                    style: AppTextStyles.semiBold(
                      size: AppDimens.ssp(11),
                      color: AppColors.brandAccent,
                    ),
                  ),
                SizedBox(width: AppDimens.sdp(8)),
                Text(
                  '${player['position'] ?? ''}',
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

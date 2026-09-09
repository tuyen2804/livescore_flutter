import 'package:flutter/material.dart';
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

/// Port `presentation/UniqueTournamentActivity.kt` + `activity_unique_tournament.xml`:
/// header 74sdp (logo · tên · hạng mục · nút chọn mùa) → 2 tab viên thuốc
/// Fixtures / Table → nội dung cuộn.
/// Tab Fixtures: "Upcoming Matches" rồi "Recent Matches".
/// Tab Table: "Participating Teams" (hàng ngang) rồi bảng xếp hạng.
class UniqueTournamentScreen extends StatelessWidget {
  const UniqueTournamentScreen({
    super.key,
    required this.uniqueTournamentId,
    required this.name,
    required this.sportSlug,
  });

  final int uniqueTournamentId;
  final String name;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) =>
            UniqueTournamentProvider(sl())..load(uniqueTournamentId),
        child: _View(
          uniqueTournamentId: uniqueTournamentId,
          name: name,
          sportSlug: sportSlug,
        ),
      );
}

class _View extends StatefulWidget {
  const _View({
    required this.uniqueTournamentId,
    required this.name,
    required this.sportSlug,
  });

  final int uniqueTournamentId;
  final String name;
  final String sportSlug;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  int _tab = 0;

  Future<void> _pickSeason(UniqueTournamentProvider provider) async {
    if (provider.seasons.isEmpty) return;
    final picked = await showModalBottomSheet<SeasonInfo>(
      context: context,
      backgroundColor: AppColors.itemBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final season in provider.seasons)
              ListTile(
                onTap: () => Navigator.of(context).pop(season),
                title: Text(
                  season.year ?? season.name,
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(13),
                    color: season.id == provider.selectedSeason?.id
                        ? AppColors.brandAccent
                        : AppColors.text500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await provider.selectSeason(widget.uniqueTournamentId, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<UniqueTournamentProvider>();
    final isTable = _tab == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SofaDetailHeader(
            logoUrl: ApiConstants.uniqueTournamentLogo(widget.uniqueTournamentId),
            title: widget.name,
            subtitle: widget.sportSlug,
            logoSize: 28,
            trailing: provider.seasons.isEmpty
                ? null
                : SeasonPickerButton(
                    label: provider.selectedSeason?.year ??
                        provider.selectedSeason?.name ??
                        '',
                    onTap: () => _pickSeason(provider),
                  ),
          ),
          SizedBox(height: AppDimens.sdp(14)),
          SegmentedTabs(
            tabs: [s.fixtures, s.table],
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          SizedBox(height: AppDimens.sdp(14)),
          if (isTable && provider.standingRows.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
              child: const SofaStandingHeader(),
            ),
          Expanded(
            child: provider.isLoading
                ? const AppLoading()
                : Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
                    child: isTable
                        ? _TableTab(provider: provider)
                        : _FixturesTab(
                            provider: provider,
                            sportSlug: widget.sportSlug,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FixturesTab extends StatelessWidget {
  const _FixturesTab({required this.provider, required this.sportSlug});

  final UniqueTournamentProvider provider;
  final String sportSlug;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (provider.nextEvents.isEmpty && provider.lastEvents.isEmpty) {
      return AppEmptyView(message: s.noData, icon: Icons.event_busy);
    }

    return ListView(
      padding: EdgeInsets.only(
        top: AppDimens.sdp(10),
        bottom: AppDimens.sdp(16),
      ),
      children: [
        _SectionLabel(text: s.subtabUpcoming),
        if (provider.nextEvents.isEmpty)
          _EmptyLine(text: s.noUpcomingMatches)
        else
          for (final event in provider.nextEvents)
            _Row(event: event, sportSlug: sportSlug),
        SizedBox(height: AppDimens.sdp(16)),
        _SectionLabel(text: s.subtabFinished),
        if (provider.lastEvents.isEmpty)
          _EmptyLine(text: s.noRecentMatches)
        else
          for (final event in provider.lastEvents)
            _Row(event: event, sportSlug: sportSlug),
      ],
    );
  }
}

class _TableTab extends StatelessWidget {
  const _TableTab({required this.provider});

  final UniqueTournamentProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final teams = provider.participatingTeams;
    if (provider.standingRows.isEmpty && teams.isEmpty) {
      return AppEmptyView(message: s.noData, icon: Icons.table_chart_outlined);
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        if (teams.isNotEmpty) ...[
          _SectionLabel(text: s.teams),
          SizedBox(
            height: AppDimens.sdp(64),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.sofascoreTeamDetail,
                    arguments: {
                      'teamId': team.id,
                      'teamName': team.name,
                      'sportSlug': '',
                    },
                  ),
                  child: SizedBox(
                    width: AppDimens.sdp(56),
                    child: Column(
                      children: [
                        AppImage(
                          source: team.logoUrl,
                          width: AppDimens.sdp(32),
                          height: AppDimens.sdp(32),
                          placeholderAsset: 'assets/icons/ic_ball.svg',
                        ),
                        SizedBox(height: AppDimens.sdp(4)),
                        Text(
                          team.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.regular(
                            size: AppDimens.ssp(9),
                            color: AppColors.text100,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: AppDimens.sdp(16)),
        ],
        for (final row in provider.standingRows) SofaStandingRow(row: row),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: AppDimens.sdp(8)),
        child: Text(
          text,
          style: AppTextStyles.medium(
            size: AppDimens.ssp(13),
            color: AppColors.text500,
          ),
        ),
      );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
        child: Text(
          text,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(11),
            color: AppColors.textSecondary,
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.event, required this.sportSlug});

  final SofascoreEvent event;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => SofaEventRow(
        event: event,
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.sofascoreMatchDetail,
          arguments: {
            'eventId': event.id,
            'sportSlug': event.sportSlug.isNotEmpty ? event.sportSlug : sportSlug,
          },
        ),
      );
}

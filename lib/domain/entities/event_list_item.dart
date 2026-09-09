import 'package:equatable/equatable.dart';

import '../../data/models/sofascore/sofascore_models.dart';

/// Port 1:1 của `data/sofascore/EventListItem.kt`.
sealed class EventListItem extends Equatable {
  const EventListItem();
}

class SectionHeaderItem extends EventListItem {
  const SectionHeaderItem({
    required this.sectionTitle,
    this.categoryId = 0,
    this.iconText = '🌍',
    this.countText = '',
    this.isExpanded = true,
  });

  final String sectionTitle;
  final int categoryId;
  final String iconText;
  final String countText;
  final bool isExpanded;

  SectionHeaderItem copyWith({bool? isExpanded}) => SectionHeaderItem(
        sectionTitle: sectionTitle,
        categoryId: categoryId,
        iconText: iconText,
        countText: countText,
        isExpanded: isExpanded ?? this.isExpanded,
      );

  @override
  List<Object?> get props => [sectionTitle, categoryId, countText, isExpanded];
}

class TournamentSubHeaderItem extends EventListItem {
  const TournamentSubHeaderItem({
    required this.tournamentName,
    required this.categoryName,
    this.logoUrl,
    this.uniqueTournamentId = 0,
    this.isPinned = false,
    this.isExpanded = true,
  });

  final String tournamentName;
  final String categoryName;
  final String? logoUrl;
  final int uniqueTournamentId;
  final bool isPinned;
  final bool isExpanded;

  TournamentSubHeaderItem copyWith({bool? isExpanded, bool? isPinned}) =>
      TournamentSubHeaderItem(
        tournamentName: tournamentName,
        categoryName: categoryName,
        logoUrl: logoUrl,
        uniqueTournamentId: uniqueTournamentId,
        isPinned: isPinned ?? this.isPinned,
        isExpanded: isExpanded ?? this.isExpanded,
      );

  @override
  List<Object?> get props =>
      [tournamentName, categoryName, uniqueTournamentId, isPinned, isExpanded];
}

class MatchItem extends EventListItem {
  const MatchItem(this.event);
  final SofascoreEvent event;

  @override
  List<Object?> get props => [
        event.id,
        event.status?.type,
        event.homeScore?.current,
        event.awayScore?.current,
      ];
}

class StageSeriesItem extends EventListItem {
  const StageSeriesItem({required this.uniqueStage, required this.hasChildren});
  final UniqueStage uniqueStage;
  final bool hasChildren;

  @override
  List<Object?> get props => [uniqueStage.id, hasChildren];
}

class StageRaceItem extends EventListItem {
  const StageRaceItem({required this.stage, required this.isLastInSeries});
  final SofascoreStage stage;
  final bool isLastInSeries;

  @override
  List<Object?> get props => [stage.id, isLastInSeries];
}

class CyclingRaceItem extends EventListItem {
  const CyclingRaceItem(this.stage);
  final SofascoreStage stage;

  @override
  List<Object?> get props => [stage.id];
}

class OrganisationItem extends EventListItem {
  const OrganisationItem(this.uniqueTournament);
  final UniqueTournament uniqueTournament;

  @override
  List<Object?> get props => [uniqueTournament.id];
}

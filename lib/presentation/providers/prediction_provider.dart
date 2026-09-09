import 'dart:async';

import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../domain/entities/match_entities.dart';
import '../../domain/repositories/football_repository.dart';
import 'base_provider.dart';

/// Port `presentation/prediction/PredictionViewModel.kt`.
/// Chỉ dùng API bóng đá; xếp giải yêu thích → đội yêu thích → giải top,
/// rồi theo giờ bóng lăn GIẢM DẦN (khác màn Home).
class PredictionProvider extends BaseProvider {
  PredictionProvider(this._football, this._db) {
    unawaited(fetchDataForSelectedDate());
  }

  final FootballRepository _football;
  final LeagueDbHelper _db;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Failure? _failure;
  List<LeagueSection> _leagueFixtures = const [];

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  List<LeagueSection> get leagueFixtures => _leagueFixtures;
  bool get isEmpty => _leagueFixtures.isEmpty;

  List<DateTime> get dateStrip {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return [for (var i = -3; i <= 3; i++) base.add(Duration(days: i))];
  }

  void changeDateByAmount(int amount) {
    _selectedDate = _selectedDate.add(Duration(days: amount));
    notifyListeners();
    unawaited(fetchDataForSelectedDate());
  }

  void setDate(DateTime date) {
    if (DateTimeUtils.isSameDay(date, _selectedDate)) return;
    _selectedDate = date;
    notifyListeners();
    unawaited(fetchDataForSelectedDate());
  }

  Future<void> refreshData() => fetchDataForSelectedDate();

  Future<void> fetchDataForSelectedDate() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await _football.getLeagueLive(_selectedDate);
    await result.fold(
      (failure) async => setState(() {
        _failure = failure;
        _leagueFixtures = const [];
      }),
      (sections) async {
        final ordered = await _orderForPrediction(sections);
        setState(() => _leagueFixtures = ordered);
      },
    );

    setState(() => _isLoading = false);
  }

  /// Bản gốc sắp theo `m2.kickoffEpoch.compareTo(m1.kickoffEpoch)` — mới nhất
  /// lên trước, và không tách nhóm "môn khác" như màn Home.
  Future<List<LeagueSection>> _orderForPrediction(
    List<LeagueSection> sections,
  ) async {
    final favLeagues = (await _db.getFavouriteLeagues()).map((e) => e.id).toSet();
    final topLeagues = (await _db.getAllLeagues())
        .where((e) => e.priority != null)
        .map((e) => e.id)
        .toSet();

    int rank(LeagueSection s) {
      if (favLeagues.contains(s.leagueId)) return 0;
      if (topLeagues.contains(s.leagueId)) return 1;
      return 2;
    }

    final ordered = sections
        .map((s) => s.copyWith(
              fixtures: s.fixtures.toList()
                ..sort((a, b) => _epoch(b).compareTo(_epoch(a))),
            ))
        .toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    return ordered;
  }

  int _epoch(MatchFixture f) => int.tryParse(f.kickoffUtc ?? '') ?? 0;
}

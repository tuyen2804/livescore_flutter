import 'dart:async';

import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/datasources/remote/football_remote_data_source.dart';
import '../../data/models/football/football_models.dart';
import 'base_provider.dart';

/// Port `presentation/highlight/HighlightViewModel.kt`.
/// Highlight lấy từ API bóng đá riêng (`/live-score/match-high-light`).
class HighlightProvider extends BaseProvider {
  HighlightProvider(this._remote) {
    unawaited(fetchHighlights());
  }

  final FootballRemoteDataSource _remote;

  List<HighlightDto> _highlights = const [];
  bool _isLoading = false;
  Failure? _failure;
  Set<String> _favouriteLeagueIds = const {};

  List<HighlightDto> get highlights => _highlights;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  /// 5 mục đầu làm banner trượt ngang.
  List<HighlightDto> get banners => _highlights.take(5).toList(growable: false);

  /// 10 mục đầu ở khối "Popular".
  List<HighlightDto> get popularHighlights =>
      _highlights.take(10).toList(growable: false);

  List<HighlightDto> get favoriteHighlights => _highlights
      .where((h) => _favouriteLeagueIds.contains('${h.leagueId}'))
      .toList(growable: false);

  /// Nhóm theo giải để dựng các hàng ngang như `HighlightGroupAdapter`.
  Map<String, List<HighlightDto>> get groupedByLeague {
    final map = <String, List<HighlightDto>>{};
    for (final h in _highlights) {
      map.putIfAbsent(h.leagueName, () => <HighlightDto>[]).add(h);
    }
    return map;
  }

  void setFavouriteLeagueIds(Set<String> ids) {
    _favouriteLeagueIds = ids;
    notifyListeners();
  }

  Future<void> fetchHighlights({DateTime? date}) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });
    try {
      final list = await _remote.getHighlights(
        DateTimeUtils.apiDate(date ?? DateTime.now()),
      );
      setState(() => _highlights = list);
    } catch (e) {
      // Bản gốc nuốt lỗi và trả về danh sách rỗng.
      setState(() {
        _failure = UnknownFailure('$e');
        _highlights = const [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Tách videoId từ URL YouTube để lấy ảnh nền.
  static String? youtubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    }
    return uri.queryParameters['v'];
  }
}

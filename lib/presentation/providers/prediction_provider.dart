import 'dart:async';

import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/match_entities.dart';
import '../../domain/repositories/sofascore_repository.dart';
import 'base_provider.dart';

/// Port `presentation/prediction/PredictionViewModel.kt`.
/// Xếp giải yêu thích → giải top, rồi theo giờ bóng lăn GIẢM DẦN (khác Home).
///
/// Nguồn trận lấy từ Sofascore như màn Home — `getSportFeed('football', ...)`
/// đi qua nhánh feed ngày phân trang trong `HomeFeedLoader`.
class PredictionProvider extends BaseProvider {
  PredictionProvider(this._sofascore) {
    unawaited(fetchDataForSelectedDate());
  }

  final SofascoreRepository _sofascore;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Failure? _failure;
  List<LeagueSection> _leagueFixtures = const [];

  Timer? _dateDebounce;

  /// Bỏ phản hồi về muộn sau khi người dùng đã đổi ngày.
  int _loadToken = 0;

  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  List<LeagueSection> get leagueFixtures => _leagueFixtures;
  bool get isEmpty => _leagueFixtures.isEmpty;

  /// Dải ngày cho thanh chọn ngày: **một tháng trước → một tháng sau**.
  ///
  /// Bản gốc chỉ có 7 ngày (−3…+3). Lịch bóng đá thì cần xa hơn nhiều: vòng
  /// bảng cúp châu Âu cách nhau vài tuần, và người dùng hay dò ngược lại kết
  /// quả vòng trước.
  ///
  /// `DateStrip` tự cuộn tới ngày đang chọn nên danh sách dài không gây phiền.
  List<DateTime> get dateStrip {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return [
      for (var i = -_dateStripDays; i <= _dateStripDays; i++)
        base.add(Duration(days: i)),
    ];
  }

  /// Số ngày mỗi phía quanh hôm nay.
  static const int _dateStripDays = 30;

  void changeDateByAmount(int amount) {
    setDate(_selectedDate.add(Duration(days: amount)));
  }

  void setDate(DateTime date) {
    if (DateTimeUtils.isSameDay(date, _selectedDate)) return;
    _selectedDate = date;
    notifyListeners();
    // Hoãn một nhịp như màn Home: dải 61 ngày nên người dùng hay bấm liên tiếp,
    // mỗi lần nạp là ~27 request.
    _dateDebounce?.cancel();
    _dateDebounce = Timer(
      const Duration(milliseconds: 250),
      () => unawaited(fetchDataForSelectedDate()),
    );
  }

  @override
  void dispose() {
    _dateDebounce?.cancel();
    super.dispose();
  }

  Future<void> refreshData() => fetchDataForSelectedDate();

  Future<void> fetchDataForSelectedDate() async {
    final token = ++_loadToken;
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await _sofascore.getSportFeed('football', _selectedDate);
    if (token != _loadToken) return;
    await result.fold(
      (failure) async => setState(() {
        _failure = failure;
        _leagueFixtures = const [];
      }),
      (sections) async =>
          setState(() => _leagueFixtures = _orderForPrediction(sections)),
    );

    setState(() => _isLoading = false);
  }

  /// Giữ nguyên thứ tự giải mà feed đã xếp, chỉ đảo thứ tự trận trong giải.
  ///
  /// Bản gốc sắp theo `m2.kickoffEpoch.compareTo(m1.kickoffEpoch)` — trận mới
  /// nhất lên trước, ngược với Home. Đó là khác biệt cố ý của màn này: người
  /// dùng vào đây để xem trận vừa đá xong.
  ///
  /// Phần xếp hạng giải theo SQLite đã bỏ. Nó so `leagueId` với id giải yêu
  /// thích trong SQLite hệ **Sportmonks**, trong khi `leagueId` từ feed giờ là
  /// `uniqueTournamentId` của **Sofascore** — không bao giờ khớp, nên mọi giải
  /// đều rơi vào cùng một hạng và phép sắp xếp thành vô nghĩa. Thứ tự giải đã
  /// do `HomeFeedLoader` lo: giải ghim trước, rồi `userCount` × hệ số khu vực.
  List<LeagueSection> _orderForPrediction(List<LeagueSection> sections) {
    return sections
        .map((s) => s.copyWith(
              fixtures: s.fixtures.toList()
                ..sort((a, b) => _epoch(b).compareTo(_epoch(a))),
            ))
        .toList(growable: false);
  }

  /// `kickoffEpoch` là đường chính; `kickoffUtc` chỉ còn là lưới an toàn cho
  /// dữ liệu cũ nằm trong cache.
  int _epoch(MatchFixture f) => f.kickoffEpoch != 0
      ? f.kickoffEpoch
      : int.tryParse(f.kickoffUtc ?? '') ?? 0;
}

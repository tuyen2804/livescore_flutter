/// Quy đổi mã `state` của API bóng đá riêng sang nhãn trạng thái —
/// port bảng `when (match.state)` trong `HomeViewModel.processMatches`.
class MatchStatus {
  const MatchStatus._();

  static const String ns = 'NS';
  static const String live = 'LIVE';
  static const String ht = 'HT';
  static const String ft = 'FT';
  static const String aet = 'AET';
  static const String pen = 'PEN';
  static const String postp = 'POSTP';
  static const String cancl = 'CANCL';
  static const String tbd = 'TBD';

  /// Mã state được coi là "đang diễn ra hoặc đã bắt đầu" ở màn Live.
  static const List<int> liveStates = [2, 3, 4, 6, 7, 9, 21, 22, 23, 25];

  static String fromState(int state) => switch (state) {
        1 || 26 => ns,
        2 || 4 || 6 || 21 || 22 || 23 => live,
        3 => ht,
        5 || 17 || 8 => ft,
        7 => aet,
        9 || 25 => pen,
        10 || 11 || 16 || 18 => postp,
        12 || 14 || 15 || 20 => cancl,
        13 || 19 => tbd,
        _ => tbd,
      };

  /// Nhãn hiển thị ở thẻ live: HT/AET/PEN giữ nguyên, còn lại là phút thi đấu.
  static String liveLabel(int state, int playingTime) {
    final status = fromState(state);
    return switch (status) {
      ht => ht,
      aet => aet,
      pen => pen,
      _ => "$playingTime'",
    };
  }

  /// Thứ tự sắp xếp trong một giải: FT → POSTP → NS → còn lại.
  static int sortRank(String status) => switch (status) {
        ft => 0,
        postp => 1,
        ns => 2,
        _ => 3,
      };
}

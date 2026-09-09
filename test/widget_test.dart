import 'package:flutter_test/flutter_test.dart';

import 'package:live_score/core/utils/match_status.dart';
import 'package:live_score/core/utils/sport_presentation.dart';

void main() {
  group('MatchStatus', () {
    test('quy đổi state của API bóng đá sang nhãn', () {
      expect(MatchStatus.fromState(1), MatchStatus.ns);
      expect(MatchStatus.fromState(2), MatchStatus.live);
      expect(MatchStatus.fromState(3), MatchStatus.ht);
      expect(MatchStatus.fromState(5), MatchStatus.ft);
      expect(MatchStatus.fromState(7), MatchStatus.aet);
      expect(MatchStatus.fromState(9), MatchStatus.pen);
      expect(MatchStatus.fromState(10), MatchStatus.postp);
      expect(MatchStatus.fromState(12), MatchStatus.cancl);
      expect(MatchStatus.fromState(99), MatchStatus.tbd);
    });

    test('nhãn live hiện phút, trừ HT/AET/PEN', () {
      expect(MatchStatus.liveLabel(2, 64), "64'");
      expect(MatchStatus.liveLabel(3, 45), MatchStatus.ht);
      expect(MatchStatus.liveLabel(9, 90), MatchStatus.pen);
    });
  });

  group('SportPresentation', () {
    test('chỉ bóng đá không dùng Sofascore', () {
      expect(SportPresentation.usesSofascore('football'), isFalse);
      expect(SportPresentation.usesSofascore('tennis'), isTrue);
    });

    test('orderSports giữ thứ tự của bản gốc', () {
      final ordered = SportPresentation.orderSports([
        'tennis',
        'football',
        'cricket',
        'unknown-sport',
      ]);
      expect(ordered.first, 'football');
      expect(ordered.indexOf('tennis') < ordered.indexOf('cricket'), isTrue);
      expect(ordered.last, 'unknown-sport');
    });

    test('profile điểm số theo môn', () {
      expect(
        SportPresentation.homeScoreProfile('tennis'),
        HomeScoreProfile.tennisGameAndSets,
      );
      expect(
        SportPresentation.homeScoreProfile('motorsport'),
        HomeScoreProfile.stage,
      );
    });
  });
}

/// Port `domain/model/AdsConfig.kt` + `data/remote/model/AdsConfigDto.kt`.
///
/// JSON từ `api.gamesontop.com` có dạng:
/// ```json
/// { "data": { "rc_ads_from": 0,
///             "rc_ads_set": { "0": { "firstDelay": 30, "rewardDelay": 0,
///                                    "firstDelayType": 0, "rewardInterDelay": 0,
///                                    "adsIntersConfig": { "LiveScore_inter_Inapp": 25 } } } } }
/// ```
class AdsSet {
  const AdsSet({
    required this.firstDelay,
    required this.rewardDelay,
    required this.firstDelayType,
    required this.inters,
    required this.rewardInterDelay,
  });

  final int firstDelay;
  final int rewardDelay;
  final int firstDelayType;

  /// Khoảng cách giữa hai lần show inter, tính bằng giây, theo từng placement.
  /// `-1` = tắt hẳn, `0` = show mọi lúc.
  final Map<String, int> inters;
  final int rewardInterDelay;

  static int _int(dynamic v) => switch (v) {
        int() => v,
        num() => v.toInt(),
        String() => int.tryParse(v) ?? 0,
        _ => 0,
      };

  factory AdsSet.fromJson(Map<String, dynamic> json) => AdsSet(
        firstDelay: _int(json['firstDelay']),
        rewardDelay: _int(json['rewardDelay']),
        firstDelayType: _int(json['firstDelayType']),
        rewardInterDelay: _int(json['rewardInterDelay']),
        inters: switch (json['adsIntersConfig']) {
          final Map<String, dynamic> m =>
            m.map((k, v) => MapEntry(k, _int(v))),
          _ => const <String, int>{},
        },
      );

  Map<String, dynamic> toJson() => {
        'firstDelay': firstDelay,
        'rewardDelay': rewardDelay,
        'firstDelayType': firstDelayType,
        'rewardInterDelay': rewardInterDelay,
        'adsIntersConfig': inters,
      };

  @override
  String toString() => 'AdsSet(firstDelay: $firstDelay, rewardDelay: '
      '$rewardDelay, rewardInterDelay: $rewardInterDelay, inters: $inters)';
}

class AdsConfig {
  const AdsConfig({required this.adsSet, required this.adsFrom});

  /// Key là ngưỡng số lần mở app (`playout`) mà bộ cấu hình đó bắt đầu áp dụng.
  final Map<int, AdsSet> adsSet;
  final int adsFrom;

  static const AdsConfig empty = AdsConfig(adsSet: {}, adsFrom: 0);

  /// `AdsConfigRepositoryImpl.toDomain`: key nào không parse được sang số thì bỏ.
  factory AdsConfig.fromJson(Map<String, dynamic> json) {
    final raw = json['rc_ads_set'];
    final set = <int, AdsSet>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        final index = int.tryParse('$key');
        if (index != null && value is Map) {
          set[index] = AdsSet.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }
    return AdsConfig(
      adsSet: set,
      adsFrom: AdsSet._int(json['rc_ads_from']),
    );
  }

  Map<String, dynamic> toJson() => {
        'rc_ads_from': adsFrom,
        'rc_ads_set':
            adsSet.map((k, v) => MapEntry('$k', v.toJson())),
      };
}

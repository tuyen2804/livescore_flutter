import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../data/models/sofascore/match_prediction.dart';
import '../../providers/detail_providers.dart';

/// Màn dự đoán trận.
///
/// Khác bản gốc ở **nguồn dữ liệu**: `match-forecast-new` hỏng hoàn toàn nên
/// chuyển sang Sofascore. Ba nguồn được hiển thị **tách bạch, ghi rõ xuất xứ**:
///
/// 1. *Cộng đồng dự đoán* — số phiếu thật, có ở mọi trận (trận hạng thấp nhất
///    cũng ~8.600 phiếu).
/// 2. *Tỷ lệ theo nhà cái* — suy từ kèo 1X2, đã bỏ biên lợi nhuận.
/// 3. *Phân tích AI* — chỉ xuất hiện **sau khi trận kết thúc**; bản trước trận
///    của Sofascore đòi tài khoản đăng nhập nên không dùng được.
class MatchForecastScreen extends StatelessWidget {
  const MatchForecastScreen({
    super.key,
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.kickoffEpoch = 0,
    this.countryName,
  });

  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;

  /// Giờ bóng lăn (epoch giây) — dùng để dò đúng trận bên Sofascore.
  final int kickoffEpoch;

  /// Quốc gia của giải, giúp phân biệt các giải trùng tên.
  final String? countryName;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return ChangeNotifierProvider(
      create: (_) => MatchForecastProvider(sl())
        ..load(matchId: matchId, languageCode: locale),
      child: _ForecastView(
        homeTeamName: homeTeamName,
        awayTeamName: awayTeamName,
        homeTeamLogo: homeTeamLogo,
        awayTeamLogo: awayTeamLogo,
      ),
    );
  }
}

class _ForecastView extends StatelessWidget {
  const _ForecastView({
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
  });

  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchForecastProvider>();
    final data = provider.prediction;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        title: Text(
          s.matchPrediction,
          style: AppTextStyles.semiBold(
            size: AppDimens.ssp(16),
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: provider.isLoading
          ? const EarthLoadingOverlay(label: 'Loading')
          : ListView(
              padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
              children: [
                _MatchHeader(
                  homeName: homeTeamName,
                  awayName: awayTeamName,
                  homeLogo: homeTeamLogo,
                  awayLogo: awayTeamLogo,
                  confidence: _confidence(data),
                ),
                if (data == null || data.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: AppDimens.sdp(20)),
                    child: _NoPrediction(
                      title: s.noPredictionAvailable,
                      message: s
                          .theMatchHasEndedPredictionsAreOnlyAvailableForUpcomingOrLiveMatches,
                    ),
                  )
                else
                  ..._buildRows(context, s, data),
              ],
            ),
    );
  }

  /// Độ tin cậy = lựa chọn cao nhất của nguồn tốt nhất đang có.
  ///
  /// Ưu tiên AI (chính xác nhất, nhưng chỉ có sau trận), rồi tới kèo, cuối cùng
  /// là phiếu cộng đồng — để ô này gần như luôn có số.
  int? _confidence(MatchPrediction? d) {
    if (d == null) return null;
    final ai = d.ai?.winProbability;
    if (ai != null) return _maxOf(ai.home, ai.draw, ai.away);
    final odds = d.odds;
    if (odds != null) return _maxOf(odds.home, odds.draw, odds.away);
    final vote = d.communityVote;
    if (vote != null) {
      final p = vote.percents;
      return _maxOf(p[0], p[1], p[2]);
    }
    return null;
  }

  static int _maxOf(int a, int b, int c) => [a, b, c].reduce((x, y) => x > y ? x : y);

  /// Port `MatchForecastFragment.setupForecast` — mỗi mục là **một hàng gập
  /// được**, không phải thẻ riêng: icon 25dp · tiêu đề · giá trị · mũi tên.
  ///
  /// Hàng nào có chi tiết mới hiện mũi tên; hàng chỉ có một con số thì không
  /// gập được, đúng như `addPredictionItem(setupDetails = null)` bên Kotlin.
  List<Widget> _buildRows(BuildContext context, S s, MatchPrediction d) {
    final rows = <Widget>[];
    final vote = d.communityVote;
    final odds = d.odds;
    final ai = d.ai;

    // --- Kết quả trận ---
    final result = vote?.percents ??
        (odds == null ? null : [odds.home, odds.draw, odds.away]);
    if (result != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_match_result.svg',
        title: s.matchResultPredictions,
        value: _winnerLabel(s, result[0], result[1], result[2]),
        subtitle: vote == null
            ? s.aiMainPick
            : s.votesCountFormat(_thousands(vote.total)),
        details: [
          _SubRow(logoUrl: homeTeamLogo, name: homeTeamName, percent: '${result[0]}%'),
          _SubRow(asset: 'assets/icons/ic_ball.svg', name: s.drawText, percent: '${result[1]}%'),
          _SubRow(logoUrl: awayTeamLogo, name: awayTeamName, percent: '${result[2]}%'),
        ],
      ));
    }

    // --- Dự đoán của app ---
    //
    // Chỉ hiện khi **lệch đáng kể** so với phiếu cộng đồng. Trận một chiều thì
    // hai bên cho gần như cùng con số, thêm hàng nữa chỉ làm màn hình trông như
    // bị lặp nội dung.
    if (odds != null && vote != null && _differs(vote.percents, odds)) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_ai.svg',
        title: s.aiMainPick,
        value: _winnerLabel(s, odds.home, odds.draw, odds.away),
        details: [
          _SubRow(logoUrl: homeTeamLogo, name: homeTeamName, percent: '${odds.home}%'),
          _SubRow(asset: 'assets/icons/ic_ball.svg', name: s.drawText, percent: '${odds.draw}%'),
          _SubRow(logoUrl: awayTeamLogo, name: awayTeamName, percent: '${odds.away}%'),
        ],
      ));
    }

    // --- Bàn thắng đầu tiên ---
    final firstGoal = d.firstGoalVote;
    if (firstGoal != null) {
      final p = firstGoal.percents;
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_first_goal.svg',
        title: s.firstGoalPredictions,
        value: p[0] > p[1] && p[0] > p[2]
            ? s.homeText
            : (p[2] > p[1] && p[2] > p[0] ? s.awayText : s.noGoal),
        subtitle: s.votesCountFormat(_thousands(firstGoal.total)),
        details: [
          _SubRow(logoUrl: homeTeamLogo, name: homeTeamName, percent: '${p[0]}%'),
          _SubRow(asset: 'assets/icons/ic_ball.svg', name: s.noGoal, percent: '${p[1]}%'),
          _SubRow(logoUrl: awayTeamLogo, name: awayTeamName, percent: '${p[2]}%'),
        ],
      ));
    }

    // --- Các mục một giá trị, không gập ---
    if (ai?.homeScore != null && ai?.awayScore != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_match_score.svg',
        title: s.matchScorePredictions,
        value: '${ai!.homeScore} - ${ai.awayScore}',
      ));
    }
    if (ai?.totalGoals != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_total_goals.svg',
        title: s.totalGoalsPredictions,
        value: '${ai!.totalGoals}',
      ));
    }
    if (ai?.corners != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_corner_kick.svg',
        title: s.cornerPredictions,
        // Sofascore chỉ cho **tổng** phạt góc cả trận, không tách hai đội như
        // backend cũ — nên là một số chứ không phải "6 - 4".
        value: '${ai!.corners}',
      ));
    }

    final btts = d.bothTeamsToScoreVote;
    if (btts != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_ball.svg',
        title: s.bothTeamsToScore,
        value: btts.yesPercent >= 50 ? s.yesText : s.noText,
        details: [
          _SubRow(asset: 'assets/icons/ic_ball.svg', name: s.yesText, percent: '${btts.yesPercent}%'),
          _SubRow(asset: 'assets/icons/ic_ball.svg', name: s.noText, percent: '${100 - btts.yesPercent}%'),
        ],
      ));
    } else if (ai?.bothTeamsToScore != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_ball.svg',
        title: s.bothTeamsToScore,
        value: ai!.bothTeamsToScore! ? s.yesText : s.noText,
      ));
    }

    // --- Các mục suy ra cho trận chưa đá ---
    //
    // Nguồn số là `event/{id}/odds/1/all`, nhưng **không hiển thị dưới dạng
    // kèo cược**: không có chữ tài/xỉu, không có mức chấp, không có tỷ lệ
    // trả thưởng. Mỗi mục quy về một **khoảng dự đoán** ("3+ bàn", "0–9 phạt
    // góc") kèm phần trăm.
    //
    // Làm vậy vì hai lý do: thuật ngữ cá cược làm app bị nâng độ tuổi và dễ bị
    // từ chối trên store, và người xem tỉ số không cần đọc kèo.
    //
    // `marketId` ổn định hơn `marketName` vì tên đổi theo ngôn ngữ:
    // 9 = tổng bàn · 21 = phạt góc · 20 = thẻ · 3 = hiệp một.
    //
    // AI (sau trận) chính xác hơn nên nếu có thì lấy AI, bỏ phần suy ra.
    if (ai?.totalGoals == null) {
      _addThreshold(rows, d.markets, 9, 'assets/icons/ic_total_goals.svg',
          s.totalGoalsPredictions, '2.5', s.goalsText);
    }
    if (ai?.corners == null) {
      _addThreshold(rows, d.markets, 21, 'assets/icons/ic_corner_kick.svg',
          s.cornerPredictions, '9.5', s.cornersText);
    }
    _addThreshold(rows, d.markets, 20, 'assets/icons/ic_ball.svg',
        s.cardsText, '4.5', s.cardsText);
    _addMarket(rows, d.markets, 3, 'assets/icons/ic_match_score.svg',
        s.firstHalfText);

    // --- Thẻ phạt dự đoán (sau trận) ---
    if (ai?.yellowCards != null) {
      rows.add(_PredictionRow(
        icon: 'assets/icons/ic_ball.svg',
        title: 'Yellow cards',
        value: '${ai!.yellowCards}',
      ));
    }

    // --- Phân tích chữ ---
    if (ai != null && ai.sections.isNotEmpty) {
      rows.add(_AnalysisCard(
        title: s.inDepthAiAnalysis,
        sections: ai.sections,
      ));
    }

    return rows;
  }

  /// Quy một mức ngưỡng thành **khoảng dự đoán**, bỏ hẳn chữ Over/Under.
  ///
  /// Mức `2.5` với `Over` chiếm ưu thế → "3+ bàn"; `Under` ưu thế → "0–2 bàn".
  /// Người đọc thấy một dự đoán về trận, không thấy một cửa cược.
  void _addThreshold(
    List<Widget> rows,
    List<OddsMarket> markets,
    int marketId,
    String icon,
    String title,
    String group,
    String unit,
  ) {
    final market = OddsMarket.find(markets, marketId, group: group);
    if (market == null) return;

    final line = double.tryParse(group);
    if (line == null) return;
    final low = line.floor(); // 2.5 → 2
    final high = low + 1; // 2.5 → 3

    OddsChoice? over;
    OddsChoice? under;
    for (final c in market.choices) {
      final name = c.name.toLowerCase();
      if (name.startsWith('o')) over = c;
      if (name.startsWith('u')) under = c;
    }
    if (over == null || under == null) return;

    final overWins = over.percent >= under.percent;
    rows.add(_PredictionRow(
      icon: icon,
      title: title,
      value: overWins ? '$high+ $unit' : '0–$low $unit',
      details: [
        _SubRow(
          asset: 'assets/icons/ic_ball.svg',
          name: '$high+ $unit',
          percent: '${over.percent}%',
        ),
        _SubRow(
          asset: 'assets/icons/ic_ball.svg',
          name: '0–$low $unit',
          percent: '${under.percent}%',
        ),
      ],
    ));
  }

  /// Thêm một hàng dựng từ kèo, bỏ qua nếu trận không có market đó.
  ///
  /// Giá trị thu gọn là **cửa có xác suất cao nhất**, mở ra mới thấy đủ các
  /// cửa — giống hệt cách hàng "kết quả trận" hoạt động.
  void _addMarket(
    List<Widget> rows,
    List<OddsMarket> markets,
    int marketId,
    String icon,
    String title, {
    String? group,
  }) {
    final market = OddsMarket.find(markets, marketId, group: group);
    final best = market?.best;
    if (market == null || best == null) return;

    rows.add(_PredictionRow(
      icon: icon,
      title: group == null ? title : '$title $group',
      value: best.name,
      details: [
        for (final choice in market.choices)
          _SubRow(
            asset: 'assets/icons/ic_ball.svg',
            name: choice.name,
            percent: '${choice.percent}%',
          ),
      ],
    ));
  }

  /// Lệch từ 5 điểm phần trăm trở lên ở bất kỳ cửa nào mới coi là khác biệt
  /// đáng xem.
  static bool _differs(List<int> vote, OddsProbability odds) =>
      (vote[0] - odds.home).abs() >= 5 ||
      (vote[1] - odds.draw).abs() >= 5 ||
      (vote[2] - odds.away).abs() >= 5;

  /// Port khối `when` của `setupForecast`: hiện tên cửa thắng, không phải %.
  static String _winnerLabel(S s, int home, int draw, int away) {
    if (home > draw && home > away) return s.homeWin;
    if (away > draw && away > home) return s.awayWin;
    return s.drawText;
  }

  /// `80761` → `80,761` — số phiếu tới hàng chục nghìn, không tách thì khó đọc.
  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Port `ctrMatchHeader`: dòng "AI Main Pick" + độ tin cậy, dưới là hai ô đội
/// có viền với chữ VS ở giữa.
class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.homeName,
    required this.awayName,
    this.homeLogo,
    this.awayLogo,
    this.confidence,
  });

  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;
  final int? confidence;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(12),
        vertical: AppDimens.sdp(10),
      ),
      padding: EdgeInsets.all(AppDimens.sdp(12)),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_ai_pick.svg',
                width: AppDimens.sdp(14),
                height: AppDimens.sdp(14),
              ),
              SizedBox(width: AppDimens.sdp(6)),
              Expanded(
                child: Text(
                  s.aiMainPick,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: AppColors.text500,
                  ),
                ),
              ),
              if (confidence != null)
                Text(
                  s.confidenceFormat(confidence!),
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: AppColors.brandAccent,
                  ),
                ),
            ],
          ),
          SizedBox(height: AppDimens.sdp(12)),
          Row(
            children: [
              Expanded(child: _TeamBox(name: homeName, logo: homeLogo)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(8)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.sdp(8),
                    vertical: AppDimens.sdp(4),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor),
                    borderRadius: BorderRadius.circular(AppDimens.sdp(8)),
                  ),
                  child: Text(
                    'VS',
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(10),
                      color: AppColors.text500,
                    ),
                  ),
                ),
              ),
              Expanded(child: _TeamBox(name: awayName, logo: awayLogo)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Port `llHome` / `llAway`: nền viền bo 12, logo trên, tên dưới.
class _TeamBox extends StatelessWidget {
  const _TeamBox({required this.name, this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(10)),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
        ),
        child: Column(
          children: [
            AppImage(
              source: logo,
              width: AppDimens.sdp(34),
              height: AppDimens.sdp(34),
              placeholderAsset: 'assets/icons/ic_ball.svg',
            ),
            SizedBox(height: AppDimens.sdp(6)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(10),
                  color: AppColors.text500,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Port `item_forecast_predict.xml`.
class _PredictionRow extends StatefulWidget {
  const _PredictionRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.details = const [],
  });

  final String icon;
  final String title;
  final String value;
  final String? subtitle;
  final List<_SubRow> details;

  @override
  State<_PredictionRow> createState() => _PredictionRowState();
}

class _PredictionRowState extends State<_PredictionRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final expandable = widget.details.isNotEmpty;
    return Container(
      margin: EdgeInsets.only(
        left: AppDimens.sdp(12),
        right: AppDimens.sdp(12),
        bottom: AppDimens.sdp(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
          onTap: expandable ? () => setState(() => _open = !_open) : null,
          child: Padding(
            padding: EdgeInsets.all(AppDimens.sdp(15)),
            child: Column(
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      widget.icon,
                      width: AppDimens.sdp(25),
                      height: AppDimens.sdp(25),
                    ),
                    SizedBox(width: AppDimens.sdp(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.medium(
                              size: AppDimens.ssp(14),
                              color: AppColors.text200,
                            ),
                          ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: AppTextStyles.regular(
                                size: AppDimens.ssp(10),
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppDimens.sdp(10)),
                    Text(
                      widget.value,
                      style: AppTextStyles.semiBold(
                        size: AppDimens.ssp(14),
                        color: AppColors.brandAccent,
                      ),
                    ),
                    if (expandable) ...[
                      SizedBox(width: AppDimens.sdp(6)),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: SvgPicture.asset(
                          'assets/icons/ic_arrow_down.svg',
                          width: AppDimens.sdp(20),
                          height: AppDimens.sdp(20),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_open && expandable) ...[
                  SizedBox(height: AppDimens.sdp(10)),
                  ...widget.details,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Port `item_forecast_sub_row.xml`: icon 24dp · tên · phần trăm màu accent.
class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.name,
    required this.percent,
    this.logoUrl,
    this.asset,
  });

  final String name;
  final String percent;
  final String? logoUrl;
  final String? asset;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
        child: Row(
          children: [
            AppImage(
              source: logoUrl,
              width: AppDimens.sdp(24),
              height: AppDimens.sdp(24),
              placeholderAsset: asset ?? 'assets/icons/ic_ball.svg',
            ),
            SizedBox(width: AppDimens.sdp(8)),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(14),
                  color: AppColors.text200,
                ),
              ),
            ),
            Text(
              percent,
              style: AppTextStyles.semiBold(
                size: AppDimens.ssp(14),
                color: AppColors.brandAccent,
              ),
            ),
          ],
        ),
      );
}

/// Port `ctrAnalysis`: tiêu đề + đoạn văn dài.
class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.title, required this.sections});

  final String title;
  final List<AiSection> sections;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(
          left: AppDimens.sdp(12),
          right: AppDimens.sdp(12),
          bottom: AppDimens.sdp(10),
        ),
        padding: EdgeInsets.all(AppDimens.sdp(15)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.semiBold(
                size: AppDimens.ssp(14),
                color: AppColors.text500,
              ),
            ),
            for (final section in sections) ...[
              SizedBox(height: AppDimens.sdp(10)),
              if (section.subtitle.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: AppDimens.sdp(4)),
                  child: Text(
                    section.subtitle,
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(12),
                      color: AppColors.brandAccent,
                    ),
                  ),
                ),
              Text(
                section.text,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(12),
                  color: AppColors.text200,
                ),
              ),
            ],
          ],
        ),
      );
}

/// Port `ctrNoPrediction`: `ic_ball` 80dp + tiêu đề 16sp bold + mô tả 14sp.
class _NoPrediction extends StatelessWidget {
  const _NoPrediction({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_ball.svg',
            width: AppDimens.sdp(80),
            height: AppDimens.sdp(80),
          ),
          SizedBox(height: AppDimens.sdp(14)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(16),
              color: AppColors.text500,
            ),
          ),
          SizedBox(height: AppDimens.sdp(6)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(32)),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(14),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
}

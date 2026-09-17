import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/repositories/football_sofascore_repository.dart';
import '../../providers/detail_providers.dart';
import '../../widgets/settings_toolbar.dart';

/// Port `presentation/detail/PlayerDetailFragment.kt` +
/// `fragment_detail_player.xml`: toolbar 74sdp chỉ có nút back, ảnh 90sdp
/// nền `#e6e6e6`, tên 20ssp bold, rồi một thẻ `bg_league_grid_item` chứa
/// 8 dòng thông tin.
///
/// Dữ liệu vẫn đến qua arguments như trước (đội hình nguồn cũ không có id cầu
/// thủ nên chỉ có từng đó). Khi [playerId] có giá trị — đội hình lấy từ
/// Sofascore — màn tự gọi thêm hồ sơ để điền **chân thuận** và làm chính xác
/// các dòng còn lại; dòng "Prefer foot" trước đây luôn là "-".
class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({
    super.key,
    required this.playerName,
    required this.playerPos,
    required this.teamName,
    this.playerImg,
    this.playerHeight,
    this.playerWeight,
    this.playerAge,
    this.playerNumber,
    this.playerNationality,
    this.playerId,
  });

  final String playerName;
  final String playerPos;
  final String teamName;
  final String? playerImg;
  final String? playerHeight;
  final String? playerWeight;
  final String? playerAge;
  final String? playerNumber;
  final String? playerNationality;
  final int? playerId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PlayerDetailProvider(sl())..load(playerId),
        child: _PlayerDetailView(
          playerName: playerName,
          playerPos: playerPos,
          teamName: teamName,
          playerImg: playerImg,
          playerHeight: playerHeight,
          playerWeight: playerWeight,
          playerAge: playerAge,
          playerNumber: playerNumber,
          playerNationality: playerNationality,
        ),
      );
}

class _PlayerDetailView extends StatelessWidget {
  const _PlayerDetailView({
    required this.playerName,
    required this.playerPos,
    required this.teamName,
    this.playerImg,
    this.playerHeight,
    this.playerWeight,
    this.playerAge,
    this.playerNumber,
    this.playerNationality,
  });

  final String playerName;
  final String playerPos;
  final String teamName;
  final String? playerImg;
  final String? playerHeight;
  final String? playerWeight;
  final String? playerAge;
  final String? playerNumber;
  final String? playerNationality;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final profile = context.watch<PlayerDetailProvider>().profile;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          const SettingsToolbar(title: ''),
          SizedBox(height: AppDimens.sdp(16)),
          Container(
            width: AppDimens.sdp(90),
            height: AppDimens.sdp(90),
            color: const Color(0xFFE6E6E6),
            child: AppImage(source: playerImg, fit: BoxFit.cover),
          ),
          SizedBox(height: AppDimens.sdp(14)),
          Text(
            playerName.isEmpty ? s.unknown : playerName,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(20),
              color: AppColors.text500,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: AppDimens.sdp(14),
                right: AppDimens.sdp(14),
                top: AppDimens.sdp(20),
                bottom: AppDimens.sdp(10),
              ),
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.sdp(20),
                    vertical: AppDimens.sdp(18),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.itemBg,
                    borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
                  ),
                  child: Column(
                    children: [
                      // Hồ sơ Sofascore (nếu có) được ưu tiên, còn lại rơi
                      // về giá trị truyền sang từ màn đội hình.
                      _Row(
                        label: s.club,
                        value: profile?.teamName ?? teamName,
                        isFirst: true,
                      ),
                      _Row(
                        label: s.position,
                        value: profile?.position ?? playerPos,
                      ),
                      _Row(
                        label: s.height,
                        value: profile?.height != null
                            ? '${profile!.height}cm'
                            : playerHeight,
                      ),
                      _Row(label: s.age, value: _age(profile) ?? playerAge),
                      _Row(
                        label: s.shirt,
                        value: profile?.jerseyNumber != null
                            ? '#${profile!.jerseyNumber}'
                            : playerNumber,
                      ),
                      // Backend cũ không có dữ liệu này nên dòng luôn trống.
                      _Row(label: s.preferFoot, value: profile?.preferredFoot),
                      _Row(label: s.weight, value: playerWeight),
                      _Row(
                        label: s.nationality,
                        value: profile?.nationality ?? playerNationality,
                      ),
                      // Hai dòng dưới chỉ có từ Sofascore; backend cũ không
                      // trả nên trước đây không hiển thị được.
                      if (profile?.marketValue != null)
                        _Row(
                          label: 'Market value',
                          value: _money(
                            profile!.marketValue!,
                            profile.marketValueCurrency,
                          ),
                        ),
                      if (profile?.contractUntil != null)
                        _Row(
                          label: 'Contract until',
                          value: profile!.contractUntil,
                        ),
                    ],
                  ),
                ),
                if (profile?.stats != null) ...[
                  SizedBox(height: AppDimens.sdp(12)),
                  _SeasonStats(stats: profile!.stats!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tính tuổi từ ngày sinh của hồ sơ; thiếu thì để màn dùng giá trị cũ.
  String? _age(PlayerProfile? profile) {
    final dob = profile?.dateOfBirth;
    if (dob == null) return null;
    final parsed = DateTime.tryParse(dob);
    if (parsed == null) return null;
    final now = DateTime.now();
    var age = now.year - parsed.year;
    if (now.month < parsed.month ||
        (now.month == parsed.month && now.day < parsed.day)) {
      age--;
    }
    return age <= 0 ? null : '$age';
  }
}

/// Nhãn 13ssp `text200` bên trái, giá trị 13ssp `text500` bên phải
/// cách 10sdp; các dòng sau cách dòng trước 20sdp.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isFirst = false});

  final String label;
  final String? value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: isFirst ? 0 : AppDimens.sdp(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(13),
                color: AppColors.text200,
              ),
            ),
            SizedBox(width: AppDimens.sdp(10)),
            Expanded(
              child: Text(
                (value == null || value!.isEmpty) ? '-' : value!,
                textAlign: TextAlign.end,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(13),
                  color: AppColors.text500,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Bốn ô thống kê mùa hiện tại — phần Sofascore cho mà backend cũ không có.
class _SeasonStats extends StatelessWidget {
  const _SeasonStats({required this.stats});

  final PlayerSeasonStats stats;

  /// Thang điểm Sofascore: dưới 6.5 kém, từ 7.0 trở lên tốt.
  Color get _ratingColor {
    final r = stats.rating;
    if (r == null) return AppColors.text500;
    if (r >= 7.0) return AppColors.homeColor;
    if (r < 6.5) return AppColors.awayColor;
    return AppColors.drawColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(16),
        vertical: AppDimens.sdp(14),
      ),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stats.tournamentName ?? 'This season',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.medium(
              size: AppDimens.ssp(11),
              color: AppColors.text200,
            ),
          ),
          SizedBox(height: AppDimens.sdp(12)),
          Row(
            children: [
              _StatBox(label: 'Apps', value: '${stats.appearances}'),
              _StatBox(label: 'Goals', value: '${stats.goals}'),
              _StatBox(label: 'Assists', value: '${stats.assists}'),
              _StatBox(
                label: 'Rating',
                value: stats.ratingText,
                color: _ratingColor,
              ),
            ],
          ),
          if (stats.minutesPlayed != null) ...[
            SizedBox(height: AppDimens.sdp(10)),
            Row(
              children: [
                _Chip(
                  text: "${stats.minutesPlayed}'",
                  color: AppColors.text400,
                ),
                if ((stats.yellowCards ?? 0) > 0)
                  _Chip(
                    text: '${stats.yellowCards}',
                    color: AppColors.drawColor,
                  ),
                if ((stats.redCards ?? 0) > 0)
                  _Chip(text: '${stats.redCards}', color: AppColors.awayColor),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(18),
                color: color ?? AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDimens.sdp(2)),
            Text(
              label,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.text200,
              ),
            ),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(right: AppDimens.sdp(6)),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.sdp(8),
          vertical: AppDimens.sdp(3),
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppDimens.sdp(6)),
        ),
        child: Text(
          text,
          style: AppTextStyles.medium(
            size: AppDimens.ssp(10),
            color: color,
          ),
        ),
      );
}

/// `12.500.000` → `12.5M`, tránh dòng giá trị dài tràn ra ngoài thẻ.
String _money(int value, String? currency) {
  final symbol = switch (currency) {
    'EUR' => '€',
    'USD' => r'$',
    'GBP' => '£',
    _ => '',
  };
  if (value >= 1000000) {
    final m = value / 1000000;
    return '$symbol${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
  }
  if (value >= 1000) return '$symbol${(value / 1000).round()}K';
  return '$symbol$value';
}

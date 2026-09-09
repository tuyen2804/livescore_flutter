import 'package:equatable/equatable.dart';

/// Port `domain/model/LanguageModel.kt` + danh sách trong `LanguageUtils.kt`.
class LanguageModel extends Equatable {
  const LanguageModel({
    required this.code,
    required this.name,
    required this.flagAsset,
    this.isSelected = false,
  });

  final String code;
  final String name;

  /// File cờ trong `assets/icons` (SVG) hoặc `assets/images` (webp).
  final String flagAsset;
  final bool isSelected;

  LanguageModel copyWith({bool? isSelected}) => LanguageModel(
        code: code,
        name: name,
        flagAsset: flagAsset,
        isSelected: isSelected ?? this.isSelected,
      );

  @override
  List<Object?> get props => [code, isSelected];

  /// Đúng thứ tự của `LanguageUtils.getLanguages`.
  static const List<LanguageModel> all = [
    LanguageModel(code: 'hi', name: 'हिंदी', flagAsset: 'assets/images/flag_hi.webp'),
    LanguageModel(code: 'fr', name: 'Français', flagAsset: 'assets/icons/flag_fr.svg'),
    LanguageModel(code: 'ar', name: 'العربية', flagAsset: 'assets/icons/flag_ae.svg'),
    LanguageModel(
        code: 'es', name: 'Español (España)', flagAsset: 'assets/icons/flag_es.svg'),
    LanguageModel(code: 'en', name: 'English', flagAsset: 'assets/icons/flag_en.svg'),
    LanguageModel(code: 'in', name: 'Indonesia', flagAsset: 'assets/icons/flag_id.svg'),
    LanguageModel(
        code: 'pt', name: 'Português (Brasil)', flagAsset: 'assets/images/flag_br.webp'),
    LanguageModel(code: 'ja', name: '日本語', flagAsset: 'assets/icons/flag_ja.svg'),
    LanguageModel(code: 'vi', name: 'Tiếng Việt', flagAsset: 'assets/icons/flag_vi.svg'),
    LanguageModel(code: 'th', name: 'ไทย', flagAsset: 'assets/icons/flag_th.svg'),
    LanguageModel(code: 'ru', name: 'Русский', flagAsset: 'assets/icons/flag_ru.svg'),
    LanguageModel(code: 'ko', name: '한국어', flagAsset: 'assets/icons/flag_ko.svg'),
    LanguageModel(code: 'de', name: 'Deutsch', flagAsset: 'assets/icons/flag_ge.svg'),
  ];
}

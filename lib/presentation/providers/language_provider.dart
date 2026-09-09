import '../../data/datasources/local/app_prefs.dart';
import '../../domain/entities/language_model.dart';
import 'base_provider.dart';

/// Port `presentation/language/LanguageViewModel.kt`.
class LanguageProvider extends BaseProvider {
  LanguageProvider(this._prefs) {
    loadLanguages();
  }

  final AppPrefs _prefs;

  List<LanguageModel> _languages = const [];
  LanguageModel? _selected;

  List<LanguageModel> get languages => _languages;
  LanguageModel? get selected => _selected;

  void loadLanguages() {
    final saved = _prefs.getString(AppPrefs.keyLanguageCode);
    _languages = LanguageModel.all
        .map((l) => l.copyWith(isSelected: saved != null && l.code == saved))
        .toList(growable: false);
    _selected = _languages.where((l) => l.isSelected).firstOrNull;
    notifyListeners();
  }

  void selectLanguage(LanguageModel language) {
    _languages = _languages
        .map((l) => l.copyWith(isSelected: l.code == language.code))
        .toList(growable: false);
    _selected = language;
    notifyListeners();
  }

  /// Ghi lựa chọn + đánh dấu đã qua bước chọn ngôn ngữ.
  Future<String?> saveSelectedLanguage() async {
    final code = _selected?.code;
    if (code == null) return null;
    await _prefs.setLanguageCode(code);
    await _prefs.setPassedLanguage(true);
    return code;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

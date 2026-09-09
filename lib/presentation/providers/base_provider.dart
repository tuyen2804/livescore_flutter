import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';

enum ViewStatus { initial, loading, refreshing, success, empty, error }

/// Trạng thái chung cho mọi provider — thay cho cặp LiveData
/// `isLoading` + `data` + `error` của bản Android.
@immutable
class ViewState<T> {
  const ViewState._({
    required this.status,
    this.data,
    this.failure,
  });

  const ViewState.initial() : this._(status: ViewStatus.initial);
  const ViewState.loading({T? data})
      : this._(status: ViewStatus.loading, data: data);
  const ViewState.refreshing({T? data})
      : this._(status: ViewStatus.refreshing, data: data);
  const ViewState.success(T data)
      : this._(status: ViewStatus.success, data: data);
  const ViewState.empty() : this._(status: ViewStatus.empty);
  const ViewState.error(Failure failure, {T? data})
      : this._(status: ViewStatus.error, failure: failure, data: data);

  final ViewStatus status;
  final T? data;
  final Failure? failure;

  bool get isInitial => status == ViewStatus.initial;
  bool get isLoading => status == ViewStatus.loading;
  bool get isRefreshing => status == ViewStatus.refreshing;
  bool get isSuccess => status == ViewStatus.success;
  bool get isEmpty => status == ViewStatus.empty;
  bool get isError => status == ViewStatus.error;
  bool get isBusy => isLoading || isRefreshing;
  bool get hasData => data != null;
}

/// Đế chung: chống `notifyListeners` sau khi dispose.
abstract class BaseProvider extends ChangeNotifier {
  bool _disposed = false;
  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  /// Đổi state rồi báo UI, chỉ khi provider còn sống.
  void setState(VoidCallback mutate) {
    if (_disposed) return;
    mutate();
    notifyListeners();
  }
}

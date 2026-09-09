import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Port của `NetworkMonitor.kt`.
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

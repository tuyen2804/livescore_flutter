import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/local/app_prefs.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/datasources/remote/football_remote_data_source.dart';
import '../../data/datasources/remote/home_feed_loader.dart';
import '../../data/datasources/remote/sofascore_remote_data_source.dart';
import '../../data/repositories/football_repository_impl.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import '../../domain/repositories/football_repository.dart';
import '../../domain/repositories/sofascore_repository.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../services/remote_config_service.dart';

final GetIt sl = GetIt.instance;

/// Thay cho các `@Module` của Hilt: NetworkModule, PrefsModule,
/// DatabaseModule, JsonModule.
Future<void> initDependencies() async {
  // ---- Hạ tầng ----
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ---- Local ----
  final prefs = await AppPrefs.create();
  sl.registerSingleton<AppPrefs>(prefs);
  sl.registerLazySingleton<LeagueDbHelper>(LeagueDbHelper.new);

  // ---- Dịch vụ Firebase / thông báo ----
  final remoteConfig = RemoteConfigService();
  await remoteConfig.init();
  sl.registerSingleton<RemoteConfigService>(remoteConfig);
  sl.registerLazySingleton<AnalyticsService>(AnalyticsService.new);

  final notifications = NotificationService();
  await notifications.init();
  sl.registerSingleton<NotificationService>(notifications);

  // ---- Mạng ----
  // Base URL bóng đá lấy từ Remote Config, giống `ApiClient.BASE_URL`.
  sl.registerLazySingleton<DioClient>(
    () => DioClient.football(baseUrl: remoteConfig.baseUrl),
    instanceName: 'football',
  );
  sl.registerLazySingleton<DioClient>(
    DioClient.sofascore,
    instanceName: 'sofascore',
  );

  // ---- Data source ----
  sl.registerLazySingleton<FootballRemoteDataSource>(
    () => FootballRemoteDataSourceImpl(sl(instanceName: 'football')),
  );
  sl.registerLazySingleton<SofascoreRemoteDataSource>(
    () => SofascoreRemoteDataSource(sl(instanceName: 'sofascore')),
  );
  sl.registerLazySingleton<HomeFeedLoader>(
    () => HomeFeedLoader(sl(), sl()),
  );

  // ---- Repository ----
  sl.registerLazySingleton<FootballRepository>(
    () => FootballRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<SofascoreRepositoryImpl>(
    () => SofascoreRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<SofascoreRepository>(
    () => sl<SofascoreRepositoryImpl>(),
  );
}

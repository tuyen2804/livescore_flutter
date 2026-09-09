import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/di/injection.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_dimens.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/app_provider.dart';
import 'presentation/providers/highlight_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/leagues_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/prediction_provider.dart';
import 'presentation/providers/teams_provider.dart';

class LiveScoreApp extends StatelessWidget {
  const LiveScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider sống suốt vòng đời app.
        ChangeNotifierProvider(create: (_) => AppProvider(sl(), sl())),
        // Các tab của MainScreen giữ state khi chuyển qua lại, giống
        // ViewModel gắn với NavHost của bản Android.
        ChangeNotifierProvider(create: (_) => HomeProvider(sl(), sl(), sl(), sl())),
        ChangeNotifierProvider(create: (_) => LeaguesProvider(sl(), sl(), sl())),
        ChangeNotifierProvider(create: (_) => HighlightProvider(sl())),
        ChangeNotifierProvider(create: (_) => TeamsProvider(sl(), sl(), sl())),
        ChangeNotifierProvider(create: (_) => PredictionProvider(sl(), sl())),
        ChangeNotifierProvider(create: (_) => NotificationProvider(sl(), sl())),
      ],
      child: Consumer<AppProvider>(
        builder: (context, app, _) => MaterialApp(
          title: 'Live Score',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppRouter.navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: app.themeMode,
          locale: app.locale,
          supportedLocales: AppProvider.supportedLocales,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            // Khởi tạo hệ quy đổi sdp/ssp một lần, trước khi vẽ màn đầu tiên.
            AppDimens.init(context);
            return MediaQuery.withNoTextScaling(child: child ?? const SizedBox());
          },
        ),
      ),
    );
  }
}

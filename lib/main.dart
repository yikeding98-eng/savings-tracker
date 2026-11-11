import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'screens/root_page.dart';
import 'services/reminder_service.dart';
import 'services/storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = Storage();
  final reminder = ReminderService();
  await reminder.init();

  final state = AppState(storage: storage, reminder: reminder);
  await state.load();

  if (state.settings.reminderEnabled) {
    await reminder.requestPermission();
    await state.rescheduleReminder();
  }

  runApp(SavingsApp(state: state));
}

class SavingsApp extends StatelessWidget {
  const SavingsApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: '存款管家',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.system,
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const <Locale>[
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        home: const RootPage(),
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}

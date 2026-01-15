import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_first_app/screens/dashboard_screen.dart';
import 'package:my_first_app/services/database_helper.dart';
import 'package:my_first_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('zh_CN', null);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      // Initialize notifications
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.requestPermissions();

      // Check if user has set a custom time
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final timeResult = await db.query(
        'app_kv',
        where: 'key = ?',
        whereArgs: ['reminder_time'],
      );

      // Only schedule default if no setting exists
      if (timeResult.isEmpty) {
        await notificationService.scheduleDailyReminder(
          id: 1,
          title: '记得测量血压',
          body: '晚上好！现在是测量血压的最佳时间。',
          time: const TimeOfDay(hour: 21, minute: 0),
        );
      }
    } catch (e) {
      debugPrint('Initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的血压',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

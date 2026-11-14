import 'app_imports.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // تأكد من استيراد كود الويب

Future<void> requestAllAppPermissions() async {
  // تخطي طلب الصلاحيات بالكامل لو التطبيق شغال على الويب
  if (kIsWeb) return;
  
  try {
    await Permission.storage.request();
    if (await Permission.manageExternalStorage.status.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    await Permission.contacts.request();
    await Permission.camera.request();
    if (await Permission.ignoreBatteryOptimizations.status.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  } catch (e) {
    debugPrint('خطأ أثناء طلب الصلاحيات: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: ServerConfig.firebaseOptions,
      );
    }
  } catch (e) {
    debugPrint('تنبيه تهيئة فايربيس: $e');
  }

  // استدعاء الصلاحيات بشرط ألا يكون العمل على الويب
  if (!kIsWeb) {
    await requestAllAppPermissions();
  }

  CloudSyncService.initOfflineSupport();
  await LicensingService.loadLicenseStatus();
  await LocalStorageService.loadLocally();

  unawaited(
    Future.microtask(() async {
      try {
        await CloudSyncService.syncFromCloud(isAuto: true);
      } catch (e) {
        debugPrint('خطأ في المزامنة اللحظية: $e');
      }
    }),
  );

  runApp(const Aqarat());
}

class Aqarat extends StatelessWidget {
  const Aqarat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منظومة الكابتن لإدارة العقارات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 2,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
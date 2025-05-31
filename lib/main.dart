import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'screens/wrapper_screen.dart';
import 'config/app_config.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Tarih formatları için Türkçe desteği ekle
    await initializeDateFormatting('tr_TR', null);
    
    // SharedPreferences'i başlat ve kontrol et (değeri değiştirme!)
    final prefs = await SharedPreferences.getInstance();
    
    // Bildirim ayarlarını kontrol et - SADECE ilk kurulumda varsayılan değeri ayarla
    if (prefs.containsKey('notification_reminder_minutes')) {
      // Mevcut değeri koru - değiştirme
      final currentValue = prefs.getInt('notification_reminder_minutes');
      developer.log('Uygulama başlatıldı, mevcut bildirim süresi korunuyor: $currentValue dakika');
    } else {
      // SADECE değer yoksa (ilk kurulum) varsayılan değeri kaydet
      final success = await prefs.setInt('notification_reminder_minutes', 10);
      developer.log('İlk kurulum: Varsayılan bildirim süresi ayarlandı: 10 dakika, Başarılı: $success');
    }
    
    // Supabase başlat
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    
    // Bildirim servisini başlat
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    
    // Bildirim süresini kontrol et (değiştirmeden)
    final reminderMinutes = await notificationService.getReminderMinutes();
    developer.log('Ana uygulama: Mevcut bildirim süresi: $reminderMinutes dakika');
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Uygulama başlatma hatası: $e');
    // Uygulama hatası ekranını göster
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMate - Hata',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Uygulama başlatılamadı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hata detayı: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Uygulamayı yeniden başlatma girişimi
                    main();
                  },
                  child: const Text('Yeniden Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'TaskMate',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          // Tarih seçici temalarını iyileştir
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: Colors.deepPurple,
            headerForegroundColor: Colors.white,
            dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.deepPurple;
              }
              return null;
            }),
            dayForegroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white;
              }
              return null;
            }),
          ),
          timePickerTheme: TimePickerThemeData(
            dialBackgroundColor: Colors.grey[200],
            hourMinuteTextColor: Colors.deepPurple,
            dayPeriodTextColor: Colors.deepPurple,
            dialHandColor: Colors.deepPurple,
            hourMinuteColor: MaterialStateColor.resolveWith((states) => 
              states.contains(MaterialState.selected) 
                ? Colors.deepPurple.withOpacity(0.2)
                : Colors.transparent),
          ),
        ),
        locale: const Locale('tr', 'TR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        home: const WrapperScreen(),
      ),
    );
  }
}

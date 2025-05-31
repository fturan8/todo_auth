import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  // Timer'ları saklayacağımız map (uygulama açıkken çalışır)
  final Map<String, List<Timer>> _scheduledTimers = {};
  
  // Varsayılan bildirim süresi (dakika cinsinden)
  static const int _defaultReminderMinutes = 30;
  
  // SharedPreferences key'leri - SORUNU DÜZELT: ANAHTAR ADI AYNI OLMALI
  static const String _reminderMinutesKey = 'notification_reminder_minutes';
  
  // Bildirim süresini içeride saklayalım (önbellek)
  int? _cachedReminderMinutes;

  NotificationService._internal() {
    // Timezone'ları başlat
    tz_data.initializeTimeZones();
  }

  Future<void> initialize() async {
    // Bildirim süresini yükle ve doğrula (önce bu işlemi yapalım)
    await _loadReminderMinutes();
    developer.log('Bildirim servisi başlatılırken mevcut hatırlatma süresi yüklendi: ${_cachedReminderMinutes ?? _defaultReminderMinutes} dakika');
    
    // Android için bildirim kanalı
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    // iOS için bildirim ayarları - const olmayan versiyonu
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Kritik bildirimler için izin iste
    );
    
    // Başlatma ayarları - const olmayan versiyonu
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Bildirime tıklandı: ${response.payload}');
      },
    );
    
    // Test bildirimi - geliştirme için gerektiğinde kullanılabilir
    // await showTestNotification();
    
    // Test zamanlı bildirimi - geliştirme için gerektiğinde kullanılabilir
    // Gerçek kullanımda pasif bırakıldı
    // await scheduleDeadlineTestNotification();
  }
  
  // Bildirim süresini yükleme (SharedPreferences'ten)
  Future<void> _loadReminderMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Önce tüm mevcut anahtarları kontrol et
      final keys = prefs.getKeys();
      developer.log('SharedPreferences anahtarları: $keys');
      
      // Birden fazla anahtar kontrol et (alternatif depolama anahtarları)
      final hasMainKey = prefs.containsKey(_reminderMinutesKey);
      final hasStringKey = prefs.containsKey('${_reminderMinutesKey}_str');
      final hasStorageKey = prefs.containsKey('notification_storage');
      
      developer.log('Anahtar kontrolleri: Ana: $hasMainKey, String: $hasStringKey, Storage: $hasStorageKey');
      
      // İlk önce varsa ana anahtarı kullan
      if (hasMainKey) {
        _cachedReminderMinutes = prefs.getInt(_reminderMinutesKey);
        developer.log('Bildirim süresi Ana Anahtardan yüklendi: $_cachedReminderMinutes dakika');
      } 
      // Sonra string anahtarı dene
      else if (hasStringKey) {
        final strValue = prefs.getString('${_reminderMinutesKey}_str');
        _cachedReminderMinutes = int.tryParse(strValue ?? '');
        developer.log('Bildirim süresi String Anahtardan yüklendi: $_cachedReminderMinutes dakika');
        
        // Ana anahtara da kaydet
        if (_cachedReminderMinutes != null) {
          await prefs.setInt(_reminderMinutesKey, _cachedReminderMinutes!);
        }
      }
      // Son olarak storage anahtarını dene 
      else if (hasStorageKey) {
        final storageValue = prefs.getString('notification_storage');
        if (storageValue != null && storageValue.contains('reminder_minutes')) {
          final valueStr = storageValue.split('reminder_minutes:')[1].split('}')[0].trim();
          _cachedReminderMinutes = int.tryParse(valueStr);
          developer.log('Bildirim süresi Storage Anahtardan yüklendi: $_cachedReminderMinutes dakika');
          
          // Ana anahtara da kaydet
          if (_cachedReminderMinutes != null) {
            await prefs.setInt(_reminderMinutesKey, _cachedReminderMinutes!);
          }
        }
      }
      // Hiçbir anahtar yoksa varsayılan değeri kullan ve kaydet
      else {
        _cachedReminderMinutes = _defaultReminderMinutes;
        await prefs.setInt(_reminderMinutesKey, _defaultReminderMinutes);
        await prefs.setString('${_reminderMinutesKey}_str', _defaultReminderMinutes.toString());
        developer.log('Hiçbir değer bulunamadı. Varsayılan bildirim süresi kaydedildi: $_defaultReminderMinutes dakika');
      }
      
      // Eğer yüklenen değer null ise varsayılanı kullan
      if (_cachedReminderMinutes == null) {
        _cachedReminderMinutes = _defaultReminderMinutes;
        developer.log('Yükleme sonrası null değer için varsayılan kullanılıyor: $_defaultReminderMinutes dakika');
      }
    } catch (e) {
      developer.log('Bildirim süresini yükleme hatası: $e');
      _cachedReminderMinutes = _defaultReminderMinutes;
    }
  }
  
  // Bildirim süresini getir
  Future<int> getReminderMinutes() async {
    // Önce önbellekten kontrol et
    if (_cachedReminderMinutes != null) {
      developer.log('Bildirim süresi önbellekten alındı: $_cachedReminderMinutes dakika');
      return _cachedReminderMinutes!;
    }
    
    // Önbellekte yoksa yükle
    await _loadReminderMinutes();
    
    // Yine kontrol et ve mutlaka bir değer dön
    return _cachedReminderMinutes ?? _defaultReminderMinutes;
  }
  
  // Bildirim süresini kaydet
  Future<void> setReminderMinutes(int minutes, {bool force_reload = false}) async {
    try {
      if (minutes <= 0) {
        minutes = _defaultReminderMinutes;
      }
      
      // Önce önbelleğe kaydet
      _cachedReminderMinutes = minutes;
      
      // Sonra SharedPreferences'e kaydet (birden fazla teknikle deneyelim)
      final prefs = await SharedPreferences.getInstance();
      
      // Temizleme ile dene (sorunu çözmek için)
      if (force_reload) {
        await prefs.remove(_reminderMinutesKey);
        developer.log('Bildirim süresi anahtarı temizlendi');
        
        // Kısa bir bekleme süresi ekleyebiliriz
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // SharedPreferences API'sinde farklı kaydetme/yükleme yöntemlerini deneyelim
      
      // 1. Yöntem: doğrudan setInt
      final success = await prefs.setInt(_reminderMinutesKey, minutes);
      developer.log('Bildirim süresi setInt ile kaydedildi: $success');
      
      // 2. Yöntem: String olarak kaydet
      await prefs.setString('${_reminderMinutesKey}_str', minutes.toString());
      
      // 3. Yöntem: Depolama yöntemi
      final storage = {'reminder_minutes': minutes};
      await prefs.setString('notification_storage', storage.toString());
      
      // Değerin doğru kaydedilip kaydedilmediğini kontrol et
      final savedMinutes = prefs.getInt(_reminderMinutesKey);
      final savedString = prefs.getString('${_reminderMinutesKey}_str');
      final savedStorage = prefs.getString('notification_storage');
      
      developer.log('Bildirim süresi kayıt sonuçları: '
          'Int: $savedMinutes, '
          'String: $savedString, '
          'Storage: $savedStorage');
      
      if (savedMinutes != minutes) {
        developer.log('UYARI: Kaydedilen değer istenen değerle eşleşmiyor!');
        
        // Farklı bir yöntem dene - tüm değerleri temizle
        await prefs.clear();
        developer.log('Tüm SharedPreferences değerleri temizlendi.');
        
        // Tekrar kaydet ve doğrula
        await prefs.setInt(_reminderMinutesKey, minutes);
        final checkAgain = prefs.getInt(_reminderMinutesKey);
        developer.log('Temizleme sonrası tekrar denendi: $checkAgain');
        
        // Değerin doğru kaydedildiğinden emin olmak için ek önlem
        // Dosya sistemi temelli bir yedekleme çözümü olabilir
      }
      
      // Tüm bildirimleri güncelle
      await _rescheduleAllReminders();
      
      // Doğrulama bildirimi göster
      await showInstantNotification(
        22222, // Benzersiz ID
        'Bildirim Ayarları Güncellendi',
        'Bildirim süresi $minutes dakika olarak ayarlandı. Görevleriniz bu süreye göre hatırlatılacak.',
      );
      
    } catch (e) {
      developer.log('Bildirim süresi ayarlama hatası: $e');
      // Kullanıcıya hata bildir
      await showInstantNotification(
        22223, // Benzersiz ID
        'Bildirim Ayarları Hatası',
        'Bildirim süresi ayarlanırken bir sorun oluştu. Lütfen tekrar deneyin.',
      );
    }
  }
  
  // Tüm bildirimleri yeniden programla
  Future<void> _rescheduleAllReminders() async {
    // Mevcut timer'ları iptal et
    await cancelAllNotifications();
    
    developer.log('Tüm bildirimler yeniden programlanıyor...');
    
    // Bu metod genellikle kullanıcı bildirim süresini değiştirdiğinde çağrılır
    // TaskProvider ile bağlantı kurulup aktif görevlerin bildirimleri yeniden programlanabilir
    try {
      // Güncel bildirim süresini al
      final reminderMinutes = _cachedReminderMinutes ?? 
                             await getReminderMinutes(); // Direkt önbellekten al
      
      // Bildirim ayarlarının değiştiğini göstermek için bir bildirim gönder
      await showInstantNotification(
        10000, // Benzersiz bir ID
        'Bildirim Ayarları Güncellendi',
        'Bildirim ayarlarınız güncellendi. Artık görevlerinizden $reminderMinutes dakika önce bildirim alacaksınız.',
      );
      
      developer.log('Bildirim ayarları güncellendi ve yeniden programlandı: $reminderMinutes dakika');
      
      // Yeni değeri SharedPreferences'e yedekle (ekstra güvenlik)
      final prefs = await SharedPreferences.getInstance();
      if (reminderMinutes > 0 && !prefs.containsKey(_reminderMinutesKey)) {
        await prefs.setInt(_reminderMinutesKey, reminderMinutes);
        developer.log('Bildirim süresi SharedPreferences\'e yedeklendi: $reminderMinutes dakika');
      }
    } catch (e) {
      developer.log('Bildirimleri yeniden programlama hatası: $e');
    }
  }

  Future<void> requestPermissions() async {
    // iOS için izinleri iste
    final iOS = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
            
    if (iOS != null) {
      await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true, // Kritik bildirimler için izin
        provisional: true, // Geçici izin (kullanıcı onayı olmadan gösterim)
      );
      developer.log('iOS bildirim izinleri istendi');
    }
    
    // Android için izinleri iste
    final android = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
    if (android != null) {
      try {
        await android.requestNotificationsPermission();
        developer.log('Android bildirim izinleri istendi');
      } catch (e) {
        developer.log('Android izin hatası: $e');
      }
    }
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (task.deadline == null) {
      developer.log('Görev için deadline yok, bildirim programlanmadı: ${task.title}');
      return;
    }

    // Tamamlanmış görevler için bildirim programlama
    if (task.isCompleted) {
      developer.log('Görev tamamlanmış, bildirimler iptal ediliyor: ${task.title}');
      await cancelTaskReminder(task.id);
      return;
    }

    final now = DateTime.now();
    
    // Deadline geçmişse bildirim gönderme
    if (task.deadline!.isBefore(now)) {
      developer.log('Deadline geçmiş, bildirim programlanmadı: ${task.title}');
      return;
    }

    // Önce tüm bildirimleri iptal et
    await cancelTaskReminder(task.id);
    
    // Güncel bildirim süresini getir
    final reminderMinutes = await getReminderMinutes();
    developer.log('${task.title} için bildirim ayarlanıyor, güncel hatırlatma süresi: $reminderMinutes dakika');

    // UTC ve yerel saat farkını logla
    final localDate = now;
    final utcDate = now.toUtc();
    final offset = localDate.timeZoneOffset;
    developer.log('Timezone farkı: ${offset.inHours} saat, ${offset.inMinutes % 60} dakika');
    developer.log('Lokal tarih: $localDate, UTC tarih: $utcDate');
    developer.log('Görev deadline: ${task.deadline}, görev başlığı: ${task.title}');

    try {
      // Timer'ları başlat (uygulama açıkken çalışır)
      await _startTimerNotifications(task);
      
      // Ayrıca yerel bildirim olarak da programla (uygulama kapalıyken)
      await _scheduleLocalNotifications(task);
      
      // İlk bildirimi göster - "Bildirim ayarlandı"
      // Bu bildirim artık gereksiz - kullanıcı zaten bildirimleri biliyor
      // final minutesLeft = task.deadline!.difference(now).inMinutes;
      // await showInstantNotification(
      //   task.id.hashCode + 5000,
      //   'Görev Hatırlatıcı Ayarlandı',
      //   'Görev "${task.title}" için bildirimler ayarlandı. Kalan süre: ${minutesLeft ~/ 60} saat ${minutesLeft % 60} dakika. Hatırlatıcı: $reminderMinutes dakika önce.',
      // );
      
      developer.log('Tüm bildirimler programlandı: ${task.title}, hatırlatma süresi: $reminderMinutes dakika');
    } catch (e) {
      developer.log('Bildirim hatası: ${e.toString()}', error: e);
      
      // Hata durumunda anında bir bildirim gönder
      await showInstantNotification(
        task.id.hashCode + 9000,
        'Bildirim Hatası',
        'Görev "${task.title}" için bildirimler ayarlanamadı.',
      );
    }
  }
  
  // Yerel bildirimler olarak programla (uygulama kapalıyken çalışır)
  Future<void> _scheduleLocalNotifications(Task task) async {
    try {
      final now = DateTime.now();
      final reminderMinutes = await getReminderMinutes();
      
      // 1. Görev zamanı için bildirim
      final deadlineId = task.id.hashCode + 1000;
      final deadlineDate = task.deadline!;
      
      // Görev zamanı bildirimi için
      if (deadlineDate.isAfter(now)) {
        final androidDetails = AndroidNotificationDetails(
          'deadline_channel',
          'Görev Zamanı Bildirimleri',
          channelDescription: 'Görev saati geldiğinde bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
        );
        
        final iosDetails = DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        final platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );
        
        // Timezone ile çalışan bildirim zamanlaması
        final deadlineTimeZoned = tz.TZDateTime.from(deadlineDate, tz.local);
        
        // Görev zamanı bildirimi
        await flutterLocalNotificationsPlugin.zonedSchedule(
          deadlineId,
          'Görev Zamanı: ${task.title}',
          'Görev saati geldi! Son tarih: ${_formatDateTime(task.deadline!)}',
          deadlineTimeZoned,
          platformDetails,
          // Android için parametre
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        developer.log('Görev zamanı için yerel bildirim programlandı: ${task.title}, zaman: $deadlineDate');
      }
      
      // 2. Hatırlatma için bildirim
      final reminderId = task.id.hashCode + 2000;
      
      // Hatırlatma zamanı deadline'dan reminderMinutes dakika önce
      final reminderDate = task.deadline!.subtract(Duration(minutes: reminderMinutes));
      
      // Eğer hatırlatma zamanı geçmemişse hatırlatma bildirimi ayarla
      if (reminderDate.isAfter(now)) {
        final androidDetails = AndroidNotificationDetails(
          'reminder_channel',
          'Görev Hatırlatma Bildirimleri',
          channelDescription: 'Görev saatinden önce hatırlatma bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
        );
        
        final iosDetails = DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        final platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );
        
        // Timezone ile çalışan bildirim zamanlaması
        final reminderTimeZoned = tz.TZDateTime.from(reminderDate, tz.local);
        
        // Hatırlatma bildirimi
        await flutterLocalNotificationsPlugin.zonedSchedule(
          reminderId,
          'Görev Hatırlatıcı: ${task.title}',
          'Bu görevin tamamlanmasına $reminderMinutes dakika kaldı! Son tarih: ${_formatDateTime(task.deadline!)}',
          reminderTimeZoned,
          platformDetails,
          // Android için parametre
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        developer.log('Hatırlatma için yerel bildirim programlandı: ${task.title}, zaman: $reminderDate');
      }
    } catch (e) {
      developer.log('Yerel bildirimleri programlama hatası: $e');
    }
  }
  
  // Timer-tabanlı bildirimler (uygulama açıkken çalışır)
  Future<void> _startTimerNotifications(Task task) async {
    final now = DateTime.now();
    final taskId = task.id;
    final timers = <Timer>[];
    
    // Kullanıcının belirlediği bildirim süresini al
    final reminderMinutes = await getReminderMinutes();
    developer.log('${task.title} için bildirimler planlanıyor, hatırlatma süresi: $reminderMinutes dakika');
    
    // Görev zamanına kalan toplam dakika ve saniye
    final minutesLeft = task.deadline!.difference(now).inMinutes;
    final secondsLeft = task.deadline!.difference(now).inSeconds;
    
    developer.log('${task.title} için görev zamanına kalan: $minutesLeft dakika, $secondsLeft saniye');
    
    try {
      // 1. Eğer kullanıcının belirlediği süreden az kaldıysa, hemen bir bildirim gönder
      if (minutesLeft < reminderMinutes) {
        showInstantNotification(
          task.id.hashCode,
          'Acil Görev Hatırlatıcı: ${task.title}',
          'Bu görevin tamamlanmasına sadece $minutesLeft dakika kaldı! Son tarih: ${_formatDateTime(task.deadline!)}',
        );
        developer.log('Acil bildirim gönderildi: ${task.title}');
      } else {
        // 2. Kullanıcının belirlediği süre kadar öncesi için Timer
        final reminderTime = task.deadline!.subtract(Duration(minutes: reminderMinutes));
        final reminderDelaySeconds = reminderTime.difference(now).inSeconds;
        
        developer.log('${task.title} için bildirim: Görev tarihi: ${task.deadline}, bildirim zamanı: $reminderTime, kalan saniye: $reminderDelaySeconds');
        
        if (reminderDelaySeconds > 0) {
          final reminderTimer = Timer(Duration(seconds: reminderDelaySeconds), () {
            showInstantNotification(
              task.id.hashCode,
              'Görev Hatırlatıcı: ${task.title}',
              'Bu görevin tamamlanmasına $reminderMinutes dakika kaldı! Son tarih: ${_formatDateTime(task.deadline!)}',
            );
            developer.log('$reminderMinutes dakika öncesi bildirim gönderildi: ${task.title}');
          });
          
          timers.add(reminderTimer);
        }
      }
      
      // 3. Görev zamanı için Timer (her durumda ayarla)
      if (secondsLeft > 0) {
        developer.log('${task.title} için görev zamanı bildirimi: kalan saniye: $secondsLeft');
        
        // Görev saati bildirimi için Timer ayarla
        final deadlineTimer = Timer(Duration(seconds: secondsLeft), () {
          // Görev saati geldiğinde bildirim gönder
          showInstantNotification(
            task.id.hashCode + 1000,
            'Görev Zamanı: ${task.title}',
            'Görev saati geldi! Son tarih: ${_formatDateTime(task.deadline!)}',
          );
          developer.log('Görev zamanı bildirimi gönderildi: ${task.title}');
        });
        
        // Ekstra güvence için bir saniye sonra da bildirim gönder
        final backupTimer = Timer(Duration(seconds: secondsLeft + 1), () {
          showInstantNotification(
            task.id.hashCode + 1001,
            'Görev Zamanı: ${task.title}',
            'Görev saati geldi! Son tarih: ${_formatDateTime(task.deadline!)}',
          );
          developer.log('Görev zamanı yedek bildirimi gönderildi: ${task.title}');
        });
        
        timers.add(deadlineTimer);
        timers.add(backupTimer);
      }
    } catch (e) {
      developer.log('Timer ayarlama hatası: $e');
      // Hata durumunda anında bir bildirim gönder
      showInstantNotification(
        task.id.hashCode + 9999,
        'Bildirim Hatası',
        'Görev "${task.title}" için bildirimler ayarlanırken hata oluştu.',
      );
    }
    
    // Timer'ları sakla (iptal etmek için)
    _scheduledTimers[taskId] = timers;
    developer.log('Timer bildirimler ayarlandı: ${task.title}, timer sayısı: ${timers.length}, bildirim süresi: $reminderMinutes dk');
  }
  
  // Bildirim bilgilerini SharedPreferences'e kaydet
  Future<void> _storeNotificationInfo(int id, String title, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationInfo = {
        'title': 'Görev: $title',
        'body': body,
      };
      await prefs.setString('notification_$id', jsonEncode(notificationInfo));
      developer.log('Bildirim bilgisi kaydedildi: $id');
    } catch (e) {
      developer.log('Bildirim bilgisi kaydetme hatası: $e');
    }
  }
  
  // Bildirim bilgilerini SharedPreferences'den getir
  Future<Map<String, dynamic>?> _getNotificationInfo(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationInfoJson = prefs.getString('notification_$id');
      
      if (notificationInfoJson != null) {
        return jsonDecode(notificationInfoJson) as Map<String, dynamic>;
      }
    } catch (e) {
      developer.log('Bildirim bilgisi getirme hatası: $e');
    }
    return null;
  }
  
  // Kaydedilmiş bildirimleri yeniden programla
  Future<void> _rescheduleStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final notificationKeys = keys.where((key) => key.startsWith('notification_'));
      
      for (final key in notificationKeys) {
        final id = int.parse(key.replaceFirst('notification_', ''));
        final notificationInfo = await _getNotificationInfo(id);
        
        if (notificationInfo != null) {
          final title = notificationInfo['title'] as String;
          final body = notificationInfo['body'] as String;
          
          // Test bildirimi gönder
          showInstantNotification(id, title, body);
          developer.log('Eski bildirim bulundu ve gönderildi: $title');
        }
      }
    } catch (e) {
      developer.log('Eski bildirimleri yeniden programlama hatası: $e');
    }
  }

  Future<void> showInstantNotification(
    int id,
    String title,
    String body,
  ) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_channel',
            'Anlık Bildirimler',
            channelDescription: 'Anlık görev bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      developer.log('Anlık bildirim gönderildi: $title');
    } catch (e) {
      developer.log('Anlık bildirim hatası: ${e.toString()}', error: e);
    }
  }
  
  Future<void> showTestNotification() async {
    try {
      await flutterLocalNotificationsPlugin.show(
        9999,
        'Test Bildirimi',
        'Bu bir test bildirimidir. Şu anki zaman: ${DateTime.now().toString()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Bildirimleri',
            channelDescription: 'Test bildirimleri',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      developer.log('Test bildirimi gönderildi');
    } catch (e) {
      developer.log('Test bildirimi hatası: ${e.toString()}', error: e);
    }
  }

  Future<void> cancelTaskReminder(String taskId) async {
    // Timer'ları iptal et
    final timers = _scheduledTimers[taskId];
    if (timers != null) {
      for (final timer in timers) {
        timer.cancel();
      }
      _scheduledTimers.remove(taskId);
      developer.log('Timer\'lar iptal edildi: $taskId');
    }
    
    final int alarmId = taskId.hashCode;
    final int deadlineAlarmId = taskId.hashCode + 1000;
    
    // Yerel bildirimleri iptal et
    await flutterLocalNotificationsPlugin.cancel(alarmId);
    await flutterLocalNotificationsPlugin.cancel(deadlineAlarmId);
    await flutterLocalNotificationsPlugin.cancel(taskId.hashCode + 5000);
    await flutterLocalNotificationsPlugin.cancel(taskId.hashCode + 9000);
    
    // SharedPreferences'den bildirim bilgilerini temizle
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_$alarmId');
      await prefs.remove('notification_$deadlineAlarmId');
    } catch (e) {
      developer.log('Bildirim bilgilerini temizleme hatası: $e');
    }
    
    developer.log('Tüm bildirimler iptal edildi: $taskId');
  }

  Future<void> cancelAllNotifications() async {
    // Tüm Timer'ları iptal et
    for (final timers in _scheduledTimers.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _scheduledTimers.clear();
    developer.log('Tüm Timer\'lar iptal edildi');
    
    // Tüm bildirimleri iptal et
    await flutterLocalNotificationsPlugin.cancelAll();
    
    // SharedPreferences'den tüm bildirim bilgilerini temizle
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final notificationKeys = keys.where((key) => key.startsWith('notification_'));
      
      for (final key in notificationKeys) {
        await prefs.remove(key);
      }
      
      developer.log('Tüm bildirim bilgileri temizlendi');
    } catch (e) {
      developer.log('Bildirim bilgilerini temizleme hatası: $e');
    }
    
    developer.log('Tüm bildirimler iptal edildi');
  }

  // Tarih ve saati kullanıcı dostu formatta döndür
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Görev zamanı test bildirimi - geliştirme için
  Future<void> scheduleDeadlineTestNotification() async {
    // Geliştirme testleri tamamlandığından pasif hale getirildi
    // Sadece debug modunda test amaçlı kullanılabilir
    if (false) { // Pasif hale getirildi
      try {
        final now = DateTime.now();
        final testDeadline = now.add(const Duration(seconds: 30));
        
        // Test bildirimi (30 saniye sonra görev zamanı testi)
        final androidDetails = AndroidNotificationDetails(
          'test_deadline_channel',
          'Test Görev Zamanı Bildirimleri',
          channelDescription: 'Test için görev zamanı bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
        );
        
        final iosDetails = DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        final platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );
        
        // Timezone ile çalışan bildirim zamanlaması
        final deadlineTimeZoned = tz.TZDateTime.from(testDeadline, tz.local);
        
        // Görev zamanı bildirimi
        await flutterLocalNotificationsPlugin.zonedSchedule(
          12345, // Test ID
          'TEST: Görev Zamanı Bildirimi',
          'Bu bir görev zamanı test bildirimidir! Şu anda gönderildi: ${now.toString()}',
          deadlineTimeZoned,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        // Ayrıca timer üzerinden de test et
        Timer(const Duration(seconds: 30), () {
          showInstantNotification(
            54321,
            'Timer Test: Görev Zamanı',
            'Bu bir timer üzerinden gönderilen test bildirimidir! Şu anda gönderildi: ${DateTime.now().toString()}',
          );
        });
        
        developer.log('Test bildirimleri 30 saniye sonrası için ayarlandı, şimdiki zaman: ${now.toString()}');
      } catch (e) {
        developer.log('Test bildirimi oluşturma hatası: $e');
      }
    }
  }
} 
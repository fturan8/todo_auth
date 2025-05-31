import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _reminderMinutesController = TextEditingController();
  bool _isLoading = true;
  int _currentReminderMinutes = 30; // Varsayılan değer

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Doğrudan SharedPreferences'ten yükle
      final prefs = await SharedPreferences.getInstance();
      final directValue = prefs.getInt('notification_reminder_minutes');
      developer.log('Doğrudan yüklenen: $directValue');
      
      // Servis üzerinden yükle
      final reminderMinutes = await _notificationService.getReminderMinutes();
      developer.log('Servis üzerinden yüklenen: $reminderMinutes');
      
      setState(() {
        _currentReminderMinutes = reminderMinutes;
        _reminderMinutesController.text = reminderMinutes.toString();
      });
    } catch (e) {
      developer.log('Ayarlar yüklenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayarlar yüklenirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reminderMinutes = int.tryParse(_reminderMinutesController.text) ?? 30;
      
      // Doğrudan SharedPreferences'e kaydet (hata tespiti için)
      final prefs = await SharedPreferences.getInstance();
      
      // Temizleme ve yeniden yazma stratejisi
      developer.log('Bildirim süresi ayarlanıyor: $reminderMinutes dakika');
      
      // 1. Önce anahtarları temizle
      await prefs.remove('notification_reminder_minutes');
      await prefs.remove('notification_reminder_minutes_str');
      await prefs.remove('notification_storage');
      
      // 2. Değeri birden fazla formatta kaydet (yedekleme)
      await prefs.setInt('notification_reminder_minutes', reminderMinutes);
      await prefs.setString('notification_reminder_minutes_str', reminderMinutes.toString());
      
      final storage = {'reminder_minutes': reminderMinutes};
      await prefs.setString('notification_storage', storage.toString());
      
      // 3. Tüm değerleri doğrula
      final intValue = prefs.getInt('notification_reminder_minutes');
      final strValue = prefs.getString('notification_reminder_minutes_str');
      final storageValue = prefs.getString('notification_storage');
      
      developer.log('Kaydedilen değerler - Int: $intValue, String: $strValue, Storage: $storageValue');
      
      // Bildirim süresini force_reload ile kaydet
      await _notificationService.setReminderMinutes(reminderMinutes, force_reload: true);
      
      // Kaydedilen değeri doğrula
      final savedMinutes = await _notificationService.getReminderMinutes();
      
      developer.log('Servis üzerinden alınan: $savedMinutes');
      
      setState(() {
        _currentReminderMinutes = savedMinutes;
        _reminderMinutesController.text = savedMinutes.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim ayarları kaydedildi: $savedMinutes dakika'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      developer.log('Ayarları kaydetme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ayarlar kaydedilirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Görev Bildirimi Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Görev son tarihinden ne kadar önce bildirim almak istiyorsunuz?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reminderMinutesController,
                          decoration: const InputDecoration(
                            labelText: 'Bildirim Süresi (dakika)',
                            border: OutlineInputBorder(),
                            hintText: '30',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'dakika',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Şu anda, görev son tarihinden $_currentReminderMinutes dakika önce bildirim alacaksınız.',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Not: Görev saati geldiğinde de ayrıca bir bildirim alacaksınız.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Ayarları Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _reminderMinutesController.dispose();
    super.dispose();
  }
} 
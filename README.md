# TaskMate - Görev Takip Uygulaması

TaskMate, kullanıcıların görev oluşturup tamamlayabildikleri, sadece kendilerine ait verileri görebildikleri ve Supabase Authentication ile kimlik doğrulaması yapabildikleri bir Flutter To-Do uygulamasıdır.

## Özellikler

- **Kullanıcı Yönetimi**: Kayıt, giriş ve şifre sıfırlama (Supabase Authentication)
- **Görev Yönetimi**: Oluşturma, düzenleme, silme ve tamamlama
- **Akıllı Filtreleme**: Tüm, tamamlanan, son tarihli, gecikmiş ve yaklaşan görevler
- **Güvenlik**: Kullanıcıya özel görevler (row-level security)
- **Bildirim Sistemi**: Özelleştirilebilir hatırlatmalar ve son tarih bildirimleri
- **Görsel İyileştirmeler**: Modern arayüz ve görev kartları
- **Çevrimdışı Destek**: Offline erişim ve senkronizasyon
- **Türkçe Dil Desteği**: Tamamen Türkçe arayüz

## Son Güncellemeler

### v1.2.0 - 2024-08-05

- **Bildirim Sistemi İyileştirmeleri**:
  - Bildirim süresi kullanıcı tarafından ayarlanabilir hale getirildi
  - SharedPreferences ile kalıcı depolama sorunları çözüldü
  - Uygulama kapatılıp açıldığında kullanıcının belirlediği sürenin sıfırlanması engellendi
  - Görev saati ve görev hatırlatma bildirimleri düzeltildi

- **Görev Filtreleme İyileştirmeleri**:
  - Tamamlanmış görevlerin gecikmiş olarak işaretlenmesi sorunu çözüldü
  - Filtre değiştirme işlemleri optimize edildi
  - Filtreleme sonrası verilerin doğru yüklenmesi sağlandı

- **Kullanıcı Deneyimi İyileştirmeleri**:
  - Gereksiz test bildirimleri kaldırıldı
  - Görev tamamlama işlemi hızlandırıldı
  - Görev kartları tasarımı geliştirildi

## Kurulum

### Gereksinimler

- Flutter 3.x veya üzeri
- Supabase hesabı
- Dart 3.x veya üzeri

### Adımlar

1. Projeyi klonlayın
```bash
git clone https://github.com/your-username/taskmate.git
cd taskmate
```

2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

3. Supabase Ayarları

- [Supabase](https://supabase.io/) üzerinde yeni bir proje oluşturun
- SQL Editor'da aşağıdaki tabloyu oluşturun:

```sql
-- Görevler tablosu
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  deadline TIMESTAMP WITH TIME ZONE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Row Level Security (RLS) politikaları
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Kullanıcı sadece kendi görevlerini görebilir
CREATE POLICY "Users can view their own tasks" ON tasks
  FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcı sadece kendi görevlerini ekleyebilir
CREATE POLICY "Users can insert their own tasks" ON tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Kullanıcı sadece kendi görevlerini düzenleyebilir
CREATE POLICY "Users can update their own tasks" ON tasks
  FOR UPDATE USING (auth.uid() = user_id);

-- Kullanıcı sadece kendi görevlerini silebilir
CREATE POLICY "Users can delete their own tasks" ON tasks
  FOR DELETE USING (auth.uid() = user_id);
```

4. API Anahtarlarının Güvenliği

**ÖNEMLİ**: GitHub'a yüklemeden önce, API anahtarlarınızı gizlemeniz gerekir.

`.env` dosyası oluşturabilir veya `lib/config/app_config.dart` dosyasını düzenleyebilirsiniz:

```dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

Bu dosyayı `.gitignore` dosyanıza eklediğinizden emin olun:
```
lib/config/app_config.dart  # Supabase API anahtarlarını içerir
```

5. Uygulamayı çalıştırın
```bash
flutter run
```

## Yapı

- **lib/config**: Uygulama konfigürasyonu ve API anahtarları
- **lib/models**: Veri modelleri (Task, User, vb.)
- **lib/providers**: State management (TaskProvider, AuthProvider)
- **lib/screens**: Uygulama ekranları (Home, Login, vb.)
- **lib/services**: Servisler (TaskService, NotificationService, vb.)
- **lib/widgets**: Yeniden kullanılabilir UI bileşenleri
- **lib/utils**: Yardımcı fonksiyonlar ve araçlar

## Teknolojiler

- **Flutter**: UI framework
- **Supabase**: Backend as a Service (Auth ve Database)
- **Provider**: State Management
- **Flutter Local Notifications**: Bildirimler
- **Shared Preferences**: Yerel depolama
- **Intl**: Tarih ve dil yerelleştirme

## Güvenlik Önlemleri

Bu projede aşağıdaki güvenlik önlemleri alınmıştır:

1. **API Anahtarları Gizleme**: Supabase anahtarları .gitignore ile korunur
2. **Row-Level Security**: Kullanıcılar sadece kendi verilerine erişebilir
3. **Güvenli Depolama**: Hassas veriler güvenli bir şekilde saklanır
4. **Input Validation**: Kullanıcı girişleri doğrulanır
5. **Error Handling**: Hatalar güvenli bir şekilde yönetilir

## Sorun Giderme

Eğer uygulamayı çalıştırırken sorunlarla karşılaşırsanız:

1. **Bağımlılıkları güncelleyin**: `flutter pub upgrade`
2. **Cache'i temizleyin**: `flutter clean`
3. **Supabase anahtarlarının doğru olduğundan emin olun**
4. **Platform izinlerini kontrol edin**: Bildirimler, depolama, vb.
5. **Log çıktılarını inceleyin**: Hata mesajları genellikle sorunun kaynağını gösterir

## Katkıda Bulunma

1. Bu repo'yu fork edin
2. Yeni bir feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

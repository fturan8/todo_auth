# TaskMate Teknik Altyapısı

## Kullanılan Teknolojiler

### Frontend
- **Flutter**: UI geliştirme framework'ü
- **Dart**: Programlama dili
- **Provider**: State management çözümü
- **Flutter Local Notifications**: Bildirim yönetimi
- **Shared Preferences**: Yerel depolama
- **Intl**: Tarih formatları ve yerelleştirme

### Backend
- **Supabase**: BaaS (Backend as a Service) çözümü
  - **Auth**: Kimlik doğrulama servisi
  - **PostgreSQL**: Veritabanı
  - **Row-Level Security**: Veri güvenliği

## Mimari Yapı

### Klasör Yapısı
- **lib/config**: Uygulama konfigürasyonu ve API anahtarları
- **lib/models**: Veri modelleri (Task, User, vb.)
- **lib/providers**: State management (TaskProvider, AuthProvider)
- **lib/screens**: Uygulama ekranları (Home, Login, vb.)
- **lib/services**: Servisler (TaskService, NotificationService, vb.)
- **lib/widgets**: Yeniden kullanılabilir UI bileşenleri
- **lib/utils**: Yardımcı fonksiyonlar ve araçlar

### Veri Modelleri
- **Task**: id, title, description, isCompleted, deadline, createdAt, userId
- **User**: id, email, metadata

### API Servisleri
- **TaskService**: Görevleri veritabanından getirme, ekleme, güncelleme, silme
- **AuthService**: Kullanıcı kaydı, girişi, çıkışı, şifre sıfırlama
- **NotificationService**: Bildirimleri yönetme, zamanlama, iptal etme

## Önemli Kod Bileşenleri

### Veritabanı Şeması
```sql
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  deadline TIMESTAMP WITH TIME ZONE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);
```

### Bildirim Sistemi
```dart
Future<void> scheduleTaskReminder(Task task) async {
  // Bildirim zamanlaması ve yönetimi
}
```

### Görev Filtreleme
```dart
List<Task> get overdueTasks => _overdueTasks.where((task) => !task.isCompleted).toList();
```

## Güvenlik Önlemleri

### API Anahtarlarının Gizlenmesi
```dart
class AppConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### Row-Level Security
```sql
CREATE POLICY "Users can view their own tasks" ON tasks
  FOR SELECT USING (auth.uid() = user_id);
```

## Performans Optimizasyonları
- Görev listelerinin ayrı ayrı tutulması (deadline, overdue, upcoming)
- Bildirimlerin etkin yönetimi ve gereksiz bildirimlerin engellenmesi
- SharedPreferences ile uygulama ayarlarının etkili yönetimi
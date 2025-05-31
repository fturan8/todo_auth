# TaskMate Görev Takip Uygulaması Projesi

## Proje Amacı
TaskMate, kullanıcıların görevlerini etkili bir şekilde organize etmelerini, takip etmelerini ve yönetmelerini sağlayan bir Flutter mobil uygulamasıdır. Uygulama, Supabase Authentication ve veritabanı ile entegre çalışarak kullanıcıların sadece kendi görevlerine erişebilmelerini sağlar, son tarihli görevler için bildirimler gönderir ve görevleri çeşitli kriterlere göre filtreleme imkanı sunar.

## Proje Kapsamı
- Kullanıcı kimlik doğrulama (kayıt, giriş, şifre sıfırlama)
- Görev oluşturma, düzenleme, silme ve tamamlama işlevleri
- Son tarihli, gecikmiş ve yaklaşan görevlerin görüntülenmesi
- Özelleştirilebilir bildirim ayarları
- Görevlerin duruma göre filtrelenmesi (tamamlanan, son tarihli, gecikmiş, yaklaşan)
- Türkçe dil desteği

## Çözülen Sorunlar
1. **Bildirim Sistemi İyileştirmeleri**:
   - Bildirim süresi ayarlarının kullanıcı tarafından özelleştirilebilmesi
   - SharedPreferences ile ayarların kalıcı olarak saklanması
   - Uygulama kapatılıp açıldığında ayarların korunması

2. **Görev Filtreleme İyileştirmeleri**:
   - Tamamlanmış görevlerin gecikmiş olarak işaretlenmemesi
   - Filtre değiştirme işlemlerinin optimize edilmesi
   - Filtreleme sonrası verilerin doğru yüklenmesi

3. **Kullanıcı Deneyimi İyileştirmeleri**:
   - Görev kartları tasarımının iyileştirilmesi
   - Görev tamamlama işleminin hızlandırılması
   - Gereksiz bildirimlerin engellenmesi

## Teknik Detaylar
- **Backend**: Supabase (Auth ve PostgreSQL veritabanı)
- **Frontend**: Flutter ile geliştirilen cross-platform mobil uygulama
- **State Management**: Provider pattern
- **Bildirimler**: Flutter Local Notifications
- **Yerel Depolama**: Shared Preferences
- **Dil Desteği**: Flutter Intl ve Localizations

## Güvenlik Önlemleri
- Supabase Row-Level Security ile kullanıcı verilerinin korunması
- API anahtarlarının .gitignore ile korunması
- Hassas verilerin güvenli bir şekilde depolanması
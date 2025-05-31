class AppConfig {
  // Supabase ayarları - .env dosyasından yüklenmelidir
  static const String supabaseUrl = 'YOUR_SUPABASE_URL'; // .env dosyasından alınmalı
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // .env dosyasından alınmalı

  // ÖNEMLİ: Bu dosyayı GitHub'a yüklemeden önce:
  // 1. Gerçek API anahtarlarınızı buraya eklemeyiniz
  // 2. Gerçek bir projede .env dosyası ve dotenv paketi kullanın
  // 3. .gitignore dosyanızda bu dosyayı veya API anahtarlarını içeren herhangi bir dosyayı ekleyin
} 
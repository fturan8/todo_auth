import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  
  Future<List<Task>> getTasks() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    try {
      developer.log('Görevler alınıyor: user_id=${user.id}');
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      
      developer.log('Alınan görevler: ${response.toString()}');
      return (response as List<dynamic>)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();
    } catch (e) {
      developer.log('Görevleri alma hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<Task> createTask(String title, String? description, DateTime? deadline) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    if (deadline != null) {
      final isUtc = deadline.isUtc;
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      developer.log('Timezone farkı: ${offset.inHours} saat, ${offset.inMinutes % 60} dakika');
      developer.log('Deadline (orijinal): $deadline, UTC mi: $isUtc');
      
      if (!isUtc) {
        deadline = deadline.toUtc();
        developer.log('Deadline (UTC formatında): $deadline');
      }
    }

    final data = {
      'title': title,
      'description': description,
      'is_completed': false,
      'deadline': deadline?.toIso8601String(),
      'user_id': user.id,
    };

    try {
      developer.log('Görev oluşturuluyor: $data');
      final response = await _supabaseClient.from('tasks').insert(data).select();
      developer.log('Oluşturulan görev yanıtı: ${response.toString()}');
      
      if (response.isEmpty) {
        throw Exception('Görev oluşturuldu ancak dönen veri yok');
      }
      
      return Task.fromJson(response.first);
    } catch (e) {
      developer.log('Görev oluşturma hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<Task> updateTask(Task task) async {
    try {
      // Deadline'ı kontrol edelim ve UTC'ye çevirelim
      DateTime? taskDeadline = task.deadline;
      if (taskDeadline != null && !taskDeadline.isUtc) {
        taskDeadline = taskDeadline.toUtc();
        developer.log('Güncelleme için deadline UTC formatına çevrildi: $taskDeadline');
        // Task'ı kopyalayarak deadline'ı UTC formatında güncelleyelim
        task = task.copyWith(deadline: taskDeadline);
      }
      
      developer.log('Görev güncelleniyor: ${task.toJson()}');
      final response = await _supabaseClient
          .from('tasks')
          .update(task.toJson())
          .eq('id', task.id)
          .select();
      
      developer.log('Güncellenen görev yanıtı: ${response.toString()}');
      return Task.fromJson(response.first);
    } catch (e) {
      developer.log('Görev güncelleme hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      developer.log('Görev siliniyor: $taskId');
      await _supabaseClient.from('tasks').delete().eq('id', taskId);
      developer.log('Görev silindi: $taskId');
    } catch (e) {
      developer.log('Görev silme hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<Task> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    return await updateTask(updatedTask);
  }

  Future<List<Task>> getTasksByDeadline() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    try {
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .not('deadline', 'is', null)
          .eq('is_completed', false)
          .order('deadline', ascending: true);
      
      return (response as List<dynamic>)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();
    } catch (e) {
      developer.log('Görevleri alma hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<List<Task>> getOverdueTasks() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    developer.log('Şu anki UTC zaman: $now');
    
    try {
      // Sadece tamamlanmamış ve geçmiş deadline'ı olan görevleri al
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .eq('is_completed', false) // Kesinlikle sadece tamamlanmamış görevler
          .not('deadline', 'is', null)
          .lt('deadline', now)
          .order('deadline', ascending: true);
      
      developer.log('Gecikmeli görevler sorgusu yapıldı: ${response.toString()}');
      
      // Veritabanından gelen timestamp'leri ve lokal zamanı kontrol et
      final tasks = (response as List<dynamic>)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();
          
      // Ekstra kontrol - gerçekten gecikmeli ve tamamlanmamış mı?
      final filteredTasks = tasks.where((task) {
        if (task.deadline == null || task.isCompleted) return false;
        
        final localNow = DateTime.now();
        final taskDeadlineLocal = task.deadline!;
        final isOverdue = taskDeadlineLocal.isBefore(localNow);
        
        developer.log('Gecikmiş görev kontrolü: ${task.title}, deadline: ${task.deadline}, şimdi: $localNow, gecikmiş mi: $isOverdue, tamamlanmış mı: ${task.isCompleted}');
        
        // Sadece gecikmiş VE tamamlanmamış olanlar
        return isOverdue && !task.isCompleted;
      }).toList();
      
      developer.log('Filtrelenmiş gecikmeli görev sayısı: ${filteredTasks.length}, görevler: ${filteredTasks.map((t) => t.title).join(", ")}');
      return filteredTasks;
    } catch (e) {
      developer.log('Gecikmeli görevleri alma hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }

  Future<List<Task>> getUpcomingTasks() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    
    try {
      // Sadece tamamlanmamış ve gelecek deadline'ı olan görevleri al
      final response = await _supabaseClient
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .eq('is_completed', false) // Kesinlikle sadece tamamlanmamış görevler
          .not('deadline', 'is', null)
          .gte('deadline', now)
          .order('deadline', ascending: true);
      
      final tasks = (response as List<dynamic>)
          .map((taskJson) => Task.fromJson(taskJson))
          .toList();
          
      // Ekstra kontrol - gerçekten yaklaşan ve tamamlanmamış mı?
      final filteredTasks = tasks.where((task) {
        if (task.deadline == null || task.isCompleted) return false;
        
        final localNow = DateTime.now();
        final taskDeadlineLocal = task.deadline!;
        final isUpcoming = taskDeadlineLocal.isAfter(localNow) || 
                          taskDeadlineLocal.difference(localNow).inMinutes == 0;
                          
        developer.log('Yaklaşan görev kontrolü: ${task.title}, deadline: ${task.deadline}, şimdi: $localNow, yaklaşan mı: $isUpcoming, tamamlanmış mı: ${task.isCompleted}');
        
        // Sadece yaklaşan VE tamamlanmamış olanlar
        return isUpcoming && !task.isCompleted;
      }).toList();
      
      developer.log('Yaklaşan görev sayısı: ${filteredTasks.length}, görevler: ${filteredTasks.map((t) => t.title).join(", ")}');
      return filteredTasks;
    } catch (e) {
      developer.log('Yaklaşan görevleri alma hatası: ${e.toString()}', error: e);
      rethrow;
    }
  }
} 
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import 'dart:developer' as developer;

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final NotificationService _notificationService = NotificationService();
  List<Task> _tasks = [];
  List<Task> _deadlineTasks = [];
  List<Task> _overdueTasks = [];
  List<Task> _upcomingTasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtreleme için
  bool _showOnlyCompleted = false;
  bool _showOnlyWithDeadline = false;
  bool _showOnlyOverdue = false;
  bool _showOnlyUpcoming = false;

  List<Task> get tasks {
    if (_showOnlyCompleted) {
      return _tasks.where((task) => task.isCompleted).toList();
    } else if (_showOnlyWithDeadline) {
      return _deadlineTasks;
    } else if (_showOnlyOverdue) {
      return _overdueTasks;
    } else if (_showOnlyUpcoming) {
      return _upcomingTasks;
    }
    return _tasks;
  }

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get tasksWithDeadline => _deadlineTasks;
  
  // Gecikmiş görevler - tamamlanmış olanları hariç tut
  List<Task> get overdueTasks => _overdueTasks.where((task) => !task.isCompleted).toList();
  
  // Yaklaşan görevler - tamamlanmış olanları hariç tut
  List<Task> get upcomingTasks => _upcomingTasks.where((task) => !task.isCompleted).toList();
  
  // Gecikmiş görev sayısı - tamamlanmış olanları hariç tut
  int get overdueTasksCount => _overdueTasks.where((task) => !task.isCompleted).length;
  
  // Yaklaşan görev sayısı - tamamlanmış olanları hariç tut
  int get upcomingTasksCount => _upcomingTasks.where((task) => !task.isCompleted).length;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showOnlyCompleted => _showOnlyCompleted;
  bool get showOnlyWithDeadline => _showOnlyWithDeadline;
  bool get showOnlyOverdue => _showOnlyOverdue;
  bool get showOnlyUpcoming => _showOnlyUpcoming;

  TaskProvider() {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _taskService.getTasks();
      
      // Diğer listeleri doldur
      await fetchTasksByDeadline();
      await fetchOverdueTasks();
      await fetchUpcomingTasks();
      
      // Konsola durumu yazdır
      final completedTasks = _tasks.where((t) => t.isCompleted).toList();
      developer.log('Görevlerin durumu: '
          'Toplam: ${_tasks.length}, '
          'Tamamlanan: ${completedTasks.length}, '
          'Tamamlanmayan: ${_tasks.length - completedTasks.length}, '
          'Son Tarihli: ${_deadlineTasks.length}, '
          'Gecikmiş: ${_overdueTasks.length}, '
          'Yaklaşan: ${_upcomingTasks.length}');
      
      // Gecikmiş görevi logla
      if (_overdueTasks.isNotEmpty) {
        for (final task in _overdueTasks) {
          developer.log('GECİKMİŞ GÖREV: ${task.title}, Tamamlanmış: ${task.isCompleted}, Deadline: ${task.deadline}');
        }
      }
      
      // Kesinlikle tamamlanmış görevleri overdue listesinden çıkar
      _overdueTasks = _overdueTasks.where((task) => !task.isCompleted).toList();
      _upcomingTasks = _upcomingTasks.where((task) => !task.isCompleted).toList();
      
      // Güncelleme sonrası kontrol
      developer.log('FİLTRELEME SONRASI: '
          'Gecikmiş: ${_overdueTasks.length}, '
          'Yaklaşan: ${_upcomingTasks.length}');
      
      // Bildirimleri programla
      _scheduleNotificationsForTasks();
    } catch (e) {
      _errorMessage = 'Görevler yüklenemedi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _scheduleNotificationsForTasks() {
    // Tamamlanmayan ve deadline'ı olan görevler için bildirim planla
    int count = 0;
    for (final task in _tasks) {
      if (!task.isCompleted && task.deadline != null) {
        _notificationService.scheduleTaskReminder(task);
        count++;
      }
    }
    print('Toplam $count görev için bildirimler yeniden programlandı');
  }

  Future<void> fetchTasksByDeadline() async {
    try {
      _deadlineTasks = await _taskService.getTasksByDeadline();
      developer.log('Son tarihli görevler yüklendi: ${_deadlineTasks.length}');
    } catch (e) {
      developer.log('Son tarihli görevleri yükleme hatası: $e');
      // Hata oluşsa bile ana hatayı etkilemesin
    }
  }

  Future<void> fetchOverdueTasks() async {
    try {
      _overdueTasks = await _taskService.getOverdueTasks();
      developer.log('Gecikmiş görevler yüklendi: ${_overdueTasks.length}');
    } catch (e) {
      developer.log('Gecikmiş görevleri yükleme hatası: $e');
      // Hata oluşsa bile ana hatayı etkilemesin
    }
  }
  
  Future<void> fetchUpcomingTasks() async {
    try {
      _upcomingTasks = await _taskService.getUpcomingTasks();
      developer.log('Yaklaşan görevler yüklendi: ${_upcomingTasks.length}');
    } catch (e) {
      developer.log('Yaklaşan görevleri yükleme hatası: $e');
      // Hata oluşsa bile ana hatayı etkilemesin
    }
  }

  Future<bool> toggleTaskCompletion(Task task, {BuildContext? context}) async {
    // Önce kullanıcı arayüzünü hemen güncelleyelim
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    
    // Görev listesinde güncelleme yap
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = updatedTask;
      
      // Eğer görev tamamlandıysa, gecikmiş ve yaklaşan listelerinden çıkar
      if (updatedTask.isCompleted) {
        _overdueTasks.removeWhere((t) => t.id == task.id);
        _upcomingTasks.removeWhere((t) => t.id == task.id);
        developer.log('Görev tamamlandı, listelerden çıkarıldı: ${task.title}');
      }
      
      // UI'ı hemen güncelle
      notifyListeners(); 
    }
    
    try {
      // Veritabanında güncelleme yap
      final dbUpdatedTask = await _taskService.toggleTaskCompletion(task);
      
      // Görev tamamlandıysa, bildirimleri iptal et
      if (dbUpdatedTask.isCompleted) {
        await _notificationService.cancelTaskReminder(task.id);
        developer.log('Görev tamamlandı, bildirimleri iptal edildi: ${task.title}');
      } else {
        // Görev tekrar aktifleştirilmişse ve deadline'ı varsa, bildirimleri yeniden planla
        if (dbUpdatedTask.deadline != null) {
          await _notificationService.scheduleTaskReminder(dbUpdatedTask);
          developer.log('Görev tamamlanmadı olarak işaretlendi, bildirimleri yeniden planlandı: ${task.title}');
        }
      }
      
      // Tüm liste verilerini yeniden yükle (bu en güvenilir yöntem)
      await fetchTasksByDeadline();
      await fetchOverdueTasks();
      await fetchUpcomingTasks();
      
      // Değişikliği diğer ekranlara da bildir
      notifyListeners();
      
      return true;
    } catch (e) {
      // Hata durumunda orijinal görevi geri yükle
      if (index >= 0) {
        _tasks[index] = task;
        notifyListeners();
      }
      
      // Hata mesajını kaydet
      _errorMessage = 'Görev durumu güncellenemedi';
      
      // Context varsa hata bildirimini göster
      if (context != null) {
        _showErrorSnackbar(
          context, 
          'Görev durumu değiştirilirken bir sorun oluştu. Lütfen tekrar deneyin.'
        );
      }
      
      return false;
    }
  }

  Future<void> addTask(String title, String? description, {DateTime? deadline}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTask = await _taskService.createTask(title, description, deadline);
      _tasks.insert(0, newTask); // Yeni görev en başa eklenir
      
      // Gerekirse deadline ve overdue listelerini güncelle
      if (deadline != null) {
        await fetchTasksByDeadline();
        await fetchOverdueTasks();
        await fetchUpcomingTasks();
        
        // Bildirimi planla ve log ekle
        await _notificationService.scheduleTaskReminder(newTask);
        developer.log('Yeni görev için bildirim programlandı: ${newTask.title}');
      }
    } catch (e) {
      _errorMessage = 'Görev eklenemedi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask(Task task) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTask = await _taskService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        _tasks[index] = updatedTask;
      }
      
      // Deadline veya tamamlanma durumu değiştiyse listeleri güncelle
      if (task.deadline != null || updatedTask.isCompleted != task.isCompleted) {
        await fetchTasksByDeadline();
        await fetchOverdueTasks();
        await fetchUpcomingTasks();
        
        // Bildirimi güncelle
        _notificationService.scheduleTaskReminder(updatedTask);
      }
    } catch (e) {
      _errorMessage = 'Görev güncellenemedi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _taskService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _deadlineTasks.removeWhere((task) => task.id == taskId);
      _overdueTasks.removeWhere((task) => task.id == taskId);
      _upcomingTasks.removeWhere((task) => task.id == taskId);
      
      // Bildirimi iptal et
      _notificationService.cancelTaskReminder(taskId);
    } catch (e) {
      _errorMessage = 'Görev silinemedi: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleShowOnlyCompleted() {
    _showOnlyCompleted = !_showOnlyCompleted;
    if (_showOnlyCompleted) {
      _showOnlyWithDeadline = false;
      _showOnlyOverdue = false;
      _showOnlyUpcoming = false;
    }
    developer.log('Filtreleme değişti: tamamlananlar=$_showOnlyCompleted');
    notifyListeners();
  }

  void toggleShowOnlyWithDeadline() {
    _showOnlyWithDeadline = !_showOnlyWithDeadline;
    if (_showOnlyWithDeadline) {
      _showOnlyCompleted = false;
      _showOnlyOverdue = false;
      _showOnlyUpcoming = false;
    }
    developer.log('Filtreleme değişti: son tarihliler=$_showOnlyWithDeadline');
    notifyListeners();
  }

  void toggleShowOnlyOverdue() {
    _showOnlyOverdue = !_showOnlyOverdue;
    if (_showOnlyOverdue) {
      _showOnlyCompleted = false;
      _showOnlyWithDeadline = false;
      _showOnlyUpcoming = false;
    }
    developer.log('Filtreleme değişti: gecikmişler=$_showOnlyOverdue');
    notifyListeners();
  }
  
  void toggleShowOnlyUpcoming() {
    _showOnlyUpcoming = !_showOnlyUpcoming;
    if (_showOnlyUpcoming) {
      _showOnlyCompleted = false;
      _showOnlyWithDeadline = false;
      _showOnlyOverdue = false;
    }
    developer.log('Filtreleme değişti: yaklaşanlar=$_showOnlyUpcoming');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Hata mesajlarını göstermek için yardımcı metod
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 
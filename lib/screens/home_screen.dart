import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_dialog.dart';
import 'notification_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Widget oluşturulduktan sonra görevleri getir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final user = authProvider.user;

    // Tamamlanmamış görevleri sayalım
    final pendingCount = taskProvider.pendingTasks.length;
    
    // Tamamlanmamış gecikmiş görevleri sayalım
    final overdueCount = taskProvider.overdueTasks.length;
    
    // Tamamlanmamış yaklaşan görevleri sayalım
    final upcomingCount = taskProvider.upcomingTasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskMate'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtreleme Seçenekleri',
            onSelected: (value) {
              switch (value) {
                case 'all':
                  // Tüm filtreleri kapat
                  if (taskProvider.showOnlyCompleted) {
                    taskProvider.toggleShowOnlyCompleted();
                  }
                  if (taskProvider.showOnlyWithDeadline) {
                    taskProvider.toggleShowOnlyWithDeadline();
                  }
                  if (taskProvider.showOnlyOverdue) {
                    taskProvider.toggleShowOnlyOverdue();
                  }
                  if (taskProvider.showOnlyUpcoming) {
                    taskProvider.toggleShowOnlyUpcoming();
                  }
                  setState(() {}); // UI'ı güncelle
                  break;
                case 'completed':
                  setState(() {
                    // Diğer filtreler açıksa kapat
                    if (taskProvider.showOnlyWithDeadline) {
                      taskProvider.toggleShowOnlyWithDeadline();
                    }
                    if (taskProvider.showOnlyOverdue) {
                      taskProvider.toggleShowOnlyOverdue();
                    }
                    if (taskProvider.showOnlyUpcoming) {
                      taskProvider.toggleShowOnlyUpcoming();
                    }
                    // Tamamlananlar filtresini aç/kapat
                    taskProvider.toggleShowOnlyCompleted();
                  });
                  break;
                case 'deadline':
                  setState(() {
                    // Diğer filtreler açıksa kapat
                    if (taskProvider.showOnlyCompleted) {
                      taskProvider.toggleShowOnlyCompleted();
                    }
                    if (taskProvider.showOnlyOverdue) {
                      taskProvider.toggleShowOnlyOverdue();
                    }
                    if (taskProvider.showOnlyUpcoming) {
                      taskProvider.toggleShowOnlyUpcoming();
                    }
                    // Son tarihli görevler filtresini aç/kapat
                    taskProvider.toggleShowOnlyWithDeadline();
                  });
                  break;
                case 'overdue':
                  setState(() {
                    // Diğer filtreler açıksa kapat
                    if (taskProvider.showOnlyCompleted) {
                      taskProvider.toggleShowOnlyCompleted();
                    }
                    if (taskProvider.showOnlyWithDeadline) {
                      taskProvider.toggleShowOnlyWithDeadline();
                    }
                    if (taskProvider.showOnlyUpcoming) {
                      taskProvider.toggleShowOnlyUpcoming();
                    }
                    // Gecikmiş görevler filtresini aç/kapat
                    taskProvider.toggleShowOnlyOverdue();
                  });
                  break;
                case 'upcoming':
                  setState(() {
                    // Diğer filtreler açıksa kapat
                    if (taskProvider.showOnlyCompleted) {
                      taskProvider.toggleShowOnlyCompleted();
                    }
                    if (taskProvider.showOnlyWithDeadline) {
                      taskProvider.toggleShowOnlyWithDeadline();
                    }
                    if (taskProvider.showOnlyOverdue) {
                      taskProvider.toggleShowOnlyOverdue();
                    }
                    // Yaklaşan görevler filtresini aç/kapat
                    taskProvider.toggleShowOnlyUpcoming();
                  });
                  break;
              }
              
              // Filtreleme sonrası verilerin güncellenmesi
              taskProvider.fetchTasks();
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'all',
                child: Text('Tümünü Göster'),
              ),
              PopupMenuItem<String>(
                value: 'completed',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: taskProvider.showOnlyCompleted
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Tamamlananlar'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'deadline',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: taskProvider.showOnlyWithDeadline
                          ? Colors.orange
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Son Tarihli Görevler'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'overdue',
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: taskProvider.showOnlyOverdue
                          ? Colors.red
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Gecikmiş Görevler'),
                    if (taskProvider.overdueTasks.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${taskProvider.overdueTasks.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'upcoming',
                child: Row(
                  children: [
                    Icon(
                      Icons.upcoming,
                      color: taskProvider.showOnlyUpcoming
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text('Yaklaşan Görevler'),
                    if (taskProvider.upcomingTasks.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${taskProvider.upcomingTasks.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
            tooltip: 'Bildirim Ayarları',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, ${user?.email?.split('@').first ?? 'Kullanıcı'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getFilterStatusText(taskProvider),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$pendingCount Bekleyen',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (overdueCount > 0)
                      Text(
                        '$overdueCount Gecikmiş',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (upcomingCount > 0)
                      Text(
                        '$upcomingCount Yaklaşan',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          if (taskProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (taskProvider.tasks.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                itemCount: taskProvider.tasks.length,
                itemBuilder: (context, index) {
                  final task = taskProvider.tasks[index];
                  return TaskItem(
                    task: task,
                    onToggle: (context) => taskProvider.toggleTaskCompletion(task, context: context),
                    onDelete: () => _confirmDelete(context, task),
                    onEdit: () => _showEditDialog(context, task),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Görev Ekle',
      ),
    );
  }

  String _getFilterStatusText(TaskProvider taskProvider) {
    if (taskProvider.showOnlyCompleted) {
      return 'Tamamlanan görevler listeleniyor';
    } else if (taskProvider.showOnlyWithDeadline) {
      return 'Son tarihli görevler listeleniyor';
    } else if (taskProvider.showOnlyOverdue) {
      return 'Gecikmiş görevler listeleniyor';
    } else if (taskProvider.showOnlyUpcoming) {
      return 'Yaklaşan görevler listeleniyor';
    } else {
      return 'Tüm görevleriniz';
    }
  }

  Widget _buildEmptyState() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(taskProvider),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateTitle(taskProvider),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(taskProvider),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmptyStateIcon(TaskProvider taskProvider) {
    if (taskProvider.showOnlyCompleted) {
      return Icons.check_circle_outline;
    } else if (taskProvider.showOnlyWithDeadline) {
      return Icons.calendar_today;
    } else if (taskProvider.showOnlyOverdue) {
      return Icons.warning_amber_outlined;
    } else if (taskProvider.showOnlyUpcoming) {
      return Icons.upcoming;
    } else {
      return Icons.task_alt;
    }
  }

  String _getEmptyStateTitle(TaskProvider taskProvider) {
    if (taskProvider.showOnlyCompleted) {
      return 'Henüz tamamlanmış görev yok';
    } else if (taskProvider.showOnlyWithDeadline) {
      return 'Son tarihli görev yok';
    } else if (taskProvider.showOnlyOverdue) {
      return 'Gecikmiş görev yok';
    } else if (taskProvider.showOnlyUpcoming) {
      return 'Yaklaşan görev yok';
    } else {
      return 'Henüz görev eklenmemiş';
    }
  }

  String _getEmptyStateMessage(TaskProvider taskProvider) {
    if (taskProvider.showOnlyCompleted) {
      return 'Görevlerinizi tamamladığınızda burada görünecekler';
    } else if (taskProvider.showOnlyWithDeadline) {
      return 'Son tarihli görevleriniz burada görünecek';
    } else if (taskProvider.showOnlyOverdue) {
      return 'Tebrikler! Hiç gecikmiş göreviniz yok';
    } else if (taskProvider.showOnlyUpcoming) {
      return 'Yaklaşan görevleriniz burada görünecek';
    } else {
      return 'Yeni görev eklemek için + butonuna tıklayın';
    }
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddTaskDialog();
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, Task task) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTaskDialog(taskToEdit: task);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Görevi Sil'),
          content: const Text('Bu görevi silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<TaskProvider>(context, listen: false)
                    .deleteTask(task.id);
                Navigator.of(context).pop();
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
} 
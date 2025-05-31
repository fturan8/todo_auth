import 'package:flutter/material.dart';
import '../models/task.dart';
import 'package:intl/intl.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final Function(BuildContext) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final dateTimeFormat = DateFormat('dd MMMM yyyy HH:mm', 'tr_TR');
    final formattedDate = dateFormat.format(task.createdAt);
    final now = DateTime.now();
    final bool isOverdue = task.deadline != null && 
                          task.deadline!.isBefore(now) && 
                          !task.isCompleted;
    
    // Yaklaşan görev durumu
    final bool isUpcoming = task.deadline != null && 
                           task.deadline!.isAfter(now) && 
                           !task.isCompleted;
                           
    // Görev durumu
    final String taskStatus = task.isCompleted 
        ? 'Tamamlandı' 
        : (isOverdue 
            ? 'Gecikmiş' 
            : (isUpcoming ? 'Yaklaşan' : 'Devam Ediyor'));
            
    // Görev durumu rengi
    final Color statusColor = task.isCompleted 
        ? Colors.green 
        : (isOverdue 
            ? Colors.red 
            : (isUpcoming ? Colors.blue : Colors.orange));
    
    // Kart arka plan rengi
    final Color cardColor = isOverdue 
        ? Colors.red.withOpacity(0.1) 
        : (isUpcoming 
            ? Colors.blue.withOpacity(0.1) 
            : (task.isCompleted 
                ? Colors.green.withOpacity(0.05) 
                : Colors.white));
    
    // Kart kenarlık rengi
    final Color borderColor = isOverdue 
        ? Colors.red.withOpacity(0.3) 
        : (isUpcoming 
            ? Colors.blue.withOpacity(0.3) 
            : (task.isCompleted 
                ? Colors.green.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.2)));

    // Küçük kart görünümü
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: () => _showTaskDetails(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onToggle(context),
                activeColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.deadline != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.deadline!.day} ${_getMonthName(task.deadline!.month)}, ${task.deadline!.hour.toString().padLeft(2, '0')}:${task.deadline!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  taskStatus,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showOptionsMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showTaskDetails(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'tr_TR');
    final timeFormat = DateFormat('HH:mm', 'tr_TR');
    final now = DateTime.now();
    final bool isOverdue = task.deadline != null && 
                          task.deadline!.isBefore(now) && 
                          !task.isCompleted;
    
    // Yaklaşan görev durumu
    final bool isUpcoming = task.deadline != null && 
                           task.deadline!.isAfter(now) && 
                           !task.isCompleted;
                           
    // Görev durumu
    final String taskStatus = task.isCompleted 
        ? 'Tamamlandı' 
        : (isOverdue 
            ? 'Gecikmiş' 
            : (isUpcoming ? 'Yaklaşan' : 'Devam Ediyor'));
            
    // Görev durumu rengi
    final Color statusColor = task.isCompleted 
        ? Colors.green 
        : (isOverdue 
            ? Colors.red 
            : (isUpcoming ? Colors.blue : Colors.orange));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              task.isCompleted 
                ? Icons.check_circle 
                : (isOverdue 
                    ? Icons.warning 
                    : (isUpcoming 
                        ? Icons.upcoming 
                        : Icons.pending_actions)),
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description != null && task.description!.isNotEmpty) ...[
                const Text(
                  'Açıklama:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
              
              // Durum
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      task.isCompleted 
                        ? Icons.check_circle 
                        : (isOverdue 
                            ? Icons.warning 
                            : (isUpcoming 
                                ? Icons.upcoming 
                                : Icons.pending_actions)),
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      taskStatus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Oluşturulma Tarihi
              const Text(
                'Oluşturulma Tarihi:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateFormat.format(task.createdAt),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Son Tarih
              if (task.deadline != null) ...[
                const Text(
                  'Son Tarih:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(task.deadline!),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isOverdue ? Colors.red : Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeFormat.format(task.deadline!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? Colors.red : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      if (isOverdue) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getOverdueDuration(task.deadline!, now),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit();
            },
            child: const Text('Düzenle'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onToggle(context);
            },
            child: Text(task.isCompleted ? 'Tamamlanmadı İşaretle' : 'Tamamlandı İşaretle'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
  
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  title: const Text('Detayları Göster'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTaskDetails(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.orange),
                  title: const Text('Düzenle'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                ListTile(
                  leading: Icon(
                    task.isCompleted ? Icons.check_box_outline_blank : Icons.check_box,
                    color: task.isCompleted ? Colors.grey : Colors.green,
                  ),
                  title: Text(task.isCompleted ? 'Tamamlanmadı İşaretle' : 'Tamamlandı İşaretle'),
                  onTap: () {
                    Navigator.pop(context);
                    onToggle(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Sil'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _confirmDelete(BuildContext context) {
    showDialog(
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
                Navigator.of(context).pop();
                onDelete();
              },
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  String _getOverdueDuration(DateTime deadline, DateTime now) {
    final difference = now.difference(deadline);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün gecikmiş';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat gecikmiş';
    } else {
      return '${difference.inMinutes} dakika gecikmiş';
    }
  }
  
  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Ocak';
      case 2: return 'Şubat';
      case 3: return 'Mart';
      case 4: return 'Nisan';
      case 5: return 'Mayıs';
      case 6: return 'Haziran';
      case 7: return 'Temmuz';
      case 8: return 'Ağustos';
      case 9: return 'Eylül';
      case 10: return 'Ekim';
      case 11: return 'Kasım';
      case 12: return 'Aralık';
      default: return '';
    }
  }
} 
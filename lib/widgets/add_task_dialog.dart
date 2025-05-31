import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskDialog({Key? key, this.taskToEdit}) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;

  bool get isEditMode => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description ?? '';
      _selectedDeadline = widget.taskToEdit!.deadline;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = _selectedDeadline ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            picked.year, 
            picked.month, 
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _removeDeadline() {
    setState(() {
      _selectedDeadline = null;
    });
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      try {
        if (isEditMode) {
          final updatedTask = widget.taskToEdit!.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
            deadline: _selectedDeadline,
          );
          await taskProvider.updateTask(updatedTask);
        } else {
          await taskProvider.addTask(
            _titleController.text.trim(),
            _descriptionController.text.trim().isEmpty 
                ? null 
                : _descriptionController.text.trim(),
            deadline: _selectedDeadline,
          );
        }
        
        if (taskProvider.errorMessage != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(taskProvider.errorMessage!)),
            );
          }
        } else {
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    
    return AlertDialog(
      title: Text(isEditMode ? 'Görevi Düzenle' : 'Yeni Görev Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (taskProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    taskProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen bir başlık girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (İsteğe bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Son Tarih (İsteğe bağlı)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: _selectedDeadline != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _removeDeadline,
                          )
                        : null,
                  ),
                  child: _selectedDeadline != null
                      ? Text(dateFormat.format(_selectedDeadline!))
                      : const Text('Son tarih seçin'),
                ),
              ),
              if (_selectedDeadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDeadline!.isBefore(DateTime.now())
                            ? 'Bu görev için son tarih geçmiş!'
                            : 'Bu görev için son tarih belirlenmiş.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedDeadline!.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: taskProvider.isLoading 
              ? null 
              : _saveTask,
          child: taskProvider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditMode ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }
} 
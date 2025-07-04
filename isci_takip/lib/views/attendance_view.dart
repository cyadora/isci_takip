import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../models/worker_model.dart';
import '../view_models/worker_view_model.dart';
import '../view_models/project_view_model.dart';
import '../view_models/attendance_view_model.dart';
import '../services/firestore_service.dart';
import 'monthly_report_view.dart';

class AttendanceView extends StatefulWidget {
  final ProjectModel project;

  const AttendanceView({super.key, required this.project});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  final Map<String, bool> _attendanceMap = {};
  final Map<String, WorkerModel> _workersMap = {};
  bool _isLoading = false;
  List<String> _assignedWorkerIds = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAssignedWorkers();
  }

  Future<void> _loadAssignedWorkers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the latest project data to ensure we have the most up-to-date assignedWorkerIds
      final projectViewModel = Provider.of<ProjectViewModel>(context, listen: false);
      // Use the FirestoreService directly since _firestoreService is private
      final firestoreService = FirestoreService();
      final updatedProject = await firestoreService.getProject(widget.project.id);
      
      if (updatedProject != null) {
        _assignedWorkerIds = updatedProject.assignedWorkerIds;
      } else {
        // Fallback to the project passed to the widget
        _assignedWorkerIds = widget.project.assignedWorkerIds;
      }
      
      // Make sure worker view model is initialized
      final workerViewModel = Provider.of<WorkerViewModel>(context, listen: false);
      if (workerViewModel.workers.isEmpty) {
        workerViewModel.init();
        // Wait for the workers to load
        await Future.delayed(const Duration(seconds: 1));
      }

      // Create a map of worker IDs to worker models for easy lookup
      for (final worker in workerViewModel.workers) {
        _workersMap[worker.id] = worker;
      }

      // Debug output
      print('Assigned worker IDs: $_assignedWorkerIds');
      print('Workers map keys: ${_workersMap.keys.toList()}');

      // Initialize attendance map with all workers present by default
      for (final workerId in _assignedWorkerIds) {
        _attendanceMap[workerId] = true;
      }
    } catch (e) {
      if (mounted) {
        print('Error loading assigned workers: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sarsılmaz İnşaat - Yoklama: ${widget.project.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Bugün için yoklama alın',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mevcut İşçi Sayısı: ${_attendanceMap.entries.where((entry) => entry.value).length}/${_attendanceMap.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Date display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  _getFormattedDate(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWorkersList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Consumer<AttendanceViewModel>(
                        builder: (context, viewModel, child) {
                          return ElevatedButton(
                            onPressed: viewModel.isLoading ? null : _saveAttendance,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: viewModel.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Yoklamayı Kaydet'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MonthlyReportView(project: widget.project),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Aylık Raporu Görüntüle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersList() {
    if (_assignedWorkerIds.isEmpty) {
      return const Center(
        child: Text('Bu projeye atanmış işçi bulunmamaktadır'),
      );
    }

    return ListView.builder(
      itemCount: _assignedWorkerIds.length,
      itemBuilder: (context, index) {
        final workerId = _assignedWorkerIds[index];
        final worker = _workersMap[workerId];
        
        if (worker == null) {
          return const SizedBox.shrink(); // Skip if worker not found
        }

        return SwitchListTile(
          title: Text('${worker.firstName} ${worker.lastName}'),
          subtitle: null,
          secondary: CircleAvatar(
            backgroundColor: Colors.blue,
            backgroundImage: worker.photoUrl.isNotEmpty ? NetworkImage(worker.photoUrl) : null,
            child: worker.photoUrl.isEmpty ? Text(
              worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ) : null,
          ),
          value: _attendanceMap[workerId] ?? false,
          onChanged: (bool value) {
            setState(() {
              _attendanceMap[workerId] = value;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Future<void> _saveAttendance() async {
    final attendanceViewModel = Provider.of<AttendanceViewModel>(context, listen: false);
    
    try {
      final existingRecords = await attendanceViewModel.markAttendance(
        widget.project.id,
        _attendanceMap,
      );
      
      if (!mounted) return;
      
      if (existingRecords.isNotEmpty) {
        // Show alert for existing records
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Uyarı'),
            content: Text(
              'Bazı işçiler için bugün zaten yoklama alınmış (${existingRecords.length} işçi).\n'
              'Bu işçilerin yoklamaları güncellenmedi.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yoklama başarıyla kaydedildi')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
}

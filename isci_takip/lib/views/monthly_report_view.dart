import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/worker_model.dart';
import '../view_models/worker_view_model.dart';
import '../view_models/attendance_view_model.dart';
import 'package:intl/intl.dart';

class MonthlyReportView extends StatefulWidget {
  final ProjectModel project;

  const MonthlyReportView({super.key, required this.project});

  @override
  State<MonthlyReportView> createState() => _MonthlyReportViewState();
}

class _MonthlyReportViewState extends State<MonthlyReportView> {
  final Map<String, WorkerModel> _workersMap = {};
  // Değiştirildi: bool yerine Map<String, dynamic> kullanarak detaylı bilgi saklama
  final Map<String, Map<String, Map<String, dynamic>>> _monthlyAttendanceMap = {};
  bool _isLoading = true;
  List<String> _assignedWorkerIds = [];
  
  // Current month and year
  late int _selectedMonth;
  late int _selectedYear;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize with current month and year
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get assigned workers
      _assignedWorkerIds = widget.project.assignedWorkerIds;
      
      // Get worker details
      final workerViewModel = Provider.of<WorkerViewModel>(context, listen: false);
      if (workerViewModel.workers.isEmpty) {
        workerViewModel.init();
        // Verilerin yüklenmesini beklemek için kısa bir gecikme
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Create a map of worker IDs to worker models
      for (final worker in workerViewModel.workers) {
        _workersMap[worker.id] = worker;
      }
      
      // Load monthly attendance for each worker
      final attendanceViewModel = Provider.of<AttendanceViewModel>(context, listen: false);
      
      for (final workerId in _assignedWorkerIds) {
        if (_workersMap.containsKey(workerId)) {
          final monthlyAttendance = await attendanceViewModel.getMonthlyAttendance(
            widget.project.id,
            workerId,
            _selectedYear,
            _selectedMonth,
          );
          
          _monthlyAttendanceMap[workerId] = monthlyAttendance;
        }
      }
    } catch (e) {
      if (mounted) {
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
  
  void _changeMonth(int delta) {
    setState(() {
      int newMonth = _selectedMonth + delta;
      int newYear = _selectedYear;
      
      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }
      
      _selectedMonth = newMonth;
      _selectedYear = newYear;
    });
    
    _loadData();
  }
  
  String _getMonthName(int month) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }
  
  int _getPresentDaysCount(Map<String, Map<String, dynamic>> attendanceMap) {
    int count = 0;
    for (var entry in attendanceMap.values) {
      // Yeni format: Map içinde 'present' anahtarı kontrol ediliyor
      if (entry.containsKey('present') && entry['present'] == true) {
        count++;
      }
    }
    return count;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aylık Rapor: ${widget.project.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_getMonthName(_selectedMonth)} $_selectedYear',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          
          // Worker list with attendance summary
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWorkersList(),
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
    
    // Get the number of days in the selected month
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    
    return ListView.builder(
      itemCount: _assignedWorkerIds.length,
      itemBuilder: (context, index) {
        final workerId = _assignedWorkerIds[index];
        final worker = _workersMap[workerId];
        final monthlyAttendance = _monthlyAttendanceMap[workerId] ?? {};
        
        if (worker == null) {
          return const SizedBox.shrink(); // Skip if worker not found
        }
        
        final presentDays = _getPresentDaysCount(monthlyAttendance);
        final attendancePercentage = daysInMonth > 0 
            ? (presentDays / daysInMonth * 100).toStringAsFixed(1) 
            : '0';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text('${worker.firstName} ${worker.lastName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mevcut Gün: $presentDays / $daysInMonth (%$attendancePercentage)'),
                if (monthlyAttendance.isNotEmpty)
                  FutureBuilder<String>(
                    future: _getLastAttendanceInfo(monthlyAttendance),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Text(
                          snapshot.data!,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            isThreeLine: true,
            trailing: CircleAvatar(
              backgroundColor: Colors.blue,
              backgroundImage: worker.photoUrl.isNotEmpty ? NetworkImage(worker.photoUrl) : null,
              child: worker.photoUrl.isEmpty ? Text(
                worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ) : null,
            ),
            onTap: () {
              _showMonthlyAttendanceDetails(worker, monthlyAttendance);
            },
          ),
        );
      },
    );
  }
  
  // Son puantaj kaydının bilgilerini döndüren yardımcı metod
  Future<String> _getLastAttendanceInfo(Map<String, Map<String, dynamic>> monthlyAttendance) async {
    if (monthlyAttendance.isEmpty) return '';
    
    // En son kaydı bul (tarih sıralamasına göre)
    final sortedDates = monthlyAttendance.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Tarihleri azalan sırada sırala
    
    if (sortedDates.isEmpty) return '';
    
    final lastDate = sortedDates.first;
    final lastAttendance = monthlyAttendance[lastDate];
    
    if (lastAttendance == null) return '';
    
    final createdByName = lastAttendance.containsKey('createdByName') ? lastAttendance['createdByName'] : null;
    final createdAt = lastAttendance.containsKey('createdAt') ? lastAttendance['createdAt'] : null;
    
    if (createdByName == null) return '';
    
    if (createdAt != null && createdAt is Timestamp) {
      final dateTime = createdAt.toDate();
      final formattedDate = '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      return 'Son kayıt: $createdByName, $formattedDate';
    }
    
    return 'Son kayıt: $createdByName';
  }
  
  void _showMonthlyAttendanceDetails(WorkerModel worker, Map<String, Map<String, dynamic>> monthlyAttendance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${worker.firstName} ${worker.lastName} - ${_getMonthName(_selectedMonth)} Yoklama Detayı'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: monthlyAttendance.length,
            itemBuilder: (context, index) {
              final entry = monthlyAttendance.entries.elementAt(index);
              final dateStr = entry.key;
              final attendanceDetails = entry.value;
              
              // Yoklama durumunu al
              final present = attendanceDetails.containsKey('present') ? 
                  attendanceDetails['present'] as bool? ?? false : false;
              
              // Kayıt yapan kullanıcı bilgilerini al
              final createdByName = attendanceDetails.containsKey('createdByName') ? 
                  attendanceDetails['createdByName'] as String? ?? 'Bilinmiyor' : 'Bilinmiyor';
              final createdAt = attendanceDetails.containsKey('createdAt') ? 
                  attendanceDetails['createdAt'] as Timestamp? : null;
              
              // Parse the date string (format: YYYY-MM-DD)
              final dateParts = dateStr.split('-');
              final date = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
              
              // Format the date for display
              final formattedDate = DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
              
              // Kayıt zamanını formatla
              String createdAtStr = '';
              if (createdAt != null) {
                final createdDateTime = createdAt.toDate();
                createdAtStr = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR').format(createdDateTime);
              }
              
              return ListTile(
                leading: Icon(
                  present ? Icons.check_circle : Icons.cancel,
                  color: present ? Colors.green : Colors.red,
                ),
                title: Text(formattedDate),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(present ? 'Mevcut' : 'Yok'),
                    Text(
                      'Kayıt: $createdByName${createdAtStr.isNotEmpty ? ', $createdAtStr' : ''}',
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

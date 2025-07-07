import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/worker_model.dart';
import '../models/user_model.dart';
import '../view_models/worker_view_model.dart';
import '../view_models/project_view_model.dart';
import '../view_models/attendance_view_model.dart';
import '../view_models/user_view_model.dart';
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
  bool _showAttendedWorkers = false; // Puantaj girişi yapılanları gösterme durumu

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
      final firestoreService = FirestoreService();
      final updatedProject = await firestoreService.getProject(widget.project.id);
      
      if (updatedProject != null) {
        _assignedWorkerIds = updatedProject.assignedWorkerIds;
      } else {
        _assignedWorkerIds = widget.project.assignedWorkerIds;
      }
      
      final workerViewModel = Provider.of<WorkerViewModel>(context, listen: false);
      if (workerViewModel.workers.isEmpty) {
        workerViewModel.init();
        await Future.delayed(const Duration(seconds: 1));
      }

      for (final worker in workerViewModel.workers) {
        _workersMap[worker.id] = worker;
      }

      // Seçili tarih için mevcut yoklamaları yükle
      await _loadAttendanceForDate();
      
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

  // Puantaj kayıtlarını saklayacak haritalar
  final Map<String, dynamic> _attendanceDetails = {};
  
  Future<void> _loadAttendanceForDate() async {
    final dateString = _getFormattedDateString(_selectedDate);
    final attendanceViewModel = Provider.of<AttendanceViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final bool isAdmin = userViewModel.isAdmin;
    
    // Mevcut yoklama kayıtlarını al
    final existingAttendance = await attendanceViewModel.getAttendanceForDate(
      widget.project.id,
      dateString,
    );
    
    // Yoklama haritasını güncelle
    _attendanceMap.clear();
    _attendanceDetails.clear();
    
    // Tüm işçiler için işlem yap
    for (final workerId in _assignedWorkerIds) {
      bool hasAttendanceRecord = existingAttendance.containsKey(workerId);
      bool isPresent = false;
      
      if (hasAttendanceRecord) {
        // Yeni format: Map<String, dynamic> içinde detaylar var
        if (existingAttendance[workerId] is Map) {
          final details = existingAttendance[workerId];
          if (details is Map<String, dynamic>) {
            isPresent = details.containsKey('present') ? 
                details['present'] as bool? ?? false : false;
            _attendanceDetails[workerId] = details;
          }
        } else {
          // Eski format: doğrudan boolean değer
          isPresent = existingAttendance[workerId] as bool? ?? false;
        }
      }
      
      // Puantaj giriş filtre kontrolü
      bool shouldShow = true;
      // Eğer seçilen seçenek "Puantajı yapılmış olanları gösterme" ise, kayıtı olan işçileri gizle
      if (hasAttendanceRecord && !_showAttendedWorkers) {
        shouldShow = false;
      }
      
      // Gösterilecekse haritaya ekle
      if (shouldShow) {
        _attendanceMap[workerId] = isPresent;
      }
    }
    
    setState(() {});
  }

  String _getFormattedDateString(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate() async {
    // Admin kullanıcıların geriye dönük puantaj girebilmesi, diğer kullanıcıların sadece o gün için giriş yapabilmesi
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final bool isAdmin = userViewModel.isAdmin;
    
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    // Admin için 1 yıl geriye, normal kullanıcılar için sadece bugün
    final DateTime firstDate = isAdmin 
        ? today.subtract(const Duration(days: 365)) 
        : today;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isAdmin ? _selectedDate : today,
      firstDate: firstDate,
      lastDate: today, // Bugüne kadar
      locale: const Locale('tr', 'TR'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadAttendanceForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sarsılmaz İnşaat - Yoklama: ${widget.project.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Puantaj girişi yapılanları göster/gizle toggle'ı
          Consumer<UserViewModel>(
            builder: (context, userViewModel, child) {
              // Sadece admin için göster
              if (userViewModel.isAdmin) {
                return IconButton(
                  icon: Icon(
                    _showAttendedWorkers ? Icons.visibility : Icons.visibility_off,
                    color: _showAttendedWorkers ? Colors.green : Colors.grey,
                  ),
                  onPressed: () async {
                    setState(() {
                      _showAttendedWorkers = !_showAttendedWorkers;
                    });
                    // Yeni ayara göre puantaj listesini yeniden yükle
                    await _loadAttendanceForDate();
                    // Kullanıcıya bilgi ver
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_showAttendedWorkers 
                          ? 'Puantaj girişi yapılan işçiler gösteriliyor' 
                          : 'Puantaj girişi yapılan işçiler gizlendi')),
                      );
                    }
                  },
                  tooltip: _showAttendedWorkers ? 'Puantaj Girişi Yapılanları Gizle' : 'Puantaj Girişi Yapılanları Göster',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MonthlyReportView(project: widget.project),
                ),
              );
            },
            tooltip: 'Aylık Rapor',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Yoklama Tarihi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // Tarih seçici
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Text(
                          _getFormattedDate(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Mevcut İşçi Sayısı: ${_attendanceMap.entries.where((entry) => entry.value).length}/${_attendanceMap.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Geçmiş tarih uyarısı
          if (_selectedDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Geçmiş tarih için yoklama görüntülüyorsunuz',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
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
        final attendanceDetails = _attendanceDetails[workerId];
        
        if (worker == null) {
          return const SizedBox.shrink();
        }
        
        // Puantaj detaylarını göster (kim, ne zaman giriş yapmış)
        String? subtitleText;
        if (attendanceDetails != null) {
          final createdByName = attendanceDetails['createdByName'];
          final createdAt = attendanceDetails['createdAt'];
          
          if (createdByName != null) {
            if (createdAt != null) {
              // Timestamp'i DateTime'a çevir
              if (createdAt is Timestamp) {
                final dateTime = createdAt.toDate();
                final formattedDate = '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                subtitleText = 'Kayıt: $createdByName, $formattedDate';
              } else {
                subtitleText = 'Kayıt: $createdByName';
              }
            } else {
              subtitleText = 'Kayıt: $createdByName';
            }
          }
        }

        return SwitchListTile(
          title: Text('${worker.firstName} ${worker.lastName}'),
          subtitle: subtitleText != null ? Text(
            subtitleText,
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ) : null,
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
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
                    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  Future<void> _saveAttendance() async {
    final attendanceViewModel = Provider.of<AttendanceViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final dateString = _getFormattedDateString(_selectedDate);
    
    try {
      // Mevcut kullanıcı bilgilerini al
      final UserModel currentUser = userViewModel.currentUser!;
      final bool isAdmin = userViewModel.isAdmin;
      
      // Seçilen tarihe göre doğru metodu çağır
      final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final DateTime selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      
      Map<String, bool> existingRecords = {};
      
      // Admin kullanıcılar için göre özel mantık
      if (isAdmin) {
        // Admin kullanıcılar her zaman tüm puantaj kayıtlarını güncelleyebilir
        existingRecords = await attendanceViewModel.markAttendanceForDate(
          widget.project.id,
          _attendanceMap,
          dateString,
          currentUser,
          forceUpdate: true, // Admin için her zaman güncellemeyi zorla
        );
      } else {
        // Normal kullanıcılar için standart akış
        if (selectedDay.isAtSameMomentAs(today)) {
          // Bugünün puantajı için
          existingRecords = await attendanceViewModel.markAttendance(
            widget.project.id,
            _attendanceMap,
            currentUser,
          );
        } else {
          // Normal kullanıcılar geçmiş tarihleri düzenleyemez
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Geçmiş tarihlere ait puantajları sadece yöneticiler düzenleyebilir')),
          );
          return;
        }
      }
      
      if (!mounted) return;
      
      if (existingRecords.isNotEmpty && !(_showAttendedWorkers && isAdmin)) {
        // Admin değilse veya puantaj güncelleme modu açık değilse uyarı göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Uyarı'),
            content: Text(
              'Bazı işçiler için ${_getFormattedDate()} tarihinde zaten yoklama alınmış (${existingRecords.length} işçi).\n'
              'Bu işçilerin yoklamaları güncellenmedi.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_getFormattedDate()} tarihi için yoklama kaydedildi')),
        );
        // Puantaj listesini yeniden yükle
        _loadAttendanceForDate();
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }
}
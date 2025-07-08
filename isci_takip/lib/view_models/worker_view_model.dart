import 'dart:io';
import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../services/worker_service.dart';

class WorkerViewModel extends ChangeNotifier {
  final WorkerService _workerService = WorkerService();
  
  List<WorkerModel> _workers = [];
  List<WorkerModel> _activeWorkers = [];
  List<WorkerModel> _filteredWorkers = []; // Alt kullanıcı için filtrelenmiş işçiler
  List<WorkerModel> _filteredActiveWorkers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<WorkerModel> get workers => _workers;
  List<WorkerModel> get activeWorkers => _activeWorkers;
  List<WorkerModel> get filteredWorkers => _filteredWorkers;
  List<WorkerModel> get filteredActiveWorkers => _filteredActiveWorkers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize streams
  void init() {
    _listenToWorkers();
  }
  
  // Listen to all workers
  void _listenToWorkers() {
    _workerService.getWorkers().listen(
      (workersList) {
        _workers = workersList;
        // Aktif işçileri filtrele
        _activeWorkers = workersList.where((worker) => worker.isActive).toList();
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }
  
  // İşçi ekle
  Future<bool> addWorker(WorkerModel worker, {File? photoFile}) async {
    try {
      _setLoading(true);
      
      final workerId = await _workerService.addWorker(worker, photoFile: photoFile);
      
      _setLoading(false);
      return workerId != null;
    } catch (e) {
      _setError('\u0130şçi eklenirken hata oluştu: $e');
      return false;
    }
  }
  
  // İşçi güncelle
  Future<bool> updateWorker(String workerId, Map<String, dynamic> data, {File? photoFile}) async {
    try {
      _setLoading(true);
      
      final success = await _workerService.updateWorker(workerId, data, photoFile: photoFile);
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('\u0130şçi güncellenirken hata oluştu: $e');
      return false;
    }
  }
  
  // İşçi sil
  Future<bool> deleteWorker(String workerId) async {
    try {
      _setLoading(true);
      
      final success = await _workerService.deleteWorker(workerId);
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('\u0130şçi silinirken hata oluştu: $e');
      return false;
    }
  }
  
  // İşçi aktiflik durumunu güncelle
  Future<bool> setWorkerActiveStatus(String workerId, bool isActive) async {
    try {
      _setLoading(true);
      
      final success = await _workerService.setWorkerActiveStatus(workerId, isActive);
      
      _setLoading(false);
      return success;
    } catch (e) {
      _setError('\u0130şçi durumu güncellenirken hata oluştu: $e');
      return false;
    }
  }
  
  // Yükleme durumunu ayarla
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Hata mesajını ayarla
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
  
  // Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Kullanıcı yetkilerine göre doğru işçi listesini döndür
  List<WorkerModel> getWorkersForUser(bool showOnlyActive, List<String>? userProjectIds) {
    // Admin veya yetkiler boş ise tüm işçileri göster
    if (userProjectIds == null || userProjectIds.isEmpty) {
      return showOnlyActive ? _activeWorkers : _workers;
    }
    
    // Alt kullanıcı için şimdilik tüm işçileri göster (proje filtrelemesi daha sonra eklenecek)
    // TODO: Proje bazında işçi filtrelemesi eklenecek
    return showOnlyActive ? _activeWorkers : _workers;
  }
}

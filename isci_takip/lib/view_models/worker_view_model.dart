import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../services/firestore_service.dart';

class WorkerViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
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
    _listenToActiveWorkers();
  }
  
  // Listen to all workers
  void _listenToWorkers() {
    _firestoreService.getWorkers().listen(
      (workersList) {
        _workers = workersList;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }
  
  // Listen to active workers
  void _listenToActiveWorkers() {
    _firestoreService.getActiveWorkers().listen(
      (activeWorkersList) {
        _activeWorkers = activeWorkersList;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }
  
  // Add a worker
  Future<dynamic> addWorker(WorkerModel worker) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      // This now returns the DocumentReference
      final docRef = await _firestoreService.addWorker(worker);
      
      _isLoading = false;
      notifyListeners();
      return docRef.id; // Return the worker ID
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Update a worker
  Future<bool> updateWorker(WorkerModel worker) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _firestoreService.updateWorker(worker);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Delete a worker
  Future<bool> deleteWorker(String workerId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _firestoreService.deleteWorker(workerId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Set worker active status
  Future<bool> setWorkerActiveStatus(String workerId, bool isActive) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      await _firestoreService.setWorkerActiveStatus(workerId, isActive);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Alt kullanıcı için işçileri filtrele (sadece yetkili olduğu projelerdeki işçiler)
  void filterWorkersForUser(List<String> userProjectIds) {
    if (userProjectIds.isEmpty) {
      _filteredWorkers = [];
      _filteredActiveWorkers = [];
    } else {
      // Projelere atanmış tüm işçi ID'lerini topla
      Set<String> allowedWorkerIds = {};
      
      // Bu kısım için FirestoreService'den proje atamalarını almamız gerekiyor
      // Şimdilik basit bir filtreleme yapalım
      
      _filteredWorkers = _workers;
      _filteredActiveWorkers = _activeWorkers;
    }
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

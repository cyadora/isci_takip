import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/firestore_service.dart';

class ProjectViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<ProjectModel> _projects = [];
  List<ProjectModel> _activeProjects = [];
  List<ProjectModel> _userProjects = []; // Alt kullanıcının yetkili olduğu projeler
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<ProjectModel> get projects => _projects;
  List<ProjectModel> get activeProjects => _activeProjects;
  List<ProjectModel> get userProjects => _userProjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Initialize streams
  void init({String? userId, List<String>? userProjectIds}) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    // Fetch projects immediately to ensure they're loaded
    _fetchProjects(userId: userId, userProjectIds: userProjectIds);
    
    // Then set up listeners for real-time updates
    _setupListeners(userId: userId, userProjectIds: userProjectIds);
  }
  
  // Fetch projects immediately (non-stream)
  Future<void> _fetchProjects({String? userId, List<String>? userProjectIds}) async {
    try {
      final projectsList = await _firestoreService.fetchAllProjects();
      
      // Alt kullanıcı ise sadece yetkili olduğu projeleri göster
      if (userProjectIds != null && userProjectIds.isNotEmpty) {
        _userProjects = projectsList.where((project) => userProjectIds.contains(project.id)).toList();
        _projects = _userProjects;
        _activeProjects = _userProjects.where((project) => project.isActive).toList();
      } else {
        // Admin ise tüm projeleri göster
        _projects = projectsList;
        _activeProjects = projectsList.where((project) => project.isActive).toList();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Projeler yüklenirken bir hata oluştu: $error';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Set up real-time listeners for updates
  void _setupListeners({String? userId, List<String>? userProjectIds}) {
    // Listen to all projects
    _firestoreService.getProjects().listen((projectsList) {
      // Alt kullanıcı ise sadece yetkili olduğu projeleri göster
      if (userProjectIds != null && userProjectIds.isNotEmpty) {
        _userProjects = projectsList.where((project) => userProjectIds.contains(project.id)).toList();
        _projects = _userProjects;
        _activeProjects = _userProjects.where((project) => project.isActive).toList();
      } else {
        // Admin ise tüm projeleri göster
        _projects = projectsList;
        _activeProjects = projectsList.where((project) => project.isActive).toList();
      }
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Projeler güncellenirken bir hata oluştu: $error';
      notifyListeners();
    });
  }
  
  // Get projects for a specific worker
  Stream<List<ProjectModel>> getProjectsForWorker(String workerId) {
    return _firestoreService.getProjectsForWorker(workerId);
  }
  
  // Add a new project
  Future<bool> addProject(ProjectModel project) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.addProject(project);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Proje eklenirken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update an existing project
  Future<bool> updateProject(ProjectModel project) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.updateProject(project);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Proje güncellenirken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Delete a project
  Future<bool> deleteProject(String projectId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.deleteProject(projectId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Proje silinirken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Set project active status
  Future<bool> setProjectActiveStatus(String projectId, bool isActive) async {
    try {
      await _firestoreService.setProjectActiveStatus(projectId, isActive);
      return true;
    } catch (e) {
      _errorMessage = 'Proje durumu değiştirilirken bir hata oluştu: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Assign worker to project
  Future<bool> assignWorkerToProject(String projectId, String workerId) async {
    try {
      await _firestoreService.assignWorkerToProject(projectId, workerId);
      return true;
    } catch (e) {
      _errorMessage = 'İşçi projeye eklenirken bir hata oluştu: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Remove worker from project
  Future<bool> removeWorkerFromProject(String projectId, String workerId) async {
    try {
      await _firestoreService.removeWorkerFromProject(projectId, workerId);
      return true;
    } catch (e) {
      _errorMessage = 'İşçi projeden çıkarılırken bir hata oluştu: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Assign workers to a project
  Future<bool> assignWorkers(String projectId, List<String> workerIds) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get the project directly from Firestore to ensure we have the latest data
      final projectSnapshot = await _firestoreService.getProject(projectId);
      
      if (projectSnapshot == null) {
        throw Exception('Proje bulunamadı');
      }
      
      // Update the project with the assigned worker IDs
      final updatedProject = projectSnapshot.copyWith(assignedWorkerIds: workerIds);
      await _firestoreService.updateProject(updatedProject);
      
      // First delete all existing assignments for this project
      await _firestoreService.deleteProjectAssignments(projectId);
      
      // Then create new assignments
      for (final workerId in workerIds) {
        await _firestoreService.createProjectAssignment(projectId, workerId);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'İşçi atamaları kaydedilirken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class UserViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  List<UserModel> _users = [];
  List<UserModel> _subUsers = []; // Alt kullanıcılar
  List<UserModel> _pendingUsers = []; // Onay bekleyen kullanıcılar
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  List<UserModel> get users => _users;
  List<UserModel> get subUsers => _subUsers;
  List<UserModel> get pendingUsers => _pendingUsers;
  
  // Check if current user is admin
  bool get isAdmin => _currentUser?.role == 'admin';
  
  // Check if current user is subadmin
  bool get isSubAdmin => _currentUser?.role == 'subadmin';
  
  // Initialize the view model
  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get current user with role information
      _currentUser = await _authService.getCurrentUserModel();
      
      // If user is admin, fetch all users
      if (isAdmin) {
        await fetchAllUsers();
        await fetchPendingUsers();
      }
      
      // If user is admin or subadmin, fetch sub-users
      if (isAdmin || isSubAdmin) {
        await fetchSubUsers();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Initialize current user - used after login/registration
  Future<void> initializeCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get current user with role information
      _currentUser = await _authService.getCurrentUserModel();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Fetch all users (admin only)
  Future<void> fetchAllUsers() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _users = await _authService.getAllUsers();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user role (admin only)
  Future<bool> updateUserRole(String userId, String role) async {
    if (!isAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final result = await _authService.updateUserRole(userId, role);
      
      // Refresh users list
      if (result) {
        await fetchAllUsers();
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Register a new user (admin only)
  Future<bool> registerUser(String email, String password, {
    String role = 'user',
    List<String>? assignedProjectIds,
  }) async {
    if (!isAdmin && !isSubAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Admin can create any role, subadmin can only create normal users
      if (isSubAdmin && role != 'user') {
        _errorMessage = 'Alt yöneticiler sadece normal kullanıcı oluşturabilir';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final newUserId = await _authService.registerWithEmailAndPassword(
        email, 
        password, 
        role: role
      );
      
      if (newUserId != null) {
        // Create user in Firestore with additional data
        final newUser = UserModel(
          uid: newUserId,
          email: email,
          role: role,
          assignedProjectIds: assignedProjectIds,
          createdBy: _currentUser?.id,
          createdAt: DateTime.now(),
          isActive: true,
          isApproved: true, // Admin tarafından oluşturulan kullanıcılar otomatik onaylı
        );
        
        await _firestoreService.createUser(newUser);
        
        // Refresh users list
        if (isAdmin) {
          await fetchAllUsers();
        }
        
        if (isAdmin || isSubAdmin) {
          await fetchSubUsers();
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Kullanıcı oluşturulamadı');
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Make current user admin
  Future<bool> makeCurrentUserAdmin() async {
    if (_currentUser == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Update user role to admin
      final result = await _authService.updateUserRole(_currentUser!.id, 'admin');
      
      if (result) {
        // Update user in Firestore
        await _firestoreService.setUserRole(_currentUser!.id, 'admin');
        
        // Update current user model
        _currentUser = _currentUser!.copyWith(role: 'admin');
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Fetch sub-users created by current user
  Future<void> fetchSubUsers() async {
    if (_currentUser == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get users created by current user
      _firestoreService.getUsersCreatedBy(_currentUser!.id).listen((users) {
        _subUsers = users;
        notifyListeners();
      });
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Assign projects to a user
  Future<bool> assignProjectsToUser(String userId, List<String> projectIds) async {
    if (!isAdmin && !isSubAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.assignProjectsToUser(userId, projectIds);
      
      // Refresh sub-users
      await fetchSubUsers();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Set user active status
  Future<bool> setUserActiveStatus(String userId, bool isActive) async {
    if (!isAdmin && !isSubAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.setUserActiveStatus(userId, isActive);
      
      // Refresh users lists
      if (isAdmin) {
        await fetchAllUsers();
      }
      
      if (isAdmin || isSubAdmin) {
        await fetchSubUsers();
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Kullanıcı silme (sadece admin)
  Future<bool> deleteUser(String userId) async {
    if (!isAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Kullanıcıyı Firestore'dan sil
      await _firestoreService.deleteUser(userId);
      
      // Kullanıcıyı Authentication'dan sil
      final result = await _authService.deleteUser(userId);
      
      // Kullanıcı listelerini yenile
      if (result) {
        await fetchAllUsers();
        await fetchPendingUsers();
      }
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Kullanıcı onaylama (sadece admin)
  Future<bool> approveUser(String userId) async {
    if (!isAdmin) return false;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      // Kullanıcıyı onayla
      await _firestoreService.setUserApprovalStatus(userId, true);
      
      // Kullanıcı listelerini yenile
      await fetchAllUsers();
      await fetchPendingUsers();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Onay bekleyen kullanıcıları getir (sadece admin)
  Future<void> fetchPendingUsers() async {
    if (!isAdmin) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      _pendingUsers = await _firestoreService.getPendingUsers();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}

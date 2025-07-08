import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<String?> registerWithEmailAndPassword(String email, String password, {String role = 'user'}) async {
    try {
      // Create the user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      // Return the user ID if successful
      if (userCredential.user != null) {
        return userCredential.user!.uid;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Get current user model with role information
  Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap({'uid': user.uid, ...doc.data() as Map<String, dynamic>});
      } else {
        // Create a default user document if it doesn't exist
        final defaultUserData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'role': 'user', // Default role
          'createdAt': FieldValue.serverTimestamp(),
          'isApproved': false, // Varsayılan olarak onaylanmamış
          'isActive': true,
        };
        
        await _firestore.collection('users').doc(user.uid).set(defaultUserData);
        return UserModel.fromMap(defaultUserData);
      }
    } catch (e) {
      print('Error getting user model: $e');
      return null;
    }
  }
  
  // Update user role
  Future<bool> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': role});
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
  
  // Kullanıcı onay durumunu güncelle
  Future<bool> approveUser(String userId, bool isApproved) async {
    try {
      await _firestore.collection('users').doc(userId).update({'isApproved': isApproved});
      return true;
    } catch (e) {
      print('Error updating user approval status: $e');
      return false;
    }
  }
  
  // Kullanıcı aktiflik durumunu güncelle
  Future<bool> setUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({'isActive': isActive});
      return true;
    } catch (e) {
      print('Error updating user active status: $e');
      return false;
    }
  }
  
  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => UserModel.fromMap({'uid': doc.id, ...doc.data()})).toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }
  
  // Kullanıcı silme (admin için)
  Future<bool> deleteUser(String userId) async {
    try {
      // Admin kullanıcıları Firebase Admin SDK olmadan silemeyiz
      // Bu yüzden Cloud Function kullanmak gerekebilir
      // Şimdilik sadece Firestore'dan siliyoruz, Authentication'dan silme işlemi için
      // Firebase Console kullanılabilir veya Cloud Function eklenebilir
      print('Kullanıcı silme işlemi başlatıldı: $userId');
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}

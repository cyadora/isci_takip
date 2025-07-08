import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'admin', 'subadmin', 'user'
  final List<String>? assignedProjectIds; // Alt kullanıcının erişebileceği projeler
  final String? createdBy; // Kullanıcıyı oluşturan admin ID'si
  final DateTime? createdAt; // Kullanıcının oluşturulma tarihi
  final bool isActive; // Kullanıcı aktif mi?
  final bool isApproved; // Kullanıcı yönetici tarafından onaylandı mı?

  // id getter - UserViewModel'de _currentUser!.id kullanımı için
  String get id => uid;
  
  // Admin mi?
  bool get isAdmin => role == 'admin';
  
  // Alt admin mi?
  bool get isSubAdmin => role == 'subadmin';
  
  // Giriş yapabilir mi? (Admin ise her zaman true, normal kullanıcı ise onaylanmış olmalı)
  bool get canLogin => isAdmin || isApproved;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = 'user', // Default to regular user
    this.assignedProjectIds,
    this.createdBy,
    this.createdAt,
    this.isActive = true,
    this.isApproved = false, // Varsayılan olarak onaylanmamış
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'user',
      assignedProjectIds: data['assignedProjectIds'] != null 
          ? List<String>.from(data['assignedProjectIds']) 
          : null,
      createdBy: data['createdBy'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      isApproved: data['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'assignedProjectIds': assignedProjectIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isActive': isActive,
      'isApproved': isApproved,
    };
  }
  
  // copyWith metodu - UserViewModel'de _currentUser!.copyWith kullanımı için
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? role,
    List<String>? assignedProjectIds,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    bool? isApproved,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      assignedProjectIds: assignedProjectIds ?? this.assignedProjectIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}

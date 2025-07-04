import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String address;
  final String photoUrl;
  final bool safetyDocsComplete;
  final bool entryDocsComplete;
  final bool isActive;

  WorkerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
    this.photoUrl = '',
    this.safetyDocsComplete = false,
    this.entryDocsComplete = false,
    this.isActive = true,
  });

  factory WorkerModel.fromMap(Map<String, dynamic> data, String id) {
    return WorkerModel(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      safetyDocsComplete: data['safetyDocsComplete'] ?? false,
      entryDocsComplete: data['entryDocsComplete'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'safetyDocsComplete': safetyDocsComplete,
      'entryDocsComplete': entryDocsComplete,
      'isActive': isActive,
    };
  }

  WorkerModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? address,
    String? photoUrl,
    bool? safetyDocsComplete,
    bool? entryDocsComplete,
    bool? isActive,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      safetyDocsComplete: safetyDocsComplete ?? this.safetyDocsComplete,
      entryDocsComplete: entryDocsComplete ?? this.entryDocsComplete,
      isActive: isActive ?? this.isActive,
    );
  }
}

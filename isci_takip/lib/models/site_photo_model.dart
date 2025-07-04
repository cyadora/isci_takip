import 'package:cloud_firestore/cloud_firestore.dart';

class SitePhotoModel {
  String id;
  final String projectId;
  final String uploaderId;
  final DateTime timestamp;
  final String photoUrl;
  final String fileName;

  SitePhotoModel({
    required this.id,
    required this.projectId,
    required this.uploaderId,
    required this.timestamp,
    required this.photoUrl,
    required this.fileName,
  });

  // Firestore'dan veri almak için factory constructor
  factory SitePhotoModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SitePhotoModel(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      uploaderId: data['uploaderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'] ?? '',
      fileName: data['fileName'] ?? '',
    );
  }

  // Firestore'a veri göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'uploaderId': uploaderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'photoUrl': photoUrl,
      'fileName': fileName,
    };
  }
}

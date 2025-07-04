import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String name;
  final String location;
  final DateTime startDate;
  final List<String> assignedWorkerIds;
  final bool isActive;

  ProjectModel({
    required this.id,
    required this.name,
    required this.location,
    required this.startDate,
    this.assignedWorkerIds = const [],
    this.isActive = true,
  });

  // Create a copy of the current project with modified fields
  ProjectModel copyWith({
    String? id,
    String? name,
    String? location,
    DateTime? startDate,
    List<String>? assignedWorkerIds,
    bool? isActive,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      assignedWorkerIds: assignedWorkerIds ?? this.assignedWorkerIds,
      isActive: isActive ?? this.isActive,
    );
  }

  // Convert ProjectModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
      'assignedWorkerIds': assignedWorkerIds,
      'isActive': isActive,
    };
  }

  // Create ProjectModel from Firestore document
  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : DateTime.now(),
      assignedWorkerIds: List<String>.from(map['assignedWorkerIds'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }
}

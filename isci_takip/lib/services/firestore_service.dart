import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../models/project_model.dart';
import '../models/site_photo_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _workersCollection = 'workers';
  final String _projectsCollection = 'projects';
  final String _projectAssignmentsCollection = 'project_assignments';
  final String _attendanceCollection = 'attendance';
  final String _sitePhotosCollection = 'site_photos';
  final String _usersCollection = 'users';

  // Collection references
  CollectionReference get workersCollection => _firestore.collection(_workersCollection);
  CollectionReference get projectsCollection => _firestore.collection(_projectsCollection);
  CollectionReference get projectAssignmentsCollection => _firestore.collection(_projectAssignmentsCollection);
  CollectionReference get attendanceCollection => _firestore.collection(_attendanceCollection);
  CollectionReference get sitePhotosCollection => _firestore.collection(_sitePhotosCollection);
  CollectionReference get usersCollection => _firestore.collection(_usersCollection);

  // Get workers stream
  Stream<List<WorkerModel>> getWorkers() {
    return workersCollection
        .orderBy('firstName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkerModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  
  // Get active workers stream
  Stream<List<WorkerModel>> getActiveWorkers() {
    return workersCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkerModel.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  
  // Get a single worker
  Future<WorkerModel?> getWorker(String workerId) async {
    DocumentSnapshot doc = await workersCollection.doc(workerId).get();
    
    if (doc.exists) {
      return WorkerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    
    return null;
  }
  
  // Add a worker
  Future<DocumentReference> addWorker(WorkerModel worker) {
    return workersCollection.add(worker.toMap());
  }
  
  // Update a worker
  Future<void> updateWorker(WorkerModel worker) {
    return workersCollection.doc(worker.id).update(worker.toMap());
  }
  
  // Delete a worker
  Future<void> deleteWorker(String workerId) {
    return workersCollection.doc(workerId).delete();
  }
  
  // Set worker active status
  Future<void> setWorkerActiveStatus(String workerId, bool isActive) {
    return workersCollection.doc(workerId).update({'isActive': isActive});
  }
  
  // PROJECT MANAGEMENT METHODS
  
  // Get projects stream
  Stream<List<ProjectModel>> getProjects() {
    return projectsCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // Get active projects stream
  Stream<List<ProjectModel>> getActiveProjects() {
    return projectsCollection
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // Get a single project
  Future<ProjectModel?> getProject(String projectId) async {
    DocumentSnapshot doc = await projectsCollection.doc(projectId).get();
    
    if (doc.exists) {
      return ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    
    return null;
  }
  
  // Fetch all projects (non-stream)
  Future<List<ProjectModel>> fetchAllProjects() async {
    final snapshot = await projectsCollection.orderBy('name').get();
    
    return snapshot.docs
        .map((doc) => ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  // Add a project
  Future<DocumentReference> addProject(ProjectModel project) {
    return projectsCollection.add(project.toMap());
  }
  
  // Update a project
  Future<void> updateProject(ProjectModel project) {
    return projectsCollection.doc(project.id).update(project.toMap());
  }
  
  // Delete a project
  Future<void> deleteProject(String projectId) {
    return projectsCollection.doc(projectId).delete();
  }
  
  // Set project active status
  Future<void> setProjectActiveStatus(String projectId, bool isActive) {
    return projectsCollection.doc(projectId).update({'isActive': isActive});
  }
  
  // Assign worker to project
  Future<void> assignWorkerToProject(String projectId, String workerId) async {
    DocumentSnapshot projectDoc = await projectsCollection.doc(projectId).get();
    if (projectDoc.exists) {
      List<String> workerIds = List<String>.from(projectDoc.get('assignedWorkerIds') ?? []);
      if (!workerIds.contains(workerId)) {
        workerIds.add(workerId);
        await projectsCollection.doc(projectId).update({'assignedWorkerIds': workerIds});
      }
    }
  }
  
  // Remove worker from project
  Future<void> removeWorkerFromProject(String projectId, String workerId) async {
    DocumentSnapshot projectDoc = await projectsCollection.doc(projectId).get();
    if (projectDoc.exists) {
      List<String> workerIds = List<String>.from(projectDoc.get('assignedWorkerIds') ?? []);
      workerIds.remove(workerId);
      await projectsCollection.doc(projectId).update({'assignedWorkerIds': workerIds});
    }
  }
  
  // Get projects for worker
  Stream<List<ProjectModel>> getProjectsForWorker(String workerId) {
    return projectsCollection
        .where('assignedWorkerIds', arrayContains: workerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // PROJECT ASSIGNMENT METHODS
  
  // Create a batch for multiple operations
  WriteBatch batch() {
    return _firestore.batch();
  }
  
  // Create a project assignment
  Future<DocumentReference> createProjectAssignment(String projectId, String workerId) {
    return projectAssignmentsCollection.add({
      'projectId': projectId,
      'workerId': workerId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Delete all project assignments for a project
  Future<void> deleteProjectAssignments(String projectId) async {
    final snapshot = await projectAssignmentsCollection
        .where('projectId', isEqualTo: projectId)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    return batch.commit();
  }
  
  // Get all project assignments for a project
  Stream<List<String>> getProjectAssignments(String projectId) {
    return projectAssignmentsCollection
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.get('workerId') as String)
            .toList());
  }
  
  // Get all projects assigned to a worker
  Stream<List<String>> getWorkerAssignments(String workerId) {
    return projectAssignmentsCollection
        .where('workerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.get('projectId') as String)
            .toList());
  }
  
  // ATTENDANCE MANAGEMENT METHODS
  
  // Check if attendance record exists for a worker on a specific date
  Future<bool> checkAttendanceExists(String projectId, String workerId, String date) async {
    final snapshot = await attendanceCollection
        .where('projectId', isEqualTo: projectId)
        .where('workerId', isEqualTo: workerId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }
  
  // Create attendance record
  Future<DocumentReference> createAttendanceRecord(
    String projectId,
    String workerId,
    String date,
    bool present,
  ) {
    return attendanceCollection.add({
      'projectId': projectId,
      'workerId': workerId,
      'date': date,
      'present': present,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Get attendance records for a project on a specific date
  Future<Map<String, bool>> getAttendanceRecords(String projectId, String date) async {
    final snapshot = await attendanceCollection
        .where('projectId', isEqualTo: projectId)
        .where('date', isEqualTo: date)
        .get();
    
    final Map<String, bool> records = {};
    for (var doc in snapshot.docs) {
      records[doc.get('workerId') as String] = doc.get('present') as bool;
    }
    
    return records;
  }
  
  // Get attendance status for a specific worker on a specific date
  Future<bool> getWorkerAttendanceForDate(String projectId, String workerId, String date) async {
    final snapshot = await attendanceCollection
        .where('projectId', isEqualTo: projectId)
        .where('workerId', isEqualTo: workerId)
        .where('date', isEqualTo: date)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return false; // No record means not present
    }
    
    return snapshot.docs.first.get('present') as bool;
  }
  
  // Get attendance history for a worker
  Future<List<Map<String, dynamic>>> getWorkerAttendanceHistory(String workerId) async {
    final snapshot = await attendanceCollection
        .where('workerId', isEqualTo: workerId)
        .orderBy('date', descending: true)
        .limit(30) // Last 30 records
        .get();
    
    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'projectId': doc.get('projectId'),
              'date': doc.get('date'),
              'present': doc.get('present'),
            })
        .toList();
  }
  
  // SITE PHOTOS MANAGEMENT METHODS
  
  // Create a site photo record
  Future<DocumentReference> createSitePhoto(SitePhotoModel photo) {
    return sitePhotosCollection.add(photo.toMap());
  }
  
  // Get all site photos for a project
  Future<List<SitePhotoModel>> getSitePhotos(String projectId) async {
    final snapshot = await sitePhotosCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => SitePhotoModel.fromFirestore(doc))
        .toList();
  }
  
  // Delete a site photo
  Future<void> deleteSitePhoto(String photoId) {
    return sitePhotosCollection.doc(photoId).delete();
  }
  
  // USER MANAGEMENT METHODS
  
  // Get a user by ID
  Future<UserModel?> getUser(String uid) async {
    DocumentSnapshot doc = await usersCollection.doc(uid).get();
    
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    
    return null;
  }
  
  // Create a new user
  Future<void> createUser(UserModel user) {
    return usersCollection.doc(user.uid).set(user.toMap());
  }
  
  // Update a user
  Future<void> updateUser(UserModel user) {
    return usersCollection.doc(user.uid).update(user.toMap());
  }
  
  // Get all users (for admin)
  Stream<List<UserModel>> getUsers() {
    return usersCollection
        .orderBy('email')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // Get users created by a specific admin
  Stream<List<UserModel>> getUsersCreatedBy(String adminUid) {
    return usersCollection
        .where('createdBy', isEqualTo: adminUid)
        .orderBy('email')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
  
  // Assign projects to a user
  Future<void> assignProjectsToUser(String uid, List<String> projectIds) {
    return usersCollection.doc(uid).update({'assignedProjectIds': projectIds});
  }
  
  // Set user active status
  Future<void> setUserActiveStatus(String uid, bool isActive) {
    return usersCollection.doc(uid).update({'isActive': isActive});
  }
  
  // Set user role
  Future<void> setUserRole(String uid, String role) {
    return usersCollection.doc(uid).update({'role': role});
  }
}

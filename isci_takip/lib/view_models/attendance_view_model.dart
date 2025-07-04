import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Mark attendance for multiple workers
  Future<Map<String, bool>> markAttendance(String projectId, Map<String, bool> attendanceMap) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final dateString = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      // Check for existing attendance records for today
      Map<String, bool> existingRecords = {};
      
      for (final workerId in attendanceMap.keys) {
        final exists = await _firestoreService.checkAttendanceExists(projectId, workerId, dateString);
        if (exists) {
          existingRecords[workerId] = true;
        } else {
          // Create new attendance record
          await _firestoreService.createAttendanceRecord(
            projectId,
            workerId,
            dateString,
            attendanceMap[workerId] ?? false,
          );
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
      return existingRecords;
    } catch (e) {
      _errorMessage = 'Yoklama kaydedilirken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }
  
  // Get attendance records for a project on a specific date
  Future<Map<String, bool>> getAttendanceForDate(String projectId, String dateString) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final records = await _firestoreService.getAttendanceRecords(projectId, dateString);
      
      _isLoading = false;
      notifyListeners();
      
      return records;
    } catch (e) {
      _errorMessage = 'Yoklama kayıtları alınırken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }
  
  // Get monthly attendance records for a worker in a project
  Future<Map<String, bool>> getMonthlyAttendance(String projectId, String workerId, int year, int month) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Get the number of days in the specified month
      final daysInMonth = DateTime(year, month + 1, 0).day;
      
      // Create a map to store attendance status for each day
      final Map<String, bool> monthlyAttendance = {};
      
      // Fetch attendance for each day in the month
      for (int day = 1; day <= daysInMonth; day++) {
        final dateString = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
        final dayAttendance = await _firestoreService.getWorkerAttendanceForDate(projectId, workerId, dateString);
        monthlyAttendance[dateString] = dayAttendance;
      }
      
      _isLoading = false;
      notifyListeners();
      
      return monthlyAttendance;
    } catch (e) {
      _errorMessage = 'Aylık yoklama kayıtları alınırken bir hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return {};
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

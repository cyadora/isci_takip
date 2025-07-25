import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import '../models/site_photo_model.dart';
import '../services/firestore_service.dart';

class PhotoUploadViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isLoading = false;
  String? errorMessage;
  List<SitePhotoModel> photos = [];
  
  // Fotoğrafı Firebase Storage'a yükle ve Firestore'a kaydet
  Future<bool> uploadPhoto(String projectId, File imageFile) async {
    try {
      isLoading = true;
      errorMessage = null;
      Future.microtask(() => notifyListeners());
      
      // Kullanıcı ID'sini al
      final uploaderId = _auth.currentUser?.uid;
      if (uploaderId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      
      // Dosya adını oluştur (benzersiz olması için timestamp ekle)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileExtension = path.extension(imageFile.path);
      final String fileName = 'photo_${timestamp}$fileExtension';
      
      // Firebase Storage'a yükle
      final storageRef = _storage.ref().child('site_photos/$projectId/$fileName');
      final uploadTask = storageRef.putFile(imageFile);
      
      // Yükleme işlemini bekle
      final snapshot = await uploadTask;
      
      // Yüklenen dosyanın URL'sini al
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Firestore'a kaydet
      final sitePhoto = SitePhotoModel(
        id: '', // Firestore tarafından otomatik oluşturulacak
        projectId: projectId,
        uploaderId: uploaderId,
        timestamp: DateTime.now(),
        photoUrl: downloadUrl,
        fileName: fileName,
      );
      
      await _firestoreService.createSitePhoto(sitePhoto);
      
      // Fotoğraf listesini yenile
      await getPhotos(projectId);
      
      isLoading = false;
      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Fotoğraf yüklenirken bir hata oluştu: ${e.toString()}';
      // UI güncellemesini mikro görev sırasına koy
      Future.microtask(() => notifyListeners());
      return false;
    }
  }
  
  // XFile'dan fotoğraf yükleme metodu (hem web hem de mobil için)
  Future<bool> uploadPhotoFromXFile(String projectId, XFile photoFile) async {
    try {
      isLoading = true;
      errorMessage = null;
      // UI güncellemesini mikro görev sırasına koy
      Future.microtask(() => notifyListeners());

      // Kullanıcı kimliğini al
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMessage = 'Oturum açık değil';
        isLoading = false;
        // UI güncellemesini mikro görev sırasına koy
        Future.microtask(() => notifyListeners());
        return false;
      }

      // Dosya adını oluştur
      final fileName = path.basename(photoFile.name);
      final timestamp = DateTime.now();
      final storageFileName = '${timestamp.millisecondsSinceEpoch}_$fileName';
      
      // Storage referansını oluştur
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('site_photos')
          .child(projectId)
          .child(storageFileName);

      // Dosyayı yükle
      UploadTask uploadTask;
      if (kIsWeb) {
        // Web için bytes olarak yükle
        final bytes = await photoFile.readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        // Mobil için File olarak yükle
        final file = File(photoFile.path);
        uploadTask = storageRef.putFile(file);
      }
      
      final snapshot = await uploadTask.whenComplete(() {});

      // Dosya URL'sini al
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore'a meta verileri kaydet
      final photo = SitePhotoModel(
        id: '',
        projectId: projectId,
        uploaderId: currentUser.uid,
        timestamp: timestamp,
        photoUrl: downloadUrl,
        fileName: storageFileName,
      );

      await _firestoreService.createSitePhoto(photo);

    // Fotoğraf listesini güncelle
    await getPhotos(projectId);

    isLoading = false;
    // UI güncellemesini mikro görev sırasına koy
    Future.microtask(() => notifyListeners());
    return true;
  } catch (e) {
    errorMessage = 'Fotoğraf yüklenirken hata oluştu: $e';
    isLoading = false;
    // UI güncellemesini mikro görev sırasına koy
    Future.microtask(() => notifyListeners());
    return false;
  }
  }
  
  // Belirli bir projeye ait tüm fotoğrafları getir
  Future<List<SitePhotoModel>> getPhotos(String projectId) async {
    try {
      // Loading state değişikliklerini sadece hazırsa bildir
      if (!isLoading) {
        isLoading = true;
        errorMessage = null;
        // UI güncellemesini mikro görev sırasına koy
        Future.microtask(() => notifyListeners());
      }
      
      // Fotoğrafları yükle
      photos = await _firestoreService.getSitePhotos(projectId);
      
      // Eğer mounted durumundaysa (context hala geçerliyse) bildir
      isLoading = false;
      // notifyListeners çağrısını Future mikro-görev sırasına koyarak build çakışmasını önle
      Future.microtask(() => notifyListeners());
      return photos;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Fotoğraflar yüklenirken bir hata oluştu: ${e.toString()}';
      // notifyListeners çağrısını Future mikro-görev sırasına koy
      Future.microtask(() => notifyListeners());
      return [];
    }
  }
  
  // Hata mesajını temizle
  void clearError() {
    errorMessage = null;
    // UI güncellemesini mikro görev sırasına koy
    Future.microtask(() => notifyListeners());
  }
}

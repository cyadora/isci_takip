import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/worker_model.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'workers';

  // Tüm işçileri getir
  Stream<List<WorkerModel>> getWorkers() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkerModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Belirli bir işçiyi getir
  Future<WorkerModel?> getWorker(String workerId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(workerId).get();
      if (doc.exists) {
        return WorkerModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('İşçi getirme hatası: $e');
      return null;
    }
  }

  // İşçi ekle
  Future<String?> addWorker(WorkerModel worker, {File? photoFile}) async {
    try {
      // Önce işçi verilerini ekle
      final docRef = await _firestore.collection(_collection).add(worker.toMap());
      
      // Eğer fotoğraf varsa yükle ve işçi belgesini güncelle
      if (photoFile != null) {
        final photoUrl = await uploadWorkerPhoto(docRef.id, photoFile);
        if (photoUrl != null) {
          await _firestore.collection(_collection).doc(docRef.id).update({
            'photoUrl': photoUrl
          });
        }
      }
      
      return docRef.id;
    } catch (e) {
      print('İşçi ekleme hatası: $e');
      return null;
    }
  }

  // İşçi güncelle
  Future<bool> updateWorker(String workerId, Map<String, dynamic> data, {File? photoFile}) async {
    try {
      // Eğer fotoğraf varsa önce yükle
      if (photoFile != null) {
        final photoUrl = await uploadWorkerPhoto(workerId, photoFile);
        if (photoUrl != null) {
          data['photoUrl'] = photoUrl;
        }
      }
      
      // İşçi verilerini güncelle
      await _firestore.collection(_collection).doc(workerId).update(data);
      return true;
    } catch (e) {
      print('İşçi güncelleme hatası: $e');
      return false;
    }
  }

  // İşçi sil
  Future<bool> deleteWorker(String workerId) async {
    try {
      await _firestore.collection(_collection).doc(workerId).delete();
      
      // İşçinin fotoğrafını da sil
      try {
        await _storage.ref('worker_photos/$workerId').delete();
      } catch (e) {
        // Fotoğraf yoksa hata vermesini engelle
        print('Fotoğraf silme hatası (önemsiz): $e');
      }
      
      return true;
    } catch (e) {
      print('İşçi silme hatası: $e');
      return false;
    }
  }

  // İşçi fotoğrafı yükle
  Future<String?> uploadWorkerPhoto(String workerId, File photoFile) async {
    try {
      // Dosyanın var olduğunu kontrol et
      if (!await photoFile.exists()) {
        throw Exception('Yüklenecek fotoğraf dosyası bulunamadı: ${photoFile.path}');
      }

      // Dosya boyutunu kontrol et (10MB'dan büyük dosyaları reddet)
      final fileSize = await photoFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Fotoğraf dosyası çok büyük: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB. Maksimum 10MB olmalı.');
      }

      // Storage referansını oluştur
      final storageRef = _storage.ref().child('worker_photos/$workerId');
      
      // Fotoğrafı yükle
      try {
        final uploadTask = await storageRef.putFile(
          photoFile,
          SettableMetadata(
            contentType: 'image/jpeg', // Varsayılan olarak JPEG kabul et
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
              'workerId': workerId,
            },
          ),
        );
        
        // Yüklenen fotoğrafın URL'sini al
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      } catch (uploadError) {
        print('Firebase Storage yükleme hatası: $uploadError');
        throw Exception('Fotoğraf yükleme başarısız: $uploadError');
      }
    } catch (e) {
      print('Fotoğraf yükleme hatası: $e');
      return null;
    }
  }

  // İşçinin aktiflik durumunu güncelle
  Future<bool> setWorkerActiveStatus(String workerId, bool isActive) async {
    try {
      await _firestore.collection(_collection).doc(workerId).update({
        'isActive': isActive
      });
      return true;
    } catch (e) {
      print('İşçi aktiflik durumu güncelleme hatası: $e');
      return false;
    }
  }
}

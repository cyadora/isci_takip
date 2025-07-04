import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../models/project_model.dart';
import '../view_models/photo_upload_view_model.dart';

class PhotoUploadView extends StatefulWidget {
  final ProjectModel project;

  const PhotoUploadView({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<PhotoUploadView> createState() => _PhotoUploadViewState();
}

class _PhotoUploadViewState extends State<PhotoUploadView> {
  // Web için Uint8List, mobil için File kullanacağız
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  XFile? _pickedFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _pickedFile = pickedFile;
        
        if (kIsWeb) {
          // Web için bytes olarak yükle
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          // Mobil için File olarak yükle
          setState(() {
            _selectedImageFile = File(pickedFile.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken bir hata oluştu: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    // Web platformunda kamera ve galeri seçenekleri farklı çalışır
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fotoğraf Seç'),
          content: const Text('Web tarayıcısında kamera erişimi sınırlıdır. Lütfen bir dosya seçin.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery); // Web'de her iki seçenek de dosya seçiciyi açar
              },
              child: const Text('Dosya Seç'),
            ),
          ],
        ),
      );
    } else {
      // Mobil platformlar için normal diyalog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fotoğraf Kaynağı'),
          content: const Text('Fotoğrafı nereden almak istersiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              child: const Text('Kamera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Galeri'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    final viewModel = Provider.of<PhotoUploadViewModel>(context, listen: false);
    final success = await viewModel.uploadPhotoFromXFile(widget.project.id, _pickedFile!);

    setState(() {
      _isUploading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf başarıyla yüklendi')),
      );
      Navigator.pop(context, true); // Başarılı yükleme ile geri dön
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Fotoğraf yüklenirken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.name} - Fotoğraf Yükle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Proje bilgisi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.project.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.project.location ?? 'Konum belirtilmedi',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fotoğraf seçme butonu
            if (_selectedImageFile == null && _selectedImageBytes == null)
              ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Fotoğraf Çek/Seç'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            // Seçilen fotoğraf önizlemesi
            if (_selectedImageFile != null || _selectedImageBytes != null) ...[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedImageBytes != null
                    ? Image.memory(
                        _selectedImageBytes!,
                        fit: BoxFit.contain,
                      )
                    : Image.file(
                        _selectedImageFile!,
                        fit: BoxFit.contain,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Yükleme ve iptal butonları
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadImage,
                      icon: const Icon(Icons.upload),
                      label: _isUploading
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Yükleniyor...'),
                              ],
                            )
                          : const Text('Yükle'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImageFile = null;
                        _selectedImageBytes = null;
                        _pickedFile = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'İptal',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

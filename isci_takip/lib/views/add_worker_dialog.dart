import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/worker_model.dart';
import '../view_models/worker_view_model.dart';

class AddWorkerDialog extends StatefulWidget {
  const AddWorkerDialog({super.key});

  @override
  State<AddWorkerDialog> createState() => _AddWorkerDialogState();
}

class _AddWorkerDialogState extends State<AddWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController(); // YENİ
  final _salaryController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isActive = true;
  DateTime? _startDate;
  bool _isLoading = false;
  
  // Pozisyon seçenekleri - YENİ
  final List<String> _positions = [
    'Usta',
    'Kalfa',
    'İşçi',
    'Operatör',
    'Demirci',
    'Duvarcı',
    'Boyacı',
    'Elektrikçi',
    'Tesisatçı',
    'Marangoz',
    'Asfaltçı',
    'Hafriyatçı',
    'Vinç Operatörü',
    'Forklift Operatörü',
    'Şoför',
    'Bekçi',
    'Diğer'
  ];
  
  // Photo upload related variables
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    _positionController.dispose(); // YENİ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni İşçi Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad alanı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'Soyad *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyad alanı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Pozisyon dropdown - YENİ
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Görev/Pozisyon *',
                  border: OutlineInputBorder(),
                ),
                items: _positions.map((String position) {
                  return DropdownMenuItem<String>(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _positionController.text = newValue;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Görev seçimi zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(
                  labelText: 'Pozisyon',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Maaş',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Photo upload section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İşçi Fotoğrafı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _selectedImage != null
                            ? Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.file(
                                      _selectedImage!,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : Container(
                                height: 100,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Center(
                                  child: Text('Fotoğraf Yok'),
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUploadingImage
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ],
                  ),
                ],
              ),
              if (_isUploadingImage)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('İşe Başlama Tarihi:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                      }
                    },
                    child: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Tarih Seç',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Aktif:'),
                  Switch(
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () {
            if (_formKey.currentState!.validate()) {
              _addWorker(context);
            }
          },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Ekle'),
        ),
      ],
    );
  }

  // Image picker method
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
      );
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(String workerId) async {
    if (_selectedImage == null) return '';
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('worker_photos')
          .child('$workerId.jpg');
      
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: $e')),
      );
      return '';
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _addWorker(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    
    double? salary;
    if (_salaryController.text.isNotEmpty) {
      salary = double.tryParse(_salaryController.text);
    }
    
    // First add the worker without photo URL
    final newWorker = WorkerModel(
      id: '', // ID will be generated by Firestore
      firstName: _nameController.text,
      lastName: _surnameController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      photoUrl: '',
      position: _positionController.text, // YENİ
      safetyDocsComplete: _isActive,
      entryDocsComplete: false,
    );
    
    final result = await viewModel.addWorker(newWorker);
    
    if (!mounted) return;
    
    if (result is String) { // If success, result is the worker ID
      String workerId = result;
      String photoUrl = '';
      
      // If there's a selected image, upload it
      if (_selectedImage != null) {
        photoUrl = await _uploadImage(workerId);
        
        // Update the worker with the photo URL
        if (photoUrl.isNotEmpty) {
          final updatedWorker = newWorker.copyWith(
            id: workerId,
            photoUrl: photoUrl,
            position: _positionController.text, // YENİ
          );
          await viewModel.updateWorker(updatedWorker);
        }
      }
      
      if (!mounted) return;
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşçi başarıyla eklendi')),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşçi eklenirken bir hata oluştu')),
      );
    }
  }
}

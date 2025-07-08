import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/worker_model.dart';
import '../view_models/worker_view_model.dart';
import '../view_models/user_view_model.dart';
import '../view_models/photo_upload_view_model.dart';
import 'worker_details_view.dart';

class WorkersView extends StatefulWidget {
  const WorkersView({super.key});

  @override
  State<WorkersView> createState() => _WorkersViewState();
}

class _WorkersViewState extends State<WorkersView> {
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    // Initialize the worker view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkerViewModel>(context, listen: false).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sarsılmaz İnşaat - İşçiler'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showOnlyActive ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showOnlyActive = !_showOnlyActive;
              });
            },
            tooltip: _showOnlyActive ? 'Tüm İşçileri Göster' : 'Sadece Aktif İşçileri Göster',
          ),
        ],
      ),
      body: Consumer2<WorkerViewModel, UserViewModel>(
        builder: (context, workerViewModel, userViewModel, child) {
          if (workerViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Kullanıcı yetkilerine göre işçi listesini al
          final workers = workerViewModel.getWorkersForUser(
            _showOnlyActive, 
            userViewModel.currentUser?.assignedProjectIds,
          );

          if (workers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showOnlyActive
                        ? 'Aktif işçi bulunmamaktadır'
                        : 'Hiç işçi bulunmamaktadır',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni işçi eklemek için + butonuna tıklayın',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: workers.length,
            itemBuilder: (context, index) {
              final worker = workers[index];
              return WorkerListItem(worker: worker);
            },
          );
        },
      ),
      // Only show add worker button for admin users
      floatingActionButton: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          if (userViewModel.isAdmin) {
            return FloatingActionButton(
              onPressed: () => _showAddEditWorkerDialog(context),
              tooltip: 'Yeni İşçi Ekle',
              child: const Icon(Icons.add),
            );
          } else {
            return const SizedBox.shrink(); // Hide the button for non-admin users
          }
        },
      ),
    );
  }

  void _showAddEditWorkerDialog(BuildContext context, {WorkerModel? worker}) {
    showDialog(
      context: context,
      builder: (context) => AddEditWorkerDialog(worker: worker),
    );
  }
}

class WorkerListItem extends StatelessWidget {
  final WorkerModel worker;

  const WorkerListItem({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: worker.safetyDocsComplete ? Colors.green.shade300 : Colors.red.shade200,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Karta tıklandığında işçi detay dialogunu göster
          showDialog(
            context: context,
            builder: (context) => WorkerDetailsDialog(worker: worker),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildWorkerAvatar(worker),
          title: Text(
            '${worker.firstName} ${worker.lastName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: worker.safetyDocsComplete ? Colors.black87 : Colors.red.shade700,
            ),
          ),
          subtitle: Text(
            '${worker.position.isNotEmpty ? worker.position : "Pozisyon belirtilmemiş"} - ${worker.address}',
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Consumer<UserViewModel>(
            builder: (context, userViewModel, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button - only for admin users
                  if (userViewModel.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AddEditWorkerDialog(worker: worker),
                        );
                      },
                      tooltip: 'Düzenle',
                    ),
                  // Toggle status button - only for admin users
                  if (userViewModel.isAdmin)
                    IconButton(
                      icon: Icon(
                        worker.safetyDocsComplete ? Icons.person_off : Icons.person,
                        color: worker.safetyDocsComplete ? Colors.red : Colors.green,
                      ),
                      onPressed: () => _toggleWorkerStatus(context, worker),
                      tooltip: worker.safetyDocsComplete ? 'Pasif Yap' : 'Aktif Yap',
                    ),
                  // Details button - for all users
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => WorkerDetailsDialog(worker: worker),
                      );
                    },
                    tooltip: 'Detaylar',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggleWorkerStatus(BuildContext context, WorkerModel worker) {
    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    viewModel.setWorkerActiveStatus(worker.id, !worker.safetyDocsComplete);
  }
  
  // İşçi avatarını güvenli bir şekilde oluştur
  Widget _buildWorkerAvatar(WorkerModel worker) {
    return CircleAvatar(
      backgroundColor: worker.safetyDocsComplete ? Colors.green : Colors.grey,
      radius: 24,
      child: _buildAvatarContent(worker),
    );
  }
  
  // Avatar içeriğini oluştur (fotoğraf veya harf)
  Widget _buildAvatarContent(WorkerModel worker) {
    // Fotoğraf URL'si boşsa harf göster
    if (worker.photoUrl.isEmpty) {
      return Text(
        worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      );
    }
    
    // Network fotoğrafı için
    if (worker.photoUrl.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          worker.photoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          },
          errorBuilder: (context, error, stackTrace) {
            print('Network image error: $error');
            return Text(
              worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            );
          },
        ),
      );
    }
    
    // Yerel dosya fotoğrafı için
    try {
      // Web platformunda File sınıfı farklı çalıştığı için kısa devre yapıyoruz
      bool isWeb = identical(0, 0.0);
      
      if (isWeb) {
        // Web platformunda yerel dosya erişimi farklı çalışır
        // Bu durumda network image olarak deniyoruz
        return ClipOval(
          child: Image.network(
            worker.photoUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Fotoğraf yükleme hatası: $error');
              return Text(
                worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              );
            },
          ),
        );
      } else {
        // Mobil platformlarda File API'sini kullanabiliriz
        final file = File(worker.photoUrl);
        if (!file.existsSync()) {
          print('File not found: ${worker.photoUrl}');
          return Text(
            worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          );
        }
        
        return ClipOval(
          child: Image.file(
            file,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('File image error: $error');
              return Text(
                worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              );
            },
          ),
        );
      }
    } catch (e) {
      print('Image loading error: $e');
      return Text(
        worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      );
    }
  }
}

class AddEditWorkerDialog extends StatefulWidget {
  final WorkerModel? worker;

  const AddEditWorkerDialog({super.key, this.worker});

  @override
  State<AddEditWorkerDialog> createState() => _AddEditWorkerDialogState();
}

class _AddEditWorkerDialogState extends State<AddEditWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _positionController = TextEditingController(); 
  final _positions = [
    'İşçi',
    'Usta',
    'Formen',
    'Şoför',
    'Operatör',
    'Teknisyen',
    'Mühendis',
    'Diğer',
  ];
  
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isActive = true;
  String _selectedPhotoUrl = '';
  
  bool get isEditing => widget.worker != null;
  
  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.firstName;
      _surnameController.text = widget.worker!.lastName;
      _phoneController.text = widget.worker!.phone;
      _addressController.text = widget.worker!.address;
      _positionController.text = widget.worker!.position;
      _isActive = widget.worker!.safetyDocsComplete;
      _selectedPhotoUrl = widget.worker!.photoUrl;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _positionController.dispose();
    super.dispose();
  }
  
  // Platform uyumlu işçi fotoğrafı görüntüleme metodu
  Widget _buildWorkerImage(String photoUrl) {
    if (photoUrl.isEmpty) {
      return const Icon(Icons.person, size: 50);
    }
    
    // Web platformu için veya http/https ile başlayan URL'ler için
    if (photoUrl.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Ağ fotoğrafı yükleme hatası: $error');
            return const Icon(Icons.person, size: 50);
          },
        ),
      );
    } 
    // Mobil platformlar için dosya yolu
    else {
      try {
        // Dosya var mı kontrol et
        final file = File(photoUrl);
        if (!file.existsSync()) {
          print('Dosya bulunamadı: $photoUrl');
          return const Icon(Icons.person, size: 50);
        }
        
        return ClipOval(
          child: Image.file(
            file,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Dosya fotoğrafı yükleme hatası: $error');
              return const Icon(Icons.person, size: 50);
            },
          ),
        );
      } catch (e) {
        print('Fotoğraf yükleme hatası: $e');
        // Herhangi bir hata durumunda placeholder göster
        return const Icon(Icons.person, size: 50);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'İşçi Düzenle' : 'Yeni İşçi Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              
              // Fotoğraf seçimi
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: _buildWorkerImage(_selectedPhotoUrl),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Ad
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen işçinin adını girin';
                  }
                  return null;
                },
              ),
              
              // Soyad
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(labelText: 'Soyad'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen işçinin soyadını girin';
                  }
                  return null;
                },
              ),
              
              // Telefon
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              
              // Adres
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Adres'),
                maxLines: 2,
              ),
              
              // Pozisyon (dropdown)
              DropdownButtonFormField<String>(
                value: _positions.contains(_positionController.text) 
                    ? _positionController.text 
                    : _positions.first,
                decoration: const InputDecoration(labelText: 'Pozisyon'),
                items: _positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _positionController.text = value;
                    });
                  }
                },
              ),
              
              // Aktif/Pasif durumu
              Row(
                children: [
                  const Text('Güvenlik Belgeleri Tamamlandı:'),
                  const SizedBox(width: 8),
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
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _saveWorker(context);
            }
          },
          child: Text(isEditing ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      // Kamera veya galeri seçimi için dialog göster
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Fotoğraf Seç'),
          content: const Text('Fotoğrafı nereden seçmek istiyorsunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Kamera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Galeri'),
            ),
          ],
        ),
      );
      
      if (source == null) return;
      
      // iOS ve diğer platformlarda daha güvenli fotoğraf seçimi
      try {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );
        
        if (image != null) {
          setState(() {
            _isLoading = true;
          });
          
          // Dosya yolunu kaydet
          final String filePath = image.path;
          
          // Dosyanın var olduğunu kontrol et
          final fileExists = await File(filePath).exists();
          if (!fileExists) {
            throw Exception('Seçilen dosya bulunamadı: $filePath');
          }
          
          setState(() {
            _selectedPhotoUrl = filePath;
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fotoğraf seçildi')),
            );
          }
        }
      } catch (imageError) {
        print('Fotoğraf seçme hatası: $imageError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $imageError')),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Fotoğraf seçme dialog hatası: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata oluştu: $e')),
        );
      }
    }
  }

  void _saveWorker(BuildContext context) async {
    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    
    try {
      if (!_formKey.currentState!.validate()) {
        return; // Form doğrulaması başarısız olursa işlemi durdur
      }
      
      setState(() => _isLoading = true);
      
      // İşçi modelini oluştur
      final worker = WorkerModel(
          id: widget.worker?.id ?? '',
          firstName: _nameController.text,
          lastName: _surnameController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          photoUrl: widget.worker?.photoUrl ?? '', // Mevcut fotoğraf URL'si (varsa)
          position: _positionController.text, 
          safetyDocsComplete: _isActive,
          entryDocsComplete: widget.worker?.entryDocsComplete ?? false,
          isActive: true,
      );
      
      // Fotoğraf dosyası kontrolü ve hazırlığı
      File? photoFile;
      if (_selectedPhotoUrl.isNotEmpty && !_selectedPhotoUrl.startsWith('http')) {
        try {
          photoFile = File(_selectedPhotoUrl);
          
          // Dosyanın var olduğunu kontrol et
          if (!await photoFile.exists()) {
            print('Fotoğraf dosyası bulunamadı: $_selectedPhotoUrl');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seçilen fotoğraf dosyası bulunamadı')),
            );
            setState(() => _isLoading = false);
            return;
          }
        } catch (fileError) {
          print('Fotoğraf dosyası hatası: $fileError');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fotoğraf dosyası hatası: $fileError')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
      
      bool success;
      if (widget.worker != null) {
        // Düzenleme modu - sadece değişen alanları gönder
        final Map<String, dynamic> updateData = {
          'firstName': _nameController.text,
          'lastName': _surnameController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'position': _positionController.text,
          'safetyDocsComplete': _isActive,
          'isActive': true,
        };
        
        // İşçiyi güncelle (fotoğraf varsa yükle)
        success = await viewModel.updateWorker(widget.worker!.id, updateData, photoFile: photoFile);
      } else {
        // Yeni işçi ekle (fotoğraf varsa yükle)
        success = await viewModel.addWorker(worker, photoFile: photoFile);
      }
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşçi başarıyla kaydedildi')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen hata"}')),
        );
      }
    } catch (e) {
      print('_saveWorker genel hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşçi kaydedilirken beklenmeyen hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class WorkerDetailsDialog extends StatelessWidget {
  final WorkerModel worker;

  const WorkerDetailsDialog({Key? key, required this.worker}) : super(key: key);

  // Geliştirimiş bilgi satırı - ikonlar ve renkli göstergelerle
  Widget _buildDetailRow(String label, String value, {IconData? icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) 
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon, size: 20, color: Colors.blue[700]),
            ),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Durum göstergesi widget'ı
  Widget _buildStatusIndicator(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green[700] : Colors.red[700],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Aktif' : 'Pasif',
            style: TextStyle(
              color: isActive ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Belge durumu göstergesi
  Widget _buildDocumentStatusChip(String label, bool isComplete) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isComplete ? Colors.green[200]! : Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isComplete ? Icons.task_alt : Icons.pending_actions,
            size: 14,
            color: isComplete ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isComplete ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }
  
  // Platform uyumlu işçi fotoğrafı görüntüleme metodu
  Widget _buildWorkerImage(String photoUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue[200]!, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(75),
        child: photoUrl.startsWith('http') 
            ? Image.network(
                photoUrl,
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 150,
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Ağ fotoğrafı yükleme hatası: $error');
                  return _buildPlaceholderImage();
                },
              )
            : _buildFileImage(photoUrl),
      ),
    );
  }
  
  // Dosya yolundan resim yükleme
  Widget _buildFileImage(String photoUrl) {
    try {
      // Dosya var mı kontrol et
      final file = File(photoUrl);
      if (!file.existsSync()) {
        print('Dosya bulunamadı: $photoUrl');
        return _buildPlaceholderImage();
      }
      
      return Image.file(
        file,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Dosya fotoğrafı yükleme hatası: $error');
          return _buildPlaceholderImage();
        },
      );
    } catch (e) {
      print('Fotoğraf yükleme hatası: $e');
      return _buildPlaceholderImage();
    }
  }
  
  // Placeholder resim widget'ı
  Widget _buildPlaceholderImage() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey[200],
      child: Icon(Icons.person, size: 80, color: Colors.grey[400]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Provider.of<UserViewModel>(context, listen: false).isAdmin;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${worker.firstName} ${worker.lastName}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  _buildStatusIndicator(worker.safetyDocsComplete),
                ],
              ),
              const Divider(height: 24, thickness: 1),
              
              // Content area with photo and details
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo section
                      if (worker.photoUrl.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: _buildWorkerImage(worker.photoUrl),
                          ),
                        ),
                      
                      const SizedBox(height: 8),
                      
                      // Contact information section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'İletişim Bilgileri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            _buildDetailRow('Telefon', worker.phone, icon: Icons.phone),
                            _buildDetailRow('Adres', worker.address, icon: Icons.home),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Documents section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                'Belge Durumu',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            Wrap(
                              children: [
                                _buildDocumentStatusChip(
                                  'Güvenlik Belgeleri',
                                  worker.safetyDocsComplete,
                                ),
                                _buildDocumentStatusChip(
                                  'Giriş Belgeleri',
                                  worker.entryDocsComplete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Kapat'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  if (isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Düzenle'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => AddEditWorkerDialog(worker: worker),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

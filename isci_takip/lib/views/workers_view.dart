import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: worker.safetyDocsComplete ? Colors.green : Colors.grey,
          child: Text(
            worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text('${worker.firstName} ${worker.lastName}'),
        subtitle: Text(worker.address ?? 'Adres belirtilmemiş'),
        trailing: Consumer<UserViewModel>(builder: (context, userViewModel, child) {
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkerDetailsView(workerId: worker.id),
                    ),
                  );
                },
                tooltip: 'Detaylar',
              ),
            ],
          );
        }),
        onTap: () {
          // Navigate to worker details view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerDetailsView(workerId: worker.id),
            ),
          );
        },
      ),
    );
  }

  void _toggleWorkerStatus(BuildContext context, WorkerModel worker) {
    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    viewModel.setWorkerActiveStatus(worker.id, !worker.safetyDocsComplete);
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
  bool _isActive = true;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  String _selectedPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _nameController.text = widget.worker!.firstName;
      _surnameController.text = widget.worker!.lastName;
      _phoneController.text = widget.worker!.phone;
      _addressController.text = widget.worker!.address;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.worker != null;
    
    return AlertDialog(
      title: Text(isEditing ? 'İşçi Düzenle' : 'Yeni İşçi Ekle'),
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
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Fotoğraf seçme bölümü
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_selectedPhotoUrl.isNotEmpty)
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _selectedPhotoUrl.startsWith('http')
                            ? NetworkImage(_selectedPhotoUrl)
                            : FileImage(File(_selectedPhotoUrl)) as ImageProvider,
                        backgroundColor: Colors.grey[300],
                      )
                    else
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, size: 40),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Fotoğraf Seç'),
                    ),
                    if (_selectedPhotoUrl.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedPhotoUrl = '';
                          });
                        },
                        child: const Text('Fotoğrafı Kaldır'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('İş Güvenliği Evrakları Tamamlandı:'),
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
        
        // Basitçe fotoğraf path'ini kaydet (iOS'ta da çalışacak)
        setState(() {
          _selectedPhotoUrl = image.path;
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fotoğraf seçildi')),
          );
        }
      }
    } catch (e) {
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
      setState(() => _isLoading = true);
      
      final worker = WorkerModel(
        id: widget.worker?.id ?? '',
        firstName: _nameController.text,
        lastName: _surnameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        photoUrl: _selectedPhotoUrl,
        safetyDocsComplete: _isActive,
        entryDocsComplete: false,
        isActive: true, // Yeni işçiler varsayılan olarak aktif
      );
      
      bool success;
      if (widget.worker != null) {
        success = await viewModel.updateWorker(worker);
      } else {
        final result = await viewModel.addWorker(worker);
        success = result != false;
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class WorkerDetailsDialog extends StatelessWidget {
  final WorkerModel worker;

  const WorkerDetailsDialog({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${worker.firstName} ${worker.lastName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (worker.photoUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      worker.photoUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 50),
                        );
                      },
                    ),
                  ),
                ),
              ),
            _buildDetailRow('Durum', worker.safetyDocsComplete ? 'Aktif' : 'Pasif'),
            _buildDetailRow('Telefon', worker.phone),
            _buildDetailRow('Adres', worker.address),
            _buildDetailRow('Güvenlik Belgeleri', worker.safetyDocsComplete ? 'Tamamlandı' : 'Tamamlanmadı'),
            _buildDetailRow('Giriş Belgeleri', worker.entryDocsComplete ? 'Tamamlandı' : 'Tamamlanmadı'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Kapat'),
        ),
        // Edit button - only for admin users
        if (Provider.of<UserViewModel>(context, listen: false).isAdmin)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => AddEditWorkerDialog(worker: worker),
              );
            },
            child: const Text('Düzenle'),
          ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/worker_model.dart';
import '../view_models/worker_view_model.dart';

class WorkerDetailsView extends StatelessWidget {
  final String workerId;
  
  const WorkerDetailsView({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkerViewModel>(context);
    final worker = viewModel.workers.firstWhere(
      (w) => w.id == workerId, 
      orElse: () => WorkerModel(id: '', firstName: '', lastName: '', phone: '', address: '')
    );
    
    if (worker.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('İşçi Detayları'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('İşçi bulunamadı'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${worker.firstName} ${worker.lastName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditWorkerDialog(context, worker);
            },
            tooltip: 'Düzenle',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker profile header
            Center(
              child: Column(
                children: [
                  _buildWorkerAvatar(worker),
                  const SizedBox(height: 16),
                  Text(
                    '${worker.firstName} ${worker.lastName}',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Document status
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evrak Durumu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Icon(
                        worker.safetyDocsComplete ? Icons.check_circle : Icons.cancel,
                        color: worker.safetyDocsComplete ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      title: const Text('İş Güvenliği Evrakları'),
                      subtitle: Text(
                        worker.safetyDocsComplete ? 'Tamamlandı' : 'Eksik',
                        style: TextStyle(
                          color: worker.safetyDocsComplete ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        worker.entryDocsComplete ? Icons.check_circle : Icons.cancel,
                        color: worker.entryDocsComplete ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      title: const Text('Giriş Evrakları'),
                      subtitle: Text(
                        worker.entryDocsComplete ? 'Tamamlandı' : 'Eksik',
                        style: TextStyle(
                          color: worker.entryDocsComplete ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Görev Bilgisi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      context,
                      icon: Icons.work,
                      title: 'Pozisyon',
                      value: worker.position.isNotEmpty ? worker.position : 'Belirtilmemiş',
                    ),
                  ],
                ),
              ),
            ),
            
            // Worker contact details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İletişim Bilgileri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailItem(
                      context,
                      icon: Icons.phone,
                      title: 'Telefon',
                      value: worker.phone,
                    ),
                    _buildDetailItem(
                      context,
                      icon: Icons.location_on,
                      title: 'Adres',
                      value: worker.address,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _showEditWorkerDialog(context, worker);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Düzenle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showDeleteConfirmationDialog(context, worker);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Sil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditWorkerDialog(BuildContext context, WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => WorkerFormDialog(worker: worker),
    );
  }

  // İşçi fotoğrafını güvenli bir şekilde gösteren widget
  Widget _buildWorkerAvatar(WorkerModel worker) {
    if (worker.photoUrl.isEmpty) {
      // Fotoğraf yoksa baş harfini göster
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue,
        child: Text(
          worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
          style: const TextStyle(fontSize: 40, color: Colors.white),
        ),
      );
    }
    
    // Ağ üzerinden fotoğraf yükleme
    if (worker.photoUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.blue,
        backgroundImage: null, // Doğrudan backgroundImage kullanmak yerine child içinde Image widget kullanacağız
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.network(
            worker.photoUrl,
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
              return Text(
                worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              );
            },
          ),
        ),
      );
    } 
    // Yerel dosya sisteminden fotoğraf yükleme
    else {
      try {
        // Dosya var mı kontrol et
        final file = File(worker.photoUrl);
        if (!file.existsSync()) {
          print('Dosya bulunamadı: ${worker.photoUrl}');
          return CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Text(
              worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 40, color: Colors.white),
            ),
          );
        }
        
        return CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          backgroundImage: null, // Doğrudan backgroundImage kullanmak yerine child içinde Image widget kullanacağız
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.file(
              file,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Dosya fotoğrafı yükleme hatası: $error');
                return Text(
                  worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                );
              },
            ),
          ),
        );
      } catch (e) {
        print('Fotoğraf yükleme hatası: $e');
        return CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          child: Text(
            worker.firstName.isNotEmpty ? worker.firstName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, WorkerModel worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşçiyi Sil'),
        content: Text('${worker.firstName} ${worker.lastName} isimli işçiyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
              viewModel.deleteWorker(worker.id).then((success) {
                Navigator.of(context).pop(); // Dialog'u kapat
                Navigator.of(context).pop(); // Detay sayfasından çık
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İşçi başarıyla silindi')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('İşçi silinirken bir hata oluştu')),
                  );
                }
              });
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class WorkerFormDialog extends StatefulWidget {
  final WorkerModel worker;

  const WorkerFormDialog({super.key, required this.worker});

  @override
  State<WorkerFormDialog> createState() => _WorkerFormDialogState();
}

class _WorkerFormDialogState extends State<WorkerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _positionController = TextEditingController(); // YENİ
  bool _safetyDocsComplete = false;
  bool _entryDocsComplete = false;

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
  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.worker.firstName;
    _lastNameController.text = widget.worker.lastName;
    _phoneController.text = widget.worker.phone;
    _addressController.text = widget.worker.address;
    _photoUrlController.text = widget.worker.photoUrl;
    _safetyDocsComplete = widget.worker.safetyDocsComplete;
    _entryDocsComplete = widget.worker.entryDocsComplete;
    _positionController.text = widget.worker.position; // YENİ
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _photoUrlController.dispose();
    _positionController.dispose(); // YENİ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('İşçi Düzenle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
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
                controller: _lastNameController,
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
                value: _positions.contains(_positionController.text) 
                    ? _positionController.text 
                    : null,
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
                  labelText: 'Telefon *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Telefon alanı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adres alanı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Fotoğraf URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('İş Güvenliği Evrakları Tamamlandı'),
                value: _safetyDocsComplete,
                onChanged: (value) {
                  setState(() {
                    _safetyDocsComplete = value;
                  });
                },
                activeColor: Colors.green,
              ),
              SwitchListTile(
                title: const Text('Giriş Evrakları Tamamlandı'),
                value: _entryDocsComplete,
                onChanged: (value) {
                  setState(() {
                    _entryDocsComplete = value;
                  });
                },
                activeColor: Colors.green,
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
          child: const Text('Güncelle'),
        ),
      ],
    );
  }

  void _saveWorker(BuildContext context) {
    final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
    
    // Güncellenecek verileri bir Map olarak hazırla
    final Map<String, dynamic> updateData = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'photoUrl': _photoUrlController.text,
      'position': _positionController.text,
      'safetyDocsComplete': _safetyDocsComplete,
      'entryDocsComplete': _entryDocsComplete,
    };
    
    viewModel.updateWorker(widget.worker.id, updateData).then((success) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşçi bilgileri güncellendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Güncelleme başarısız"}')),
        );
      }
    });
  }
}

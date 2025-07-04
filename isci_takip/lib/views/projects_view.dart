import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../view_models/project_view_model.dart';
import '../view_models/user_view_model.dart';
import 'worker_details_view.dart';
import 'assign_workers_view.dart';
import 'attendance_view.dart';
import 'site_photos_view.dart';
import 'monthly_report_view.dart';

class ProjectsView extends StatefulWidget {
  final bool forReporting;
  
  const ProjectsView({super.key, this.forReporting = false});

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  bool _showOnlyActive = true;

  @override
  void initState() {
    super.initState();
    // Initialize the project view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final projectViewModel = Provider.of<ProjectViewModel>(context, listen: false);
      
      // Alt kullanıcı ise sadece yetkili olduğu projeleri göster
      if (userViewModel.currentUser != null && !userViewModel.currentUser!.isAdmin) {
        projectViewModel.init(
          userId: userViewModel.currentUser!.id,
          userProjectIds: userViewModel.currentUser!.assignedProjectIds,
        );
      } else {
        projectViewModel.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forReporting ? 'Sarsılmaz İnşaat - Rapor İçin Proje Seçin' : 'Sarsılmaz İnşaat - Projeler'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Toggle between all projects and active projects
          IconButton(
            icon: Icon(
              _showOnlyActive ? Icons.visibility : Icons.visibility_off,
              color: _showOnlyActive ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showOnlyActive = !_showOnlyActive;
              });
            },
            tooltip: _showOnlyActive ? 'Tüm Projeleri Göster' : 'Sadece Aktif Projeleri Göster',
          ),
        ],
      ),
      body: Consumer<ProjectViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hata: ${viewModel.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.clearError();
                      viewModel.init();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final projects = _showOnlyActive ? viewModel.activeProjects : viewModel.projects;

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _showOnlyActive
                        ? 'Aktif proje bulunamadı'
                        : 'Hiç proje bulunamadı',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (Provider.of<UserViewModel>(context, listen: false).isAdmin)
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddProjectDialog(context);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Proje Ekle'),
                    ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectListItem(context, project);
            },
          );
        },
      ),
      floatingActionButton: Provider.of<UserViewModel>(context).isAdmin
          ? FloatingActionButton(
              onPressed: () {
                _showAddProjectDialog(context);
              },
              tooltip: 'Proje Ekle',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildProjectListItem(BuildContext context, ProjectModel project) {
    // Eğer rapor görünümü için kullanılıyorsa, tıklandığında direkt MonthlyReportView'a yönlendir
    if (widget.forReporting) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(
            project.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            true ? 'Aktif' : 'Pasif',
            style: TextStyle(
              color: true ? Colors.green : Colors.red,
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.business, color: Colors.white),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MonthlyReportView(project: project),
              ),
            );
          },
        ),
      );
    }
    
    // Normal proje görünümü
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          project.isActive ? 'Aktif' : 'Pasif',
          style: TextStyle(
            color: project.isActive ? Colors.green : Colors.red,
          ),
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.business, color: Colors.white),
        ),
        children: [
          if (project.location != null && project.location!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(project.location!),
                  ),
                ],
              ),
            ),
          if (project.location != null && project.location!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(project.location!),
                  ),
                ],
              ),
            ),
          if (project.startDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Başlangıç: ${project.startDate!.day}/${project.startDate!.month}/${project.startDate!.year}',
                  ),
                ],
              ),
            ),
          if (project.startDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Bitiş: ${project.startDate!.day}/${project.startDate!.month}/${project.startDate!.year}',
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Only admin can assign workers
                Consumer<UserViewModel>(
                  builder: (context, userViewModel, child) {
                    return ElevatedButton.icon(
                      onPressed: userViewModel.isAdmin
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignWorkersView(project: project),
                              ),
                            );
                          }
                        : null,
                      icon: const Icon(Icons.people),
                      label: const Text('İşçiler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                        disabledForegroundColor: Colors.white.withOpacity(0.5),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceView(project: project),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Yoklama'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SitePhotosView(project: project),
                      ),
                    );
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Fotoğraflar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                // Only admin can toggle project status
                Consumer2<ProjectViewModel, UserViewModel>(
                  builder: (context, projectViewModel, userViewModel, child) {
                    return ElevatedButton.icon(
                      onPressed: userViewModel.isAdmin
                        ? () {
                            // Toggle project active status
                            projectViewModel.setProjectActiveStatus(
                              project.id,
                              !project.isActive,
                            );
                          }
                        : null,
                      icon: Icon(project.isActive ? Icons.cancel : Icons.check_circle),
                      label: Text(project.isActive ? 'Pasif Yap' : 'Aktif Yap'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: project.isActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: (project.isActive ? Colors.red : Colors.green).withOpacity(0.3),
                        disabledForegroundColor: Colors.white.withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Aylık rapor butonu ekleme
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MonthlyReportView(project: project),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('Aylık Rapor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddProjectDialog(),
    );
  }
}

class AddProjectDialog extends StatefulWidget {
  const AddProjectDialog({super.key});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _clientContactController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _clientNameController.dispose();
    _clientContactController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Proje Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Proje Adı *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Proje adı zorunludur';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Bütçe',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Müşteri Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clientContactController,
                decoration: const InputDecoration(
                  labelText: 'Müşteri İletişim',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Başlangıç Tarihi:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
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
                  const Text('Bitiş Tarihi:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                      }
                    },
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
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
              _addProject(context);
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

  void _addProject(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final viewModel = Provider.of<ProjectViewModel>(context, listen: false);
    
    double? budget;
    if (_budgetController.text.isNotEmpty) {
      budget = double.tryParse(_budgetController.text);
    }
    
    final newProject = ProjectModel(
      id: '', // ID will be generated by Firestore
      name: _nameController.text,
      location: _locationController.text.isEmpty ? _descriptionController.text : _locationController.text,
      startDate: _startDate ?? DateTime.now(), // Eğer _startDate null ise şimdiki tarihi kullan
      assignedWorkerIds: [],
    );
    
    final success = await viewModel.addProject(newProject);
    
    if (!mounted) return;
    
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proje başarıyla eklendi')),
      );
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proje eklenirken bir hata oluştu')),
      );
    }
  }
}

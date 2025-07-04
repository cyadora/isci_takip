import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../models/worker_model.dart';
import '../view_models/worker_view_model.dart';
import '../view_models/project_view_model.dart';

class AssignWorkersView extends StatefulWidget {
  final ProjectModel project;

  const AssignWorkersView({super.key, required this.project});

  @override
  State<AssignWorkersView> createState() => _AssignWorkersViewState();
}

class _AssignWorkersViewState extends State<AssignWorkersView> {
  final Set<String> _selectedWorkerIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with already assigned workers
    _selectedWorkerIds.addAll(widget.project.assignedWorkerIds);
    
    // Make sure worker view model is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<WorkerViewModel>(context, listen: false);
      if (viewModel.workers.isEmpty) {
        viewModel.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İşçileri Projeye Ata: ${widget.project.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Projeye atamak istediğiniz işçileri seçin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: Consumer<WorkerViewModel>(
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

                if (viewModel.workers.isEmpty) {
                  return const Center(
                    child: Text('Henüz işçi bulunmamaktadır'),
                  );
                }

                return ListView.builder(
                  itemCount: viewModel.workers.length,
                  itemBuilder: (context, index) {
                    final worker = viewModel.workers[index];
                    final bool hasIncompleteDocuments = !worker.safetyDocsComplete;
                    final isSelected = _selectedWorkerIds.contains(worker.id);

                    return CheckboxListTile(
                      title: Text('${worker.firstName} ${worker.lastName}'),
                      subtitle: hasIncompleteDocuments
                          ? const Text(
                              'Evrak eksik',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            )
                          : null,
                      value: isSelected,
                      onChanged: hasIncompleteDocuments
                          ? null // Disable checkbox if documents are incomplete
                          : (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedWorkerIds.add(worker.id);
                                } else {
                                  _selectedWorkerIds.remove(worker.id);
                                }
                              });
                            },
                      activeColor: Theme.of(context).colorScheme.primary,
                      secondary: hasIncompleteDocuments
                          ? const Tooltip(
                              message: 'İş güvenliği evrakları eksik',
                              child: Icon(Icons.warning, color: Colors.orange),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAssignments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Atamayı Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssignments() async {
    setState(() {
      _isLoading = true;
    });

    final projectViewModel = Provider.of<ProjectViewModel>(context, listen: false);
    
    try {
      final success = await projectViewModel.assignWorkers(
        widget.project.id,
        _selectedWorkerIds.toList(),
      );
      
      if (!mounted) return;
      
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşçi atamaları başarıyla kaydedildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşçi atamaları kaydedilirken bir hata oluştu')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
}

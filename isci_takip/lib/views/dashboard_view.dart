import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/worker_view_model.dart';
import 'workers_view.dart';
import 'projects_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
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
    return Consumer<WorkerViewModel>(
      builder: (context, viewModel, child) {
        final totalWorkers = viewModel.workers.length;
        final activeWorkers = viewModel.activeWorkers.length;
        final inactiveWorkers = totalWorkers - activeWorkers;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Genel Bakış',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Stats cards
              Row(
                children: [
                  _buildStatCard(
                    context,
                    title: 'Toplam İşçi',
                    value: totalWorkers.toString(),
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context,
                    title: 'Aktif İşçi',
                    value: activeWorkers.toString(),
                    icon: Icons.person,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatCard(
                    context,
                    title: 'Pasif İşçi',
                    value: inactiveWorkers.toString(),
                    icon: Icons.person_off,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  _buildActionCard(
                    context,
                    title: 'İşçileri Yönet',
                    subtitle: 'İşçi ekle, düzenle veya sil',
                    icon: Icons.manage_accounts,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WorkersView()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildActionCard(
                    context,
                    title: 'Projeler',
                    subtitle: 'Projeleri görüntüle ve yönet',
                    icon: Icons.work,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProjectsView()),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Container()), // Empty space for alignment
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent workers section
              Text(
                'Son Eklenen İşçiler',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              
              if (viewModel.workers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Henüz işçi bulunmamaktadır'),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.workers.length > 5 ? 5 : viewModel.workers.length,
                  itemBuilder: (context, index) {
                    final worker = viewModel.workers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
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
                        trailing: Chip(
                          label: Text(
                            worker.safetyDocsComplete ? 'Aktif' : 'Pasif',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: worker.safetyDocsComplete ? Colors.green : Colors.grey,
                          padding: const EdgeInsets.all(0),
                        ),
                      ),
                    );
                  },
                ),
              
              const SizedBox(height: 16),
              
              // View all button
              if (viewModel.workers.isNotEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WorkersView()),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Tüm İşçileri Görüntüle'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    icon,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      icon,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

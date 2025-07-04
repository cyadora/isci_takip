import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import '../view_models/user_view_model.dart';
import 'workers_view.dart';
import 'dashboard_view.dart';
import 'add_worker_dialog.dart';
import 'projects_view.dart';
import 'login_view.dart';
import 'user_management_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  
  // Admin şifre doğrulama dialogunu göster
  void _showAdminPasswordDialog(BuildContext context, UserViewModel userViewModel) {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    // Sabit admin şifresi - gerçek uygulamada bu güvenli bir şekilde saklanmalıdır
    const String adminPassword = "admin123";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Doğrulama'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Admin Şifresi',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifre girin';
              }
              if (value != adminPassword) {
                return 'Hatalı şifre';
              }
              return null;
            },
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                
                // Şifre doğru, kullanıcıyı admin yap
                if (userViewModel.currentUser != null) {
                  await userViewModel.makeCurrentUserAdmin();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin yetkilerine sahip oldunuz!')),
                    );
                  }
                }
              }
            },
            child: const Text('Doğrula'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = Provider.of<LoginViewModel>(context);
    final userViewModel = Provider.of<UserViewModel>(context);
    
    // Initialize user view model if not already initialized
    if (userViewModel.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userViewModel.init();
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sarsılmaz İnşaat İşçi Takip Sistemi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await loginViewModel.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginView()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Çıkış Yap',
          ),
          // Show user role badge
          if (userViewModel.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Chip(
                label: Text(
                  userViewModel.isAdmin ? 'Yönetici' : 'Kullanıcı',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: userViewModel.isAdmin 
                  ? Colors.deepOrange
                  : Colors.blue,
              ),
            ),
        ],
      ),
      body: const DashboardView(),
      floatingActionButton: userViewModel.isAdmin ? FloatingActionButton(
        onPressed: () {
          // Show add worker dialog
          showDialog(
            context: context,
            builder: (context) => const AddWorkerDialog(),
          );
        },
        tooltip: 'İşçi Ekle',
        child: const Icon(Icons.add),
      ) : null, // Only show FAB for admin users
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'İşçi Takip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Yönetim Paneli',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Ana Sayfa'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('İşçiler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkersView()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Projeler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProjectsView()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Aylık Raporlar'),
              onTap: () {
                Navigator.pop(context);
                // Önce proje seçimi için ProjectsView'a yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProjectsView(forReporting: true)),
                );
              },
            ),
            const Divider(),
            // User Management (Admin Only)
            if (userViewModel.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Kullanıcı Yönetimi'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementView()),
                  );
                },
              ),
            const Divider(),
            // Admin olma butonu (sadece normal kullanıcılar için göster)
            if (!userViewModel.isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Admin Ol', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  // Admin şifre doğrulaması için dialog göster
                  _showAdminPasswordDialog(context, userViewModel);
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                Navigator.pop(context);
                await loginViewModel.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginView()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

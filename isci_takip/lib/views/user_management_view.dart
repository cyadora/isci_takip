import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../view_models/user_view_model.dart';
import '../view_models/project_view_model.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  @override
  void initState() {
    super.initState();
    // Initialize the view model
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<UserViewModel>(context, listen: false);
      viewModel.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<UserViewModel>(
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

          // Check if user is admin
          if (viewModel.currentUser == null || !viewModel.isAdmin) {
            return const Center(
              child: Text('Bu sayfaya erişim yetkiniz bulunmamaktadır.'),
            );
          }

          if (viewModel.users.isEmpty && viewModel.pendingUsers.isEmpty) {
            return const Center(
              child: Text('Henüz kullanıcı bulunmamaktadır.'),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddUserDialog(context),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Yeni Kullanıcı Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: 'Kullanıcılar (${viewModel.users.length})'),
                    Tab(text: 'Onay Bekleyenler (${viewModel.pendingUsers.length})', 
                      icon: viewModel.pendingUsers.isNotEmpty ? 
                        const Icon(Icons.notification_important, color: Colors.red) : null),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Aktif kullanıcılar tabı
                      viewModel.users.isEmpty
                        ? const Center(child: Text('Aktif kullanıcı bulunmamaktadır.'))
                        : ListView.builder(
                            itemCount: viewModel.users.length,
                            itemBuilder: (context, index) {
                              final user = viewModel.users[index];
                              final bool isCurrentUser = user.uid == viewModel.currentUser?.uid;
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      user.displayName?.isNotEmpty == true
                                          ? user.displayName![0].toUpperCase()
                                          : user.email[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user.displayName ?? user.email),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.role == 'admin' ? 'Yönetici' : user.role == 'subadmin' ? 'Alt Yönetici' : 'Kullanıcı'),
                                      if (!user.isActive)
                                        const Text('Pasif', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                  trailing: isCurrentUser
                                      ? const Chip(
                                          label: Text('Siz'),
                                          backgroundColor: Colors.grey,
                                        )
                                      : PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'admin') {
                                              _changeUserRole(context, user, 'admin');
                                            } else if (value == 'user') {
                                              _changeUserRole(context, user, 'user');
                                            } else if (value == 'subadmin') {
                                              _changeUserRole(context, user, 'subadmin');
                                            } else if (value == 'delete') {
                                              _showDeleteUserConfirmation(context, user);
                                            } else if (value == 'activate') {
                                              _activateUser(context, user);
                                            } else if (value == 'deactivate') {
                                              _deactivateUser(context, user);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                            if (user.role != 'admin')
                                              const PopupMenuItem<String>(
                                                value: 'admin',
                                                child: Text('Yönetici Yap'),
                                              ),
                                            if (user.role != 'subadmin')
                                              const PopupMenuItem<String>(
                                                value: 'subadmin',
                                                child: Text('Alt Yönetici Yap'),
                                              ),
                                            if (user.role != 'user')
                                              const PopupMenuItem<String>(
                                                value: 'user',
                                                child: Text('Normal Kullanıcı Yap'),
                                              ),
                                            const PopupMenuDivider(),
                                            if (user.isActive)
                                              const PopupMenuItem<String>(
                                                value: 'deactivate',
                                                child: Text('Pasif Yap', style: TextStyle(color: Colors.orange)),
                                              )
                                            else
                                              const PopupMenuItem<String>(
                                                value: 'activate',
                                                child: Text('Aktif Yap', style: TextStyle(color: Colors.green)),
                                              ),
                                            const PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Sil', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                      
                      // Onay bekleyen kullanıcılar tabı
                      viewModel.pendingUsers.isEmpty
                        ? const Center(child: Text('Onay bekleyen kullanıcı bulunmamaktadır.'))
                        : ListView.builder(
                            itemCount: viewModel.pendingUsers.length,
                            itemBuilder: (context, index) {
                              final user = viewModel.pendingUsers[index];
                              
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: Colors.amber.shade50,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber,
                                    child: const Icon(Icons.person_outline, color: Colors.white),
                                  ),
                                  title: Text(user.displayName ?? user.email),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Kayıt tarihi: ${user.createdAt != null ? _formatDate(user.createdAt!) : "Bilinmiyor"}'),
                                      const Text('Onay bekliyor', style: TextStyle(color: Colors.orange)),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () => _approveUser(context, user),
                                        tooltip: 'Onayla',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteUserConfirmation(context, user),
                                        tooltip: 'Sil',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';
    List<String> selectedProjectIds = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Kullanıcı Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    hintText: 'kullanici@ornek.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    hintText: 'En az 6 karakter',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Rolü',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('Normal Kullanıcı'),
                    ),
                    DropdownMenuItem(
                      value: 'subadmin',
                      child: Text('Alt Yönetici'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Proje seçimi (sadece normal kullanıcı için)
                if (selectedRole == 'user')
                  Consumer<ProjectViewModel>(
                    builder: (context, projectViewModel, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Erişim Yetkisi Verilecek Projeler:'),
                          const SizedBox(height: 8),
                          ...projectViewModel.projects.map((project) {
                            return CheckboxListTile(
                              title: Text(project.name),
                              value: selectedProjectIds.contains(project.id),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    selectedProjectIds.add(project.id);
                                  } else {
                                    selectedProjectIds.remove(project.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                  _addUser(
                    context,
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    selectedRole,
                    selectedProjectIds,
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addUser(BuildContext context, String email, String password, String role, List<String> projectIds) async {
    final viewModel = Provider.of<UserViewModel>(context, listen: false);
    
    Navigator.of(context).pop(); // Close the dialog
    
    final result = await viewModel.registerUser(
      email, 
      password, 
      role: role,
      assignedProjectIds: projectIds.isNotEmpty ? projectIds : null,
    );
    
    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı başarıyla eklendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    }
  }

  // Tarih formatını düzenle
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Kullanıcı rolünü değiştir
  Future<void> _changeUserRole(BuildContext context, UserModel user, String newRole) async {
    // Don't change if it's already the same role
    if (user.role == newRole) return;
    
    final viewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await viewModel.updateUserRole(user.uid, newRole);
    
    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? user.email} kullanıcısının rolü güncellendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    }
  }
  
  // Kullanıcıyı aktif yap
  Future<void> _activateUser(BuildContext context, UserModel user) async {
    final viewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await viewModel.setUserActiveStatus(user.uid, true);
    
    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? user.email} kullanıcısı aktif yapıldı')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    }
  }
  
  // Kullanıcıyı pasif yap
  Future<void> _deactivateUser(BuildContext context, UserModel user) async {
    final viewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await viewModel.setUserActiveStatus(user.uid, false);
    
    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? user.email} kullanıcısı pasif yapıldı')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    }
  }
  
  // Kullanıcı onaylama
  Future<void> _approveUser(BuildContext context, UserModel user) async {
    final viewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await viewModel.approveUser(user.uid);
    
    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? user.email} kullanıcısı onaylandı')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    }
  }
  
  // Kullanıcı silme onayı göster
  void _showDeleteUserConfirmation(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Silme'),
        content: Text('${user.displayName ?? user.email} kullanıcısını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteUser(context, user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  // Kullanıcı silme
  Future<void> _deleteUser(BuildContext context, UserModel user) async {
    final viewModel = Provider.of<UserViewModel>(context, listen: false);
    final result = await viewModel.deleteUser(user.uid);
    
    if (context.mounted) {
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.displayName ?? user.email} kullanıcısı silindi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu"}')),
        );
      }
    }
  }
}

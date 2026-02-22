import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/produce_service.dart';
import '../../models/produce_model.dart';
import '../../utils/app_theme.dart';
import '../produce/produce_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.userModel;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryGreen,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user.role == UserRole.farmer
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role == UserRole.farmer ? 'Farmer' : 'Buyer',
                style: TextStyle(
                  color: user.role == UserRole.farmer
                      ? AppTheme.primaryGreen
                      : AppTheme.accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info cards
            _InfoTile(icon: Icons.email, label: 'Email', value: user.email),
            _InfoTile(icon: Icons.phone, label: 'Phone', value: user.phone),
            if (user.location != null && user.location!.isNotEmpty)
              _InfoTile(
                  icon: Icons.location_on,
                  label: 'Location',
                  value: user.location!),
            const SizedBox(height: 16),

            // Settings section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock, color: AppTheme.primaryGreen),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePassword(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: AppTheme.primaryGreen),
                    title: const Text('About AgroConnect'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAbout(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Sign Out',
                        style: TextStyle(color: Colors.red)),
                    onTap: () => _confirmSignOut(context, authService),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My produce (for farmers)
            if (user.role == UserRole.farmer) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Produce',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/add-produce'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<ProduceModel>>(
                stream: context
                    .read<ProduceService>()
                    .getFarmerProduce(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final produceList = snapshot.data ?? [];

                  if (produceList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.eco, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No produce listed yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/add-produce'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Produce'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: produceList.map((produce) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: produce.imageUrls.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      produce.imageUrls.first,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.eco),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.eco),
                                  ),
                            title: Text(produce.name),
                            subtitle: Text(
                              'UGX ${produce.price.toStringAsFixed(0)} / ${produce.unit}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: produce.isReady
                                    ? AppTheme.readyColor
                                    : AppTheme.unreadyColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                produce.isReady ? 'Ready' : 'Unready',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProduceDetailScreen(produce: produce),
                                ),
                              );
                            },
                          ),
                        )).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPwController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Current Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: newPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: confirmPwController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm New Password'),
                validator: (v) {
                  if (v != newPwController.text) return 'Passwords don\'t match';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final authService = ctx.read<AuthService>();
              final error = await authService.changePassword(
                currentPassword: currentPwController.text,
                newPassword: newPwController.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Password changed successfully!'),
                    backgroundColor:
                        error != null ? Colors.red : AppTheme.primaryGreen,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'AgroConnect',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.eco,
        color: AppTheme.primaryGreen,
        size: 48,
      ),
      children: [
        const Text(
          'AgroConnect connects farmers directly with buyers. '
          'Farmers can list their produce (ready or upcoming), '
          'and buyers can browse, chat, and purchase directly.',
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              authService.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

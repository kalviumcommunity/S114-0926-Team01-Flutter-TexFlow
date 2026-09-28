import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/production_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (!authState.isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Admin access required',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Panel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.factory), text: 'Stages'),
            Tab(icon: Icon(Icons.tune), text: 'Alert Config'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                authState.user!.name.isNotEmpty ? authState.user!.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: colorScheme.onSurface),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildUsersTab(context, ref),
            _buildStagesTab(context, ref),
            _buildAlertConfigTab(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppButton(
                label: 'Add User',
                icon: Icons.person_add,
                onPressed: () => _showAddUserDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Register new users. Note: User listing requires backend endpoint.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          AppCard(
            title: 'Create New User',
            child: _buildUserForm(context, ref),
          ),
          const SizedBox(height: 24),
          AppCard(
            title: 'Current User (Demo)',
            child: _buildCurrentUserInfo(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'supervisor';
    bool isLoading = false;

    return Consumer(
      builder: (context, ref, child) {
        return Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  if (value.length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter email';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedRole = value;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter password';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Register User',
                  icon: Icons.person_add,
                  onPressed: isLoading ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    isLoading = true;
                    (context as Element).markNeedsBuild();

                    try {
                      final authApi = ref.read(authApiProvider);
                      await authApi.register(RegisterRequest(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                        role: selectedRole,
                      ));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User registered successfully'), backgroundColor: Colors.green),
                        );
                        nameController.clear();
                        emailController.clear();
                        passwordController.clear();
                        selectedRole = 'supervisor';
                        (context as Element).markNeedsBuild();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      isLoading = false;
                      if (context.mounted) (context as Element).markNeedsBuild();
                    }
                  },
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentUserInfo(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(user?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(user?.email ?? ''),
          trailing: Chip(
            label: Text(user?.role ?? 'supervisor'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.badge_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
          title: const Text('Current Role'),
          trailing: Text(
            user?.role ?? 'supervisor',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add User'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildUserForm(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildStagesTab(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(productionStagesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Production Stages',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              AppButton(
                label: 'Add Stage',
                icon: Icons.add,
                onPressed: () => _showAddStageDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage production stages. Note: Update/Delete requires backend endpoints.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          stagesAsync.when(
            data: (stages) => stages.isEmpty
                ? _buildEmptyState(context, 'No stages found', 'Add your first production stage')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stages.length,
                    itemBuilder: (context, index) {
                      final stage = stages[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer,
                            child: Text('${stage.order}', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(stage.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stage.description != null) Text(stage.description!),
                              Text('Order: ${stage.order}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditStageDialog(context, ref, stage),
                                tooltip: 'Edit (requires backend PUT)',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _showDeleteStageConfirm(context, ref, stage),
                                tooltip: 'Delete (requires backend DELETE)',
                              ),
                            ],
                          ),
                        );
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _buildErrorState(context, 'Failed to load stages: $err'),
          ),
          const SizedBox(height: 24),
          AppCard(
            title: 'Add New Stage',
            child: _buildStageForm(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildStageForm(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final orderController = TextEditingController(text: '1');
    bool isLoading = false;

    return Consumer(
      builder: (context, ref, child) {
        return Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Stage Name *',
                  prefixIcon: Icon(Icons.factory_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter stage name';
                  if (value.length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Order *',
                  prefixIcon: Icon(Icons.format_list_numbered),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter order';
                  final order = int.tryParse(value);
                  if (order == null || order < 1) return 'Order must be a positive integer';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Add Stage',
                  icon: Icons.add,
                  onPressed: isLoading ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    isLoading = true;
                    (context as Element).markNeedsBuild();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Stage creation requires backend POST /api/production/stages endpoint'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    isLoading = false;
                    if (context.mounted) (context as Element).markNeedsBuild();
                  },
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddStageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Production Stage'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: _buildStageForm(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditStageDialog(BuildContext context, WidgetRef ref, ProductionStage stage) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: stage.name);
    final descriptionController = TextEditingController(text: stage.description ?? '');
    final orderController = TextEditingController(text: stage.order.toString());
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Stage'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Stage Name *',
                      prefixIcon: Icon(Icons.factory_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter stage name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: orderController,
                    decoration: const InputDecoration(
                      labelText: 'Order *',
                      prefixIcon: Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter order';
                      final order = int.tryParse(value);
                      if (order == null || order < 1) return 'Order must be a positive integer';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Save Changes',
                      icon: Icons.save,
                      onPressed: isLoading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        isLoading = true;
                        (dialogContext as Element).markNeedsBuild();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stage update requires backend PUT /api/production/stages/:id endpoint'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          Navigator.pop(dialogContext);
                        }
                        isLoading = false;
                      },
                      isLoading: isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteStageConfirm(BuildContext context, WidgetRef ref, ProductionStage stage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Stage'),
        content: Text('Are you sure you want to delete "${stage.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stage deletion requires backend DELETE /api/production/stages/:id endpoint'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertConfigTab(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alert Threshold Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure bottleneck detection thresholds. Note: Changes require backend endpoint.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          AppCard(
            title: 'Bottleneck Detection Thresholds',
            child: Column(
              children: [
                _buildThresholdItem(
                  context,
                  'Medium Alert',
                  'Triggered when current stage output < 70% of previous stage',
                  0.7,
                  Colors.orange,
                ),
                const Divider(),
                _buildThresholdItem(
                  context,
                  'High Alert',
                  'Triggered when current stage output < 50% of previous stage',
                  0.5,
                  Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            title: 'Alert Settings',
            child: Column(
              children: [
                _buildSettingItem(
                  context,
                  Icons.notifications_active,
                  'Enable Bottleneck Alerts',
                  'Automatically create alerts when bottlenecks are detected',
                  true,
                  (value) {},
                ),
                const Divider(),
                _buildSettingItem(
                  context,
                  Icons.email,
                  'Email Notifications',
                  'Send email alerts to supervisors',
                  false,
                  (value) {},
                ),
                const Divider(),
                _buildSettingItem(
                  context,
                  Icons.schedule,
                  'Auto-resolve After',
                  'Automatically resolve alerts after shift ends',
                  false,
                  (value) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            title: 'Actions',
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Test Alert Generation',
                    icon: Icons.bug_report,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test alert sent (backend endpoint needed)'), backgroundColor: Colors.blue),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Save Configuration',
                    icon: Icons.save,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Configuration saved (backend endpoint needed)'), backgroundColor: Colors.green),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdItem(BuildContext context, String title, String description, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Threshold editing requires backend endpoint'), backgroundColor: Colors.orange),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(productionStagesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
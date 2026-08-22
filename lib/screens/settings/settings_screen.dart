import 'package:expense_track/constants.dart';
import 'package:expense_track/data/data.dart';
import 'package:expense_track/services/auth_service.dart';
import 'package:expense_track/services/export_service.dart';
import 'package:expense_track/utils/formatters.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _exporting = false;
  bool _changingPassword = false;
  bool _saving = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _persist(String successMessage) async {
    if (_saving) return;
    _saving = true;
    try {
      await AppData.saveSettings();
      _showMessage(successMessage);
    } catch (e) {
      _showMessage(Formatters.friendlyError(e));
    } finally {
      _saving = false;
    }
  }

  // ─── Profile ────────────────────────────────────────────────────────────

  Future<void> _editName() async {
    final controller = TextEditingController(text: AppData.displayName.value);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    try {
      await AuthService.updateName(name);
      AppData.displayName.value = name;
      await _persist('Profile updated');
    } catch (e) {
      if (!mounted) return;
      _showMessage(Formatters.friendlyError(e));
    }
  }

  Future<void> _linkEmail() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign in with email'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Min 6 characters'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AuthService.linkGuestToEmail(
        emailController.text.trim(),
        passwordController.text,
        name: nameController.text,
      );
      AppData.displayName.value = nameController.text.trim();
      await _persist('Account linked');
    } catch (e) {
      if (!mounted) return;
      _showMessage(Formatters.friendlyError(e));
    }
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  // ─── Appearance / currency / notifications ─────────────────────────────

  Future<void> _pickCurrency() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Currency'),
        children: [
          RadioGroup<String>(
            groupValue: AppData.currencyCode.value,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final currency in AppConstants.currencies)
                  RadioListTile<String>(
                    title: Text('${currency['symbol']}  ${currency['code']}'),
                    value: currency['code']!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    AppData.currencyCode.value = selected;
    await _persist('Currency updated');
  }

  Future<void> _editMonthlyBudget() async {
    final controller = TextEditingController(
      text: AppData.monthlyBudget.value > 0
          ? AppData.monthlyBudget.value.toStringAsFixed(0)
          : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget amount',
            prefixText: '${AppData.currencySymbol} ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    AppData.monthlyBudget.value = result <= 0 ? 0 : result;
    await _persist('Budget updated');
  }

  Future<void> _editCategoryBudget(String category) async {
    final current = AppData.categoryBudgets.value[category] ?? 0;
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(0) : '',
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Budget for $category'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget amount',
            prefixText: '${AppData.currencySymbol} ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final updated = Map<String, double>.from(AppData.categoryBudgets.value);
    if (result <= 0) {
      updated.remove(category);
    } else {
      updated[category] = result;
    }
    AppData.categoryBudgets.value = updated;
    await _persist('Budget updated');
  }

  Future<void> _showCategoryBudgets() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Category budgets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final category
                in AppConstants.expenseCategories.map((c) => c['name'] as String))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.category_outlined),
                title: Text(category),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppData.categoryBudgets.value[category] != null
                          ? Formatters.amount(
                              AppData.categoryBudgets.value[category]!,
                              decimals: 0,
                            )
                          : 'Not set',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editCategoryBudget(category),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Data / export ──────────────────────────────────────────────────────

  Future<void> _export() async {
    if (_exporting) return;
    if (AppData.transactions.value.isEmpty) {
      _showMessage('No transactions to export');
      return;
    }
    setState(() => _exporting = true);
    try {
      await ExportService.exportAndShare(AppData.transactions.value);
    } catch (e) {
      if (!mounted) return;
      _showMessage(Formatters.friendlyError(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'Clears the locally cached transactions. Data will reload from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    AppData.reloadData();
    _showMessage('Local data cleared');
  }

  // ─── Security ───────────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    if (_changingPassword) return;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Min 6 characters'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _changingPassword = true);
    try {
      await AuthService.changePassword(
        currentController.text,
        newController.text,
      );
      if (!mounted) return;
      _showMessage('Password changed');
    } catch (e) {
      if (!mounted) return;
      _showMessage(Formatters.friendlyError(e));
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
    currentController.dispose();
    newController.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will be signed out of this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await AuthService.signOut();
    } catch (e) {
      if (!mounted) return;
      _showMessage(Formatters.friendlyError(e));
    }
  }

  // ─── About ──────────────────────────────────────────────────────────────

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Expense Tracker'),
        content: const Text(
          'Expense Tracker helps you record income and expenses, '
          'track your monthly budget and understand your spending '
          'with charts and statistics.\n\n'
          'Your data is stored privately in your own Firebase account '
          'and is never shared with other users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy'),
        content: const Text(
          'All financial data is stored in Firestore under your own '
          'user account. Firestore security rules ensure that only you '
          'can read and write your data.\n\n'
          'We do not collect, sell or share your personal information '
          'with third parties.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = AppData.user.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<String>(
        valueListenable: AppData.currencyCode,
        builder: (context, _, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// PROFILE
              _SectionCard(
                title: 'Profile',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 26,
                      child: Text(
                        _initial(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      AppData.displayName.value.isEmpty
                          ? (user?.isAnonymous ?? true)
                              ? 'Guest'
                              : (user?.email ?? 'User')
                          : AppData.displayName.value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user?.email ?? 'Guest account'),
                  ),
                  if (user?.isAnonymous ?? false)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link),
                      title: const Text('Sign in with email'),
                      subtitle: const Text(
                        'Keep your data when you create an account',
                      ),
                      onTap: _linkEmail,
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit profile'),
                    onTap: _editName,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// APPEARANCE
              _SectionCard(
                title: 'Appearance',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: AppData.themeMode,
                      builder: (context, mode, _) => SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {mode},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) async {
                          AppData.themeMode.value = selection.first;
                          await _persist('Appearance updated');
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// CURRENCY
              _SectionCard(
                title: 'Currency',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.currency_exchange),
                    title: Text(
                      '${AppData.currencySymbol}  ${AppData.currencyCode.value}',
                    ),
                    subtitle: const Text('Used across the app'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickCurrency,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// NOTIFICATIONS
              _SectionCard(
                title: 'Notifications',
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: AppData.notificationsEnabled,
                    builder: (context, enabled, _) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Budget alerts'),
                      subtitle: const Text(
                        'Warn when you approach or exceed your budget',
                      ),
                      value: enabled,
                      onChanged: (value) async {
                        AppData.notificationsEnabled.value = value;
                        await _persist('Notifications updated');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// BUDGET
              _SectionCard(
                title: 'Budget',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.savings_outlined),
                    title: const Text('Monthly budget'),
                    subtitle: Text(
                      AppData.monthlyBudget.value > 0
                          ? Formatters.amount(
                              AppData.monthlyBudget.value,
                              decimals: 0,
                            )
                          : 'Not set',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _editMonthlyBudget,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category_outlined),
                    title: const Text('Category budgets'),
                    subtitle: const Text('Set a limit per category'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showCategoryBudgets,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// DATA
              _SectionCard(
                title: 'Data',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('Backup / sync'),
                    subtitle: const Text('Synced with Firebase'),
                    trailing: AppData.isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle,
                            color: Colors.green, size: 20),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Export transactions'),
                    subtitle: const Text('Download as CSV and share'),
                    trailing: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _exporting ? null : _export,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear local cache'),
                    subtitle: const Text('Reload data from the server'),
                    onTap: _clearCache,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// SECURITY
              _SectionCard(
                title: 'Security',
                children: [
                  if (!(user?.isAnonymous ?? true)) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_outline),
                      title: const Text('Change password'),
                      trailing: _changingPassword
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _changingPassword ? null : _changePassword,
                    ),
                    const Divider(),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    onTap: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// ABOUT
              _SectionCard(
                title: 'About',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Expense Tracker'),
                    onTap: _showAbout,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy'),
                    onTap: _showPrivacy,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text('App version'),
                    trailing: Text(
                      AppConstants.appVersion,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  String _initial() {
    final name = AppData.displayName.value.trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    final email = AppData.user.value?.email ?? '';
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'G';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
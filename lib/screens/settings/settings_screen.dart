import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../constants/app_colors.dart';
import '../../models/settings_model.dart';
import '../../services/backup_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_title.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final BackupService _backupService = BackupService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();

  SettingsModel? _settings;
  List<Map<String, dynamic>> _backups = [];
  Map<String, dynamic> _maintenanceStats = {};
  
  bool _isLoading = true;
  bool _isSaving = false;
  File? _logoFile;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndBackups();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndBackups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _settingsService.getSettings();
      final backups = await _backupService.getBackupsList();
      final maint = await _backupService.getMaintenanceStats();

      setState(() {
        _settings = settings;
        _shopNameController.text = settings.shopName;
        _thresholdController.text = settings.lowStockLimit.toString();
        _backups = backups;
        _maintenanceStats = maint;
        
        if (settings.shopLogoPath.isNotEmpty) {
          _logoFile = File(settings.shopLogoPath);
        } else {
          _logoFile = null;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading configurations: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<String> _copyLogoToAppStorage(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) return sourcePath;
    final appDir = await getApplicationDocumentsDirectory();
    final logoDir = Directory(p.join(appDir.path, 'logo'));
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }
    final extension = p.extension(sourcePath);
    // Overwrite the logo file to prevent multiplying unused files
    final targetPath = p.join(logoDir.path, 'shop_logo$extension');
    final savedFile = await file.copy(targetPath);
    return savedFile.path;
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error selecting logo: $e");
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate() || _settings == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String logoPath = _settings!.shopLogoPath;
      if (_logoFile != null && _logoFile!.path != _settings!.shopLogoPath) {
        logoPath = await _copyLogoToAppStorage(_logoFile!.path);
      } else if (_logoFile == null) {
        logoPath = "";
      }

      final updatedSettings = _settings!.copyWith(
        shopName: _shopNameController.text.trim(),
        lowStockLimit: int.parse(_thresholdController.text),
        shopLogoPath: logoPath,
      );

      await _settingsService.updateSettings(updatedSettings);

      // Refresh Stats
      final maint = await _backupService.getMaintenanceStats();
      setState(() {
        _settings = updatedSettings;
        _maintenanceStats = maint;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Settings updated successfully"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint("Error saving settings: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update settings: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final name = await _backupService.backup();
      final backups = await _backupService.getBackupsList();
      final maint = await _backupService.getMaintenanceStats();

      setState(() {
        _backups = backups;
        _maintenanceStats = maint;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Backup created successfully: $name"),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint("Error creating backup: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Backup creation failed: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _confirmRestore(String folderName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Restore Backup?"),
        content: Text(
          "Are you sure you want to restore from '$folderName'? This will overwrite all current tiles, stock transactions, images, and showroom settings. The app will reload.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Restore"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await _backupService.restoreBackup(folderName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data restored successfully!"),
            backgroundColor: AppColors.success,
          ),
        );
        // Force pop back to dashboard to refresh connections and widgets
        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        debugPrint("Error restoring database: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Restore failed: $e"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _confirmDeleteBackup(String folderName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Delete Backup?"),
        content: Text(
          "Are you sure you want to permanently delete backup '$folderName'? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await _backupService.deleteBackup(folderName);
        final backups = await _backupService.getBackupsList();
        final maint = await _backupService.getMaintenanceStats();

        setState(() {
          _backups = backups;
          _maintenanceStats = maint;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Backup folder deleted successfully"),
            backgroundColor: AppColors.success,
          ),
        );
      } catch (e) {
        debugPrint("Error deleting backup folder: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to delete backup"),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Showroom Settings"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Shop Info Card
                        const SectionTitle(title: "Shop Branding"),
                        Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Logo Selection
                                Center(
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 48,
                                        backgroundColor: AppColors.background,
                                        backgroundImage: _logoFile != null &&
                                                _logoFile!.existsSync()
                                            ? FileImage(_logoFile!)
                                            : null,
                                        child: _logoFile == null
                                            ? const Icon(
                                                Icons.storefront_outlined,
                                                size: 40,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        onPressed: _pickLogo,
                                        icon: const Icon(
                                          Icons.photo_library_outlined,
                                          size: 16,
                                        ),
                                        label: const Text("Select Shop Logo"),
                                      ),
                                      if (_logoFile != null)
                                        TextButton(
                                          onPressed: () {
                                            setState(() => _logoFile = null);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                          ),
                                          child: const Text("Remove Logo"),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                CustomTextField(
                                  controller: _shopNameController,
                                  label: "Showroom Name",
                                  hint: "Enter shop name",
                                  prefixIcon: Icons.store,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return "Shop name is required";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Inventory Threshold Card
                        const SectionTitle(title: "Inventory Configuration"),
                        Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                CustomTextField(
                                  controller: _thresholdController,
                                  label: "Low Stock Threshold (Boxes)",
                                  hint: "5",
                                  keyboardType: TextInputType.number,
                                  prefixIcon: Icons.warning_amber_outlined,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return "Threshold is required";
                                    }
                                    final parsed = int.tryParse(val);
                                    if (parsed == null || parsed < 0) {
                                      return "Must be 0 or a positive integer";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Save Main Settings
                        PrimaryButton(
                          text: "Save Configuration",
                          onPressed: _saveSettings,
                          icon: Icons.check,
                        ),
                        const SizedBox(height: 24),

                        // 3. Database backups Card
                        const SectionTitle(title: "Database Backup & Restore"),
                        Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _createBackup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.backup_outlined),
                                  label: const Text(
                                    "Backup Now",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  "Available Backups",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_backups.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "No backups found on disk.",
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _backups.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 12),
                                    itemBuilder: (context, index) {
                                      final b = _backups[index];
                                      final name = b['folder_name'] as String;
                                      final dateStr =
                                          DateFormat('dd MMM yyyy, hh:mm a')
                                              .format(
                                        DateTime.parse(
                                          b['timestamp'] as String,
                                        ),
                                      );
                                      final dbSz = BackupService.formatBytes(
                                        b['db_size'] as int,
                                      );
                                      final imgSz = BackupService.formatBytes(
                                        b['images_size'] as int,
                                      );

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Products: ${b['product_count']} • Entries: ${b['transaction_count']}\nDB: $dbSz • Images: $imgSz",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            height: 1.4,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.restore_outlined,
                                                color: AppColors.primary,
                                              ),
                                              tooltip: "Restore this backup",
                                              onPressed: () =>
                                                  _confirmRestore(name),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.error,
                                              ),
                                              tooltip: "Delete this backup",
                                              onPressed: () =>
                                                  _confirmDeleteBackup(name),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Maintenance Stats Card
                        const SectionTitle(title: "Database Maintenance"),
                        Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildStatsRow(
                                  "Total Tile Products",
                                  "${_maintenanceStats['product_count'] ?? 0} Items",
                                ),
                                const Divider(height: 12),
                                _buildStatsRow(
                                  "Total Showroom Orders",
                                  "${_maintenanceStats['transaction_count'] ?? 0} Orders",
                                ),
                                const Divider(height: 12),
                                _buildStatsRow(
                                  "Database Size",
                                  BackupService.formatBytes(
                                    _maintenanceStats['db_size'] ?? 0,
                                  ),
                                ),
                                const Divider(height: 12),
                                _buildStatsRow(
                                  "Image Assets Size",
                                  BackupService.formatBytes(
                                    _maintenanceStats['images_size'] ?? 0,
                                  ),
                                ),
                                const Divider(height: 12),
                                _buildStatsRow(
                                  "Last Database Backup",
                                  _maintenanceStats['last_backup_time'] ??
                                      'Never',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 5. About Details Card
                        const SectionTitle(title: "About Application"),
                        Card(
                          elevation: 0.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildStatsRow(
                                  "Application Name",
                                  "Jain Tiles Gallery",
                                ),
                                const Divider(height: 12),
                                _buildStatsRow("App Version", "0.4.0"),
                                const Divider(height: 12),
                                _buildStatsRow("Database Version", "4"),
                                const Divider(height: 12),
                                _buildStatsRow("Running Environment", "Offline SQLite"),
                                const Divider(height: 12),
                                _buildStatsRow(
                                  "Developer",
                                  "Jain Showroom Tech Team",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

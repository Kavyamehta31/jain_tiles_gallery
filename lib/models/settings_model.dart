class SettingsModel {
  final int? id;
  final String shopName;
  final String shopLogoPath;
  final int lowStockLimit;
  final String lastBackupTime;

  const SettingsModel({
    this.id,
    required this.shopName,
    required this.shopLogoPath,
    required this.lowStockLimit,
    required this.lastBackupTime,
  });

  SettingsModel copyWith({
    int? id,
    String? shopName,
    String? shopLogoPath,
    int? lowStockLimit,
    String? lastBackupTime,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      shopName: shopName ?? this.shopName,
      shopLogoPath: shopLogoPath ?? this.shopLogoPath,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName,
      'shop_logo_path': shopLogoPath,
      'low_stock_limit': lowStockLimit,
      'last_backup_time': lastBackupTime,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'] as int?,
      shopName: map['shop_name'] as String,
      shopLogoPath: (map['shop_logo_path'] ?? '') as String,
      lowStockLimit: map['low_stock_limit'] as int,
      lastBackupTime: (map['last_backup_time'] ?? '') as String,
    );
  }
}

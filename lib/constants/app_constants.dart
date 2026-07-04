class AppConstants {
  AppConstants._();

  static const List<String> brands = [
    'Kajaria',
    'Valenza',
    'Johnson',
    'Somany',
    'Nitco',
    'Orientbell',
    'Simpolo',
    'Asian Granito',
    'Other',
  ];

  static const List<String> sizes = [
    '2 x 2 ft',
    '2 x 4 ft',
    '16 x 16 in',
    '20 x 20 in',
  ];

  static const Map<String, List<String>> varietiesBySize = {
    '2 x 2 ft': ['Matte', 'Glossy'],
    '2 x 4 ft': ['Matte', 'Glossy'],
    '16 x 16 in': ['Parking'],
    '20 x 20 in': ['Parking'],
  };

  static List<String> getVarieties(String? size) {
    if (size == null) return [];
    return varietiesBySize[size] ?? [];
  }
}

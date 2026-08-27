enum DeliveryZone {
  insideCity,
  outside120m,
  outside150m;

  String get labelKu => switch (this) {
        DeliveryZone.insideCity => 'ناو شار',
        DeliveryZone.outside120m => 'دەرەوەی شەقامی ١٢٠ مەتری',
        DeliveryZone.outside150m => 'دەرەوەی شەقامی ١٥٠ مەتری',
      };

  String get subtitleKu => switch (this) {
        DeliveryZone.insideCity => 'گەیاندن بۆ ناو شار',
        DeliveryZone.outside120m => 'دەرەوەی شەقامی ١٢٠ مەتری',
        DeliveryZone.outside150m => 'دەرەوەی شەقامی ١٥٠ مەتری',
      };

  /// IQD
  double get fee => switch (this) {
        DeliveryZone.insideCity => 3000,
        DeliveryZone.outside120m => 4000,
        DeliveryZone.outside150m => 5000,
      };

  static DeliveryZone? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final z in DeliveryZone.values) {
      if (z.name == raw) return z;
    }
    return null;
  }
}

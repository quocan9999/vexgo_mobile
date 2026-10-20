class CitySearchAdapter {
  CitySearchAdapter._();

  static const Map<String, String> _codeToBackendName = {
    'HCM': 'TP.HCM',
    'DL': 'Đà Lạt',
    'VT': 'Vũng Tàu',
    'NT': 'Nha Trang',
    'HN': 'Hà Nội',
    'DN': 'Đà Nẵng',
    'CT': 'Cần Thơ',
    'SP': 'Sa Pa',
    'HUE': 'Huế',
    'QN': 'Quy Nhơn',
    'PT': 'Phan Thiết',
  };

  /// Maps local city ID/code (e.g. HCM, DL) or name to verified backend search term.
  /// Backend database uses 'TP.HCM' for Ho Chi Minh City routes.
  static String resolveBackendSearchCity(String cityIdOrName) {
    final trimmed = cityIdOrName.trim();
    if (trimmed.isEmpty) return '';

    final upper = trimmed.toUpperCase();
    if (upper == 'HCM' ||
        upper == 'SG' ||
        upper == 'TP.HCM' ||
        upper == 'TP. HỒ CHÍ MINH' ||
        upper.contains('HỒ CHÍ MINH') ||
        upper.contains('SÀI GÒN')) {
      return 'TP.HCM';
    }

    if (_codeToBackendName.containsKey(upper)) {
      return _codeToBackendName[upper]!;
    }

    for (final entry in _codeToBackendName.entries) {
      if (entry.value.toLowerCase() == trimmed.toLowerCase()) {
        return entry.value;
      }
    }

    return trimmed;
  }
}

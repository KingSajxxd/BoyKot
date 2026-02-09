int toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value.replaceAll(',', '')) ?? 0;
  return 0;
}

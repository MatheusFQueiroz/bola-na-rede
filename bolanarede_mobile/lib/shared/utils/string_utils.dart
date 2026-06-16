String initials(String value, {int max = 2}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  final end = trimmed.length < max ? trimmed.length : max;
  return trimmed.substring(0, end).toUpperCase();
}

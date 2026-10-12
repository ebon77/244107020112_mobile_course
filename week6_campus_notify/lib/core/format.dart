String formatDate(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatRelativeDate(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(dateTime);
  if (difference.inDays > 0) {
    return '${difference.inDays} hari yang lalu';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} jam yang lalu';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} menit yang lalu';
  }
  return 'Baru saja';
}

String parseRouteFromPayload(Map<String, dynamic> data, {String fallback = '/'}) {
  final route = data['route']?.toString() ?? fallback;
  return route.startsWith('/') ? route : '/$route';
}

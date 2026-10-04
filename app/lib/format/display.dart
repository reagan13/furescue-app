String shortId(String? id) {
  if (id == null || id.isEmpty) {
    return '—';
  }
  final compact = id.replaceAll('-', '');
  if (compact.isEmpty) {
    return '—';
  }
  final take = compact.length < 4 ? compact.length : 4;
  return '#${compact.substring(0, take).toUpperCase()}';
}

DateTime? parseApiDate(String? input) {
  if (input == null || input.isEmpty) {
    return null;
  }
  final raw = input.contains('T') ? input : input.replaceFirst(' ', 'T');
  final stamped =
      raw.contains('Z') || raw.contains('+') || raw.contains('-', 10)
      ? raw
      : '${raw}Z';
  return DateTime.tryParse(stamped) ?? DateTime.tryParse(raw);
}

String timeAgo(String? input) {
  final then = parseApiDate(input);
  if (then == null) {
    return input == null || input.isEmpty ? '' : input;
  }
  final mins = DateTime.now().toUtc().difference(then.toUtc()).inMinutes;
  if (mins < 1) {
    return 'just now';
  }
  if (mins < 60) {
    return '${mins}m ago';
  }
  final hours = mins ~/ 60;
  if (hours < 24) {
    return '${hours}h ago';
  }
  final days = hours ~/ 24;
  if (days < 7) {
    return '${days}d ago';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = then.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String activityActionLabel(String action) {
  switch (action) {
    case 'opened':
      return 'Opened';
    case 'assigned':
      return 'Assigned';
    case 'accepted':
      return 'Accepted';
    case 'declined':
      return 'Declined';
    case 'proof_added':
      return 'Proof added';
    case 'resolved':
      return 'Resolved';
    case 'status_changed':
      return 'Status changed';
    default:
      return action.replaceAll('_', ' ');
  }
}

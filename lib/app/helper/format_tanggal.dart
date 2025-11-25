String formatTanggal(String iso) {
  try {
    final dt = DateTime.parse(iso);
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mn = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');

    return "${dt.year}-$mm-$dd ($hh:$mn:$ss)";
  } catch (e) {
    return "-";
  }
}

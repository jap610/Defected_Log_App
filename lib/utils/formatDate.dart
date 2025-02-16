import 'package:intl/intl.dart';


String formatDate(DateTime? dt) {
    if (dt == null) return '--';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

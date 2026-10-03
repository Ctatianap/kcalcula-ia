import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hora actual inyectable: los tests fijan la fecha sin depender del día en
/// que corren.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// SPEC-011 R1: saludo según la hora local.
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Buenos días';
  if (h >= 12 && h < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

const _weekdays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Iniciales de la semana, de lunes a domingo (como en el diseño).
const weekdayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// "sábado 3 de octubre".
String longDateEs(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} de ${_months[d.month - 1]}';

/// "8:15".
String timeEs(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

const mealTypeLabels = {
  'desayuno': 'Desayuno',
  'almuerzo': 'Almuerzo',
  'cena': 'Cena',
  'snack': 'Snack',
};

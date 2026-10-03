/// Fechas y etiquetas en es-CO compartidas por varias pantallas (sin
/// depender de `intl`). Vive en `ui/` porque las features no se importan
/// entre sí.
library;

const weekdaysEs = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const monthsEs = [
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
    '${weekdaysEs[d.weekday - 1]} ${d.day} de ${monthsEs[d.month - 1]}';

/// "8:15".
String timeEs(DateTime d) => '${d.hour}:${d.minute.toString().padLeft(2, '0')}';

const mealTypeLabels = {
  'desayuno': 'Desayuno',
  'almuerzo': 'Almuerzo',
  'cena': 'Cena',
  'snack': 'Snack',
};

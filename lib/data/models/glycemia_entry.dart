import 'package:glumate_mobile/core/constants/app_screen.dart';

class GlycemiaEntry {
  const GlycemiaEntry({
    required this.value,
    required this.date,
    required this.moment,
    required this.status,
    this.note = '',
  });
  final int value;
  final String date;
  final String moment;
  final GlycemiaStatus status;
  final String note;
}

const List<Map<String, Object>> kGlycemiaTrend = [
  {'day': 'Lun', 'value': 108},
  {'day': 'Mar', 'value': 132},
  {'day': 'Mer', 'value': 95},
  {'day': 'Jeu', 'value': 148},
  {'day': 'Ven', 'value': 112},
  {'day': 'Sam', 'value': 89},
  {'day': 'Dim', 'value': 124},
];

const List<GlycemiaEntry> kGlycemiaHistory = [
  GlycemiaEntry(
    value: 124,
    date: "Aujourd'hui 08:15",
    moment: 'A jeun',
    status: GlycemiaStatus.normal,
  ),
  GlycemiaEntry(
    value: 189,
    date: 'Hier 14:30',
    moment: 'Apres repas',
    status: GlycemiaStatus.hyper,
    note: 'Apres dejeuner riche',
  ),
  GlycemiaEntry(
    value: 68,
    date: 'Hier 07:45',
    moment: 'A jeun',
    status: GlycemiaStatus.hypo,
    note: 'Sensation de faiblesse',
  ),
  GlycemiaEntry(
    value: 142,
    date: '15/08 19:00',
    moment: 'Avant repas',
    status: GlycemiaStatus.normal,
  ),
  GlycemiaEntry(
    value: 215,
    date: '14/08 13:15',
    moment: 'Apres repas',
    status: GlycemiaStatus.hyper,
  ),
  GlycemiaEntry(
    value: 98,
    date: '13/08 08:00',
    moment: 'A jeun',
    status: GlycemiaStatus.normal,
  ),
];

GlycemiaStatus getGlycemiaStatus(int value) {
  if (value < 70) return GlycemiaStatus.hypo;
  if (value > 180) return GlycemiaStatus.hyper;
  return GlycemiaStatus.normal;
}

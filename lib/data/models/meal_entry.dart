class MealEntry {
  const MealEntry({
    required this.type,
    required this.description,
    required this.carbs,
    required this.date,
    required this.kcal,
  });
  final String type;
  final String description;
  final int carbs;
  final String date;
  final int kcal;
}

const List<MealEntry> kMealHistory = [
  MealEntry(
    type: 'Dejeuner',
    description: 'Poulet grille, riz, salade',
    carbs: 65,
    date: "Aujourd'hui 12:30",
    kcal: 480,
  ),
  MealEntry(
    type: 'Petit-dejeuner',
    description: 'Yaourt, granola, banane',
    carbs: 48,
    date: "Aujourd'hui 07:30",
    kcal: 320,
  ),
  MealEntry(
    type: 'Collation',
    description: 'Pomme, amandes',
    carbs: 22,
    date: 'Hier 16:00',
    kcal: 190,
  ),
  MealEntry(
    type: 'Diner',
    description: 'Saumon, legumes vapeur, quinoa',
    carbs: 38,
    date: 'Hier 19:30',
    kcal: 520,
  ),
  MealEntry(
    type: 'Dejeuner',
    description: 'Sandwich complet, soupe',
    carbs: 72,
    date: '15/08 12:15',
    kcal: 410,
  ),
];

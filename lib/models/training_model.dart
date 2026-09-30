class TrainingModel {
  final int id;
  final String title;
  final String category;
  final String code;

  const TrainingModel({
    required this.id,
    required this.title,
    required this.category,
    required this.code,
  });

  static const List<TrainingModel> defaultTrainings = [
    TrainingModel(
      id: 1,
      title: 'Mobile Programming (Flutter)',
      category: 'Teknologi Informasi',
      code: 'FLUTTER-B1',
    ),
    TrainingModel(
      id: 2,
      title: 'Web Application Development',
      category: 'Teknologi Informasi',
      code: 'WEB-B1',
    ),
    TrainingModel(
      id: 3,
      title: 'Desain Grafis & UI/UX',
      category: 'Multimedia & Desain',
      code: 'UIUX-B1',
    ),
    TrainingModel(
      id: 4,
      title: 'Teknik Komputer & Jaringan',
      category: 'Teknik',
      code: 'TKJ-B1',
    ),
    TrainingModel(
      id: 5,
      title: 'Data Science & Analytics',
      category: 'Teknologi Informasi',
      code: 'DATA-B1',
    ),
  ];

  static const List<String> defaultBatches = [
    'Batch 1 - 2026',
    'Batch 2 - 2026',
    'Batch 3 - 2026',
    'Batch 4 - 2026',
  ];
}

class DiagnosisRecord {
  final String date;
  final String plantName;
  final String diseaseName;
  final int confidence;
  final String imageUrl;
  final String overview;
  final String cause;
  final String signs;
  final List<String> solutions;

  DiagnosisRecord({
    required this.date,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    required this.imageUrl,
    required this.overview,
    required this.cause,
    required this.signs,
    required this.solutions,
  });
}

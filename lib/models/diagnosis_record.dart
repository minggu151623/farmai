class DiagnosisRecord {
  final int? id;
  final String date;
  final String plantName;
  final String diseaseName;
  final int confidence;
  final String? imagePath;
  final String imageUrl;
  final String overview;
  final String cause;
  final String signs;
  final List<String> solutions;

  DiagnosisRecord({
    this.id,
    required this.date,
    required this.plantName,
    required this.diseaseName,
    required this.confidence,
    this.imagePath,
    this.imageUrl = '',
    required this.overview,
    required this.cause,
    required this.signs,
    required this.solutions,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'confidence': confidence,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'overview': overview,
      'cause': cause,
      'signs': signs,
      'solutions': solutions.join('|||'),
    };
  }

  factory DiagnosisRecord.fromMap(Map<String, dynamic> map) {
    return DiagnosisRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      plantName: map['plantName'] as String,
      diseaseName: map['diseaseName'] as String,
      confidence: map['confidence'] as int,
      imagePath: map['imagePath'] as String?,
      imageUrl: (map['imageUrl'] as String?) ?? '',
      overview: map['overview'] as String,
      cause: map['cause'] as String,
      signs: map['signs'] as String,
      solutions: (map['solutions'] as String).split('|||'),
    );
  }
}

class DefectItem {
  String defectType;
  String documentNumber;
  DateTime timestamp;
  String createdBy; 

  DefectItem({
    required this.defectType,
    required this.documentNumber,
    required this.timestamp,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'defect_type': defectType,
      'document_number': documentNumber,
      'timestamp': timestamp.toIso8601String(),
      'created_by': createdBy, 
    };
  }
}

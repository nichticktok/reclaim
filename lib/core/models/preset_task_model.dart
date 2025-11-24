import '../constants/proof_types.dart';

class PresetTaskModel {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., "Health", "Productivity", "Mindfulness", etc.
  final bool requiresProof;
  final String? proofType; // Type of proof required: text, photo, video, location, file, any
  final String attribute; // "Wisdom", "Confidence", "Strength", "Discipline", "Focus"

  PresetTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.requiresProof = false,
    String? proofType,
    String? attribute,
  }) : attribute = attribute ?? 'Focus', // Default to Focus if not specified
       proofType = ProofTypes.isValid(proofType) ? proofType : (requiresProof ? ProofTypes.text : null);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'requiresProof': requiresProof,
      if (proofType != null) 'proofType': proofType,
      'attribute': attribute,
    };
  }

  factory PresetTaskModel.fromMap(Map<String, dynamic> map) {
    return PresetTaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      requiresProof: map['requiresProof'] ?? false,
      proofType: map['proofType'] as String?,
      attribute: map['attribute'] ?? 'Focus',
    );
  }
  
  /// Create a copy with modified fields
  PresetTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? requiresProof,
    String? proofType,
    String? attribute,
  }) {
    return PresetTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requiresProof: requiresProof ?? this.requiresProof,
      proofType: proofType ?? this.proofType,
      attribute: attribute ?? this.attribute,
    );
  }
}


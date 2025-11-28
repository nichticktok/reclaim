/// AI-suggested proof type for a project task
class ProofSuggestion {
  final String primaryProofType;
  final List<String> alternativeProofTypes;
  final String proofMechanism; // study_session, work_session, practice, research, etc.
  final String reasoning;

  ProofSuggestion({
    required this.primaryProofType,
    required this.alternativeProofTypes,
    required this.proofMechanism,
    required this.reasoning,
  });

  Map<String, dynamic> toMap() {
    return {
      'primaryProofType': primaryProofType,
      'alternativeProofTypes': alternativeProofTypes,
      'proofMechanism': proofMechanism,
      'reasoning': reasoning,
    };
  }

  factory ProofSuggestion.fromMap(Map<String, dynamic> map) {
    return ProofSuggestion(
      primaryProofType: map['primaryProofType'] ?? 'timedSession',
      alternativeProofTypes: map['alternativeProofTypes'] != null
          ? List<String>.from(map['alternativeProofTypes'])
          : [],
      proofMechanism: map['proofMechanism'] ?? 'work_session',
      reasoning: map['reasoning'] ?? '',
    );
  }
}


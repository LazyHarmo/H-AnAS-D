class Indicator {
  final String code;
  final String title;
  final String severity;
  final String evidence;
  final String explanation;

  Indicator({
    required this.code,
    required this.title,
    required this.severity,
    required this.evidence,
    required this.explanation,
  });

  factory Indicator.fromJson(Map<String, dynamic> json) => Indicator(
        code: json['code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        severity: json['severity'] as String? ?? '',
        evidence: json['evidence'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
      );
}

class AnalysisResult {
  final String analysisId;
  final int riskScore;
  final String riskLevel;
  final String summary;
  final List<String> scamCategories;
  final List<Indicator> indicators;
  final List<String> recommendedActions;
  final double confidence;
  final bool needsHumanReview;
  final int processingTimeMs;

  AnalysisResult({
    required this.analysisId,
    required this.riskScore,
    required this.riskLevel,
    required this.summary,
    required this.scamCategories,
    required this.indicators,
    required this.recommendedActions,
    required this.confidence,
    required this.needsHumanReview,
    required this.processingTimeMs,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        analysisId: json['analysis_id'] as String? ?? '',
        riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'low',
        summary: json['summary'] as String? ?? '',
        scamCategories: (json['scam_categories'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        indicators: (json['indicators'] as List?)
                ?.map((e) => Indicator.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        recommendedActions: (json['recommended_actions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        needsHumanReview: json['needs_human_review'] as bool? ?? false,
        processingTimeMs: (json['processing_time_ms'] as num?)?.toInt() ?? 0,
      );
}

class ApiException implements Exception {
  final int httpStatus;
  final String? code;
  final String message;

  ApiException({required this.httpStatus, this.code, required this.message});

  @override
  String toString() => 'ApiException($httpStatus, $code): $message';
}

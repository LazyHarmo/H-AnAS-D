import 'package:flutter/material.dart';

import 'models.dart';

Color riskColor(String riskLevel) {
  switch (riskLevel) {
    case 'low':
      return Colors.green;
    case 'medium':
      return Colors.amber.shade800;
    case 'high':
      return Colors.deepOrange;
    case 'critical':
      return Colors.red.shade900;
    default:
      return Colors.grey;
  }
}

String errorLabelFor(int httpStatus) {
  switch (httpStatus) {
    case 400:
      return 'ข้อมูลที่ส่งไม่ถูกต้อง (Invalid request)';
    case 413:
      return 'ไฟล์หรือข้อมูลมีขนาดใหญ่เกินกำหนด (Too large)';
    case 422:
      return 'ไม่สามารถประมวลผลเนื้อหานี้ได้ (Unprocessable content)';
    case 500:
      return 'เกิดข้อผิดพลาดภายในระบบ (Server error)';
    case 503:
      return 'ระบบวิเคราะห์ไม่พร้อมใช้งานชั่วคราว (Service unavailable)';
    default:
      return 'ไม่สามารถวิเคราะห์ได้ (Request failed)';
  }
}

class ResultCard extends StatelessWidget {
  final AnalysisResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = riskColor(result.riskLevel);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '${result.riskLevel.toUpperCase()} · ${result.riskScore}/100',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                if (result.needsHumanReview)
                  const Tooltip(
                    message: 'ผลลัพธ์นี้ควรได้รับการตรวจทานเพิ่มเติม',
                    child: Icon(Icons.flag, color: Colors.orange),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (result.scamCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.scamCategories
                    .map((c) => Chip(label: Text(c)))
                    .toList(),
              ),
            ],
            if (result.indicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Indicators', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...result.indicators.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            i.severity,
                            style: TextStyle(color: riskColor(_severityToLevel(i.severity))),
                          ),
                        ],
                      ),
                      if (i.evidence.isNotEmpty)
                        Text('หลักฐาน: ${i.evidence}',
                            style: Theme.of(context).textTheme.bodySmall),
                      if (i.explanation.isNotEmpty)
                        Text(i.explanation, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
            if (result.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Recommended actions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...result.recommendedActions.map(
                (a) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(a)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'confidence: ${(result.confidence * 100).toStringAsFixed(0)}% · '
              'processing: ${result.processingTimeMs} ms · '
              'id: ${result.analysisId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _severityToLevel(String severity) {
    switch (severity) {
      case 'low':
        return 'low';
      case 'medium':
        return 'medium';
      case 'high':
        return 'high';
      case 'critical':
        return 'critical';
      default:
        return 'medium';
    }
  }
}

class ErrorCard extends StatelessWidget {
  final ApiException error;

  const ErrorCard({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorLabelFor(error.httpStatus),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(error.message),
            if (error.code != null) ...[
              const SizedBox(height: 4),
              Text('code: ${error.code}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }
}

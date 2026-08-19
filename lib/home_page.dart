import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'config.dart';
import 'models.dart';
import 'result_view.dart';

const _maxMediaBytes = 5 * 1024 * 1024;
const _maxTextChars = 10000;

enum _InputTab { text, image, audio }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _textController = TextEditingController();

  _InputTab _tab = _InputTab.text;
  bool _loading = false;
  AnalysisResult? _result;
  ApiException? _error;

  String? _mediaName;
  String? _mediaMime;
  List<int>? _mediaBytes;

  String _newRequestId(String prefix) {
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16);
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-$rand';
  }

  String? _mimeForImage(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  String? _mimeForAudio(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return null;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final mime = _mimeForImage(picked.name);
    if (mime == null) {
      _showSnack('ชนิดไฟล์ภาพไม่รองรับ ใช้ PNG, JPEG หรือ WebP เท่านั้น');
      return;
    }

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxMediaBytes) {
      _showSnack('ไฟล์ภาพมีขนาดเกิน 5 MiB');
      return;
    }

    setState(() {
      _mediaName = picked.name;
      _mediaMime = mime;
      _mediaBytes = bytes;
      _result = null;
      _error = null;
    });
  }

  Future<void> _pickAudio() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final mime = _mimeForAudio(file.name);
    if (mime == null) {
      _showSnack('ชนิดไฟล์เสียงไม่รองรับ ใช้ mp3 หรือ wav เท่านั้น');
      return;
    }

    final bytes = file.bytes;
    if (bytes == null) {
      _showSnack('ไม่สามารถอ่านไฟล์เสียงได้');
      return;
    }
    if (bytes.length > _maxMediaBytes) {
      _showSnack('ไฟล์เสียงมีขนาดเกิน 5 MiB');
      return;
    }

    setState(() {
      _mediaName = file.name;
      _mediaMime = mime;
      _mediaBytes = bytes;
      _result = null;
      _error = null;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _analyze() async {
    if (!AppConfig.isConfigured) {
      _showSnack('API_BASE_URL ยังไม่ได้ตั้งค่า ดูวิธีตั้งค่าใน README');
      return;
    }
    final baseUrl = AppConfig.apiBaseUrl;
    final path = AppConfig.apiPath;

    if (_tab == _InputTab.text && _textController.text.trim().isEmpty) {
      _showSnack('กรุณากรอกข้อความ');
      return;
    }
    if ((_tab == _InputTab.image || _tab == _InputTab.audio) && _mediaBytes == null) {
      _showSnack('กรุณาเลือกไฟล์ก่อน');
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    try {
      AnalysisResult result;
      if (_tab == _InputTab.text) {
        final content = _textController.text.trim();
        if (content.length > _maxTextChars) {
          throw ApiException(
            httpStatus: 400,
            code: 'VALIDATION_ERROR',
            message: 'ข้อความยาวเกิน $_maxTextChars ตัวอักษร',
          );
        }
        result = await ApiClient.analyzeText(
          baseUrl: baseUrl,
          path: path,
          content: content,
          requestId: _newRequestId('demo-text'),
        );
      } else {
        final inputType = _tab == _InputTab.image ? 'image' : 'audio';
        final base64Data = base64Encode(_mediaBytes!);
        result = await ApiClient.analyzeMedia(
          baseUrl: baseUrl,
          path: path,
          inputType: inputType,
          mimeType: _mediaMime!,
          base64Data: base64Data,
          requestId: _newRequestId('demo-$inputType'),
        );
      }
      setState(() => _result = result);
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anti-Scammer AI — Demo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!AppConfig.isConfigured) _buildConfigWarning(),
            if (!AppConfig.isConfigured) const SizedBox(height: 16),
            _buildTabSelector(),
            const SizedBox(height: 12),
            _buildTabContent(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_loading ? 'กำลังวิเคราะห์...' : 'Analyze'),
            ),
            const SizedBox(height: 20),
            if (_result != null) ResultCard(result: _result!),
            if (_error != null) ErrorCard(error: _error!),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigWarning() {
    return Card(
      color: Colors.amber.shade50,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'API_BASE_URL is not set. Pass it via --dart-define at build/run '
                'time (see README.md) — this demo does not hard-code a backend host.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return SegmentedButton<_InputTab>(
      segments: const [
        ButtonSegment(value: _InputTab.text, label: Text('Text'), icon: Icon(Icons.text_fields)),
        ButtonSegment(value: _InputTab.image, label: Text('Image'), icon: Icon(Icons.image)),
        ButtonSegment(value: _InputTab.audio, label: Text('Audio'), icon: Icon(Icons.audiotrack)),
      ],
      selected: {_tab},
      onSelectionChanged: (selection) {
        setState(() {
          _tab = selection.first;
          _result = null;
          _error = null;
        });
      },
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case _InputTab.text:
        return TextField(
          controller: _textController,
          maxLines: 6,
          maxLength: _maxTextChars,
          decoration: const InputDecoration(
            labelText: 'ข้อความที่ต้องการตรวจสอบ',
            hintText: 'วางข้อความ SMS, แชท หรืออีเมลที่น่าสงสัยที่นี่',
            border: OutlineInputBorder(),
          ),
        );
      case _InputTab.image:
        return _buildMediaPicker(
          onPick: _pickImage,
          icon: Icons.add_photo_alternate,
          label: 'Pick screenshot',
        );
      case _InputTab.audio:
        return _buildMediaPicker(
          onPick: _pickAudio,
          icon: Icons.upload_file,
          label: 'Pick audio file (mp3/wav)',
        );
    }
  }

  Widget _buildMediaPicker({
    required VoidCallback onPick,
    required IconData icon,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(onPressed: onPick, icon: Icon(icon), label: Text(label)),
        if (_mediaName != null) ...[
          const SizedBox(height: 8),
          Text('$_mediaName (${((_mediaBytes?.length ?? 0) / 1024).toStringAsFixed(1)} KB, $_mediaMime)'),
        ],
      ],
    );
  }
}

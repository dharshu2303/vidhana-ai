import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/stt_service.dart';
import '../services/ocr_service.dart';
import '../services/translation_service.dart';
import 'fir_form_screen.dart';

const _descMonthMap = {
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
};

String? _extractDateFromText(String text) {
  final patterns = [
    RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\b'),
    RegExp(
        r'\b(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{4})\b',
        caseSensitive: false),
    RegExp(
        r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})[,\s]+(\d{4})\b',
        caseSensitive: false),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(text);
    if (m != null) return m.group(0);
  }
  return null;
}

DateTime? _parseDateFromText(String s) {
  try {
    var m = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})').firstMatch(s);
    if (m != null)
      return DateTime(int.parse(m.group(3)!), int.parse(m.group(2)!),
          int.parse(m.group(1)!));
    m = RegExp(r'(\d{1,2})\s+(\w+)\s+(\d{4})', caseSensitive: false)
        .firstMatch(s);
    if (m != null) {
      final month = _descMonthMap[m.group(2)!.toLowerCase()];
      if (month != null)
        return DateTime(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
    }
    m = RegExp(r'(\w+)\s+(\d{1,2})[,\s]+(\d{4})', caseSensitive: false)
        .firstMatch(s);
    if (m != null) {
      final month = _descMonthMap[m.group(1)!.toLowerCase()];
      if (month != null)
        return DateTime(int.parse(m.group(3)!), month, int.parse(m.group(2)!));
    }
  } catch (_) {}
  return null;
}

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _controller = TextEditingController();
  final _stt = SttService();
  final _ocr = OcrService();
  bool _loading = false;
  bool _isListening = false;
  bool _ocrLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _stt.dispose();
    super.dispose();
  }

  Future<void> _predict() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await ApiService.predict(text);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggleListening() async {
    final tr = Provider.of<TranslationService>(context, listen: false);
    if (_isListening) {
      await _stt.stopListening();
      setState(() => _isListening = false);
      return;
    }

    final ok = await _stt.initialize();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    await _stt.startListening(
      localeId: tr.sttLocale,
      onResult: (text, isFinal) {
        setState(() {
          _controller.text = text;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
      onDone: () {
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _pickImage(bool fromCamera) async {
    Navigator.pop(context); // close bottom sheet

    final xfile =
        fromCamera ? await _ocr.pickFromCamera() : await _ocr.pickFromGallery();

    if (xfile == null) return;

    setState(() => _ocrLoading = true);
    try {
      final result = await _ocr.extractText(xfile);
      final text = result['text'] as String? ?? '';
      if (text.isNotEmpty) {
        setState(() {
          _controller.text = '${_controller.text}\n$text'.trim();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('OCR Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _ocrLoading = false);
    }
  }

  void _showImagePicker() {
    final tr = Provider.of<TranslationService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(tr.t('upload_evidence'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ImageOption(
                    icon: Icons.camera_alt_rounded,
                    label: tr.t('take_photo'),
                    onTap: () => _pickImage(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ImageOption(
                    icon: Icons.photo_library_rounded,
                    label: tr.t('from_gallery'),
                    onTap: () => _pickImage(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Provider.of<TranslationService>(context);
    final sections =
        (_result?['predicted_sections'] as List?)?.cast<String>() ?? [];
    final alerts = (_result?['alerts'] as Map?)?.cast<String, dynamic>() ?? {};
    final mlConf =
        (_result?['ml_confidence'] as Map?)?.cast<String, dynamic>() ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.accent, AppColors.accent.withOpacity(0.7)],
                ),
              ),
              child:
                  const Icon(Icons.balance, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(tr.t('app_name')),
          ],
        ),
        actions: [
          // Language toggle
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate, color: AppColors.accent),
            color: AppColors.surfaceCard,
            onSelected: (v) => tr.setLocale(v),
            itemBuilder: (_) => TranslationService.supportedLocales.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          if (e.key == tr.locale)
                            const Icon(Icons.check,
                                size: 16, color: AppColors.accent)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(e.value,
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input area
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Container(
                decoration: AppTheme.glassCard(opacity: 0.06),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: 5,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: tr.t('describe_incident'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                    // Action buttons row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          // Voice button
                          _ActionChip(
                            icon: _isListening ? Icons.mic : Icons.mic_none,
                            label: _isListening
                                ? tr.t('listening')
                                : tr.t('voice_input'),
                            color: _isListening
                                ? AppColors.error
                                : AppColors.accent,
                            onTap: _toggleListening,
                          ),
                          const SizedBox(width: 8),
                          // Image upload
                          _ActionChip(
                            icon: Icons.document_scanner_rounded,
                            label: _ocrLoading
                                ? tr.t('extracting_text')
                                : tr.t('upload_evidence'),
                            color: AppColors.info,
                            onTap: _ocrLoading ? null : _showImagePicker,
                          ),
                        ],
                      ),
                    ),
                    if (_ocrLoading)
                      const LinearProgressIndicator(
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Predict button
            ElevatedButton.icon(
              onPressed: _loading ? null : _predict,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_loading ? tr.t('analyzing') : tr.t('predict_btn')),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              FadeIn(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13)),
                ),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (alerts.isNotEmpty)
                        FadeInUp(
                          child: _AlertsCard(alerts: alerts, tr: tr),
                        ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: _SectionsCard(
                            sections: sections, mlConf: mlConf, tr: tr),
                      ),
                      const SizedBox(height: 12),
                      if (sections.isNotEmpty)
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final descDate =
                                  _extractDateFromText(_controller.text.trim());
                              if (descDate != null) {
                                final parsed = _parseDateFromText(descDate);
                                final today = DateTime.now();
                                final todayOnly = DateTime(
                                    today.year, today.month, today.day);
                                if (parsed != null &&
                                    parsed.isAfter(todayOnly)) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: AppColors.surfaceCard,
                                      title: Row(children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            color: AppColors.error),
                                        const SizedBox(width: 8),
                                        Text(tr.t('future_date_title'),
                                            style: const TextStyle(
                                                color: AppColors.error)),
                                      ]),
                                      content: Text(
                                        'The date "$descDate" is a future date. An FIR can only be filed for past incidents.',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(tr.t('ok'),
                                              style: const TextStyle(
                                                  color: AppColors.accent)),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FirFormScreen(
                                    description: _controller.text.trim(),
                                    sections: sections,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.description_rounded),
                            label: Text(tr.t('generate_fir')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Action Chip Widget ──────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Image Option Widget ────────────────────────────────────────────
class _ImageOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Alerts Card ────────────────────────────────────────────────────
class _AlertsCard extends StatelessWidget {
  final Map<String, dynamic> alerts;
  final TranslationService tr;
  const _AlertsCard({required this.alerts, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Text(tr.t('missing_fields'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.warning)),
          ]),
          const SizedBox(height: 8),
          ...alerts.values.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $msg',
                    style: TextStyle(
                        color: AppColors.warning.withOpacity(0.9),
                        fontSize: 12)),
              )),
        ],
      ),
    );
  }
}

// ─── Sections Card ──────────────────────────────────────────────────
class _SectionsCard extends StatelessWidget {
  final List<String> sections;
  final Map<String, dynamic> mlConf;
  final TranslationService tr;
  const _SectionsCard(
      {required this.sections, required this.mlConf, required this.tr});

  void _showInfo(BuildContext ctx, String section) async {
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        content: const SizedBox(
          height: 60,
          child:
              Center(child: CircularProgressIndicator(color: AppColors.accent)),
        ),
      ),
    );
    try {
      final info = await ApiService.sectionInfo(section);
      if (!ctx.mounted) return;
      Navigator.pop(ctx);
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: Text(section.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((info['offense'] as String).isNotEmpty) ...[
                  Text('${tr.t('offense')}:',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(info['offense'] as String,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                ],
                Text('${tr.t('description')}:',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(info['description'] as String,
                    style: const TextStyle(color: AppColors.textSecondary)),
                if ((info['punishment'] as String).isNotEmpty &&
                    info['punishment'] != 'nan') ...[
                  const SizedBox(height: 12),
                  Text('${tr.t('punishment')}:',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(info['punishment'] as String,
                      style: const TextStyle(color: AppColors.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.t('close'),
                  style: const TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );
    } catch (_) {
      if (ctx.mounted) Navigator.pop(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassCard(opacity: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.gavel, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(tr.t('predicted_sections'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 4),
          Text(tr.t('tap_section_info'),
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          if (sections.isEmpty)
            Text(tr.t('no_sections'),
                style: const TextStyle(color: AppColors.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sections.map((s) {
                final conf = mlConf[s];
                return ActionChip(
                  label: Text(
                    conf != null
                        ? '${s.toUpperCase()} ($conf%)'
                        : s.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: AppColors.accent,
                  onPressed: () => _showInfo(context, s),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

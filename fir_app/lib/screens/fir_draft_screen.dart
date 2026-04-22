import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/theme.dart';
import '../services/translation_service.dart';
import '../services/pdf_download_service.dart' as download_service;

/// Stores FIR draft data for history
class FirHistoryItem {
  final String draft;
  final List<String> sections;
  final String complainantName;
  final DateTime createdAt;
  final String firNo;

  FirHistoryItem({
    required this.draft,
    required this.sections,
    required this.complainantName,
    required this.createdAt,
    required this.firNo,
  });
}

/// Global in-memory history store
class FirHistoryStore {
  static final FirHistoryStore _instance = FirHistoryStore._();
  factory FirHistoryStore() => _instance;
  FirHistoryStore._();

  final List<FirHistoryItem> items = [];

  void add(FirHistoryItem item) {
    items.insert(0, item);
  }
}

class FirDraftScreen extends StatefulWidget {
  final String draft;
  final String? originalDescription;
  final List<String> sections;
  final String complainantName;
  final bool fromHistory;

  const FirDraftScreen({
    super.key,
    required this.draft,
    this.originalDescription,
    this.sections = const [],
    this.complainantName = '',
    this.fromHistory = false,
  });

  @override
  State<FirDraftScreen> createState() => _FirDraftScreenState();
}

class _FirDraftScreenState extends State<FirDraftScreen> {
  @override
  void initState() {
    super.initState();
    // Only save to history when creating a new draft, not when viewing from history
    if (!widget.fromHistory) {
      _saveToHistory();
    }
  }

  void _saveToHistory() {
    final firNoMatch = RegExp(r'FIR No\.\s*:\s*(\S+)').firstMatch(widget.draft);
    FirHistoryStore().add(FirHistoryItem(
      draft: widget.draft,
      sections: widget.sections,
      complainantName: widget.complainantName.isNotEmpty
          ? widget.complainantName
          : 'Unknown',
      createdAt: DateTime.now(),
      firNo: firNoMatch?.group(1) ??
          'FIR-${DateTime.now().millisecondsSinceEpoch}',
    ));
  }

  Future<void> _exportPdf(BuildContext context) async {
    final tr = Provider.of<TranslationService>(context, listen: false);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'FIRST INFORMATION REPORT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  '(Under Section 154 Cr.P.C.)',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (pw.Context ctx) {
            // Split the draft by newlines to allow the PDF library to
            // split content across multiple pages correctly.
            final lines = widget.draft.split('\n');
            return lines.map((line) {
              return pw.Text(
                line.isEmpty ? ' ' : line,
                style: const pw.TextStyle(fontSize: 10, height: 1.2),
              );
            }).toList();
          },
          footer: (pw.Context ctx) => pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ),
      );

      final fileName = 'FIR_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (kIsWeb) {
        // Direct download for web
        final bytes = await pdf.save();
        download_service.savePdf(bytes, fileName);
      } else {
        // Print/Share layout for mobile/desktop
        await Printing.layoutPdf(
          onLayout: (format) => pdf.save(),
          name: fileName,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.t('pdf_generated'))),
        );
      }
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = Provider.of<TranslationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.t('fir_draft')),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: tr.t('copy_clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.draft));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr.t('draft_copied'))),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded,
                color: AppColors.error),
            tooltip: tr.t('download_pdf'),
            onPressed: () => _exportPdf(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FadeInUp(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassCard(opacity: 0.06),
            child: SelectableText(
              widget.draft,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.primary,
        icon: const Icon(Icons.home_rounded),
        label: Text(tr.t('new_prediction')),
      ),
    );
  }
}

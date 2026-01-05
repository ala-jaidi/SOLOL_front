import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  /// Builds a PDF report for a foot scan session.
  ///
  /// [patientName] optional; [rightLengthCm], [leftLengthCm], etc. are metric strings like '24.5 cm'.
  static Future<Uint8List> buildReport({
    String? patientName,
    required String rightLengthCm,
    required String leftLengthCm,
    required String rightWidthCm,
    required String leftWidthCm,
    String precision = '97%',
    String? analysis1,
    String? analysis2,
    String? analysis3,
    String? topImageAsset,
    String? sideImageAsset,
  }) async {
    final doc = pw.Document();

    pw.ImageProvider? topImage;
    pw.ImageProvider? sideImage;
    try {
      if (topImageAsset != null) {
        final bytes = await rootBundle.load(topImageAsset);
        topImage = pw.MemoryImage(bytes.buffer.asUint8List());
      }
      if (sideImageAsset != null) {
        final bytes = await rootBundle.load(sideImageAsset);
        sideImage = pw.MemoryImage(bytes.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('PdfService image load error: $e');
    }

    const primaryInt = 0xFF0052CC;
    const tertiaryInt = 0xFF7C4DFF;
    final primary = PdfColor.fromInt(primaryInt);
    final tertiary = PdfColor.fromInt(tertiaryInt);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Rapport de Mesure du Pied', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primary)),
                    if (patientName != null)
                      pw.Text('Patient: $patientName', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('Précision: $precision', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0x147C4DFF), // ~8% alpha
                    borderRadius: pw.BorderRadius.circular(999),
                    border: pw.Border.all(color: PdfColor.fromInt(0x4D7C4DFF), width: 1), // ~30% alpha
                  ),
                  child: pw.Text('LiDAR Mesure', style: pw.TextStyle(color: tertiary, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Metrics Grid
          pw.Text('Mesures', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.GridView(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            children: [
              _metricTile('Pied Droit', 'Longueur', rightLengthCm, primary),
              _metricTile('Pied Gauche', 'Longueur', leftLengthCm, tertiary),
              _metricTile('Largeur D', 'Avant-pied', rightWidthCm, PdfColor.fromInt(0xFF00BFA5)),
              _metricTile('Largeur G', 'Avant-pied', leftWidthCm, PdfColor.fromInt(0xFF00BFA5)),
            ],
          ),
          pw.SizedBox(height: 16),

          // Images
          if (topImage != null || sideImage != null) ...[
            pw.Text('Visualisation 3D', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                if (topImage != null)
                  pw.Expanded(
                    child: pw.Column(children: [
                      pw.Container(
                        height: 140,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 12,
                          verticalRadius: 12,
                          child: pw.Image(topImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Vue de dessus', style: const pw.TextStyle(fontSize: 10)),
                    ]),
                  ),
                if (sideImage != null) pw.SizedBox(width: 12),
                if (sideImage != null)
                  pw.Expanded(
                    child: pw.Column(children: [
                      pw.Container(
                        height: 140,
                        decoration: pw.BoxDecoration(
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 12,
                          verticalRadius: 12,
                          child: pw.Image(sideImage, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Vue latérale', style: const pw.TextStyle(fontSize: 10)),
                    ]),
                  ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Analysis
          pw.Text('Analyse', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Column(children: [
            if (analysis1 != null) _analysisTile(analysis1!, PdfColors.green600),
            if (analysis2 != null) _analysisTile(analysis2!, PdfColors.amber700),
            if (analysis3 != null) _analysisTile(analysis3!, PdfColors.blue700),
          ]),

          pw.SizedBox(height: 24),
          pw.Center(child: pw.Text('Généré automatiquement par LiDAR Mesure', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _metricTile(String label, String subtitle, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
          pw.Container(
            width: 10,
            height: 10,
            decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          ),
        ],
      ),
    );
  }

  static pw.Widget _analysisTile(String text, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color),
        color: PdfColors.white,
      ),
      child: pw.Row(
        children: [
          pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  /// Builds and opens the platform share/print dialog
  static Future<void> shareReport({
    String? patientName,
    required String rightLengthCm,
    required String leftLengthCm,
    required String rightWidthCm,
    required String leftWidthCm,
    String precision = '97%',
    String? analysis1,
    String? analysis2,
    String? analysis3,
    String? topImageAsset,
    String? sideImageAsset,
  }) async {
    try {
      final data = await buildReport(
        patientName: patientName,
        rightLengthCm: rightLengthCm,
        leftLengthCm: leftLengthCm,
        rightWidthCm: rightWidthCm,
        leftWidthCm: leftWidthCm,
        precision: precision,
        analysis1: analysis1,
        analysis2: analysis2,
        analysis3: analysis3,
        topImageAsset: topImageAsset,
        sideImageAsset: sideImageAsset,
      );
      await Printing.sharePdf(bytes: data, filename: 'rapport_pied.pdf');
    } catch (e, st) {
      debugPrint('PdfService shareReport error: $e\n$st');
      rethrow;
    }
  }
}

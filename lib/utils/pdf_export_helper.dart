import 'dart:io';                       
import 'dart:typed_data';               
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'; 
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/defect_item.dart';


Future<String> generateAndSaveDefectsPDF(
  List<DefectItem> filteredDefects,
  List<String> allCategories,
  Uint8List logoBytes,
) async {
  final pdfBytes = await _buildDefectsPDFBytes(filteredDefects, allCategories, logoBytes);

  final tempDir = await getTemporaryDirectory();
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final filePath = '${tempDir.path}/defects_$timestamp.pdf';
  final file = File(filePath);

  await file.writeAsBytes(pdfBytes);

  return filePath;
}

Future<Uint8List> _buildDefectsPDFBytes(
  List<DefectItem> filteredDefects,
  List<String> allCategories,
  Uint8List logoBytes,
) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final dateStr = DateFormat('yyyy-MM-dd').format(now);

  final logoImage = pw.MemoryImage(logoBytes);

  final totalDefects = filteredDefects.length;
  final Map<String, int> categoryCounts = {
    for (var category in allCategories.where((cat) => cat != 'All')) category: 0,
  };
  for (var defect in filteredDefects) {
    final cat = defect.defectType;
    if (categoryCounts.containsKey(cat)) {
      categoryCounts[cat] = categoryCounts[cat]! + 1;
    }
  }

  pdf.addPage(
    pw.MultiPage(
      margin: const pw.EdgeInsets.fromLTRB(20, 10, 20, 20),
      pageFormat: PdfPageFormat.a4,

      header: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 110, height: 110),
                pw.Text(
                  'CCP IRQ - Defects Report',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
        );
      },

      footer: (pw.Context context) {
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              dateStr,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              '© ${now.year} Veridos CCP IRQ',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        );
      },

      build: (pw.Context context) => [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),

        _buildSummaryTable(totalDefects, categoryCounts),
        pw.SizedBox(height: 16),

        _buildDefectsTable(filteredDefects),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _buildSummaryTable(int totalDefects, Map<String, int> categoryCounts) {
  final rows = <pw.TableRow>[];

  rows.add(
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            'Total Defects',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            totalDefects.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  categoryCounts.forEach((category, count) {
    final displayVal = (count == 0) ? 'No Data' : count.toString();
    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(category),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(displayVal),
          ),
        ],
      ),
    );
  });

  return pw.Table(
    border: pw.TableBorder.all(width: 1, color: PdfColors.grey300),
    columnWidths: {
      0: const pw.FixedColumnWidth(200),
      1: const pw.FixedColumnWidth(100),
    },
    children: rows,
  );
}

pw.Widget _buildDefectsTable(List<DefectItem> defects) {
  return pw.Table(
    border: pw.TableBorder.all(width: 1, color: PdfColors.grey300),
    columnWidths: {
      0: const pw.FixedColumnWidth(120),
      1: const pw.FixedColumnWidth(120),
      2: const pw.FixedColumnWidth(120),
    },
    children: [
      // Header row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              'Doc No.',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              'Defect Type',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(
              'Date',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),

      ...defects.map((defect) {
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(defect.timestamp);
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(defect.documentNumber),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(defect.defectType),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(dateStr),
            ),
          ],
        );
      }).toList(),
    ],
  );
}

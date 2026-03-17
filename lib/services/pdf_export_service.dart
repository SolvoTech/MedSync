import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/task_log.dart';

/// Service to generate and share PDF reports per spec §8.
class PdfExportService {
  /// Generate and show print/share dialog for a report.
  static Future<void> exportReport({
    required BuildContext context,
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required int currentStreak,
    required List<TaskLog> logs,
  }) async {
    final pdf = pw.Document();

    final total = logs.length;
    final done = logs.where((l) => l.status == 'done').length;
    final adherencePercent = total > 0 ? (done / total * 100).round() : 0;

    // Group logs by type
    final medicine = logs.where((l) => l.taskType == 'medicine').toList();
    final measurement =
        logs.where((l) => l.taskType == 'measurement').toList();
    final activity =
        logs.where((l) => l.taskType == 'physical_activity').toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(userName, startDate, endDate),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary
          pw.Header(level: 1, text: 'Ringkasan'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: [
              ['Metrik', 'Nilai'],
              ['Total Tugas', '$total'],
              ['Tugas Selesai', '$done'],
              ['Kepatuhan', '$adherencePercent%'],
              ['Streak Saat Ini', '$currentStreak hari'],
            ],
          ),
          pw.SizedBox(height: 16),

          // Medicine tasks
          if (medicine.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Riwayat Obat'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: [
                ['Tanggal', 'Waktu', 'Status', 'Catatan'],
                ...medicine.map((l) => [
                      _formatDate(l.scheduledAt),
                      _formatTime(l.scheduledAt),
                      _statusLabel(l.status),
                      l.symptomNotes ?? l.notes ?? '-',
                    ]),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Measurement tasks
          if (measurement.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Riwayat Pengukuran'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: [
                ['Tanggal', 'Waktu', 'Status', 'Catatan'],
                ...measurement.map((l) => [
                      _formatDate(l.scheduledAt),
                      _formatTime(l.scheduledAt),
                      _statusLabel(l.status),
                      l.notes ?? '-',
                    ]),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Activity tasks
          if (activity.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Riwayat Aktivitas Fisik'),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              data: [
                ['Tanggal', 'Waktu', 'Status', 'Catatan'],
                ...activity.map((l) => [
                      _formatDate(l.scheduledAt),
                      _formatTime(l.scheduledAt),
                      _statusLabel(l.status),
                      l.notes ?? '-',
                    ]),
              ],
            ),
          ],
        ],
      ),
    );

    final bytes = await pdf.save();

    if (context.mounted) {
      await Printing.sharePdf(
        bytes: Uint8List.fromList(bytes),
        filename: 'MedSync_Laporan_${_formatDateShort(startDate)}_${_formatDateShort(endDate)}.pdf',
      );
    }
  }

  static pw.Widget _buildHeader(
      String userName, DateTime start, DateTime end) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('MedSync',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Laporan Kesehatan',
                  style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(userName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                '${_formatDate(start)} – ${_formatDate(end)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Digenerate oleh MedSync • ${_formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Hal. ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  static String _formatDateShort(DateTime dt) =>
      '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _statusLabel(String status) => switch (status) {
        'done' => 'Selesai',
        'skipped' => 'Dilewati',
        'missed' => 'Terlewat',
        _ => 'Menunggu',
      };
}

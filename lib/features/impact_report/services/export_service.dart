import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/calculators/impact_calculators.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/donation_model.dart';
import '../../../data/models/waste_audit_model.dart';

class ExportService {
  /// Generates CSV format string containing verified totals, donation audits, and waste metrics.
  static String generateCsv({
    required VerifiedImpactTotals totals,
    required List<DonationModel> donations,
    required List<WasteAuditModel> audits,
    required String dateRangeLabel,
  }) {
    final List<List<dynamic>> rows = [];

    // Header & Summary
    rows.add(['FoodBridge Surplus & Waste Impact Report']);
    rows.add(['Date Range Filter', dateRangeLabel]);
    rows.add(['Generated At', DateTime.now().toIso8601String()]);
    rows.add(['Universal Disclaimer', AppConstants.universalFoodSafetyDisclaimer]);
    rows.add([]);

    // Verified Totals Section
    rows.add(['--- VERIFIED IMPACT TOTALS (ACCORDING TO AUDIT STANDARDS) ---']);
    rows.add(['Estimated Surplus Offered (Donor Estimate)', '${totals.estimatedSurplusOffered} kg']);
    rows.add(['Approved by NGO', '${totals.acceptedQuantity} kg']);
    rows.add(['Verified Collected (Actual Weighed)', '${totals.verifiedCollectedKg} kg']);
    rows.add(['Verified Distributed to Beneficiaries', '${totals.verifiedDistributedKg} kg']);
    rows.add(['Remainder Accounted (Compost/Feed)', '${totals.remainderKg} kg']);
    rows.add(['Completed Collection Efficiency', '${totals.collectionRatePercent}%']);
    rows.add([]);

    // Donations Section
    rows.add(['--- DONATION RECORDS ---']);
    rows.add([
      'Donation ID',
      'Food Description',
      'Category',
      'Listed Qty',
      'Unit',
      'Status',
      'Preparation Time',
      'Storage Condition',
      'Donor Organisation',
    ]);

    for (final d in donations) {
      rows.add([
        d.donationId,
        d.foodDescription,
        d.foodCategory,
        d.listedQuantity,
        d.unit,
        d.status.name,
        d.preparationDateTime.toIso8601String(),
        d.storageCondition,
        d.donorOrgName,
      ]);
    }

    rows.add([]);

    // Waste Audits Section
    rows.add(['--- CANTEEN DAILY WASTE AUDITS ---']);
    rows.add([
      'Audit Date',
      'Prepared (kg)',
      'Served (kg)',
      'Edible Surplus (kg)',
      'Discarded (kg)',
      'Waste Rate %',
      'Measurement Method',
      'Notes',
    ]);

    for (final a in audits) {
      rows.add([
        a.date.toIso8601String().split('T').first,
        a.preparedKg,
        a.servedKg,
        a.edibleSurplusKg,
        a.discardedKg,
        '${a.wasteRatePercent}%',
        a.measurementMethod,
        a.notes,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Generates and previews / prints a formal PDF document.
  static Future<void> printPdfReport({
    required VerifiedImpactTotals totals,
    required List<DonationModel> donations,
    required List<WasteAuditModel> audits,
    required String dateRangeLabel,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FoodBridge Impact & Audit Report',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Surplus Food Rescue, Waste Prevention & Transparent Record-Keeping', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(dateRangeLabel, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                ),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.green800),
            pw.SizedBox(height: 8),

            // Mandatory Disclaimer Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.amber600, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'NOTICE: ${AppConstants.universalFoodSafetyDisclaimer}\nThe impact dashboard counts only collected and distributed records that are verified. Estimates are separated.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.brown900),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Verified KPI Metrics Summary Table
            pw.Text('1. Verified Diversion & Collection Efficiency', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Verified Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Status & Accounting Basis', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  ],
                ),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Surplus Offered (Donor Estimate)', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totals.estimatedSurplusOffered} kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Self-reported by donor', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Approved Intake Quantity', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totals.acceptedQuantity} kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Approved by partner NGO staff', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Verified Collected Surplus', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totals.verifiedCollectedKg} kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green900))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Weighed on site by volunteer driver', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Verified Distributed to Beneficiaries', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totals.verifiedDistributedKg} kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green900))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Shelters & Community Pantries', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Remainder Diverted to Compost/Feed', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totals.remainderKg} kg', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Zero landfill policy disposition', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                ]),
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Completed Collection Rate', style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${totals.collectionRatePercent}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.blue800))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Completed vs Accepted requests', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600))),
                ]),
              ],
            ),

            pw.SizedBox(height: 18),

            // Daily Waste Audits
            pw.Text('2. Kitchen Waste Audit Log (Last 5 Entries)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Prep kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Served kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Discard kg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Waste Rate %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Methodology', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  ],
                ),
                ...audits.take(5).map((a) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${a.date.day}/${a.date.month}', style: const pw.TextStyle(fontSize: 8.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${a.preparedKg}', style: const pw.TextStyle(fontSize: 8.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${a.servedKg}', style: const pw.TextStyle(fontSize: 8.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${a.discardedKg}', style: const pw.TextStyle(fontSize: 8.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${a.wasteRatePercent}%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.green900))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(a.measurementMethod, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),

            // Footer
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Report verified for educational & NGO partnership impact.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('FoodBridge System v1.0', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FoodBridge_Impact_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}

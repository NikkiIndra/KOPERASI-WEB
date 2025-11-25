import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koperasi/app/modules/Document/utils/AddDocument.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

class DocumentController extends GetxController {
  final search = ''.obs;

  final titleC = TextEditingController();
  final yearC = TextEditingController(text: "2025");
  final rakC = TextEditingController();
  final boxC = TextEditingController();
  final descC = TextEditingController();
  final isFormValid = false.obs;

  final docs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDocs();
    search.value = "";
  }

  // =====================================================
  // SIMPAN TANPA PDF
  // =====================================================
  Future<void> saveDocument({
    required String title,
    required String year,
    required String rak,
    required String box,
    required String desc,
  }) async {
    try {
      await FirebaseFirestore.instance.collection("dokumen").add({
        "name": title,
        "year": year,
        "rak": rak,
        "box": box,
        "lokasi": "$rak / $box",
        "desc": desc,
        "update": DateTime.now().toIso8601String(),
      });

      Get.snackbar("Sukses", "Dokumen berhasil disimpan");
    } catch (e) {
      Get.snackbar("Error", "Gagal menyimpan dokumen");
    }
  }

  // =====================================================
  // LOAD FIRESTORE REALTIME
  // =====================================================
  void loadDocs() async {
    FirebaseFirestore.instance.collection("dokumen").snapshots().listen((snap) {
      docs.value = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data["id"] = d.id;
        return data;
      }).toList();
    });
  }

  // =====================================================
  // FILTER SEARCH
  // =====================================================
  // List<Map<String, dynamic>> get filteredDocs {
  //   if (search.value.isEmpty) return docs.toList();
  //   return docs.where((e) {
  //     final name = (e['name'] ?? "").toString().toLowerCase();
  //     return name.contains(search.value.toLowerCase());
  //   }).toList();
  // }
  List<Map<String, dynamic>> get filteredDocs {
    if (search.value.isEmpty) return docs;

    return docs
        .where(
          (e) => e['name'].toLowerCase().contains(search.value.toLowerCase()),
        )
        .toList();
  }

  // =====================================================
  // BUKA DIALOG
  // =====================================================
  void openAddDocumentDialog() {
    Get.dialog(AddDocumentDialog(), barrierDismissible: false);
  }

  // =====================================================
  // GENERATE PDF (TIDAK UPLOAD)
  // =====================================================
  Future<void> generatePDF({
    required String title,
    required String year,
    required String rak,
    required String box,
    required String desc,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context c) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "DOKUMEN ARSIP KOPERASI",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Nama Dokumen : $title"),
                pw.Text("Tahun        : $year"),
                pw.Text("Lokasi       : Rak $rak - Box $box"),
                pw.SizedBox(height: 20),
                pw.Text("Deskripsi:"),
                pw.Text(desc),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();

    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..download = "$title.pdf"
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // =====================================================
  // HAPUS DATA FIRESTORE SAJA
  // =====================================================
  Future<void> deleteDocument(Map data) async {
    try {
      await FirebaseFirestore.instance
          .collection("dokumen")
          .doc(data["id"])
          .delete();

      Get.snackbar("Berhasil", "Dokumen dihapus");
    } catch (e) {
      Get.snackbar("Error", "Gagal menghapus dokumen");
    }
  }

  // =====================================================
  // Validasi Form
  // =====================================================
  void validateForm(
    String title,
    String year,
    String rak,
    String box,
    String desc,
  ) {
    isFormValid.value =
        title.isNotEmpty &&
        year.isNotEmpty &&
        rak.isNotEmpty &&
        box.isNotEmpty &&
        desc.isNotEmpty;
  }
}

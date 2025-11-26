import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koperasi/app/modules/dokemenKantor/utils/AddDocument.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

import '../../../helper/import_dokumen.dart';

class DocumentController extends GetxController {
  final search = ''.obs;

  final titleC = TextEditingController();
  final yearC = TextEditingController(text: "2025");
  final blokC = TextEditingController();
  final ambalanC = TextEditingController();
  final boxC = TextEditingController();
  final descC = TextEditingController();
  final isFormValid = false.obs;

  final docs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDocs();
    search.value = "";

    // ✅ HAPUS fungsi di dalam onInit, ganti dengan:
    _migrateExistingData();
  }

  // ✅ BUAT FUNGSI TERPISAH
  void _migrateExistingData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("dokumenKantor")
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Only update if type field doesn't exist
        if (!data.containsKey('type')) {
          await doc.reference.update({"type": "manual"});
        }
      }
      print('Migration completed');
    } catch (e) {
      print('Migration error: $e');
    }
  }

  // =====================================================
  // IMPORT DOKUMEN (UPLOAD FILE) - FIXED VERSION
  // =====================================================
  Future<void> importDocument({
    required String title,
    required String year,
    required String blok,
    required String ambalan,
    required String box,
    required html.File file,
  }) async {
    try {
      print('Starting import process...');

      // 1. Upload file ke Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'dokumenKantor/$fileName',
      );

      print('Uploading file: $fileName');

      // Convert html.File to Uint8List
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      final uploadTask = storageRef.putData(Uint8List.fromList(bytes));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('File uploaded, URL: $downloadUrl');

      // 2. Simpan metadata ke Firestore
      await FirebaseFirestore.instance.collection("dokumenKantor").add({
        "name": title,
        "year": year,
        "blok": blok,
        "ambalan": ambalan,
        "box": box,
        "type": "imported",
        "fileUrl": downloadUrl,
        "fileName": file.name,
        "fileSize": file.size,
        "update": DateTime.now().toIso8601String(),
      });

      print('Firestore document saved');
      Get.snackbar('Sukses', 'Dokumen berhasil diimport');
    } catch (e) {
      print('Import error: $e');
      Get.snackbar('Error', 'Gagal mengimport dokumen: $e');
    }
  }

  // =====================================================
  // DOWNLOAD DOKUMEN (SMART LOGIC)
  // =====================================================
  Future<void> downloadDocument(Map<String, dynamic> data) async {
    try {
      final docType = data['type'] ?? 'manual'; // ✅ Default ke manual jika null

      // ✅ DOKUMEN IMPORT: Download file asli dari Storage
      if (docType == 'imported' && data['fileUrl'] != null) {
        final url = data['fileUrl'];
        final fileName = data['fileName'] ?? 'document.pdf';

        // Download file asli
        html.AnchorElement(href: url)
          ..download = fileName
          ..click();
        return;
      }
      // ✅ DOKUMEN MANUAL: Generate PDF dari data input
      else {
        await generatePDF(
          title: data['name'] ?? '',
          year: data['year'] ?? '',
          blok: data['blok']?.toString() ?? '',
          ambalan: data['ambalan']?.toString() ?? '',
          box: data['box']?.toString() ?? '',
          desc: data['desc'] ?? '',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mendownload: $e');
    }
  }

  // =====================================================
  // BUKA DIALOG IMPORT
  // =====================================================
  void openImportDialog() {
    Get.dialog(ImportDocumentDialog());
  }

  // ==================== UPDATE NASABAH ====================
  Future<void> updateDukumenKantor(String id) async {
    await FirebaseFirestore.instance
        .collection("dokumenKantor")
        .doc(id)
        .update({
          "name": titleC.text,
          "year": yearC.text,
          "blok": blokC.text,
          "ambalan": ambalanC.text,
          "box": boxC.text,
          "type": "manual",
          "update": DateTime.now().toIso8601String(),
        });
  }

  // ==================== CLEAR FORM ====================
  void clearForm() {
    titleC.clear();
    yearC.clear();
    blokC.clear();
    ambalanC.clear();
    boxC.clear();
  }

  // =====================================================
  // SIMPAN TANPA PDF
  // =====================================================
  Future<void> saveDocument({
    required String title,
    required String year,
    required String blok,
    required String ambalan,
    required String box,
    required String desc,
  }) async {
    try {
      await FirebaseFirestore.instance.collection("dokumenKantor").add({
        "name": title,
        "year": year,
        "blok": blok,
        "ambalan": ambalan,
        "box": box,
        "desc": desc,
        "type": "manual",
        "update": DateTime.now().toIso8601String(),
      });

      // AppToast.show("Dokumen berhasil disimpan");
    } catch (e) {
      // AppToast.show("Gagal menyimpan dokumen");
    }
  }

  // =====================================================
  // LOAD FIRESTORE REALTIME
  // =====================================================
  void loadDocs() async {
    FirebaseFirestore.instance.collection("dokumenKantor").snapshots().listen((
      snap,
    ) {
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
    Get.dialog(AddDocumentDialogKantor(), barrierDismissible: false);
  }

  // =====================================================
  // GENERATE PDF (TIDAK UPLOAD)
  // =====================================================
  Future<void> generatePDF({
    required String title,
    required String year,
    required String blok,
    required String ambalan,
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
                pw.Text("Blok         : $blok"),
                pw.Text("Ambalan      : $ambalan"),
                pw.Text("Box          : $box"),
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
  // =====================================================
  // HAPUS DATA FIRESTORE + STORAGE (jika imported)
  // =====================================================
  Future<void> deleteDocument(Map data) async {
    try {
      // Jika dokumen imported, hapus juga file di storage
      if (data['type'] == 'imported' && data['fileUrl'] != null) {
        try {
          final fileUrl = data['fileUrl'];
          final ref = FirebaseStorage.instance.refFromURL(fileUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting storage file: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection("dokumenKantor")
          .doc(data["id"])
          .delete();

      Get.snackbar('Sukses', 'Dokumen berhasil dihapus');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus dokumen: $e');
    }
  }

  // =====================================================
  // Validasi Form
  // =====================================================
  void validateForm(
    String title,
    String year,
    String blok,
    String ambalan,
    String box,
    String desc,
  ) {
    isFormValid.value =
        title.isNotEmpty &&
        year.isNotEmpty &&
        blok.isNotEmpty &&
        ambalan.isNotEmpty &&
        box.isNotEmpty &&
        desc.isNotEmpty;
  }
}

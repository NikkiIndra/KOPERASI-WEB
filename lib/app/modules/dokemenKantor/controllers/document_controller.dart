import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koperasi/app/helper/google_drive_service.dart';
import 'package:koperasi/app/modules/dokemenKantor/utils/AddDocument.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

import '../../../helper/import_dokumen.dart';

class DocumentController extends GetxController {
  final search = ''.obs;
  final isLoading = false.obs;
  final titleC = TextEditingController();
  final yearC = TextEditingController(text: "2025");
  final blokC = TextEditingController();
  final ambalanC = TextEditingController();
  final boxC = TextEditingController();
  final descC = TextEditingController();
  final isFormValid = false.obs;
  final isDriveConnected = false.obs; // Track Google Drive connection
  final docs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDocs();
    search.value = "";
    _migrateExistingData();

    // Check Google Drive connection on init
    checkDriveConnection();
  }

  // Check Google Drive connection
  Future<void> checkDriveConnection() async {
    isDriveConnected.value = GoogleDriveService.isLoggedIn;
  }

  // Connect to Google Drive
  Future<void> connectToDrive() async {
    try {
      final connected = await GoogleDriveService.login();
      isDriveConnected.value = connected;
      if (connected) {
        print('Connected to Google Drive');
      }
    } catch (e) {
      print('Google Drive connection error: $e');
    }
  }

  // =====================================================
  // SIMPAN DOKUMEN BIASA (TANPA TANYA DRIVE)
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
      // Langsung simpan ke Firestore tanpa tanya ke Drive
      await FirebaseFirestore.instance.collection("dokumenKantor").add({
        "name": title,
        "year": year,
        "blok": blok,
        "ambalan": ambalan,
        "box": box,
        "desc": desc,
        "type": "manual", // Tipe: manual (data input)
        "update": DateTime.now().toIso8601String(),
      });

      print('Document saved successfully');

      Get.back(); // Tutup dialog
    } catch (e) {
      print('Gagal menyimpan dokumen: $e');
    }
  }

  // =====================================================
  // DOWNLOAD DOKUMEN (SMART LOGIC) - UPDATED
  // =====================================================
  // =====================================================
  // DOWNLOAD DOKUMEN (SMART LOGIC)
  // =====================================================
  Future<void> downloadDocument(Map<String, dynamic> data) async {
    try {
      final docType = data['type'] ?? 'manual';

      // 1. DOKUMEN IMPORT (Firebase Storage)
      if (docType == 'imported') {
        final url = data['fileUrl'];
        final fileName = data['fileName'] ?? 'document.pdf';

        if (url != null) {
          html.AnchorElement(href: url)
            ..download = fileName
            ..click();
        }
        return;
      }

      // 2. DOKUMEN DRIVE (Google Drive)
      if (docType == 'drive') {
        final driveFileId = data['driveFileId'];
        final fileName = data['fileName'] ?? data['name'] ?? 'document.pdf';

        if (driveFileId == null) {
          throw Exception('File ID tidak ditemukan');
        }

        // Cek apakah sudah login ke Drive
        if (!isDriveConnected.value) {
          // Minta login dulu
          final result = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('Login Google Drive Diperlukan'),
              content: const Text(
                'Dokumen ini tersimpan di Google Drive. Login dulu untuk mendownload.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('Login ke Drive'),
                ),
              ],
            ),
          );

          if (result != true) return;

          await connectToDrive();
          if (!isDriveConnected.value) return;
        }

        await GoogleDriveService.downloadFile(driveFileId, '$fileName.pdf');
        return;
      }

      // 3. DOKUMEN MANUAL (Generate PDF dari data)
      await generatePDF(
        title: data['name'] ?? '',
        year: data['year'] ?? '',
        blok: data['blok']?.toString() ?? '',
        ambalan: data['ambalan']?.toString() ?? '',
        box: data['box']?.toString() ?? '',
        desc: data['desc'] ?? '',
      );
    } catch (e) {
      print('Gagal mendownload: $e');
    }
  }

  // =====================================================
  // UPDATE DOKUMEN + GOOGLE DRIVE
  // =====================================================
  Future<void> updateDukumenKantor(
    String id,
    Map<String, dynamic> oldData,
  ) async {
    try {
      final newTitle = titleC.text;
      final newYear = yearC.text;
      final newBlok = blokC.text;
      final newAmbalan = ambalanC.text;
      final newBox = boxC.text;
      final newDesc = descC.text;

      final driveFileId = oldData['driveFileId'];
      final docType = oldData['type'] ?? 'manual';

      // Jika dokumen ada di Google Drive, update juga di sana
      if (docType == 'drive' && driveFileId != null && isDriveConnected.value) {
        try {
          await GoogleDriveService.updateFile(
            fileId: driveFileId,
            newName: '$newTitle - $newYear.pdf',
            newDescription:
                'Dokumen: $newTitle\nTahun: $newYear\nBlok: $newBlok\nAmbalan: $newAmbalan\nBox: $newBox\nDeskripsi: $newDesc',
          );
        } catch (e) {
          print('Error updating Google Drive file: $e');
        }
      }

      // Update di Firestore
      await FirebaseFirestore.instance
          .collection("dokumenKantor")
          .doc(id)
          .update({
            "name": newTitle,
            "year": newYear,
            "blok": newBlok,
            "ambalan": newAmbalan,
            "box": newBox,
            "desc": newDesc,
            "type": docType,
            "update": DateTime.now().toIso8601String(),
          });

      print('Document updated successfully');
    } catch (e) {
      print("Error updating document: $e");
    }
  }

  // =====================================================
  // HAPUS DOKUMEN + GOOGLE DRIVE
  // =====================================================
  Future<void> deleteDocument(Map data) async {
    try {
      final docType = data['type'] ?? 'manual';
      final driveFileId = data['driveFileId'];

      // Jika dokumen ada di Google Drive, hapus juga di sana
      if (docType == 'drive' && driveFileId != null && isDriveConnected.value) {
        try {
          await GoogleDriveService.deleteFile(driveFileId);
        } catch (e) {
          print('Error deleting from Google Drive: $e');
        }
      }

      // Jika dokumen imported, hapus dari storage
      if (docType == 'imported' && data['fileUrl'] != null) {
        try {
          final fileUrl = data['fileUrl'];
          final ref = FirebaseStorage.instance.refFromURL(fileUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting storage file: $e');
        }
      }

      // Hapus dari Firestore
      await FirebaseFirestore.instance
          .collection("dokumenKantor")
          .doc(data["id"])
          .delete();

      print('Document deleted successfully');
    } catch (e) {
      print('Gagal menghapus dokumen: $e');
    }
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
  // IMPORT DOKUMEN KE GOOGLE DRIVE + FIREBASE
  // =====================================================

  Future<void> importDocument({
    required String title,
    required String year,
    required String blok,
    required String ambalan,
    required String box,
    required html.File file,
    bool saveToDrive = false, // Tambahkan parameter ini
  }) async {
    try {
      print('Starting import process...');
      print('saveToDrive: $saveToDrive');

      String? driveFileId;
      String? driveUrl;

      // 1. JIKA SIMPAN KE GOOGLE DRIVE
      if (saveToDrive && isDriveConnected.value) {
        try {
          // Convert file ke bytes
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoad.first;
          final bytes = reader.result as List<int>;
          final fileBytes = Uint8List.fromList(bytes);

          final fileName = file.name;

          // Upload ke Google Drive
          final driveService = GoogleDriveService();
          final driveData = await driveService.uploadPDF(
            fileName: fileName,
            fileBytes: fileBytes,
            description:
                'Dokumen: $title\nTahun: $year\nBlok: $blok\nAmbalan: $ambalan\nBox: $box',
          );

          if (driveData != null) {
            driveFileId = driveData['id'];
            driveUrl = driveData['driveUrl'];

            // Simpan metadata ke Firestore
            await FirebaseFirestore.instance.collection("dokumenKantor").add({
              "name": title,
              "year": year,
              "blok": blok,
              "ambalan": ambalan,
              "box": box,
              "type": "drive",
              "driveFileId": driveFileId,
              "driveUrl": driveUrl,
              "fileName": fileName,
              "fileSize": file.size,
              "update": DateTime.now().toIso8601String(),
            });

            print('Document saved to Firestore with Google Drive info');
            return;
          }
        } catch (e) {
          print('Error saving to Google Drive: $e');

          // Lanjut ke Firebase Storage
        }
      }

      // 2. SIMPAN KE FIREBASE STORAGE (default)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${file.name}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'dokumenKantor/$fileName',
      );

      print('Uploading file to Firebase Storage: $fileName');

      // Convert html.File to Uint8List
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      final uploadTask = storageRef.putData(Uint8List.fromList(bytes));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('File uploaded to Firebase, URL: $downloadUrl');

      // Simpan metadata ke Firestore
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
    } catch (e) {
      print('Import error: $e');

      rethrow;
    }
  }
  // =====================================================
  // DOWNLOAD DOKUMEN (SMART LOGIC)
  // =====================================================
  // Future<void> downloadDocument(Map<String, dynamic> data) async {
  //   try {
  //     final docType = data['type'] ?? 'manual'; // ✅ Default ke manual jika null

  //     // ✅ DOKUMEN IMPORT: Download file asli dari Storage
  //     if (docType == 'imported' && data['fileUrl'] != null) {
  //       final url = data['fileUrl'];
  //       final fileName = data['fileName'] ?? 'document.pdf';

  //       // Download file asli
  //       html.AnchorElement(href: url)
  //         ..download = fileName
  //         ..click();
  //       return;
  //     }
  //     // ✅ DOKUMEN MANUAL: Generate PDF dari data input
  //     else {
  //       await generatePDF(
  //         title: data['name'] ?? '',
  //         year: data['year'] ?? '',
  //         blok: data['blok']?.toString() ?? '',
  //         ambalan: data['ambalan']?.toString() ?? '',
  //         box: data['box']?.toString() ?? '',
  //         desc: data['desc'] ?? '',
  //       );
  //     }
  //   } catch (e) {
  //     print('Gagal mendownload: $e');
  //   }
  // }
  // =====================================================
  // IMPORT DOKUMEN KE GOOGLE DRIVE (ONLY)
  // =====================================================
  Future<void> importDocumentToDrive({
    required String title,
    required String year,
    required String blok,
    required String ambalan,
    required String box,
    required html.File file,
  }) async {
    try {
      print('Importing document to Google Drive...');

      // Validasi koneksi Drive
      if (!isDriveConnected.value) {
        throw Exception('Belum terhubung ke Google Drive');
      }

      // Convert file ke bytes
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      final fileBytes = Uint8List.fromList(bytes);

      final fileName = file.name;

      // Upload ke Google Drive
      final driveService = GoogleDriveService();
      final driveData = await driveService.uploadPDF(
        fileName: fileName,
        fileBytes: fileBytes,
        description:
            'Dokumen: $title\nTahun: $year\nBlok: $blok\nAmbalan: $ambalan\nBox: $box',
      );

      if (driveData == null) {
        throw Exception('Gagal upload ke Google Drive');
      }

      final driveFileId = driveData['id'];
      final driveUrl = driveData['driveUrl'];

      // Simpan metadata ke Firestore (hanya metadata, bukan file)
      await FirebaseFirestore.instance.collection("dokumenKantor").add({
        "name": title,
        "year": year,
        "blok": blok,
        "ambalan": ambalan,
        "box": box,
        "type": "drive", // Tipe: drive
        "driveFileId": driveFileId,
        "driveUrl": driveUrl,
        "fileName": fileName,
        "fileSize": file.size,
        "update": DateTime.now().toIso8601String(),
      });

      print(
        'Dokumen berhasil diimport ke Google Drive dengan ID: $driveFileId',
      );
    } catch (e) {
      print('Error importing to Google Drive: $e');
      rethrow;
    }
  }

  // =====================================================
  // BUKA DIALOG IMPORT
  // =====================================================
  void openImportDialog() {
    // Cek koneksi Drive dulu
    if (!isDriveConnected.value) {
      print('Google Drive belum terhubung');
      return;
    }

    Get.dialog(const ImportDocumentDialog(), barrierDismissible: false);
  }
  // ==================== UPDATE NASABAH ====================
  // Future<void> updateDukumenKantor(String id) async {
  //   await FirebaseFirestore.instance
  //       .collection("dokumenKantor")
  //       .doc(id)
  //       .update({
  //         "name": titleC.text,
  //         "year": yearC.text,
  //         "blok": blokC.text,
  //         "ambalan": ambalanC.text,
  //         "box": boxC.text,
  //         "type": "manual",
  //         "update": DateTime.now().toIso8601String(),
  //       });
  // }

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
  // Future<void> saveDocument({
  //   required String title,
  //   required String year,
  //   required String blok,
  //   required String ambalan,
  //   required String box,
  //   required String desc,
  // }) async {
  //   try {
  //     await FirebaseFirestore.instance.collection("dokumenKantor").add({
  //       "name": title,
  //       "year": year,
  //       "blok": blok,
  //       "ambalan": ambalan,
  //       "box": box,
  //       "desc": desc,
  //       "type": "manual",
  //       "update": DateTime.now().toIso8601String(),
  //     });

  //     // AppToast.show("Dokumen berhasil disimpan");
  //   } catch (e) {
  //     // AppToast.show("Gagal menyimpan dokumen");
  //   }
  // }

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
  // HAPUS DATA FIRESTORE + STORAGE (jika imported)
  // =====================================================
  // Future<void> deleteDocument(Map data) async {
  //   try {
  //     // Jika dokumen imported, hapus juga file di storage
  //     if (data['type'] == 'imported' && data['fileUrl'] != null) {
  //       try {
  //         final fileUrl = data['fileUrl'];
  //         final ref = FirebaseStorage.instance.refFromURL(fileUrl);
  //         await ref.delete();
  //       } catch (e) {
  //         print('Error deleting storage file: $e');
  //       }
  //     }

  //     await FirebaseFirestore.instance
  //         .collection("dokumenKantor")
  //         .doc(data["id"])
  //         .delete();
  //   } catch (e) {
  //     print('Gagal menghapus dokumen: $e');
  //   }
  // }

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

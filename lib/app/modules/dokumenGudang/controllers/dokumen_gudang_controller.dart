import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koperasi/app/helper/google_drive_service.dart';
import 'package:koperasi/app/modules/dokumenGudang/utils/AddDocument.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

import '../../../helper/ImportDocumentDialogGudang.dart';

class DokumenGudangController extends GetxController {
  final search = ''.obs;
  final titleC = TextEditingController();
  final yearC = TextEditingController(text: "2025");
  final bantexC = TextEditingController();
  final isFormValid = false.obs;
  final isDriveConnected = false.obs;
  final docs = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDocs();
    search.value = "";
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
        print('Berhasil terhubung ke Google Drive');
      }
    } catch (e) {
      print('Gagal terhubung ke Google Drive: $e');
    }
  }

  // Helper untuk dialog konfirmasi
  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Login'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // SIMPAN DOKUMEN BIASA
  Future<void> saveDocument({
    required String title,
    required String year,
    required String bantex,
  }) async {
    try {
      await FirebaseFirestore.instance.collection("dokumenGudang").add({
        "name": title,
        "year": year,
        "bantex": bantex,
        "type": "manual",
        "update": DateTime.now().toIso8601String(),
      });
      print('Dokumen berhasil disimpan');
    } catch (e) {
      print('Gagal menyimpan dokumen: $e');
    }
  }

  // IMPORT DOKUMEN KE GOOGLE DRIVE
  Future<void> importDocumentToDrive({
    required String title,
    required String year,
    required String bantex,
    required html.File file,
  }) async {
    try {
      print('Importing document to Google Drive...');

      if (!GoogleDriveService.isLoggedIn) {
        throw Exception('Belum terhubung ke Google Drive');
      }

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      final fileBytes = Uint8List.fromList(bytes);

      final originalName = file.name;
      final cleanName = _cleanFileName(originalName);

      final driveData = await GoogleDriveService().uploadFile(
        fileName: cleanName,
        fileBytes: fileBytes,
        description: 'Dokumen Gudang: $title\nTahun: $year\nDeskripsi: $bantex',
      );

      if (driveData == null) {
        throw Exception('Gagal upload ke Google Drive');
      }

      final driveFileId = driveData['id'];
      final driveUrl = driveData['webViewLink'] ??
          'https://drive.google.com/file/d/$driveFileId/view';

      await FirebaseFirestore.instance.collection("dokumenGudang").add({
        "name": title,
        "year": year,
        "bantex": bantex,
        "type": "drive",
        "driveFileId": driveFileId,
        "driveUrl": driveUrl,
        "fileName": cleanName,
        "originalFileName": originalName,
        "fileSize": file.size,
        "mimeType": _getMimeType(cleanName),
        "update": DateTime.now().toIso8601String(),
      });

      print('Dokumen berhasil diimport ke Google Drive dengan ID: $driveFileId');
    } catch (e) {
      print('Error importing to Google Drive: $e');
      rethrow;
    }
  }

  // Helper untuk membersihkan nama file
  String _cleanFileName(String fileName) {
    final parts = fileName.split('.');

    if (parts.length > 2) {
      final lastExt = parts.last.toLowerCase();
      final secondLastExt = parts[parts.length - 2].toLowerCase();

      const commonExtensions = {
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
        'jpg', 'jpeg', 'png', 'gif', 'txt',
      };

      if (commonExtensions.contains(secondLastExt) &&
          commonExtensions.contains(lastExt)) {
        return parts.sublist(0, parts.length - 1).join('.');
      }
    }

    return fileName;
  }

  // Helper untuk mendapatkan MIME type
  String _getMimeType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  // Helper untuk memastikan file punya ekstensi
  String _ensureFileExtension(String fileName, String defaultName, String? mimeType) {
    if (fileName.contains('.')) {
      return fileName;
    }

    final mime = mimeType ?? '';
    
    if (mime.contains('word')) {
      return '$fileName.docx';
    } else if (mime.contains('excel')) {
      return '$fileName.xlsx';
    } else if (mime.contains('image/jpeg')) {
      return '$fileName.jpg';
    } else if (mime.contains('image/png')) {
      return '$fileName.png';
    } else if (mime.contains('pdf')) {
      return '$fileName.pdf';
    }

    return '$defaultName.pdf';
  }

  // DOWNLOAD DOKUMEN
  Future<void> downloadDocument(Map<String, dynamic> data) async {
    try {
      final docType = data['type'] ?? 'manual';

      if (docType == 'drive') {
        final driveFileId = data['driveFileId'];
        final originalFileName = data['originalFileName'] ?? data['fileName'] ?? data['name'];
        final fileName = _ensureFileExtension(
          originalFileName, 
          data['name'] ?? 'document', 
          data['mimeType']
        );

        if (driveFileId == null) {
          throw Exception('File ID tidak ditemukan');
        }

        if (!GoogleDriveService.isLoggedIn) {
          final shouldLogin = await _showConfirmationDialog(
            'Login Google Drive Diperlukan',
            'Dokumen ini tersimpan di Google Drive. Login dulu untuk mendownload.',
          );

          if (!shouldLogin) return;

          await connectToDrive();
          if (!GoogleDriveService.isLoggedIn) return;
        }

        await GoogleDriveService.downloadFile(driveFileId, fileName);
        return;
      }

      await generatePDF(
        title: data['name'] ?? '',
        year: data['year'] ?? '',
        bantex: data['bantex'] ?? '',
      );
    } catch (e) {
      print('Gagal mendownload: $e');
    }
  }

  // UPDATE DOKUMEN
  Future<void> updateDokumenGudang(
    String id,
    Map<String, dynamic> oldData,
  ) async {
    try {
      final newTitle = titleC.text;
      final newYear = yearC.text;
      final newBantex = bantexC.text;

      final driveFileId = oldData['driveFileId'];
      final docType = oldData['type'] ?? 'manual';

      if (docType == 'drive' && driveFileId != null && isDriveConnected.value) {
        try {
          await GoogleDriveService.updateFile(
            fileId: driveFileId,
            newName: '$newTitle - $newYear.pdf',
            newDescription: 'Dokumen Gudang: $newTitle\nTahun: $newYear\nDeskripsi: $newBantex',
          );
        } catch (e) {
          print('Error updating Google Drive file: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection("dokumenGudang")
          .doc(id)
          .update({
            "name": newTitle,
            "year": newYear,
            "bantex": newBantex,
            "type": docType,
            "update": DateTime.now().toIso8601String(),
          });

      print('Dokumen berhasil diperbarui');
    } catch (e) {
      print('Gagal memperbarui dokumen: $e');
    }
  }

  // HAPUS DOKUMEN
  Future<void> deleteDocument(Map data) async {
    try {
      final docType = data['type'] ?? 'manual';
      final driveFileId = data['driveFileId'];

      if (docType == 'drive' && driveFileId != null && isDriveConnected.value) {
        try {
          await GoogleDriveService.deleteFile(driveFileId);
        } catch (e) {
          print('Error deleting from Google Drive: $e');
        }
      }

      await FirebaseFirestore.instance
          .collection("dokumenGudang")
          .doc(data["id"])
          .delete();

      print('Dokumen berhasil dihapus');
    } catch (e) {
      print('Gagal menghapus dokumen: $e');
    }
  }

  void clearForm() {
    titleC.clear();
    yearC.clear();
    bantexC.clear();
  }

  void loadDocs() async {
    FirebaseFirestore.instance.collection("dokumenGudang").snapshots().listen((snap) {
      docs.value = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data["id"] = d.id;
        return data;
      }).toList();
    });
  }

  void openImportDialog() {
    if (!isDriveConnected.value) {
      print('Belum terhubung ke Google Drive, tidak bisa import.');
      return;
    }

    Get.dialog(const ImportDocumentDialogGudang(), barrierDismissible: false);
  }

  List<Map<String, dynamic>> get filteredDocs {
    if (search.value.isEmpty) return docs;

    return docs
        .where(
          (e) => e['name'].toLowerCase().contains(search.value.toLowerCase()),
        )
        .toList();
  }

  void openAddDocumentDialog() {
    Get.dialog(AddDocumentDialogGudang(), barrierDismissible: false);
  }

  Future<void> generatePDF({
    required String title,
    required String year,
    required String bantex,
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
                  "DOKUMEN GUDANG KOPERASI",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text("Nama Dokumen : $title"),
                pw.Text("Tahun        : $year"),
                pw.SizedBox(height: 20),
                pw.Text("Deskripsi:"),
                pw.Text(bantex),
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

  void validateForm(String title, String year, String bantex) {
    isFormValid.value = title.isNotEmpty && year.isNotEmpty && bantex.isNotEmpty;
  }
}
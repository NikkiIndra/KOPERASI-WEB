// lib/app/modules/dokumenGudang/utils/ImportDocumentDialogGudang.dart
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/dokumenGudang/controllers/dokumen_gudang_controller.dart';

class ImportDocumentDialogGudang extends StatefulWidget {
  const ImportDocumentDialogGudang({super.key});

  @override
  _ImportDocumentDialogGudangState createState() =>
      _ImportDocumentDialogGudangState();
}

class _ImportDocumentDialogGudangState
    extends State<ImportDocumentDialogGudang> {
  final DokumenGudangController controller = Get.find();
  html.File? _selectedFile;
  bool _isLoading = false;

  // void _pickFile() {
  //   final input = html.FileUploadInputElement()
  //     ..accept = '.pdf,.doc,.docx,.jpg,.jpeg,.png';
  //   input.click();

  //   input.onChange.listen((e) {
  //     final files = input.files;
  //     if (files != null && files.isNotEmpty) {
  //       setState(() {
  //         _selectedFile = files[0];
  //       });
  //     }
  //   });
  // }

  bool _isFormValid() {
    return controller.titleC.text.isNotEmpty &&
        controller.yearC.text.isNotEmpty &&
        controller.bantexC.text.isNotEmpty &&
        _selectedFile != null;
  }

  Future<void> _importDocument() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Import ke Google Drive
      await controller.importDocumentToDrive(
        title: controller.titleC.text,
        year: controller.yearC.text,
        bantex: controller.bantexC.text,
        file: _selectedFile!,
      );

      controller.clearForm();
      Get.back();
    } catch (e) {
      print('Gagal mengimport dokumen ke Drive: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Import Dokumen ke Google Drive"),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // INFO GOOGLE DRIVE
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dokumen akan disimpan ke Google Drive",
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Semua file diupload langsung ke akun Google Drive Anda",
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // FILE PICKER
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_selectedFile?.name ?? "Pilih File"),
                  ),
                  if (_selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "File: ${_selectedFile!.name} (${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // FORM META DATA
              TextField(
                controller: controller.titleC,
                decoration: const InputDecoration(
                  labelText: "Judul Dokumen*",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.yearC,
                decoration: const InputDecoration(
                  labelText: "Tahun*",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.bantexC,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi*",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 8),
              const Text(
                "*Wajib diisi",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  controller.clearForm();
                  Get.back();
                },
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFormValid() ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading
              ? null
              : (_isFormValid() ? _importDocument : null),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : const Text("Import ke Drive"),
        ),
      ],
    );
  }

  // Di ImportDocumentDialogGudang.dart - tambahkan validasi
void _pickFile() {
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png,.txt';
  input.click();

  input.onChange.listen((e) {
    final files = input.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final fileName = file.name;
      
      // Validasi ekstensi double
      if (_hasDoubleExtension(fileName)) {
        Get.snackbar(
          'Peringatan',
          'File memiliki ekstensi ganda. Contoh: "file.docx.pdf"',
          backgroundColor: Colors.orange,
        );
      }
      
      setState(() {
        _selectedFile = file;
      });
    }
  });
}

bool _hasDoubleExtension(String fileName) {
  final parts = fileName.split('.');
  if (parts.length < 3) return false;
  
  const extensions = {'pdf','doc','docx','xls','xlsx','jpg','jpeg','png','txt'};
  final last = parts.last.toLowerCase();
  final secondLast = parts[parts.length - 2].toLowerCase();
  
  return extensions.contains(last) && extensions.contains(secondLast);
}
}

// import_document_dialog.dart
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../modules/dokemenKantor/controllers/document_controller.dart';

class ImportDocumentDialog extends StatefulWidget {
  const ImportDocumentDialog({super.key});

  @override
  _ImportDocumentDialogState createState() => _ImportDocumentDialogState();
}

class _ImportDocumentDialogState extends State<ImportDocumentDialog> {
  final DocumentController controller = Get.find();
  html.File? _selectedFile;
  bool _isLoading = false;

  void _pickFile() {
    final input = html.FileUploadInputElement()
      ..accept = '.pdf,.doc,.docx,.jpg,.jpeg,.png';
    input.click();

    input.onChange.listen((e) {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _selectedFile = files[0];
        });
      }
    });
  }

  bool _isFormValid() {
    return controller.titleC.text.isNotEmpty &&
        controller.yearC.text.isNotEmpty &&
        controller.blokC.text.isNotEmpty &&
        controller.ambalanC.text.isNotEmpty &&
        controller.boxC.text.isNotEmpty &&
        _selectedFile != null;
  }

  Future<void> _importDocument() async {
    if (!_isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await controller.importDocument(
        title: controller.titleC.text,
        year: controller.yearC.text,
        blok: controller.blokC.text,
        ambalan: controller.ambalanC.text,
        box: controller.boxC.text,
        file: _selectedFile!,
      );

      controller.clearForm();
      Get.back();
    } catch (e) {
      print('Dialog import error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Import Dokumen"),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FILE PICKER
            ElevatedButton(
              onPressed: _pickFile,
              child: Text(_selectedFile?.name ?? "Pilih File"),
            ),
            if (_selectedFile != null)
              Text(
                "File: ${_selectedFile!.name} (${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB)",
                style: TextStyle(fontSize: 12),
              ),

            SizedBox(height: 16),

            // FORM META DATA
            TextField(
              controller: controller.titleC,
              decoration: InputDecoration(
                labelText: "Judul Dokumen*",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.yearC,
              decoration: InputDecoration(
                labelText: "Tahun*",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.blokC,
              decoration: InputDecoration(
                labelText: "Blok*",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.ambalanC,
              decoration: InputDecoration(
                labelText: "Ambalan*",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller.boxC,
              decoration: InputDecoration(
                labelText: "Box*",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            SizedBox(height: 8),
            Text(
              "*Wajib diisi",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
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
          child: Text("Batal"),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : (_isFormValid() ? _importDocument : null),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(),
                )
              : Text("Import"),
        ),
      ],
    );
  }
}

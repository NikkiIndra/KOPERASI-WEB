import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../helper/format_tanggal.dart';
import '../../../helper/google_drive_service.dart'; // IMPORT SERVICE
import '../controllers/dokumen_gudang_controller.dart';

class DokumenGudangView extends GetView<DokumenGudangController> {
  const DokumenGudangView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(
          left: 110,
          right: 24,
          top: 24,
          bottom: 24,
        ),
        child: Column(
          children: [
            // SEARCH + BUTTONS
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari Dokumen",
                      suffixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.only(
                        left: 24,
                        right: 50,
                        top: 0,
                        bottom: 0,
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) => controller.search.value = v,
                  ),
                ),

                // TOMBOL CONNECT GOOGLE DRIVE
                Obx(
                  () => IconButton(
                    onPressed: () {
                      if (controller.isDriveConnected.value) {
                        GoogleDriveService.logout();
                        controller.isDriveConnected.value = false;
                      } else {
                        controller.connectToDrive();
                      }
                    },
                    icon: Icon(
                      controller.isDriveConnected.value
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: controller.isDriveConnected.value
                          ? Colors.green
                          : Colors.grey,
                    ),
                    tooltip: controller.isDriveConnected.value
                        ? 'Terputus dari Google Drive'
                        : 'Sambung ke Google Drive',
                  ),
                ),

                const SizedBox(width: 12),

                // TOMBOL IMPORT (HANYA AKTIF JIKA TERHUBUNG DRIVE)
                Obx(() {
                  final isDriveConnected = controller.isDriveConnected.value;

                  return Tooltip(
                    message: isDriveConnected
                        ? "Import dokumen ke Google Drive"
                        : "Login Google Drive diperlukan. Klik icon awan di samping kiri untuk login.",
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDriveConnected
                            ? Colors.blue.shade700
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isDriveConnected
                          ? () => controller.openImportDialog()
                          : null,
                      icon: Icon(
                        Icons.upload_file,
                        color: isDriveConnected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                      ),
                      label: Text(
                        "Import Dokumen",
                        style: TextStyle(
                          color: isDriveConnected
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(width: 12),

                // TOMBOL TAMBAH DOKUMEN BIASA
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => controller.openAddDocumentDialog(),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Tambah Dokumen",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // TABLE
            Expanded(
              child: Obx(() {
                return DataTable2(
                  minWidth: 900,
                  columnSpacing: 24,
                  horizontalMargin: 12,
                  headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                  dataRowColor: WidgetStateProperty.all(Colors.purple.shade50),
                  columns: const [
                    DataColumn(label: Text("Nama Dokumen")),
                    DataColumn(label: Text("Update")),
                    DataColumn(label: Text("Batext")),
                    DataColumn(label: Text("Tipe")),
                    DataColumn(label: Text("Aksi")),
                  ],
                  rows: controller.filteredDocs.map((data) {
                    final docType = data['type'] ?? 'manual';
                    return DataRow(
                      cells: [
                        DataCell(
                          Tooltip(
                            message: data['name'],
                            child: Text(
                              data['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(formatTanggal(data['update']))),
                        DataCell(
                          Tooltip(
                            message: data['bantex'],
                            child: Text(
                              data['bantex'] ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // TIPE DOKUMEN
                        DataCell(
                          Chip(
                            label: Text(
                              docType == 'drive' ? 'Google Drive' : 'Manual',
                              style: TextStyle(
                                color: docType == 'drive'
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: docType == 'drive'
                                ? Colors.blue
                                : Colors.grey[300],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              // EDIT
                              IconButton(
                                onPressed: () {
                                  controller.titleC.text = data['name'] ?? '';
                                  controller.yearC.text = data['year'] ?? '';
                                  controller.bantexC.text =
                                      data['bantex'] ?? '';
                                  Get.dialog(
                                    editDokumenGudangDialog(data['id'], data),
                                  );
                                },
                                icon: const Tooltip(
                                  message: "Edit Dokumen",
                                  child: Icon(CupertinoIcons.pencil, size: 20),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // DOWNLOAD
                              IconButton(
                                onPressed: () {
                                  controller.downloadDocument(data);
                                },
                                icon: Tooltip(
                                  message: docType == 'drive'
                                      ? "Download dari Google Drive"
                                      : "Generate PDF",
                                  child: Icon(
                                    docType == 'drive'
                                        ? CupertinoIcons.cloud_download_fill
                                        : CupertinoIcons.arrow_down_doc_fill,
                                    size: 20,
                                    color: docType == 'drive'
                                        ? Colors.blue
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // DELETE
                              IconButton(
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: "Hapus?",
                                    middleText:
                                        "Yakin ingin menghapus dokumen ini?",
                                    textConfirm: "Hapus",
                                    textCancel: "Batal",
                                    onConfirm: () {
                                      controller.deleteDocument(data);
                                      Get.back();
                                    },
                                  );
                                },
                                icon: const Tooltip(
                                  message: "Hapus Dokumen",
                                  child: Icon(
                                    CupertinoIcons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget editDokumenGudangDialog(String id, Map<String, dynamic> data) {
    return AlertDialog(
      title: const Text("Edit Dokumen Gudang"),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.titleC,
              decoration: const InputDecoration(labelText: "Judul Dokumen"),
            ),
            TextField(
              controller: controller.yearC,
              decoration: const InputDecoration(labelText: "Tahun"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.bantexC,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Bantex",
                alignLabelWithHint: true,
              ),
            ),

            // INFO JIKA DOKUMEN ADA DI DRIVE
            if (data['type'] == 'drive') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Dokumen ini tersimpan di Google Drive",
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () async {
            await controller.updateDokumenGudang(id, data);
            controller.clearForm();
            Get.back();
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}

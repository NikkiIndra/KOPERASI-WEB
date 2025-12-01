import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../helper/format_tanggal.dart';
import '../../../helper/google_drive_service.dart';
import '../controllers/document_controller.dart';

class DocumentView extends GetView<DocumentController> {
  const DocumentView({super.key});

  @override
  Widget build(BuildContext context) {
    // controller.search.value = "";
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
                        print('Disconnected from Google Drive');
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

                SizedBox(width: 12),

                // TOMBOL IMPORT - hanya aktif jika terhubung ke Google Drive
                Obx(() {
                  final isDriveConnected = controller.isDriveConnected.value;

                  return Tooltip(
                    message: isDriveConnected
                        ? "Import dokumen ke Google Drive"
                        : "Klik icon awan di sebelah kiri untuk login ke Google Drive terlebih dahulu",
                    preferBelow: false, // Tooltip muncul di atas
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
                  dataRowColor: WidgetStateProperty.all(
                    Colors.purple.shade50, // ungu pastel
                  ),
                  columns: const [
                    DataColumn(label: Text("Nama Dokumen")),
                    DataColumn(label: Text("Update")),
                    DataColumn(label: Text("Blok")),
                    DataColumn(label: Text("Ambalan")),
                    DataColumn(label: Text("Box")),
                    DataColumn(label: Text("Aksi")),
                  ],
                  rows: controller.filteredDocs.map((data) {
                    return DataRow(
                      cells: [
                        // NAMA DOKUMEN (ellipsis + tooltip)
                        DataCell(
                          Tooltip(
                            message: data['name'],
                            child: Text(
                              data['name'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // UPDATE
                        DataCell(Text(formatTanggal(data['update']))),

                        // LOKASI
                        DataCell(Text("${data['blok']}")),
                        DataCell(Text("${data['ambalan']}")),
                        DataCell(Text("${data['box']}")),

                        // AKSI ICONS
                        DataCell(
                          Row(
                            children: [
                              // EDIT
                              // Di dalam DataRow, di bagian onPressed IconButton edit:
                              IconButton(
                                onPressed: () {
                                  // Mengambil data dari row saat ini
                                  final rowData = data;
                                  controller.titleC.text =
                                      rowData['name'] ?? '';
                                  controller.yearC.text = rowData['year'] ?? '';
                                  controller.blokC.text =
                                      rowData['blok']?.toString() ?? '';
                                  controller.ambalanC.text =
                                      rowData['ambalan']?.toString() ?? '';
                                  controller.boxC.text =
                                      rowData['box']?.toString() ?? '';
                                  controller.descC.text = rowData['desc'] ?? '';

                                  // Panggil dialog dengan passing id dan data
                                  Get.dialog(
                                    editDokumenKantorDialog(
                                      data['id'],
                                      rowData,
                                    ),
                                  );
                                },
                                icon: Tooltip(
                                  message: "Edit Dokumen",
                                  child: const Icon(
                                    CupertinoIcons.pencil,
                                    size: 20,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),
                              // Ganti tombol download yang lama dengan:
                              IconButton(
                                onPressed: () {
                                  controller.downloadDocument(data);
                                },
                                icon: Tooltip(
                                  message: data['type'] == 'imported'
                                      ? "Download File Asli"
                                      : data['type'] == 'drive'
                                      ? "Download dari Google Drive"
                                      : "Generate PDF",
                                  child: Icon(
                                    data['type'] == 'imported'
                                        ? CupertinoIcons.arrow_down_circle_fill
                                        : data['type'] == 'drive'
                                        ? CupertinoIcons.cloud_download_fill
                                        : CupertinoIcons.arrow_down_doc_fill,
                                    size: 20,
                                    color: data['type'] == 'drive'
                                        ? Colors.blue
                                        : null,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // DELETE firestore
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
                                icon: Tooltip(
                                  message: "Hapus Dokumen",
                                  child: const Icon(
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

  // Ganti fungsi editDokumenKantorDialog menjadi seperti ini:
  Widget editDokumenKantorDialog(String id, Map<String, dynamic> data) {
    return AlertDialog(
      title: const Text("Edit Dokumen kantor"),
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
            TextField(
              controller: controller.blokC,
              decoration: const InputDecoration(labelText: "Blok"),
            ),
            TextField(
              controller: controller.ambalanC,
              decoration: const InputDecoration(labelText: "Ambalan"),
            ),
            TextField(
              controller: controller.boxC,
              decoration: const InputDecoration(labelText: "Box"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descC,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Deskripsi Isi Dokumen",
                alignLabelWithHint: true,
              ),
            ),

            // Tampilkan info Google Drive jika dokumen ada di Drive
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
            await controller.updateDukumenKantor(id, data);
            controller.clearForm();
            Get.back();
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}

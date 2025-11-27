import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../helper/format_tanggal.dart';
import '../controllers/dokumen_gudang_controller.dart';

class DokumenGudangView extends GetView<DokumenGudangController> {
  const DokumenGudangView({super.key});

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
                    DataColumn(label: Text("Bantex")),
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
                        DataCell(
                          Tooltip(
                            message: data['name'],
                            child: Text(
                              data['bantex'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        // AKSI ICONS
                        DataCell(
                          Row(
                            children: [
                              // EDIT - Gunakan IconButton
                              IconButton(
                                onPressed: () {
                                  // Pastikan data tidak null sebelum mengakses
                                  if (data['name'] != null &&
                                      data['year'] != null &&
                                      data['bantex'] != null) {
                                    controller.titleC.text = data['name'] ?? '';
                                    controller.yearC.text = data['year'] ?? '';
                                    controller.bantexC.text =
                                        data['bantex'] ?? '';
                                    Get.dialog(
                                      editDokumenGudangDialog(data['id']),
                                    );
                                  } else {
                                    print(
                                        "Data dokumen tidak lengkap untuk diedit.");
                                  }
                                },
                                icon: Tooltip(
                                  message: "Edit Dokumen",
                                  child: const Icon(
                                    CupertinoIcons.pencil,
                                    size: 20,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              const SizedBox(width: 14),

                              // DOWNLOAD - Juga gunakan IconButton
                              IconButton(
                                onPressed: () {
                                  if (data['name'] != null &&
                                      data['year'] != null &&
                                      data['bantex'] != null) {
                                    controller.generatePDF(
                                      title: data['name']!,
                                      year: data['year']!,
                                      bantex: data['bantex']!,
                                    );
                                  }
                                },
                                icon: Tooltip(
                                  message: "Download Dokumen",
                                  child: const Icon(
                                    CupertinoIcons.arrow_down_doc_fill,
                                    size: 20,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),

                              const SizedBox(width: 14),

                              // DELETE - Gunakan IconButton
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
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
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

  Widget editDokumenGudangDialog(String id) {
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
                labelText: "Deskripsi Isi Dokumen",
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () async {
            await controller.updateDokumenGudang(id);
            controller.clearForm();
            Get.back();
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}

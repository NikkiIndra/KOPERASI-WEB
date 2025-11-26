import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../helper/format_tanggal.dart';
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
                        DataCell(
                          Text("${data['blok']}"),
                        ),
                        DataCell(
                          Text("${data['ambalan']}"),
                        ),
                        DataCell(
                          Text("${data['box']}"),
                        ),

                        // AKSI ICONS
                        DataCell(
                          Row(
                            children: [
                              // DOWNLOAD: generate PDF ulang
                              GestureDetector(
                                onTap: () {
                                  controller.generatePDF(
                                    title: data['name'],
                                    year: data['year'],
                                    blok: data['blok'],
                                    ambalan: data['ambalan'],
                                    box: data['box'],
                                    desc: data['desc'],
                                  );
                                },
                                child: Tooltip(
                                  message: "Download Dokumen",
                                  child: const Icon(
                                    CupertinoIcons.arrow_down_doc_fill,
                                    size: 20,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // DELETE firestore
                              GestureDetector(
                                onTap: () {
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
                                child: Tooltip(
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
}

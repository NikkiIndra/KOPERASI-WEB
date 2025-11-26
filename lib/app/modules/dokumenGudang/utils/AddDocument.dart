import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:koperasi/app/modules/dokumenGudang/controllers/dokumen_gudang_controller.dart';

class AddDocumentDialogGudang extends StatelessWidget {
  AddDocumentDialogGudang({super.key});
  final controller = Get.find<DokumenGudangController>();
  final titleC = TextEditingController();
  final yearC = TextEditingController(text: "2025");
  final bantexC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Tambah Dokumen"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: "Judul Dokumen"),
                onChanged: (_) => controller.validateForm(
                  titleC.text,
                  yearC.text,
                  bantexC.text,
                ),
              ),
              TextField(
                controller: yearC,
                decoration: const InputDecoration(labelText: "Tahun"),
                onChanged: (_) => controller.validateForm(
                  titleC.text,
                  yearC.text,
                  bantexC.text,
                ),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: bantexC,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Isi Dokumen",
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => controller.validateForm(
                  titleC.text,
                  yearC.text,
                  bantexC.text,
                ),
              ),

              const SizedBox(height: 22),

              // Button buat generate PDF placeholder
              // ElevatedButton.icon(
              //   onPressed: () {
              //     controller.generatePDF(
              //       title: titleC.text,
              //       year: yearC.text,
              //       rak: rakC.text,
              //       box: boxC.text,
              //       desc: descC.text,
              //     );
              //   },
              //   icon: const Icon(Icons.picture_as_pdf),
              //   label: const Text("Download Template PDF"),
              // ),
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(Get.context!).pop(),

          child: const Text("Batal"),
        ),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isFormValid.value
                ? () async {
                    await controller.saveDocument(
                      title: titleC.text,
                      year: yearC.text,
                      bantex: bantexC.text,
                    );

                    Navigator.of(Get.context!).pop();

                  }
                : null, // <-- disabled
            child: const Text("Simpan"),
          ),
        ),
      ],
    );
  }
}

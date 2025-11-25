import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/document_controller.dart';

class AddDocumentDialog extends StatelessWidget {
  AddDocumentDialog({super.key});
  final controller = Get.find<DocumentController>();
  final titleC = TextEditingController();
  final yearC = TextEditingController(text: "2025");
  final rakC = TextEditingController();
  final boxC = TextEditingController();
  final descC = TextEditingController();

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
                  rakC.text,
                  boxC.text,
                  descC.text,
                ),
              ),
              TextField(
                controller: yearC,
                decoration: const InputDecoration(labelText: "Tahun"),
                onChanged: (_) => controller.validateForm(
                  titleC.text,
                  yearC.text,
                  rakC.text,
                  boxC.text,
                  descC.text,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rakC,
                      decoration: const InputDecoration(labelText: "No Rak"),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => controller.validateForm(
                        titleC.text,
                        yearC.text,
                        rakC.text,
                        boxC.text,
                        descC.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: boxC,
                      decoration: const InputDecoration(labelText: "No Box"),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => controller.validateForm(
                        titleC.text,
                        yearC.text,
                        rakC.text,
                        boxC.text,
                        descC.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descC,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi Isi Dokumen",
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => controller.validateForm(
                  titleC.text,
                  yearC.text,
                  rakC.text,
                  boxC.text,
                  descC.text,
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
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        Obx(
          () => ElevatedButton(
            onPressed: controller.isFormValid.value
                ? () async {
                    final lokasi = "${rakC.text} / ${boxC.text}";
                    await controller.saveDocument(
                      title: titleC.text,
                      year: yearC.text,
                      rak: rakC.text,
                      box: boxC.text,
                      desc: descC.text,
                    );

                    Get.back();
                  }
                : null, // <-- disabled
            child: const Text("Simpan"),
          ),
        ),
      ],
    );
  }
}

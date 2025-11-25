import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../helper/format_tanggal.dart';
import '../controllers/nasabah_controller.dart';

class NasabahView extends GetView<NasabahController> {
  const NasabahView({super.key});

  @override
  Widget build(BuildContext context) {
    // final NasabahController c = Get.find<NasabahController>();
    // controller.search.value = "";
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(
          left: 100,
          right: 24,
          top: 24,
          bottom: 24,
        ),
        child: Column(
          children: [
            // SEARCH + BUTTON
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari Nasabah",
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
                const SizedBox(width: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Get.dialog(openAddNasabahDialog());
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Tambah Nasabah",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // TABLE
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("nasabah")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // Update list ke controller (TANPA LISTEN lagi)
                controller.nasabahList.value = docs.map((d) {
                  return {
                    "id": d.id,
                    "nama": d["nama"],
                    "nik": d["nik"],
                    "alamat": d["alamat"],
                    "telepon": d["telepon"],
                    "status": d["status"],
                    "update": d.data().containsKey("update")
                        ? d["update"]
                        : null, // aman!
                  };
                }).toList();

                return Expanded(
                  child: Obx(() {
                    return DataTable2(
                      columnSpacing: 24,
                      horizontalMargin: 12,
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey[200],
                      ),
                      dataRowColor: WidgetStateProperty.all(
                        const Color(0xFFF4EEFA),
                      ),
                      minWidth: 1300,
                      columns: const [
                        DataColumn(label: Text("Nama")),
                        DataColumn(label: Text("NIK")),
                        DataColumn(label: Text("Alamat")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("No HP")),
                        DataColumn(label: Text("Update")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: controller.filtered.map((e) {
                        return DataRow(
                          cells: [
                            // NAMA
                            DataCell(
                              Tooltip(
                                message: e['nama'],
                                child: Text(
                                  e['nama'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // NIK
                            DataCell(Text(e['nik'])),

                            // ALAMAT
                            DataCell(
                              Tooltip(
                                message: e['alamat'],
                                child: Text(
                                  e['alamat'],
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // STATUS
                            DataCell(statusBadge(e['status'])),

                            // HP
                            DataCell(Text(e['telepon'])),

                            // UPDATE TANGGAL
                            DataCell(
                              Text(
                                e['update'] == null
                                    ? "-"
                                    : formatTanggal(e['update']),
                              ),
                            ),

                            // AKSI
                            DataCell(
                              Row(
                                children: [
                                  // EDIT
                                  GestureDetector(
                                    onTap: () {
                                      controller.nameC.text = e['nama'];
                                      controller.nikC.text = e['nik'];
                                      controller.alamatC.text = e['alamat'];
                                      controller.telpC.text = e['telepon'];
                                      controller.status.value = e['status'];
                                      Get.dialog(editNasabahDialog(e['id']));
                                    },
                                    child: Tooltip(
                                      message: "Edit Nasabah",
                                      child: const Icon(Icons.edit, size: 20),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // DELETE
                                  GestureDetector(
                                    onTap: () {
                                      Get.defaultDialog(
                                        title: "Hapus Nasabah?",
                                        middleText:
                                            "Yakin ingin menghapus data ini?",
                                        textConfirm: "Hapus",
                                        textCancel: "Batal",
                                        onConfirm: () {
                                          controller.deleteNasabah(e['id']);
                                          Get.back();
                                        },
                                      );
                                    },
                                    child: Tooltip(
                                      message: "Hapus Nasabah",
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget editNasabahDialog(String id) {
    return AlertDialog(
      title: const Text("Edit Nasabah"),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.nameC,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: controller.nikC,
              decoration: const InputDecoration(labelText: "NIK"),
            ),
            TextField(
              controller: controller.alamatC,
              decoration: const InputDecoration(labelText: "Alamat"),
            ),
            TextField(
              controller: controller.telpC,
              decoration: const InputDecoration(labelText: "Telepon"),
            ),
            const SizedBox(height: 12),
            Obx(
              () => DropdownButtonFormField(
                initialValue: controller.status.value,
                items: controller.statusList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => controller.status.value = v!,
                decoration: const InputDecoration(labelText: "Status"),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () async {
            await controller.updateNasabah(id);
            controller.clearForm();
            Get.back();
          },
          child: const Text("Update"),
        ),
      ],
    );
  }

  Widget openAddNasabahDialog() {
    return AlertDialog(
      title: const Text("Tambah Nasabah"),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller.nameC,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: controller.nikC,
              decoration: const InputDecoration(labelText: "NIK"),
            ),
            TextField(
              controller: controller.alamatC,
              decoration: const InputDecoration(labelText: "Alamat"),
            ),
            TextField(
              controller: controller.telpC,
              decoration: const InputDecoration(labelText: "Telepon"),
            ),

            const SizedBox(height: 12),
            Obx(
              () => DropdownButtonFormField(
                initialValue: controller.status.value,
                items: controller.statusList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => controller.status.value = v!,
                decoration: const InputDecoration(labelText: "Status"),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            if (controller.nameC.text.isEmpty ||
                controller.nikC.text.isEmpty ||
                controller.alamatC.text.isEmpty ||
                controller.telpC.text.isEmpty) {
              Get.snackbar("Error", "Semua field wajib diisi");
              return;
            }

            FirebaseFirestore.instance.collection("nasabah").add({
              "nama": controller.nameC.text,
              "nik": controller.nikC.text,
              "alamat": controller.alamatC.text,
              "telepon": controller.telpC.text,
              "status": controller.status.value,
              "update": DateTime.now().toIso8601String(), // ✅ SIMPAN UPDATE
            });
            controller.clearForm();
            Get.back();
          },
          child: const Text("Simpan"),
        ),
      ],
    );
  }

  Widget statusBadge(String status) {
    Color bgColor;

    if (status == "Aktif") {
      bgColor = Colors.greenAccent;
    } else if (status == "Non-Aktif") {
      bgColor = Colors.orangeAccent;
    } else {
      bgColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status),
    );
  }
}

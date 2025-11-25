import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NasabahController extends GetxController {
  final search = ''.obs;

  final nameC = TextEditingController();
  final nikC = TextEditingController();
  final alamatC = TextEditingController();
  final telpC = TextEditingController();

  final status = "Aktif".obs;
  final statusList = ["Aktif", "Non-Aktif", "Diblokir"];

  final nasabahList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNasabah();
    search.value = "";
  }

  // ==================== LOAD FIRESTORE REALTIME ====================
  void loadNasabah() {
    FirebaseFirestore.instance.collection("nasabah").snapshots().listen((snap) {
      nasabahList.value = snap.docs.map((d) {
        final data = d.data();

        return {
          "id": d.id,
          "nama": data["nama"],
          "nik": data["nik"],
          "alamat": data["alamat"],
          "telepon": data["telepon"],
          "status": data["status"],
          "update": data["update"], // 🔥 aman meskipun null
        };
      }).toList();
    });
  }

  // ==================== CLEAR FORM ====================
  void clearForm() {
    nameC.clear();
    nikC.clear();
    alamatC.clear();
    telpC.clear();
    status.value = "Aktif";
  }

  // ==================== FILTER ====================
  List<Map<String, dynamic>> get filtered {
    if (search.value.isEmpty) return nasabahList;

    return nasabahList
        .where(
          (e) => e['nama'].toLowerCase().contains(search.value.toLowerCase()),
        )
        .toList();
  }

  // ==================== DELETE NASABAH ====================
  Future<void> deleteNasabah(String id) async {
    await FirebaseFirestore.instance.collection("nasabah").doc(id).delete();
  }

  // ==================== UPDATE NASABAH ====================
  Future<void> updateNasabah(String id) async {
    await FirebaseFirestore.instance.collection("nasabah").doc(id).update({
      "nama": nameC.text,
      "nik": nikC.text,
      "alamat": alamatC.text,
      "telepon": telpC.text,
      "status": status.value,
      "update": DateTime.now().toIso8601String(),
    });
  }
}

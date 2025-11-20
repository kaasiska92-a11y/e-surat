import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TambahSuratKeluar extends StatefulWidget {
  final Map<String, dynamic> editData;
  final String docId;

  const TambahSuratKeluar({
    super.key,
    required this.editData,
    required this.docId,
  });

  @override
  State<TambahSuratKeluar> createState() => _TambahSuratKeluarState();
}

class _TambahSuratKeluarState extends State<TambahSuratKeluar> {
  final TextEditingController nomorController = TextEditingController();
  final TextEditingController tujuanController = TextEditingController();
  final TextEditingController perihalController = TextEditingController();
  final TextEditingController linkSuratController = TextEditingController();

  DateTime? tanggalSurat;

  @override
  void initState() {
    super.initState();
    // Jika editData ada, isi controller dan tanggal
    if (widget.editData.isNotEmpty) {
      nomorController.text = widget.editData['nomor'] ?? '';
      tujuanController.text = widget.editData['tujuan'] ?? '';
      perihalController.text = widget.editData['perihal'] ?? '';
      linkSuratController.text = widget.editData['linkSurat'] ?? '';
      if (widget.editData['tanggalSurat'] != null &&
          widget.editData['tanggalSurat'] != "") {
        final parts = widget.editData['tanggalSurat'].split('-');
        if (parts.length == 3) {
          tanggalSurat = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.poppins(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _simpanSurat() async {
    if (nomorController.text.isEmpty ||
        tujuanController.text.isEmpty ||
        perihalController.text.isEmpty ||
        tanggalSurat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data terlebih dahulu!")),
      );
      return;
    }

    try {
      if (widget.docId.isEmpty) {
        // Tambah baru
        await FirebaseFirestore.instance.collection("surat_keluar").add({
          "nomor": nomorController.text,
          "tujuan": tujuanController.text,
          "perihal": perihalController.text,
          "linkSurat": linkSuratController.text,
          "tanggalSurat":
              "${tanggalSurat!.year}-${tanggalSurat!.month}-${tanggalSurat!.day}",
          "createdAt": FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing
        await FirebaseFirestore.instance
            .collection("surat_keluar")
            .doc(widget.docId)
            .update({
              "nomor": nomorController.text,
              "tujuan": tujuanController.text,
              "perihal": perihalController.text,
              "linkSurat": linkSuratController.text,
              "tanggalSurat":
                  "${tanggalSurat!.year}-${tanggalSurat!.month}-${tanggalSurat!.day}",
            });
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Surat berhasil disimpan")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menyimpan surat: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          widget.docId.isEmpty ? "Tambah Surat Keluar" : "Edit Surat Keluar",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Nomor Surat", nomorController),

            // Tanggal Surat
            Text(
              "Tanggal Surat",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: tanggalSurat ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    tanggalSurat = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: tanggalSurat != null ? Colors.blue : Colors.grey,
                    width: tanggalSurat != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tanggalSurat != null
                          ? "${tanggalSurat!.day}-${tanggalSurat!.month}-${tanggalSurat!.year}"
                          : "Pilih Tanggal",
                      style: GoogleFonts.poppins(color: Colors.black),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField("Tujuan", tujuanController),
            _buildTextField("Perihal", perihalController),
            _buildTextField("Link Surat", linkSuratController),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simpanSurat,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  "Simpan",
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

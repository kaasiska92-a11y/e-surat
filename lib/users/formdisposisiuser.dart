import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class FormDisposisiUser extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String noSurat;
  final String nomorSurat;
  final String asalSurat;
  final String perihal;

  const FormDisposisiUser({
    super.key,
    required this.docId,
    required this.data,
    required this.noSurat,
    required this.nomorSurat,
    required this.asalSurat,
    required this.perihal,
    required String uidUser,
  });

  @override
  State<FormDisposisiUser> createState() => _FormDisposisiUserState();
}

class _FormDisposisiUserState extends State<FormDisposisiUser> {
  final TextEditingController catatanController = TextEditingController();
  bool loading = false;

  String? currentUserId;
  String? namaUser;
  String? jabatanUser;

  String? tindakanSelanjutnya;
  String? penerimaId;
  String? penerimaNama;
  String? penerimaJabatan;

  bool sudahDisposisi = false;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _getCurrentUserData();
    _cekSudahDisposisi();
  }

  Future<void> _getCurrentUserData() async {
    if (currentUserId == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        namaUser = data['nama'];
        jabatanUser = data['jabatan'];
      });
    }
  }

  Future<void> _cekSudahDisposisi() async {
    if (currentUserId == null) return;

    final q =
        await FirebaseFirestore.instance
            .collection('disposisi')
            .where('surat_masuk_id', isEqualTo: widget.docId)
            .where('pengirim_uid', isEqualTo: currentUserId)
            .get();

    setState(() {
      sudahDisposisi = q.docs.isNotEmpty;
    });
  }

  Future<void> _kirimDisposisi() async {
  if (sudahDisposisi) return;

  if (catatanController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Isi pesan disposisi terlebih dahulu!")),
    );
    return;
  }

  if (tindakanSelanjutnya == "Teruskan Disposisi" && penerimaId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Pilih penerima disposisi!")),
    );
    return;
  }

  setState(() => loading = true);

  try {
    // 1️⃣ SIMPAN DATA DISPOSISI UTAMA
    DocumentReference dispoRef =
        await FirebaseFirestore.instance.collection('disposisi').add({
      'surat_masuk_id': widget.docId,
      'pengirim_uid': currentUserId,
      'nama': namaUser,
      'jabatan': jabatanUser,
      'penerima_uid': penerimaId,
      'catatan': catatanController.text,
      'tindakan_selanjutnya': tindakanSelanjutnya,
      'created_at': Timestamp.now(),
      'sudahDibaca': false,
      'sudahDisposisi': true,
    });

    // 2️⃣ SIMPAN KE SUBCOLLECTION RIWAYAT
    await dispoRef.collection('riwayat').add({
      'pengirim_uid': currentUserId,
      'nama': namaUser,
      'jabatan': jabatanUser,
      'penerima_uid': penerimaId,
      'catatan': catatanController.text,
      'tindakan_selanjutnya': tindakanSelanjutnya,
      'timestamp': Timestamp.now(),
    });

    // Pesan sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Disposisi berhasil dikirim")),
    );

    setState(() {
      sudahDisposisi = true;
      loading = false;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal mengirim disposisi: $e")),
    );
    setState(() => loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Disposisi Surat",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child:
            sudahDisposisi
                ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Anda sudah mengirim disposisi untuk surat ini.\nTidak bisa mengirim lagi.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.green.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pesan Disposisi",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: catatanController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Tulis pesan disposisi...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tindakan Selanjutnya",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: tindakanSelanjutnya,
                        onChanged: (val) {
                          setState(() {
                            tindakanSelanjutnya = val;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "Teruskan Disposisi",
                            child: Text("Teruskan Disposisi"),
                          ),
                          DropdownMenuItem(
                            value: "Selesai",
                            child: Text("Selesai"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (tindakanSelanjutnya == "Teruskan Disposisi") ...[
                      Text(
                        "Pilih Penerima Disposisi",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .where('role', isEqualTo: 'user')
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final users =
                              snapshot.data!.docs
                                  .where((d) => d.id != currentUserId)
                                  .toList();

                          if (users.isEmpty) {
                            return Text(
                              "Tidak ada user lain untuk menerima disposisi.",
                              style: GoogleFonts.poppins(color: Colors.red),
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: penerimaId,
                                hint: const Text("Pilih penerima"),
                                onChanged: (val) {
                                  final data =
                                      users
                                              .firstWhere((u) => u.id == val)
                                              .data()
                                          as Map<String, dynamic>;
                                  setState(() {
                                    penerimaId = val;
                                    penerimaNama = data['nama'];
                                    penerimaJabatan = data['jabatan'];
                                  });
                                },
                                items:
                                    users.map((d) {
                                      final data =
                                          d.data() as Map<String, dynamic>;
                                      return DropdownMenuItem(
                                        value: d.id,
                                        child: Text(
                                          "${data['nama']} - ${data['jabatan']}",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : _kirimDisposisi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            loading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  "KIRIM DISPOSISI",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
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

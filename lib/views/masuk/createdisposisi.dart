import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuatDisposisiPage extends StatefulWidget {
  final String noSurat;

  const BuatDisposisiPage({
    super.key,
    required this.noSurat,
    required String idSurat,
    required String namaSurat,
    required String jabatanSurat,
  });

  @override
  State<BuatDisposisiPage> createState() => _BuatDisposisiPageState();
}

class _BuatDisposisiPageState extends State<BuatDisposisiPage> {
  List<Map<String, dynamic>> penerimaList = [];
  Map<String, dynamic>? penerima;
  bool loading = false;
  bool sudahDidisposisi = false;

  @override
  void initState() {
    super.initState();
    checkExistingDisposisi();
    getPenerimaList();
  }

  /// Cek apakah surat sudah didisposisi
  Future<void> checkExistingDisposisi() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('disposisi')
              .where('nomor', isEqualTo: widget.noSurat)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          sudahDidisposisi = true;
        });
      }
    } catch (e) {
      print('Error checking disposisi: $e');
    }
  }

  /// Ambil daftar penerima (role user)
  Future<void> getPenerimaList() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> data =
          snapshot.docs
              .map((doc) {
                final user = doc.data();
                if (user['role'] == 'user') {
                  return {
                    'uid': doc.id,
                    'nama': user['nama'] ?? '',
                    'jabatan': user['jabatan'] ?? '',
                  };
                }
                return null;
              })
              .where((e) => e != null)
              .cast<Map<String, dynamic>>()
              .toList();

      setState(() {
        penerimaList = data;
      });
    } catch (e) {
      print('Error loading penerima list: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal memuat data penerima: $e")));
    }
  }

  /// Simpan disposisi
  Future<void> _simpanDisposisi() async {
  if (penerima == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Harap pilih penerima!")));
    return;
  }

  setState(() => loading = true);

  try {
    // Ambil surat berdasarkan nomor
    final suratQuery = await FirebaseFirestore.instance
        .collection('surat_masuk')
        .where('nomor', isEqualTo: widget.noSurat)
        .limit(1)
        .get();

    if (suratQuery.docs.isEmpty) {
      throw "Surat tidak ditemukan!";
    }

    // Id surat_masuk
    final suratId = suratQuery.docs.first.id;

    // Referensi disposisi dengan ID YANG SAMA
    final disposisiRef =
        FirebaseFirestore.instance.collection('disposisi').doc(suratId);

    // Cek apakah disposisi sudah ada
    final cek = await disposisiRef.get();
    if (cek.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Surat ini sudah didisposisi.")),
      );
      setState(() => loading = false);
      return;
    }

    // Buat disposisi baru
    await disposisiRef.set({
      'nomor': widget.noSurat,
      'penerima_uid': penerima!['uid'],
      'nama': penerima!['nama'],
      'jabatan': penerima!['jabatan'],
      'created_at': Timestamp.now(),
      'sudahDisposisi': false,
    });

    // Update status surat_masuk
    await suratQuery.docs.first.reference.update({
      'sudahDisposisi': true,
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Disposisi berhasil dibuat!")));

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Gagal menyimpan disposisi: $e")));
  }

  setState(() => loading = false);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Buat Disposisi",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body:
          penerimaList.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pilih Penerima Disposisi",
                      style: GoogleFonts.poppins(),
                    ),
                    const SizedBox(height: 6),
                    sudahDidisposisi
                        ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Surat sudah didisposisi. Tidak dapat diteruskan lagi.",
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                          isExpanded: true,
                          value: penerima,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                          items:
                              penerimaList.map((item) {
                                return DropdownMenuItem<Map<String, dynamic>>(
                                  value: item,
                                  child: Text(
                                    "${item['jabatan']} - ${item['nama']}",
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              penerima = value;
                            });
                          },
                        ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              sudahDidisposisi ? Colors.grey : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send, color: Colors.white),
                        label:
                            loading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  "Kirim Disposisi",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        onPressed:
                            (sudahDidisposisi || loading)
                                ? null
                                : _simpanDisposisi,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

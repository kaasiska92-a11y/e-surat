import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manejemen_surat/views/disposisi_masuk/detaildisposisi.dart';

class DisposisiSuratMasuk extends StatefulWidget {
  const DisposisiSuratMasuk({super.key});

  @override
  State<DisposisiSuratMasuk> createState() => _DisposisiSuratMasukState();
}

class _DisposisiSuratMasukState extends State<DisposisiSuratMasuk> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),

      // 🔥 Tambahkan SafeArea AGAR SEARCH BAR TIDAK MELEKAT KE ATAS
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildDisposisiList()),
          ],
        ),
      ),
    );
  }

  // 🔹 Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: "Cari disposisi berdasarkan nomor, asal, atau perihal...",
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[500],
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 4),
              child: const Icon(Icons.search_rounded, color: Colors.blueAccent),
            ),
            suffixIcon:
                searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchQuery = "");
                      },
                    )
                    : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.blue.shade100, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.blue, width: 1.8),
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 StreamBuilder daftar disposisi
  Widget _buildDisposisiList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('surat_masuk')
              .orderBy('created_at', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔍 Filter: hanya yang sudah disposisi dan sesuai pencarian
        final docs =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sudahDisposisi = data['sudahDisposisi'] ?? false;
              if (!sudahDisposisi) return false;

              final query = searchQuery.toLowerCase();
              return (data['nomor'] ?? '').toString().toLowerCase().contains(
                    query,
                  ) ||
                  (data['asal'] ?? '').toString().toLowerCase().contains(
                    query,
                  ) ||
                  (data['perihal'] ?? '').toString().toLowerCase().contains(
                    query,
                  );
            }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text("Belum ada disposisi"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _DisposisiCard(docId: doc.id, data: data);
          },
        );
      },
    );
  }

  // 🔹 Fungsi buat disposisi baru
  Future<void> buatDisposisi({
    required String nomorSurat,
    required String penerimaNama,
    required String penerimaJabatan,
    required String penerimaUid,
  }) async {
    try {
      final disposisiRef = FirebaseFirestore.instance.collection('disposisi');

      await disposisiRef.add({
        'nomor': nomorSurat,
        'penerima_nama': penerimaNama,
        'penerima_jabatan': penerimaJabatan,
        'penerima_uid': penerimaUid,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'baru',
      });

      final suratRef = FirebaseFirestore.instance.collection('surat_masuk');
      final query = await suratRef.where('nomor', isEqualTo: nomorSurat).get();

      for (var doc in query.docs) {
        await doc.reference.update({'sudahDisposisi': true});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Disposisi berhasil dibuat untuk $penerimaNama"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membuat disposisi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// 🔹 CARD DISPOSISI
class _DisposisiCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _DisposisiCard({required this.docId, required this.data});

  Future<void> _hapusDisposisi(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "Hapus Disposisi?",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Text(
              "Yakin ingin menghapus disposisi ini? Data disposisi akan dihapus, dan surat akan kembali ke status belum disposisi.",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Batal",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text(
                  "Hapus",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final disposisiQuery =
            await FirebaseFirestore.instance
                .collection('disposisi')
                .where('nomor', isEqualTo: data['nomor'])
                .get();

        for (var doc in disposisiQuery.docs) {
          await doc.reference.delete();
        }

        await FirebaseFirestore.instance
            .collection('surat_masuk')
            .doc(docId)
            .update({'sudahDisposisi': false});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Disposisi berhasil dihapus"),
            backgroundColor: Colors.redAccent,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghapus disposisi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final noUrut = data['no_urut'] ?? '-';
    final nomor = data['nomor'] ?? '-';
    final asal = data['asal'] ?? '-';
    final perihal = data['perihal'] ?? '-';
    final tanggal = data['tanggal_penerimaan'] ?? '-';
    final sudahDisposisi = data['sudahDisposisi'] ?? false;
    final sudahDibaca = data['sudahDibaca'] ?? false;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailDisposisi(docId: docId, data: data),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$noUrut. $nomor",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'hapus') _hapusDisposisi(context);
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'hapus',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Hapus",
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    asal,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    perihal,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tanggal Penerimaan: $tanggal",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: sudahDisposisi ? Colors.orange : Colors.blue,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sudahDisposisi ? "Sudah Disposisi" : "Belum Disposisi",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: sudahDisposisi ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!sudahDibaca)
            Positioned(
              top: 8,
              right: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Baru",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manejemen_surat/users/detaildisposisi.user.dart';

class DisposisiUser extends StatefulWidget {
  final String namaUser;
  final String jabatanUser;

  const DisposisiUser({
    super.key,
    required this.namaUser,
    required this.jabatanUser,
    required String uidUser,
  });

  @override
  State<DisposisiUser> createState() => _DisposisiUserState();
}

class _DisposisiUserState extends State<DisposisiUser> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  bool showAntrian = true; // Tab aktif
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildTabBar(),
            const SizedBox(height: 8),
            Expanded(child: _buildDisposisiList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Cari disposisi...",
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.blueAccent,
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
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tabButton("Antrian", showAntrian),
          const SizedBox(width: 10),
          _tabButton("History", !showAntrian),
        ],
      ),
    );
  }

  Widget _tabButton(String text, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => showAntrian = (text == "Antrian")),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.blue, width: 1.5),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: active ? Colors.white : Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisposisiList() {
    final disposisiStream =
        FirebaseFirestore.instance
            .collection('disposisi')
            .where('penerima_uid', isEqualTo: currentUserId)
            .orderBy('created_at', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: disposisiStream,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        final docs =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final createdAt = (data['created_at'] as Timestamp?)?.toDate();

              // Filter berdasarkan nama dan jabatan user
              if ((data['nama'] ?? '') != widget.namaUser ||
                  (data['jabatan'] ?? '') != widget.jabatanUser) {
                return false;
              }

              // Filter tab: Antrian = created_at > 7 hari lalu, History = created_at <= 7 hari lalu
              if (showAntrian) {
                if (createdAt == null ||
                    createdAt.isBefore(sevenDaysAgo) ||
                    createdAt.isAtSameMomentAs(sevenDaysAgo)) {
                  return false;
                }
              } else {
                if (createdAt == null || createdAt.isAfter(sevenDaysAgo)) {
                  return false;
                }
              }

              // Filter search
              final query = searchQuery.toLowerCase();
              return (data['nomor'] ?? '').toLowerCase().contains(query) ||
                  (data['nama'] ?? '').toLowerCase().contains(query);
            }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Text(
              showAntrian
                  ? "Tidak ada disposisi antrian"
                  : "Belum ada riwayat disposisi",
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final disposisi = docs[index].data() as Map<String, dynamic>;
            final nomor = disposisi['nomor'] ?? '-';

            return FutureBuilder<QuerySnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('surat_masuk')
                      .where('nomor', isEqualTo: nomor)
                      .limit(1)
                      .get(),
              builder: (context, suratSnapshot) {
                if (!suratSnapshot.hasData) return const SizedBox();
                if (suratSnapshot.data!.docs.isEmpty) return const SizedBox();

                final surat =
                    suratSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                final mergedData = {...surat, ...disposisi};

                return _DisposisiCardUser(
                  docId: docs[index].id,
                  data: mergedData,
                  noUrut: mergedData['no_urut']?.toString() ?? '-',
                  nomor: mergedData['nomor'] ?? '-',
                  asal: mergedData['asal'] ?? '-',
                  perihal: mergedData['perihal'] ?? '-',
                  tanggal: mergedData['tanggal_penerimaan'] ?? '-',
                  namaTujuan: mergedData['nama'] ?? '-',
                  jabatanTujuan: mergedData['jabatan'] ?? '-',
                );
              },
            );
          },
        );
      },
    );
  }
}

// Card Disposisi User (UI sama seperti kode awal)
class _DisposisiCardUser extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String noUrut;
  final String nomor;
  final String asal;
  final String perihal;
  final String tanggal;
  final String namaTujuan;
  final String jabatanTujuan;

  const _DisposisiCardUser({
    required this.docId,
    required this.data,
    required this.noUrut,
    required this.nomor,
    required this.asal,
    required this.perihal,
    required this.tanggal,
    required this.namaTujuan,
    required this.jabatanTujuan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: nomor + titik 3
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "$noUrut. $nomor",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                asal,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 2),
              Text(
                perihal,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Tanggal Penerimaan: $tanggal",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tujuan: $namaTujuan ($jabatanTujuan)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DetailDisposisiUser(
                    docId: docId,
                    data: data,
                    noUrut: noUrut,
                    nomor: nomor,
                    asal: asal,
                    perihal: perihal,
                    tanggal: tanggal,
                    tanggalPenerimaan: '',
                    jabatanUser: '',
                    namaUser: '',
                    tanggalSurat: '',
                  ),
            ),
          );
        },
      ),
    );
  }
}

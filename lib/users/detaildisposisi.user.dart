import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manejemen_surat/users/formdisposisiuser.dart';

class DetailDisposisiUser extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const DetailDisposisiUser({
    super.key,
    required this.data,
    required this.docId,
    required String noUrut,
    required nomor,
    required asal,
    required perihal,
    required tanggal,
    required String tanggalPenerimaan,
    required String jabatanUser,
    required String namaUser,
    required String tanggalSurat,
  });

  @override
  State<DetailDisposisiUser> createState() => _DetailDisposisiUserState();
}

class _DetailDisposisiUserState extends State<DetailDisposisiUser> {
  String? jabatan;
  String? nama;
  String? catatan;
  bool sudahDisposisi = false;

  @override
  void initState() {
    super.initState();
    _getDisposisiData();
  }

  Future<void> _getDisposisiData() async {
    try {
      // Ambil dokumen disposisi berdasarkan ID (karena Anda sudah menyamakan ID disposisi == ID surat masuk)
      final docSnap =
          await FirebaseFirestore.instance
              .collection('disposisi')
              .doc(widget.docId)
              .get();

      if (docSnap.exists) {
        final disposisiData = docSnap.data()!;
        setState(() {
          nama = disposisiData['nama'] ?? disposisiData['penerima_nama'] ?? '-';
          jabatan =
              disposisiData['jabatan'] ??
              disposisiData['penerima_jabatan'] ??
              '-';
          catatan = disposisiData['catatan'] ?? 'Belum ada catatan disposisi';
          sudahDisposisi = true;
        });
      } else {
        // belum ada disposisi untuk surat ini
        setState(() {
          nama = '-';
          jabatan = '-';
          catatan = 'Belum ada catatan disposisi';
          sudahDisposisi = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error ambil data disposisi: $e");
    }
  }

  // 🔹 Fungsi membuka file
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak dapat membuka: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final lampiran = data['lampiran_surat'];

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Detail Disposisi",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,

        // 🔹 Button untuk membuat disposisi
        actions: [
          IconButton(
            icon: Icon(
              Icons.mark_unread_chat_alt_rounded, // ikon formulir disposisi
              color: sudahDisposisi ? Colors.grey.shade300 : Colors.white,
              size: 26,
            ),
            tooltip: "Buat Disposisi",

            // 🔒 Sekarang selalu bisa diklik
            onPressed: () {
              // debug: cetak dulu agar yakin docId yang dipakai benar
              debugPrint(
                "Navigasi ke FormDisposisiUser dengan docId (surat/disposisi): ${widget.docId}",
              );

              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder:
                      (_, __, ___) => FormDisposisiUser(
                        docId:
                            widget
                                .docId, // <-- PENTING: kirim ID surat_masuk (sama dengan id disposisi)
                        data: data, // data yang Anda punya (opsional)
                        noSurat: data['no_urut']?.toString() ?? '',
                        nomorSurat: data['nomor'] ?? '',
                        asalSurat: data['asal'] ?? '',
                        perihal: data['perihal'] ?? '',
                        // hapus atau isi uidUser jika diperlukan oleh constructor
                        uidUser: '',
                      ),
                  transitionsBuilder: (context, animation, secondary, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    final tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: Curves.easeInOut));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              ).then((_) => _getDisposisiData());
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.info_outline, "Informasi Surat"),
            _animatedCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildItem("Nomor Surat", data['nomor']),
                  buildItem("Tanggal Terima", data['tanggal_penerimaan']),
                  buildItem("Tanggal Surat", data['tanggal_surat']),
                  buildItem("Asal Surat", data['asal']),
                  buildItem("Sifat Surat", data['sifat']),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle(Icons.description_outlined, "Perihal & Lampiran"),
            _animatedCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Perihal",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['perihal'] ?? "-",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 14),

                  if (lampiran != null && lampiran.toString().isNotEmpty)
                    InkWell(
                      onTap: () async {
                        try {
                          await _launchURL(lampiran);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Gagal membuka lampiran: $e"),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.red,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                lampiran,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.blue.shade700,
                                  decoration: TextDecoration.underline,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Text(
                      "Tidak ada lampiran surat",
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _sectionTitle(
              Icons.history_toggle_off_rounded,
              "Riwayat Disposisi",
            ),
            const SizedBox(height: 12),

            // 🔹 List Riwayat Subcollection
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("disposisi")
                      .doc(widget.docId)
                      .collection("riwayat")
                      .orderBy("timestamp", descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      "Belum ada riwayat disposisi lainnya.",
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return Column(
                  children:
                      snapshot.data!.docs.map((doc) {
                        final riwayat = doc.data() as Map<String, dynamic>;

                        return _animatedCard(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${riwayat['jabatan'] ?? '-'} - ${riwayat['nama'] ?? '-'}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                riwayat['catatan'] ?? '-',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Tindakan: ${riwayat['tindakan_selanjutnya'] ?? '-'}",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Waktu: ${riwayat['timestamp'] != null ? riwayat['timestamp'].toDate() : '-'}",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Helper Widgets
  Widget buildItem(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "-",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCard(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _boxDecoration(),
            child: child,
          ),
        );
      },
    );
  }
}

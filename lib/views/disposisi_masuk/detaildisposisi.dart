import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailDisposisi extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const DetailDisposisi({super.key, required this.data, required this.docId});

  @override
  State<DetailDisposisi> createState() => _DetailDisposisiState();
}

class _DetailDisposisiState extends State<DetailDisposisi> {
  String? jabatan;
  String? nama;
  String? pesan;

  @override
  void initState() {
    super.initState();
    _getDisposisiData();
  }

  /// 🔹 Ambil data dari collection `disposisi` berdasarkan nomor surat
  Future<void> _getDisposisiData() async {
    try {
      final disposisiQuery =
          await FirebaseFirestore.instance
              .collection('disposisi')
              .where('nomor', isEqualTo: widget.data['nomor'])
              .get();

      if (disposisiQuery.docs.isNotEmpty) {
        final disposisiData = disposisiQuery.docs.first.data();

        setState(() {
          nama = disposisiData['nama'] ?? '-';
          jabatan = disposisiData['jabatan'] ?? '-';
          pesan = disposisiData['pesan'] ?? 'Belum ada pesan disposisi';
        });
      } else {
        setState(() {
          nama = '-';
          jabatan = '-';
          pesan = 'Belum ada pesan disposisi';
        });
      }
    } catch (e) {
      debugPrint('Error ambil data disposisi: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Tidak dapat membuka: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        shadowColor: Colors.black26,
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

                  InkWell(
                    onTap: () {
                      final link = data['lampiran_surat'];
                      if (link != null && link.isNotEmpty) {
                        _launchURL(link);
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
                              data['lampiran_surat'] ?? '',
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

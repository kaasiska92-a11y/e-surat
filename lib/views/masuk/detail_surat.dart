import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manejemen_surat/views/masuk/createdisposisi.dart';
import 'package:manejemen_surat/views/masuk/webview.dart';
import 'package:manejemen_surat/models/surat.dart';
import 'package:manejemen_surat/views/masuk/edit_surat.dart';

class DetailSurat extends StatelessWidget {
  final Surat surat;

  const DetailSurat({super.key, required this.surat});

  Future<void> _openLink(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka link surat.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F1FF),
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 3,
        shadowColor: Colors.blue.shade200,
        title: Text(
          "Detail Surat Masuk",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              title: "Informasi Surat",
              icon: Icons.info_outline,
              children: [
                _buildDetailRow("Nomor Surat", surat.nomor),
                _buildDetailRow("Tanggal Terima", surat.tanggal_penerimaan),
                _buildDetailRow("Tanggal Surat", surat.tanggalSurat),
                _buildDetailRow("Asal Surat", surat.asal),
                _buildDetailRow(
                  "Sifat Surat",
                  (surat.sifat != null && surat.sifat!.isNotEmpty)
                      ? surat.sifat!
                      : "-",
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: "Perihal",
              icon: Icons.subject,
              children: [
                Text(surat.perihal, style: GoogleFonts.poppins(fontSize: 14.5)),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: "Lampiran Surat",
              icon: Icons.picture_as_pdf,
              children: [
                surat.lampiranSurat != null && surat.lampiranSurat!.isNotEmpty
                    ? GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => WebViewPage(url: surat.lampiranSurat!),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                surat.lampiranSurat!,
                                style: GoogleFonts.poppins(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                                softWrap: true, // wrap panjang ke bawah
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    )
                    : Text(
                      "Tidak ada lampiran.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),

            if (surat.linkSurat != null && surat.linkSurat!.isNotEmpty)
              _buildSectionCard(
                title: "Link Surat",
                icon: Icons.link,
                children: [
                  InkWell(
                    onTap: () => _openLink(context, surat.linkSurat!),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              surat.linkSurat!,
                              style: GoogleFonts.poppins(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                              softWrap: true, // wrap panjang ke bawah
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: Text(
                      "Edit",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditSuratMasuk(surat: surat),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      surat.sudahDisposisi
                          ? "Sudah Disposisi"
                          : "Buat Disposisi",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          surat.sudahDisposisi
                              ? Colors.grey.shade400
                              : Colors.blue.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed:
                        surat.sudahDisposisi
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BuatDisposisiPage(
                                        noSurat: surat.nomor,
                                        idSurat: '',
                                        namaSurat: '',
                                        jabatanSurat: '',
                                      ),
                                ),
                              );
                            },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade900,
              ),
              softWrap: true, // wrap panjang ke bawah
            ),
          ),
        ],
      ),
    );
  }
}

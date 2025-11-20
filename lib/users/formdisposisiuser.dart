import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    required String
    uidUser, // Note: Parameter ini tidak digunakan di kode, tapi tetap disertakan sesuai asli
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

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _getCurrentUserData();
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

  Future<void> _kirimDisposisi() async {
    // Tambahkan logging untuk debug
    print(
      'Attempting to send disposisi. Tindakan: $tindakanSelanjutnya, Penerima: $penerimaId',
    );

    if (catatanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi pesan disposisi terlebih dahulu!")),
      );
      return;
    }

    if (tindakanSelanjutnya == "Teruskan Disposisi" && penerimaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih penerima disposisi terlebih dahulu!"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (tindakanSelanjutnya == "Teruskan Disposisi") {
        await FirebaseFirestore.instance.collection('disposisi').add({
          'surat_masuk_id': widget.docId,
          'pengirim_uid': currentUserId,
          'pengirim_nama': namaUser,
          'pengirim_jabatan': jabatanUser,
          'penerima_uid': penerimaId,
          'penerima_nama': penerimaNama,
          'penerima_jabatan': penerimaJabatan,
          'catatan': catatanController.text,
          'created_at': Timestamp.now(),
          'sudahDibaca': false,
          'sudahDisposisi': false,
        });

        print('Disposisi forwarded successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Disposisi berhasil diteruskan")),
        );
      } else if (tindakanSelanjutnya == "Selesai") {
        await FirebaseFirestore.instance
            .collection('surat_masuk')
            .doc(widget.docId)
            .update({'sudahDisposisi': true, 'updated_at': Timestamp.now()});

        print('Disposisi marked as completed.');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Disposisi selesai")));
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('Error sending disposisi: $e'); // Logging error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengirim disposisi: $e")));
    } finally {
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
          // Tambahkan ikon kembali (jika ini "logo" yang dimaksud)
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pesan Disposisi
            Text(
              "Pesan Disposisi",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: catatanController,
              maxLines: 3,
              cursorColor: Colors.blue,
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

            // Tindakan Selanjutnya
            Text(
              "Tindakan Selanjutnya",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: tindakanSelanjutnya,
              onChanged: (val) {
                setState(() {
                  tindakanSelanjutnya = val;
                  if (val == "Selesai") {
                    penerimaId = null;
                    penerimaNama = null;
                    penerimaJabatan = null;
                  }
                });
              },
              items: const [
                DropdownMenuItem(
                  value: "Teruskan Disposisi",
                  child: Text("Teruskan Disposisi"),
                ),
                DropdownMenuItem(value: "Selesai", child: Text("Selesai")),
              ],
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pilih Penerima Disposisi hanya muncul jika "Teruskan"
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
                        .where('role', isEqualTo: 'user') // Hanya role user
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter untuk mengecualikan akun yang sedang login
                  final users =
                      snapshot.data!.docs
                          .where((d) => d.id != currentUserId)
                          .toList();

                  // Tambahkan penanganan jika users kosong
                  if (users.isEmpty) {
                    return Text(
                      "Tidak ada penerima tersedia. Tambahkan user lain dengan role 'user'.",
                      style: GoogleFonts.poppins(color: Colors.red),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: penerimaId,
                    onChanged: (val) {
                      final user =
                          users.firstWhere((u) => u.id == val).data()
                              as Map<String, dynamic>;
                      setState(() {
                        penerimaId = val;
                        penerimaNama = user['nama'];
                        penerimaJabatan = user['jabatan'];
                      });
                    },
                    items:
                        users.map((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              "${data['nama']} - ${data['jabatan']}",
                              style: GoogleFonts.poppins(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Tombol Kirim
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
                            strokeWidth: 2,
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

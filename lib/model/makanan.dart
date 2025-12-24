class Makanan {
  final String namaMakanan;
  final double energi;
  final DateTime waktu;

  Makanan({
    required this.namaMakanan,
    required this.energi,
    required this.waktu,
  });

  factory Makanan.fromJson(Map<String, dynamic> json) {
    return Makanan(
      namaMakanan: json['nama_makanan'],
      energi: double.parse(json['energi']),
      waktu: DateTime.parse(json['waktu']),
    );
  }
}

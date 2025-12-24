class UserData {
  final int idUser;
  final String username;
  final String jabatan;
  final String nama;
  final String tglLahir;
  final String tinggiBadan; // Mengubah tipe data menjadi int
  final String beratBadan;
  final String alamat;
  final String kecamatan;
  final String kabupaten;
  final String provinsi;
  final String jekel;
  final String noTelp;
  final String tglDaftar;
  final String email;
  final String umur;

  UserData(
      {required this.idUser,
      required this.username,
      required this.jabatan,
      required this.nama,
      required this.tglLahir,
      required this.tinggiBadan,
      required this.beratBadan,
      required this.alamat,
      required this.kecamatan,
      required this.kabupaten,
      required this.provinsi,
      required this.jekel,
      required this.noTelp,
      required this.tglDaftar,
      required this.email,
      required this.umur});

  factory UserData.fromJson(Map<String, dynamic> json) {
    final idUser = json['id_user'];

    return UserData(
        idUser: (idUser is int) ? idUser : int.tryParse(idUser.toString()) ?? 0,
        username: json['username'],
        jabatan: json['jabatan'],
        nama: json['nama'],
        tglLahir: json['tgl_lahir'],
        tinggiBadan: json['tinggi_badan'],
        beratBadan: json['berat_badan'],
        alamat: json['alamat'],
        kecamatan: json['kecamatan'],
        kabupaten: json['kabupaten'],
        provinsi: json['provinsi'],
        jekel: json['jekel'],
        noTelp: json['no_telp'],
        tglDaftar: json['tgl_daftar'],
        email: json['email'],
        umur: json['umur']);
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'username': username,
      'jabatan': jabatan,
      'nama': nama,
      'tgl_lahir': tglLahir,
      'tinggi_badan': tinggiBadan,
      'berat_badan': beratBadan,
      'alamat': alamat,
      'kecamatan': kecamatan,
      'kabupaten': kabupaten,
      'provinsi': provinsi,
      'jekel': jekel,
      'no_telp': noTelp,
      'tgl_daftar': tglDaftar,
      'email': email,
      'umur': umur
    };
  }
}

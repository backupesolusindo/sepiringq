import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:isi_piringku/bloc/nav/bottom_nav.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/core.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  String selectedGender = 'Laki-Laki'; // Default jenis kelamin
  DateTime selectedDate = DateTime.now(); // Default tanggal lahir

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harus diisi';
    }
    return null; // Data valid
  }

  XFile? _imageFile;
  Future<void> _getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      // Simpan path gambar yang dipilih
      _saveImagePath(pickedFile.path);
    }
  }

  Future<void> _saveImagePath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image', imagePath);
  }

  Future<void> loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image');

    if (imagePath != null) {
      setState(() {
        _imageFile = XFile(imagePath);
      });
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String Id = '';
  String Nama = '';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      print(userData.nama);

      setState(() {
        Id = userData.idUser.toString();
        Nama = userData.nama;
      });
    }
  }

  TextEditingController idUserController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController jabatanController = TextEditingController();
  TextEditingController namaController = TextEditingController();
  TextEditingController tanggalLahirController = TextEditingController();
  TextEditingController tinggiBadanController = TextEditingController();
  TextEditingController beratBadanController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController kecamatanController = TextEditingController();
  TextEditingController kabupatenController = TextEditingController();
  TextEditingController provinsiController = TextEditingController();
  TextEditingController jenisKelaminController = TextEditingController();
  TextEditingController noTelpController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController umurController = TextEditingController();

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";
  String accessToken = "";

  Future<void> getToken() async {
    try {
      var response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'client_credentials',
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> tokenData = jsonDecode(response.body);
        accessToken = tokenData['access_token'];
        print('Token Akses: $accessToken');
      } else {
        print('Gagal mendapatkan token: ${response.statusCode}');
      }
    } catch (e) {
      print('Gagal mendapatkan token: $e');
    }
  }

  void registerUser() async {
    final apiUrl = base_url + 'api/UpdateProfil/UpdateProfil';

    final Map<String, dynamic> data = {
      'id_user': Id,
      'username': usernameController.text,
      'jabatan': jabatanController.text,
      'nama': Nama,
      'tgl_lahir': tanggalLahirController.text,
      'tinggi_badan': tinggiBadanController.text,
      'berat_badan': beratBadanController.text,
      'alamat': alamatController.text,
      'kecamatan': kecamatanController.text,
      'kabupaten': kabupatenController.text,
      'provinsi': provinsiController.text,
      'jekel': jenisKelaminController.text,
      'no_telp': noTelpController.text,
      'email': emailController.text,
      'umur': umurController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: json.encode(data),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Menggunakan token OAuth2
        },
      );

      if (response.statusCode == 200) {
        // Registrasi berhasil, lakukan sesuatu di sini
        print('Registrasi berhasil');
        print(response.body);
      } else {
        // Registrasi gagal, tampilkan pesan kesalahan atau lakukan sesuatu yang sesuai
        print('Registrasi gagal. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Terjadi kesalahan dalam proses registrasi
      print('Terjadi kesalahan: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    getToken();
    loadUserData();
    loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(selected: 3),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 130,
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.amber),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: EdgeInsets.only(top: 64)),
                          SizedBox(height: 20),
                          Center(
                            child: Container(
                              width: MediaQuery.of(context).size.height * 0.4,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 98, 182, 250),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: kElevationToShadow[1],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 0,
                              ),
                              child: Center(
                                child: Text(
                                  'EditProfile',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () {
                                print("Tapped on circle image");
                                _getImageFromGallery();
                              },
                              child: Container(
                                width: 120,
                                height: 120,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: _imageFile != null
                                    ? Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        size: 40.0,
                                        color: Colors.orange,
                                      ),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: usernameController,
                            decoration: InputDecoration(hintText: 'username'),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: emailController,
                                  decoration:
                                      InputDecoration(hintText: 'Email'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: noTelpController,
                                  decoration:
                                      InputDecoration(hintText: 'no telepon'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: tinggiBadanController,
                                  decoration:
                                      InputDecoration(hintText: 'Tinggi (cm)'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: beratBadanController,
                                  decoration:
                                      InputDecoration(hintText: 'Berat (kg)'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                      hintText: 'Jenis Kelamin'),
                                  value: selectedGender,
                                  onChanged: (value) {
                                    // Tambahkan kode untuk menangani perubahan jenis kelamin
                                    setState(() {
                                      selectedGender = value!;
                                    });
                                  },
                                  items: ['Laki-Laki', 'Perempuan']
                                      .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: tanggalLahirController,
                                  onTap: () async {
                                    // Tambahkan kode untuk menampilkan date picker
                                    final DateTime? pickedDate =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime.now(),
                                    );
                                    if (pickedDate != null &&
                                        pickedDate != selectedDate) {
                                      setState(() {
                                        selectedDate = pickedDate;
                                        tanggalLahirController.text =
                                            DateFormat('yyyy-MM-dd')
                                                .format(selectedDate);
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                      hintText: 'Tanggal Lahir'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: jabatanController,
                                  decoration:
                                      InputDecoration(hintText: 'Jabatan'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: umurController,
                                  decoration: InputDecoration(hintText: 'Umur'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: alamatController,
                                  decoration:
                                      InputDecoration(hintText: 'alamat'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: kecamatanController,
                                  decoration:
                                      InputDecoration(hintText: 'kecamatan'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: kabupatenController,
                                  decoration:
                                      InputDecoration(hintText: 'Kabupaten'),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: provinsiController,
                                  decoration:
                                      InputDecoration(hintText: 'Provinsi'),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Center(
                              child: Container(
                            child: ElevatedButton(
                              onPressed: () {
                                registerUser();
                              },
                              child: Text('Simpan'),
                            ),
                          ))
                        ],
                      ),
                    ],
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

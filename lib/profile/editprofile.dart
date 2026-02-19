import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  String selectedGender = 'Laki-Laki';
  DateTime selectedDate = DateTime.now();

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field ini harus diisi';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email harus diisi';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nomor telepon harus diisi';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Nomor telepon hanya boleh berisi angka';
    }
    if (value.length < 10) {
      return 'Nomor telepon minimal 10 digit';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '$fieldName hanya boleh berisi angka';
    }
    return null;
  }

  String? _validateDecimalNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(value)) {
      return '$fieldName hanya boleh berisi angka dan desimal';
    }
    return null;
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;

    // Jika belum ulang tahun di tahun ini, kurangi 1
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  void _updateAgeFromBirthDate() {
    if (tanggalLahirController.text.isNotEmpty) {
      try {
        DateTime birthDate =
            DateFormat('yyyy-MM-dd').parse(tanggalLahirController.text);
        int calculatedAge = _calculateAge(birthDate);
        setState(() {
          umurController.text = calculatedAge.toString();
        });
      } catch (e) {
        // Jika parsing gagal, biarkan umur kosong
        setState(() {
          umurController.text = '';
        });
      }
    }
  }

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String id = '';
  String nama = '';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));

      setState(() {
        id = userData.idUser.toString();
        nama = userData.nama;

        // Mengisi semua field dengan data yang ada
        usernameController.text = userData.username;
        namaController.text = userData.nama;
        tanggalLahirController.text = userData.tglLahir;
        tinggiBadanController.text = userData.tinggiBadan;
        beratBadanController.text = userData.beratBadan;
        alamatController.text = userData.alamat;
        kecamatanController.text = userData.kecamatan;
        kabupatenController.text = userData.kabupaten;
        provinsiController.text = userData.provinsi;
        jenisKelaminController.text = userData.jekel;
        noTelpController.text = userData.noTelp;
        emailController.text = userData.email;
        // umurController.text akan diisi otomatis dari tanggal lahir

        // Set dropdown dan date picker
        selectedGender =
            userData.jekel.isNotEmpty ? userData.jekel : 'Laki-Laki';
        if (userData.tglLahir.isNotEmpty) {
          try {
            selectedDate = DateFormat('yyyy-MM-dd').parse(userData.tglLahir);
            // Hitung umur otomatis dari tanggal lahir
            _updateAgeFromBirthDate();
          } catch (e) {
            selectedDate = DateTime.now();
          }
        }
      });
    }
  }

  TextEditingController idUserController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
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

  void updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    const apiUrl = '${base_url}api/UpdateProfil/UpdateProfil';

    final Map<String, dynamic> data = {
      'id_user': id,
      'username': usernameController.text,
      'jabatan': '',
      'nama': namaController.text,
      'tgl_lahir': tanggalLahirController.text,
      'tinggi_badan': tinggiBadanController.text,
      'berat_badan': beratBadanController.text,
      'alamat': alamatController.text,
      'kecamatan': kecamatanController.text,
      'kabupaten': kabupatenController.text,
      'provinsi': provinsiController.text,
      'jekel': selectedGender,
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
        },
      );

      if (response.statusCode == 200) {
        // Update berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );

        // Update data di SharedPreferences
        final updatedUserData = UserData(
          idUser: int.parse(id),
          username: usernameController.text,
          jabatan: '',
          nama: namaController.text,
          tglLahir: tanggalLahirController.text,
          tinggiBadan: tinggiBadanController.text,
          beratBadan: beratBadanController.text,
          alamat: alamatController.text,
          kecamatan: kecamatanController.text,
          kabupaten: kabupatenController.text,
          provinsi: provinsiController.text,
          jekel: selectedGender,
          noTelp: noTelpController.text,
          tglDaftar: '',
          email: emailController.text,
          umur: umurController.text,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'user_data', json.encode(updatedUserData.toJson()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal memperbarui profil. Status: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 172, 63),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: const BottomNavBar(selected: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color.fromARGB(255, 255, 172, 63),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Edit Profile Anda',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Personal Information Section
              _buildSectionTitle('Informasi Personal'),
              const SizedBox(height: 15),

              _buildFormCard([
                TextFormField(
                  controller: namaController,
                  decoration: _buildInputDecoration(
                    'Nama Lengkap',
                    Icons.person,
                  ),
                  validator: _validateNotEmpty,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: usernameController,
                  decoration: _buildInputDecoration(
                    'Username',
                    Icons.account_circle,
                  ),
                  validator: _validateNotEmpty,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: emailController,
                  decoration: _buildInputDecoration(
                    'Email',
                    Icons.email,
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: noTelpController,
                  decoration: _buildInputDecoration(
                    'No Telepon',
                    Icons.phone,
                  ),
                  validator: _validatePhone,
                ),
              ]),

              const SizedBox(height: 25),

              // Physical & Personal Details Section
              _buildSectionTitle('Detail Personal'),
              const SizedBox(height: 15),

              _buildFormCard([
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration(
                          'Jenis Kelamin',
                          Icons.wc,
                        ),
                        value: selectedGender,
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value!;
                          });
                        },
                        validator: _validateNotEmpty,
                        items: ['Laki-Laki', 'Perempuan'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: umurController,
                        readOnly: true,
                        decoration: _buildInputDecoration(
                          'Umur (Otomatis)',
                          Icons.calendar_today,
                        ).copyWith(
                          suffixText: 'tahun',
                          fillColor: Colors.grey[100],
                        ),
                        validator: (value) => _validateNumber(value, 'Umur'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: tanggalLahirController,
                  readOnly: true,
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                        tanggalLahirController.text =
                            DateFormat('yyyy-MM-dd').format(selectedDate);
                        // Hitung umur otomatis setelah tanggal lahir dipilih
                        _updateAgeFromBirthDate();
                      });
                    }
                  },
                  decoration: _buildInputDecoration(
                    'Tanggal Lahir',
                    Icons.cake,
                  ),
                  validator: _validateNotEmpty,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: tinggiBadanController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _buildInputDecoration(
                          'Tinggi Badan (cm)',
                          Icons.height,
                        ),
                        validator: (value) =>
                            _validateDecimalNumber(value, 'Tinggi badan'),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: beratBadanController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _buildInputDecoration(
                          'Berat Badan (kg)',
                          Icons.monitor_weight,
                        ),
                        validator: (value) =>
                            _validateDecimalNumber(value, 'Berat badan'),
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 25),

              // Address Information Section
              _buildSectionTitle('Informasi Alamat'),
              const SizedBox(height: 15),

              _buildFormCard([
                TextFormField(
                  controller: alamatController,
                  decoration: _buildInputDecoration(
                    'Alamat Lengkap',
                    Icons.home,
                  ),
                  validator: _validateNotEmpty,
                  maxLines: 2,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: kecamatanController,
                        decoration: _buildInputDecoration(
                          'Kecamatan',
                          Icons.location_city,
                        ),
                        validator: _validateNotEmpty,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextFormField(
                        controller: kabupatenController,
                        decoration: _buildInputDecoration(
                          'Kabupaten',
                          Icons.location_on,
                        ),
                        validator: _validateNotEmpty,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: provinsiController,
                  decoration: _buildInputDecoration(
                    'Provinsi',
                    Icons.map,
                  ),
                  validator: _validateNotEmpty,
                ),
              ]),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 172, 63),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontFamily: 'Readex Pro',
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color.fromARGB(255, 255, 172, 63),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 255, 172, 63),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }
}

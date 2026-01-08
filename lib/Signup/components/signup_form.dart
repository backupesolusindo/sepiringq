import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../Login/components/login_form.dart';
import '../../util/core.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    Key? key,
  }) : super(key: key);

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  String selectedGender = 'Laki-Laki'; // Default jenis kelamin
  DateTime selectedDate = DateTime.now(); // Default tanggal lahir

  String? _validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Harus diisi';
    }
    return null; // Data valid
  }

final TextEditingController usernameController = TextEditingController();
final TextEditingController passwordController = TextEditingController();
final TextEditingController jabatanController = TextEditingController();
final TextEditingController namaController = TextEditingController();
final TextEditingController tanggalLahirController = TextEditingController();
final TextEditingController tinggiBadanController = TextEditingController();
final TextEditingController beratBadanController = TextEditingController();
final TextEditingController alamatController = TextEditingController();
final TextEditingController kecamatanController = TextEditingController();
final TextEditingController kabupatenController = TextEditingController();
final TextEditingController provinsiController = TextEditingController();
final TextEditingController jenisKelaminController = TextEditingController();
final TextEditingController noTelpController = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController umurController = TextEditingController();

  bool _obscurePassword = true;
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

  void _validateAndRegister() {
  if (usernameController.text.isEmpty ||
      passwordController.text.isEmpty ||
      namaController.text.isEmpty ||
      emailController.text.isEmpty ||
      selectedGender.isEmpty || // Validasi jenis kelamin
      tanggalLahirController.text.isEmpty || // Validasi tanggal lahir
      noTelpController.text.isEmpty) { // Validasi nomor telepon
    Fluttertoast.showToast(
      msg: 'Semua field wajib diisi',
      backgroundColor: Colors.orange,
      toastLength: Toast.LENGTH_LONG,
    );
    return;
  }

  // ✅ Validasi panjang password minimal 6 karakter
  if (passwordController.text.length < 6) {
    Fluttertoast.showToast(
      msg: 'Password harus minimal 6 karakter',
      backgroundColor: Colors.red,
      toastLength: Toast.LENGTH_LONG,
    );
    return;
  }

  registerUser();
}

void registerUser() async {
  final apiUrl = base_url + 'API/Register/register';
  print('REGISTER URL: $apiUrl');
  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken', // optional
      },
      body: {
        'username': usernameController.text.trim(),
        'password': passwordController.text.trim(),
        'email': emailController.text.trim(),
        'nama': namaController.text.trim(),
        'tgl_lahir': tanggalLahirController.text,
        'tinggi_badan': tinggiBadanController.text,
        'berat_badan': beratBadanController.text,
        'alamat': alamatController.text,
        'kecamatan': kecamatanController.text,
        'kabupaten': kabupatenController.text,
        'provinsi': provinsiController.text,
        'jekel': selectedGender,
        'no_telp': noTelpController.text,
        'umur': umurController.text,
      },
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');


    Map<String, dynamic>? responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (_) {
      responseData = null;
    }

    if (response.statusCode == 200) {
      Fluttertoast.showToast(
        msg: responseData?['message']['message'] ?? 'Registrasi berhasil',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: responseData?['message']['message'] ?? 'Registrasi gagal',
        backgroundColor: Colors.red,
      );
    }
  } catch (e) {
    print('ERROR REGISTER: $e');
    Fluttertoast.showToast(
      msg: 'Server tidak dapat diakses',
      backgroundColor: Colors.red,
    );
  }
}



  @override
  void initState() {
    super.initState();
    getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_register.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  SizedBox(height: 80.0),
                  Text(
                    'REGISTER',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'Calibri',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 30.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: namaController,
                          decoration: InputDecoration(hintText: 'Nama'),
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(hintText: 'Username'),
                        ),
                      )
                    ],  
                  ),
                  SizedBox(height: 10),
                  Column(
                    children: [
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText:
                            _obscurePassword, // Ini adalah kunci untuk mengubah tampilan teks
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(hintText: 'Email'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: noTelpController,
                          decoration: InputDecoration(hintText: 'No Telepon'),
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
                          keyboardType: TextInputType.number,
                          controller: tinggiBadanController,
                          decoration: InputDecoration(hintText: 'Tinggi (cm)'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          controller: beratBadanController,
                          decoration: InputDecoration(hintText: 'Berat (kg)'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration:
                              InputDecoration(hintText: 'Jenis Kelamin'),
                          value: selectedGender,
                          onChanged: (value) {
                            // Tambahkan kode untuk menangani perubahan jenis kelamin
                            setState(() {
                              selectedGender = value!;
                            });
                          },
                          items: ['Laki-Laki', 'Perempuan'].map((String value) {
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
                            final DateTime? pickedDate = await showDatePicker(
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
                          decoration:
                              InputDecoration(hintText: 'Tanggal Lahir'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: umurController,
                          keyboardType: TextInputType.number,
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
                          decoration: InputDecoration(hintText: 'Alamat'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: kecamatanController,
                          decoration: InputDecoration(hintText: 'Kecamatan'),
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
                          decoration: InputDecoration(hintText: 'Kabupaten'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: provinsiController,
                          decoration: InputDecoration(hintText: 'Provinsi'),
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
  onPressed: _validateAndRegister, // ✅ Panggil fungsi validasi
  child: Text('Simpan'),
),
                  )),
                  SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Sudah punya akun? Login di sini',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


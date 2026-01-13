// lib/lupaPassword/lupaPassword.dart
// VERSI DIPERBAIKI - Date Picker Tanpa Error Localization

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/Signup/signup_screen.dart';
import 'package:isi_piringku/components/already_have_an_account_acheck.dart';
import 'package:isi_piringku/components/constants.dart';
import 'package:isi_piringku/dashboard/dashboard.dart';
import 'package:isi_piringku/lupaPassword/inputPasswordBaru.dart';
import 'package:isi_piringku/lupaPassword/lupaPassword.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'dart:developer' as developer;

import '../util/core.dart';

class Lupa extends StatefulWidget {
  const Lupa({
    Key? key,
  }) : super(key: key);

  @override
  State<Lupa> createState() => _LupaState();
}

class _LupaState extends State<Lupa> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tglLahirController = TextEditingController();
  DateTime? selectedDate; // Untuk menyimpan tanggal yang dipilih
  bool isLoading = false;

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  late UserData userData;

  @override
  void initState() {
    super.initState();
  }

  // Fungsi untuk menampilkan date picker (TANPA locale Indonesia)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1), // Default: 1 Januari 2000
      firstDate: DateTime(1950), // Tanggal paling lama: 1950
      lastDate: DateTime.now(), // Tanggal paling baru: Hari ini
      // HAPUS locale: const Locale('id', 'ID'), // Ini yang menyebabkan error
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor, // Warna header
              onPrimary: Colors.white, // Warna text di header
              onSurface: Colors.black, // Warna text di body
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryColor, // Warna button
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        // Format tanggal untuk ditampilkan (dd/MM/yyyy)
        _tglLahirController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Fungsi untuk mengkonversi tanggal ke format ddmmyyyy untuk API
  String _formatDateForAPI(DateTime date) {
    return DateFormat('ddMMyyyy').format(date);
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();

    // Validasi input
    if (email.isEmpty) {
      Fluttertoast.showToast(
        msg: "Email tidak boleh kosong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validasi email format
    if (!email.contains('@') || !email.contains('.')) {
      Fluttertoast.showToast(
        msg: "Format email tidak valid",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (selectedDate == null) {
      Fluttertoast.showToast(
        msg: "Tanggal lahir harus dipilih",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Format tanggal ke ddmmyyyy untuk API
      String tglLahirFormatted = _formatDateForAPI(selectedDate!);

      // Membuat request body
      final Map<String, String> data = {
        "email": email,
        "tgl_lahir": tglLahirFormatted,
      };

      developer.log('========================================');
      developer.log('🔄 REQUEST VERIFIKASI LUPA PASSWORD');
      developer.log('========================================');
      developer.log('URL: ${base_url}API/Login/lupaPassword');
      developer.log('Email: $email');
      developer.log('Tanggal Lahir (Display): ${_tglLahirController.text}');
      developer.log('Tanggal Lahir (API): $tglLahirFormatted');
      developer.log('Data: $data');
      developer.log('========================================');

      // Mengirim permintaan HTTP POST ke API
      final response = await http.post(
        Uri.parse(base_url + 'API/Login/lupaPassword'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: data,
      );

      developer.log('========================================');
      developer.log('📥 RESPONSE');
      developer.log('========================================');
      developer.log('Status Code: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');
      developer.log('========================================');

      // Cek apakah response kosong
      if (response.body.isEmpty) {
        throw Exception('Response kosong dari server');
      }

      // Cek apakah response adalah HTML (error dari server)
      if (response.body.trim().startsWith('<') ||
          response.body.toLowerCase().contains('<!doctype')) {
        developer.log('❌ ERROR: Server mengembalikan HTML instead of JSON');
        Fluttertoast.showToast(
          msg: "Error: Server tidak merespon dengan benar.\nPeriksa URL API.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      // Coba parse JSON
      dynamic responseData;
      try {
        responseData = json.decode(response.body);
        developer.log('✓ JSON parsed successfully');
      } catch (e) {
        developer.log('❌ Error parsing JSON: $e');
        Fluttertoast.showToast(
          msg: "Error: Response tidak valid dari server",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      if (response.statusCode == 200) {
        developer.log('✓ Response 200 OK');
        
        // Cek apakah response memiliki data user
        if (responseData['response'] != null) {
          userData = UserData.fromJson(responseData['response']);
          
          // Simpan data user ke SharedPreferences (sementara untuk verifikasi)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(userData.toJson()));
          
          developer.log('✓ User data saved: ${userData.nama}');

          Fluttertoast.showToast(
            msg: "✅ Verifikasi berhasil!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          // Navigasi ke halaman input password baru
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => pasBaru(),
            ),
          );
        } else {
          developer.log('❌ Response tidak memiliki data user');
          Fluttertoast.showToast(
            msg: "Data user tidak ditemukan",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        // Status code bukan 200
        developer.log('❌ HTTP Status Code: ${response.statusCode}');
        
        String errorMessage = 'Email atau tanggal lahir salah';

        if (responseData is Map) {
          if (responseData['message'] != null) {
            errorMessage = responseData['message'];
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'];
          }
        }

        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

        developer.log('Gagal verifikasi: ${response.statusCode}');
        developer.log('Pesan kesalahan: ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ EXCEPTION CAUGHT:');
      developer.log('Error: $e');
      developer.log('Stack trace: $stackTrace');
      
      Fluttertoast.showToast(
        msg: "Terjadi kesalahan koneksi",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lupa Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/bg_login.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),

                  // Header Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 60,
                          color: kPrimaryColor,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Verifikasi Akun',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Masukkan email dan tanggal lahir Anda\nuntuk reset password',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Email Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: kPrimaryColor),
                        hintText: 'contoh@email.com',
                        prefixIcon: Icon(Icons.email, color: kPrimaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: kPrimaryColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.0),

                  // Tanggal Lahir Field (Date Picker)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _tglLahirController,
                      readOnly: true, // Tidak bisa diketik manual
                      onTap: () {
                        // Buka date picker saat di-tap
                        _selectDate(context);
                      },
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Tanggal Lahir',
                        labelStyle: TextStyle(color: kPrimaryColor),
                        hintText: 'Pilih tanggal lahir',
                        prefixIcon:
                            Icon(Icons.calendar_today, color: kPrimaryColor),
                        suffixIcon: Icon(
                          Icons.arrow_drop_down,
                          color: kPrimaryColor,
                        ),
                        helperText: 'Tap untuk memilih tanggal',
                        helperStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: kPrimaryColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Info Card
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pastikan email dan tanggal lahir sesuai dengan data saat registrasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Verifikasi Button
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              'Verifikasi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tglLahirController.dispose();
    super.dispose();
  }
}
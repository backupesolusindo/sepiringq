// lib/lupaPassword/inputPasswordBaru.dart
// VERSI FINAL - Perbaikan Navigation & Clear Session

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

import '../components/constants.dart';
import '../util/core.dart';
import '../Login/login_screen.dart'; // Import halaman login

class pasBaru extends StatefulWidget {
  const pasBaru({super.key});

  @override
  State<pasBaru> createState() => _pasBaruState();
}

class _pasBaruState extends State<pasBaru> {
  String Id = '';
  final TextEditingController PasswordController = TextEditingController();
  final TextEditingController RePasswordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureRePassword = true;

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userData = UserData.fromJson(json.decode(userDataString));
      developer.log('User Name: ${userData.nama}');

      setState(() {
        Id = userData.idUser.toString();
        developer.log('✓ User ID Loaded: $Id');
      });
    } else {
      developer.log('❌ User data tidak ditemukan di SharedPreferences');
      Fluttertoast.showToast(
        msg: "Data user tidak ditemukan. Silakan verifikasi ulang.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _resetPass() async {
    // Validasi input kosong
    if (PasswordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Password tidak boleh kosong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (RePasswordController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Konfirmasi password tidak boleh kosong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validasi password minimal 6 karakter
    if (PasswordController.text.length < 6) {
      Fluttertoast.showToast(
        msg: "Password minimal 6 karakter",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validasi password sama
    if (PasswordController.text != RePasswordController.text) {
      Fluttertoast.showToast(
        msg: "Password tidak sama",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Validasi ID user
    if (Id.isEmpty) {
      Fluttertoast.showToast(
        msg: "ID User tidak ditemukan. Silakan verifikasi ulang.",
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
      String endpoint = 'api/UpdatePassword/updatePassword';
      String fullUrl = base_url + endpoint;

      developer.log('========================================');
      developer.log('🔄 REQUEST UPDATE PASSWORD');
      developer.log('========================================');
      developer.log('URL: $fullUrl');
      developer.log('Method: POST');
      developer.log('Content-Type: multipart/form-data');
      developer.log('Fields:');
      developer.log('  - id_user: $Id');
      developer.log('  - password: ${PasswordController.text}');
      developer.log('========================================');

      var request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      
      request.fields['id_user'] = Id;
      request.fields['password'] = PasswordController.text;
      
      request.headers['Accept'] = 'application/json';

      developer.log('Sending multipart request...');
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      developer.log('========================================');
      developer.log('📥 RESPONSE');
      developer.log('========================================');
      developer.log('Status Code: ${response.statusCode}');
      developer.log('Response Body: ${response.body}');
      developer.log('========================================');

      if (response.body.isEmpty) {
        throw Exception('Response kosong dari server');
      }

      if (response.body.trim().startsWith('<') || 
          response.body.toLowerCase().contains('<!doctype')) {
        developer.log('❌ ERROR: Server mengembalikan HTML instead of JSON');
        Fluttertoast.showToast(
          msg: "Error: Server mengembalikan halaman HTML\n\nEndpoint mungkin salah.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      dynamic responseData;
      try {
        responseData = json.decode(response.body);
        developer.log('✓ JSON parsed successfully: $responseData');
      } catch (e) {
        developer.log('❌ Error parsing JSON: $e');
        developer.log('Raw response: ${response.body}');
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
        developer.log('✓✓✓ PASSWORD BERHASIL DIUBAH! ✓✓✓');
        
        // Tampilkan pesan sukses
        String successMessage = "Password berhasil diubah!";
        if (responseData is Map && responseData['message'] != null) {
          successMessage = responseData['message'];
        }
        
        Fluttertoast.showToast(
          msg: "✅ $successMessage\n\nSilakan login dengan password baru Anda",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16,
        );

        // PENTING: CLEAR SEMUA DATA SESSION
        final prefs = await SharedPreferences.getInstance();
        
        // Hapus semua data yang terkait dengan session login
        await prefs.remove('user_data');      // Data user dari lupa password
        await prefs.clear();                   // Clear semua SharedPreferences
        
        developer.log('✓ All session data cleared from SharedPreferences');

        // Tunggu sebentar agar toast terlihat
        await Future.delayed(Duration(milliseconds: 1000));

        // NAVIGASI KE HALAMAN LOGIN dengan menghapus semua history
        if (mounted) {
          // Gunakan Navigator.pushAndRemoveUntil untuk clear semua route
          // dan pastikan user harus login ulang
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false, // Hapus semua route sebelumnya
          );
        }
      } else {
        // Status code bukan 200
        developer.log('❌ HTTP Status Code: ${response.statusCode}');
        String errorMessage = 'Gagal mengubah password';
        
        if (responseData is Map) {
          if (responseData.containsKey('message')) {
            if (responseData['message'] is String) {
              errorMessage = responseData['message'];
            } else if (responseData['message'] is Map &&
                responseData['message'].containsKey('message')) {
              errorMessage = responseData['message']['message'];
            }
          } else if (responseData['error'] != null) {
            errorMessage = responseData['error'].toString();
          }
        }

        Fluttertoast.showToast(
          msg: '❌ $errorMessage',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

        developer.log('Error details:');
        developer.log('Status: ${response.statusCode}');
        developer.log('Body: ${response.body}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ EXCEPTION CAUGHT:');
      developer.log('Error: $e');
      developer.log('Stack trace: $stackTrace');
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: '❌ Error koneksi server',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
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
        title: Text('Reset Password'),
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
                  // Title
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.lock_reset,
                          size: 60,
                          color: kPrimaryColor,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Masukkan Password Baru',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Buat password baru untuk akun Anda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  
                  // Password Baru Field
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
                      controller: PasswordController,
                      textInputAction: TextInputAction.next,
                      obscureText: _obscurePassword,
                      cursorColor: kPrimaryColor,
                      style: TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Masukkan Password Baru",
                        labelText: "Password Baru",
                        labelStyle: TextStyle(color: kPrimaryColor),
                        prefixIcon: Icon(Icons.lock, color: kPrimaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimaryColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  
                  // Konfirmasi Password Field
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
                      controller: RePasswordController,
                      textInputAction: TextInputAction.done,
                      obscureText: _obscureRePassword,
                      cursorColor: kPrimaryColor,
                      style: TextStyle(fontSize: 16),
                      onFieldSubmitted: (_) {
                        if (!isLoading) {
                          _resetPass();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Masukkan Ulang Password",
                        labelText: "Konfirmasi Password",
                        labelStyle: TextStyle(color: kPrimaryColor),
                        prefixIcon: Icon(Icons.lock_outline, color: kPrimaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureRePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureRePassword = !_obscureRePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimaryColor, width: 2),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  
                  // Password Requirements
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Password minimal 6 karakter',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30),
                  
                  // Submit Button
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
                      onPressed: isLoading ? null : _resetPass,
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Submit',
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
    PasswordController.dispose();
    RePasswordController.dispose();
    super.dispose();
  }
}
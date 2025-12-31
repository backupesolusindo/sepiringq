import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/Signup/signup_screen.dart';
import 'package:isi_piringku/components/already_have_an_account_acheck.dart';
import 'package:isi_piringku/components/constants.dart';
import 'package:isi_piringku/dashboard/dashboard.dart';
import 'package:isi_piringku/lupaPassword/lupaPassword.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../util/core.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    Key? key,
  }) : super(key: key);

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = base_url + "api/Token/token";
  String accessToken = "";
  late UserData userData;

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

    print('Token response status: ${response.statusCode}');
    print('Token response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    Map<String, dynamic> tokenData;
    try {
      tokenData = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Response bukan JSON valid: ${response.body}');
    }

    if (!tokenData.containsKey('access_token')) {
      throw Exception('Access token tidak ditemukan dalam respons');
    }

    accessToken = tokenData['access_token'] as String;
    print('Token Akses: $accessToken');

  } catch (e) {
    print('Gagal mendapatkan token: $e');
    Fluttertoast.showToast(
      msg: '❌ $e',
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }
}

  Future<void> _login() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Username dan password wajib diisi',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    // Tunggu sampai token siap
    await getToken();

    if (accessToken.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Token tidak tersedia. Coba lagi.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    final Map<String, String> data = {
      "username": username,
      "password": password,
    };

    try {
      final response = await http.post(
        Uri.parse(base_url + 'api/Login/Login'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: data,
      );

      print('Login response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['response'] != null) {
          // ✅ LOGIN BERHASIL → SIMPAN SESI
          final prefs = await SharedPreferences.getInstance();
          userData = UserData.fromJson(responseData['response']);
          prefs.setString('access_token', accessToken);
          prefs.setString('user_data', json.encode(userData.toJson()));

          Fluttertoast.showToast(
            msg: '✅ Login berhasil',
            backgroundColor: Colors.green,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
          );
        } else {
          // ❌ DATA TIDAK LENGKAP
          _handleLoginError(responseData);
        }
      } else {
        // ❌ LOGIN GAGAL → HAPUS SESI LAMA
        await _clearSession();
        _handleLoginError(json.decode(response.body));
      }
    } catch (e) {
      await _clearSession();
      print('Error login: $e');
      Fluttertoast.showToast(
        msg: '❌ Error koneksi: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  void _handleLoginError(Map<String, dynamic> responseData) {
    String errorMsg = 'Username atau password salah';
    try {
      if (responseData.containsKey('message')) {
        if (responseData['message'] is String) {
          errorMsg = responseData['message'];
        } else if (responseData['message'] is Map && responseData['message'].containsKey('message')) {
          errorMsg = responseData['message']['message'];
        }
      }
    } catch (_) {}
    
    Fluttertoast.showToast(
      msg: '❌ $errorMsg',
      backgroundColor: Colors.red,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }

  @override
  void initState() {
    super.initState();
    
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.text, // bukan email, karena pakai username
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "Username",
              prefixIcon: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Icon(Icons.person),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding),
            child: TextFormField(
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              obscureText: true,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText: "Password",
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.lock),
                ),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Lupa()),
              );
            },
            child: Text('Lupa Password'),
          ),
          const SizedBox(height: defaultPadding),
          Hero(
            tag: "login_btn",
            child: ElevatedButton(
              onPressed: _login,
              child: Text("LOGIN".toUpperCase()),
            ),
          ),
          const SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
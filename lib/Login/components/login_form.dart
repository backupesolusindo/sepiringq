import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:isi_piringku/Signup/signup_screen.dart';
import 'package:isi_piringku/components/already_have_an_account_acheck.dart';
import 'package:isi_piringku/components/constants.dart';
import 'package:isi_piringku/dashboard/dashboard.dart';
import 'package:isi_piringku/lupaPassword/lupaPassword.dart';
import 'package:isi_piringku/model/user.dart';
import 'package:isi_piringku/model/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:developer' as developer;
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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  String clientId = "PKL2023";
  String clientSecret = "PKLSERU";
  String tokenUrl = "${base_url}api/Token/token";
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

      developer.log('Token response status: ${response.statusCode}');
      developer.log('Token response body: ${response.body}');

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
      developer.log('Token Akses: $accessToken');
    } catch (e) {
      developer.log('Gagal mendapatkan token: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: '❌ Gagal mendapatkan token akses',
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Username dan password wajib diisi',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${base_url}API/Login/login'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'username': username,
          'password': password,
        },
      );

      developer.log('STATUS: ${response.statusCode}');
      developer.log('BODY: ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Response kosong dari server');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        userData = UserData.fromJson(responseData['response']);
        await prefs.setString('user_data', jsonEncode(userData.toJson()));

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false)
              .updateUser(userData);

          Fluttertoast.showToast(
            msg: '✅ Login berhasil',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        }
      } else {
        String errorMsg = 'Username atau password salah';
        try {
          if (responseData.containsKey('message')) {
            if (responseData['message'] is String) {
              errorMsg = responseData['message'];
            } else if (responseData['message'] is Map &&
                responseData['message'].containsKey('message')) {
              errorMsg = responseData['message']['message'];
            }
          }
        } catch (_) {}

        if (mounted) {
          Fluttertoast.showToast(
            msg: '❌ $errorMsg',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      developer.log('ERROR LOGIN: $e');
      if (mounted) {
        Fluttertoast.showToast(
          msg: '❌ Error koneksi server',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username Field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              cursorColor: kPrimaryColor,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username tidak boleh kosong';
                }
                return null;
              },
              decoration: const InputDecoration(
                hintText: "Username",
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.person, color: kPrimaryColor),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: defaultPadding,
                  vertical: defaultPadding,
                ),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding),

          // Password Field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              obscureText: _obscurePassword,
              cursorColor: kPrimaryColor,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Password tidak boleh kosong';
                }
                if (value.length < 6) {
                  return 'Password minimal 6 karakter';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.lock, color: kPrimaryColor),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: defaultPadding,
                  vertical: defaultPadding,
                ),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding),

          // Forgot Password Button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Lupa()),
                );
              },
              child: const Text(
                'Lupa Password?',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding * 1.5),

          // Login Button
          Hero(
            tag: "login_btn",
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        "LOGIN",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding * 1.5),

          // Sign Up Link
          AlreadyHaveAnAccountCheck(
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
